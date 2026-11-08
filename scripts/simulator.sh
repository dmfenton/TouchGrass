#!/usr/bin/env bash
# Identical thin entrypoint in each app: resolve the separately pinned Platform tool.
set -euo pipefail
repo="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
pin="$(tr -d '[:space:]' < "$repo/fenton-simulator.lock")"
[[ "$pin" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid simulator pin: $repo/fenton-simulator.lock" >&2; exit 1; }
common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)"
main="$(dirname "$common")"
source="${FENTON_PLATFORM_SOURCE:-$(dirname "$main")/platform.dmfenton.net}"
if [[ -z "${FENTON_PLATFORM_SOURCE:-}" && ! -e "$source/.git" && -e "$repo/vendor/platform.dmfenton.net/.git" ]]; then
  source="$repo/vendor/platform.dmfenton.net"
fi
tool="$common/fenton-simulator-tool/$pin"
if [[ ! -f "$tool/tools/simulators/cli.py" ]]; then
  git -C "$source" cat-file -e "$pin^{commit}" || {
    echo "Simulator tool commit $pin unavailable in $source; fetch the approved Platform commit there." >&2
    exit 1
  }
  mkdir -p "$(dirname "$tool")"
  staging="$(mktemp -d "$(dirname "$tool")/.staging.XXXXXX")"
  trap 'rm -rf -- "$staging"' EXIT
  git -C "$source" archive "$pin" tools/simulators | tar -xf - -C "$staging"
  # Concurrent launchers can share the immutable tool version.
  python3 - "$staging" "$tool" <<'PYRENAME'
import errno,os,sys
try: os.rename(sys.argv[1],sys.argv[2])
except OSError as error:
    if error.errno not in (errno.EEXIST,errno.ENOTEMPTY): raise
    if not os.path.isfile(os.path.join(sys.argv[2],"tools/simulators/cli.py")): raise
PYRENAME
  rm -rf -- "$staging"
fi
exec python3 "$tool/tools/simulators/cli.py" "$@"
