#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null
command -v swiftlint >/dev/null
bash ios/ci_scripts/ci_post_clone.sh
xcodegen generate --spec ios/project.yml
build_dir="${TOUCHGRASS_BUILD_DIR:-.build-ios}"
mkdir -p "$build_dir"
xcodebuild -project ios/TouchGrassMobile.xcodeproj -scheme TouchGrassMobile \
  -destination "generic/platform=iOS Simulator" -derivedDataPath "$build_dir" build-for-testing CODE_SIGNING_ALLOWED=NO -quiet
results="$build_dir/Tests-$(date +%s).xcresult"
simulator="${FENTON_SIMULATOR_ID:-}"
[[ -n "$simulator" ]] || simulator='{simulator}'
test_command=(xcodebuild -project ios/TouchGrassMobile.xcodeproj -scheme TouchGrassMobile \
  -destination "platform=iOS Simulator,id=$simulator" -derivedDataPath "$build_dir" -resultBundlePath "$results" \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -maximum-parallel-testing-workers 1 test-without-building CODE_SIGNING_ALLOWED=NO -quiet)
if [[ -n "${FENTON_SIMULATOR_ID:-}" ]]; then
  scripts/simulator.sh guard "$FENTON_SIMULATOR_LEASE" "$FENTON_SIMULATOR_ID"
  "${test_command[@]}"
else
  scripts/simulator.sh run --app touch-grass -- "${test_command[@]}"
fi
swiftlint lint --fix --no-cache --config ios/.swiftlint.yml --quiet
swiftlint lint --strict --no-cache --config ios/.swiftlint.yml --quiet
python3 scripts/check_ios_coverage.py "$results"
python3 scripts/check_native_signing.py
