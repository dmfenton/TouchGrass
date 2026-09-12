#!/bin/sh

set -eu

repository_root="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
platform_root="$repository_root/vendor/platform.dmfenton.net"
lock_file="$repository_root/.github/fenton-mobile.lock"

# The lock file contains one trusted shell assignment owned by this repository.
# shellcheck disable=SC1090
. "$lock_file"

if ! printf '%s\n' "${FENTON_MOBILE_SHA:-}" | grep -Eq '^[0-9a-f]{40}$'; then
  echo "Invalid FENTON_MOBILE_SHA in $lock_file" >&2
  exit 2
fi

if [ ! -d "$platform_root/.git" ]; then
  mkdir -p "$(dirname "$platform_root")"
  git clone --filter=blob:none https://github.com/dmfenton/platform.dmfenton.net.git "$platform_root"
fi

if ! git -C "$platform_root" cat-file -e "$FENTON_MOBILE_SHA^{commit}"; then
  git -C "$platform_root" fetch --filter=blob:none origin "$FENTON_MOBILE_SHA"
fi
git -C "$platform_root" checkout --detach "$FENTON_MOBILE_SHA"
test "$(git -C "$platform_root" rev-parse HEAD)" = "$FENTON_MOBILE_SHA"
