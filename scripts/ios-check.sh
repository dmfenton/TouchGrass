#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null
command -v swiftlint >/dev/null
bash ios/ci_scripts/ci_post_clone.sh
xcodegen generate --spec ios/project.yml
build_dir="${TOUCHGRASS_BUILD_DIR:-.build-ios}"
destination="${TOUCHGRASS_SIMULATOR:-platform=iOS Simulator,name=iPhone 17 Pro}"
mkdir -p "$build_dir"
xcodebuild -project ios/TouchGrassMobile.xcodeproj -scheme TouchGrassMobile \
  -destination "$destination" -derivedDataPath "$build_dir" build-for-testing CODE_SIGNING_ALLOWED=NO -quiet
results="$build_dir/Tests-$(date +%s).xcresult"
xcodebuild -project ios/TouchGrassMobile.xcodeproj -scheme TouchGrassMobile \
  -destination "$destination" -derivedDataPath "$build_dir" -resultBundlePath "$results" \
  test-without-building CODE_SIGNING_ALLOWED=NO -quiet
swiftlint lint --fix --no-cache --config ios/.swiftlint.yml --quiet
swiftlint lint --strict --no-cache --config ios/.swiftlint.yml --quiet
python3 scripts/check_ios_coverage.py "$results"
python3 scripts/check_native_signing.py
