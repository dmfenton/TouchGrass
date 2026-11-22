#!/usr/bin/env bash
# Identical thin entrypoint in each app (scripts/simulator.sh). The shared simulator pool is one
# per Mac, so its tool is installed once per Mac by dmfenton/machine at the newest Platform
# release tag, not pinned per repository. See tools/simulators/README.md.
set -euo pipefail
tool="${FENTON_SIMULATOR_TOOL:-$HOME/.local/bin/fenton-simulator}"
if [[ ! -x "$tool" ]]; then
  echo "fenton-simulator is not installed at $tool; run dmfenton/machine's install.sh on this Mac." >&2
  exit 1
fi
exec "$tool" "$@"
