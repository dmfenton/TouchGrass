#!/usr/bin/env python3
"""CI source guard for installable artifacts; simulator compilation is exempt."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for name in ("scripts/build.sh", "scripts/release.sh"):
    source = (root / name).read_text()
    if "verify_native_signature.py" not in source or "Developer ID Application" not in source:
        raise SystemExit(f"{name}: must enforce and verify Developer ID signing")
    if "Building without code signing" in source or "CODE_SIGNING_ALLOWED=NO" in source:
        raise SystemExit(f"{name}: unsigned distribution fallback is forbidden")
for path in [*root.glob("scripts/*.sh"), *root.glob(".github/workflows/*.yml")]:
    text = path.read_text()
    for forbidden in ("security default-keychain -s", "security list-keychains -d user -s", "security delete-keychain login"):
        if forbidden in text:
            raise SystemExit(f"{path.name}: interactive keychain mutation is forbidden")
print("Native signing source checks passed")
