#!/usr/bin/env python3
"""Enforce behavioral core coverage from the real simulator result bundle."""
import json
import subprocess
import sys

report = json.loads(subprocess.check_output([
    "xcrun", "xccov", "view", "--report", "--json", sys.argv[1]
]))
files = [file for target in report["targets"] for file in target.get("files", [])
         if file["name"] == "BreakPlan.swift"]
if not files:
    raise SystemExit("No BreakPlan.swift coverage found")
for file in files:
    coverage = file["lineCoverage"]
    print(f"Scheduling and progress coverage: {coverage:.1%}")
    if coverage < 0.95:
        raise SystemExit("Scheduling and progress coverage must be at least 95%")
