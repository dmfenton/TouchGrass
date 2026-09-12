#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in xcodebuild xcodegen swiftlint python3; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done
bash ios/ci_scripts/ci_post_clone.sh
xcodegen generate --spec ios/project.yml
git config extensions.worktreeConfig true
git config --worktree core.hooksPath .githooks
