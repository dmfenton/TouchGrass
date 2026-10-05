#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in xcodebuild xcodegen swiftlint python3; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done
bash ios/ci_scripts/ci_post_clone.sh
simulator_pin="$(tr -d '[:space:]' < fenton-simulator.lock)"
[[ "$simulator_pin" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid simulator tooling pin" >&2; exit 1; }
if ! git -C vendor/platform.dmfenton.net cat-file -e "$simulator_pin^{commit}"; then
  git -C vendor/platform.dmfenton.net fetch origin "$simulator_pin"
fi
xcodegen generate --spec ios/project.yml
git config extensions.worktreeConfig true
git config --worktree core.hooksPath .githooks
