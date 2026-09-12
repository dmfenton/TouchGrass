#!/usr/bin/env python3
"""Resolve a real installed simulator instead of assuming a runner's device inventory."""
import json
import subprocess


def listing(kind):
    return json.loads(subprocess.check_output(["xcrun", "simctl", "list", kind, "--json"]))[kind]


runtimes = [runtime for runtime in listing("runtimes")
            if runtime.get("isAvailable") and ".iOS-" in runtime["identifier"]]
if not runtimes:
    raise SystemExit("No iOS runtime installed. Run xcodebuild -downloadPlatform iOS first.")
runtime = max(runtimes, key=lambda item: tuple(int(part) for part in item["version"].split(".")))
devices = listing("devices").get(runtime["identifier"], [])
device = next((item for item in devices if item.get("isAvailable") and item["name"].startswith("iPhone")), None)
if device:
    identifier = device["udid"]
else:
    types = listing("devicetypes")
    device_type = next(item for item in types if item["name"] == "iPhone 16 Pro")
    identifier = subprocess.check_output([
        "xcrun", "simctl", "create", "Touch Grass CI", device_type["identifier"], runtime["identifier"]
    ], text=True).strip()
print(f"platform=iOS Simulator,id={identifier}")
