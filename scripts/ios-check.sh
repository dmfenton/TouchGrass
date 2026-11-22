#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
lease_args=(run --app touch-grass)
run_tests=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    # --no-tests: compile, lint and signing checks only; never boots a simulator. Laptop CI uses
    # it because a simulator booted first by the CI account owns the host-wide cfprefsd
    # shared-memory segment and breaks every UI test in Daniel's simulators.
    --no-tests) run_tests=0; shift ;;
    --device-type|--runtime|--queue-timeout)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo "Missing value for $1" >&2; exit 2; }
      lease_args+=("$1" "$2")
      shift 2
      ;;
    *) echo "Unknown simulator option: $1" >&2; exit 2 ;;
  esac
done
if [[ $run_tests == 0 && ${#lease_args[@]} -gt 3 ]]; then
  echo "--no-tests boots no simulator; remove the simulator selection options" >&2
  exit 2
fi
if [[ -n "${FENTON_SIMULATOR_ID:-}" && ${#lease_args[@]} -gt 3 ]]; then
  echo "Simulator selection belongs to the outer lease; remove nested selection options" >&2
  exit 2
fi
command -v xcodegen >/dev/null
command -v swiftlint >/dev/null
bash ios/ci_scripts/ci_post_clone.sh
xcodegen generate --spec ios/project.yml
build_dir="${TOUCHGRASS_BUILD_DIR:-.build-ios}"
mkdir -p "$build_dir"
xcodebuild -project ios/TouchGrassMobile.xcodeproj -scheme TouchGrassMobile \
  -destination "generic/platform=iOS Simulator" -derivedDataPath "$build_dir" build-for-testing CODE_SIGNING_ALLOWED=NO -quiet
if [[ $run_tests == 0 ]]; then
  swiftlint lint --strict --no-cache --config ios/.swiftlint.yml --quiet
  python3 scripts/check_native_signing.py
  echo "ios-check: compiled and linted; simulator tests skipped (--no-tests)"
  exit 0
fi
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
  scripts/simulator.sh "${lease_args[@]}" -- "${test_command[@]}"
fi
swiftlint lint --fix --no-cache --config ios/.swiftlint.yml --quiet
swiftlint lint --strict --no-cache --config ios/.swiftlint.yml --quiet
python3 scripts/check_ios_coverage.py "$results"
python3 scripts/check_native_signing.py
