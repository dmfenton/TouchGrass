#!/bin/bash
# Generates the iOS project and enables the tracked hook. FentonDesignSystem comes from the Platform
# release tag in ios/project.yml (dmfenton/platform docs/consuming-platform.md); Xcode resolves it
# and Package.resolved records the exact commit. The simulator pool tool is installed per Mac by
# dmfenton/machine.
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in xcodebuild xcodegen swiftlint python3; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done
xcodegen generate --spec ios/project.yml
git config extensions.worktreeConfig true
git config --worktree core.hooksPath .githooks
