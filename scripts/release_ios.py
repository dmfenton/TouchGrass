#!/usr/bin/env python3
"""Archive, verify and optionally upload Touch Grass; never mutate keychain settings."""
from __future__ import annotations
import argparse
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import time
import zipfile
from apple_api import AppStoreConnectClient, credentials
from verify_native_signature import verify

ROOT = Path(__file__).resolve().parents[1]
APP_ID = "6759848550"
BUNDLE_ID = "com.dmfenton.TouchGrass"
TEAM = "PG5D259899"


def run(*args: str, **kwargs) -> str:
    return subprocess.check_output(args, cwd=ROOT, text=True, **kwargs).strip()


def distribute(client: AppStoreConnectClient, version: str, number: str) -> str:
    deadline = time.monotonic() + 1800
    while time.monotonic() < deadline:
        response = client.request("GET", "builds", query={
            "filter[app]": APP_ID, "filter[version]": number, "include": "preReleaseVersion", "limit": "100"
        })
        versions = {item["id"]: item["attributes"]["version"] for item in response.get("included", [])}
        matching = [item for item in response["data"] if versions.get(
            item["relationships"]["preReleaseVersion"]["data"]["id"]
        ) == version]
        if matching:
            build = matching[0]
            state = build["attributes"]["processingState"]
            if state in {"FAILED", "INVALID"}:
                raise SystemExit(f"Apple rejected build processing: {state}")
            if state == "VALID":
                break
        time.sleep(20)
    else:
        raise SystemExit("Apple processing is still pending. Resume verification; do not upload again.")
    groups = client.request("GET", f"apps/{APP_ID}/betaGroups")["data"]
    group = next((item for item in groups if item["attributes"]["name"] == "Internal"), None)
    if group is None or not group["attributes"].get("isInternalGroup"):
        raise SystemExit("Create the Internal tester group in App Store Connect, then resume verification")
    members = client.request("GET", f"betaGroups/{group['id']}/betaTesters")["data"]
    if not members:
        raise SystemExit("Internal group has no testers; add your Apple account before delivery")
    linked = client.request("GET", f"betaGroups/{group['id']}/builds")["data"]
    if not any(item["id"] == build["id"] for item in linked):
        client.request("POST", f"betaGroups/{group['id']}/relationships/builds", body={
            "data": [{"type": "builds", "id": build["id"]}]
        })
    linked = client.request("GET", f"betaGroups/{group['id']}/builds")["data"]
    detail = client.request("GET", f"builds/{build['id']}/buildBetaDetail")["data"]["attributes"]
    if not any(item["id"] == build["id"] for item in linked) or detail["internalBuildState"] != "IN_BETA_TESTING":
        raise SystemExit("Build is processed but internal distribution is not yet verified. Resume verification.")
    print(f"Verified Touch Grass {version} ({number}) in TestFlight Internal")
    return build["id"]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--upload", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--profile", default="Touch Grass iOS App Store")
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version) or not re.fullmatch(r"[1-9]\d*", args.build):
        parser.error("Use a semantic version and positive integer build")
    if args.verify_only:
        distribute(AppStoreConnectClient(*credentials()), args.version, args.build)
        return
    if args.upload:
        if run("git", "status", "--porcelain"):
            raise SystemExit("Commit and review all changes before uploading")
        if run("git", "rev-parse", "HEAD") != run("git", "rev-parse", "origin/main"):
            raise SystemExit("Upload only the reviewed origin/main commit")
    archive = ROOT / ".build-ios" / f"TouchGrass-{args.version}-{args.build}.xcarchive"
    export = ROOT / ".build-ios" / f"export-{args.version}-{args.build}"
    subprocess.run([
        "xcodebuild", "-project", "ios/TouchGrassMobile.xcodeproj", "-scheme", "TouchGrassMobile",
        "-configuration", "Release", "-destination", "generic/platform=iOS", "-archivePath", str(archive),
        "archive", "CODE_SIGN_STYLE=Manual", "CODE_SIGN_IDENTITY=Apple Distribution",
        f"PROVISIONING_PROFILE_SPECIFIER={args.profile}", f"MARKETING_VERSION={args.version}",
        f"CURRENT_PROJECT_VERSION={args.build}", "-quiet"
    ], cwd=ROOT, check=True)
    app = archive / "Products/Applications/TouchGrassMobile.app"
    verify(app, "ios")
    with tempfile.TemporaryDirectory(prefix="touchgrass-release-") as temporary:
        folder = Path(temporary)
        options = folder / "ExportOptions.plist"
        options.write_bytes(plistlib.dumps({
            "method": "app-store-connect", "destination": "export", "teamID": TEAM,
            "signingStyle": "manual", "signingCertificate": "Apple Distribution",
            "provisioningProfiles": {BUNDLE_ID: args.profile}, "uploadSymbols": True,
            "manageAppVersionAndBuildNumber": False
        }))
        subprocess.run([
            "xcodebuild", "-exportArchive", "-archivePath", str(archive), "-exportPath", str(export),
            "-exportOptionsPlist", str(options), "-quiet"
        ], check=True)
        ipa, = export.glob("*.ipa")
        with zipfile.ZipFile(ipa) as package:
            package.extractall(folder / "exported")
        exported_app, = (folder / "exported/Payload").glob("*.app")
        verify(exported_app, "ios")
        if not args.upload:
            print(f"Verified archive and IPA exported to {export}. No upload requested.")
            return
        key_id, issuer, private_key = credentials()
        key = folder / f"AuthKey_{key_id}.p8"
        key.write_text(private_key.replace("\\n", "\n"))
        key.chmod(0o600)
        ipa, = export.glob("*.ipa")
        environment = dict(os.environ, API_PRIVATE_KEYS_DIR=str(folder))
        subprocess.run([
            "xcrun", "altool", "--upload-app", "-f", str(ipa), "--type", "ios",
            "--api-key", key_id, "--api-issuer", issuer
        ], env=environment, check=True)
        distribute(AppStoreConnectClient(key_id, issuer, private_key), args.version, args.build)


if __name__ == "__main__":
    main()
