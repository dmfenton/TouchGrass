#!/usr/bin/env python3
"""Consume the shared helper's device; never create or borrow unrelated simulators."""
import os

identifier = os.environ.get("FENTON_SIMULATOR_ID")
if not identifier:
    raise SystemExit("Run scripts/ios-check.sh through the shared simulator lease")
print(f"platform=iOS Simulator,id={identifier}")
