#!/usr/bin/env python3
"""Reject unsigned/ad-hoc or wrong-team native distribution bundles."""
import argparse
import plistlib
import subprocess
from pathlib import Path


def verify(bundle: Path, platform: str) -> None:
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(bundle)], check=True)
    signature = subprocess.run(["codesign", "-dvv", str(bundle)], check=True, capture_output=True, text=True).stderr
    authority = "Developer ID Application:" if platform == "macos" else "Apple Distribution:"
    if authority not in signature or "TeamIdentifier=PG5D259899" not in signature:
        raise SystemExit("Distribution requires the expected stable Apple identity and team")
    if platform == "ios":
        info = plistlib.loads((bundle / "Info.plist").read_bytes())
        if info["CFBundleIdentifier"] != "com.dmfenton.TouchGrass":
            raise SystemExit("Unexpected iOS bundle identifier")
        profile = plistlib.loads(subprocess.check_output([
            "security", "cms", "-D", "-i", str(bundle / "embedded.mobileprovision")
        ]))
        entitlements = profile["Entitlements"]
        if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices"):
            raise SystemExit("TestFlight requires an App Store provisioning profile")
        if entitlements.get("get-task-allow", False):
            raise SystemExit("TestFlight must not permit debugging")
        if entitlements.get("application-identifier") != "PG5D259899.com.dmfenton.TouchGrass":
            raise SystemExit("Provisioning profile does not match Touchgrass")
    print(f"Verified {platform} distribution signature: {bundle.name}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--platform", choices=["ios", "macos"], required=True)
    args = parser.parse_args()
    verify(args.bundle, args.platform)
