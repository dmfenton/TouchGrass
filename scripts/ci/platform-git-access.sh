#!/usr/bin/env bash
# Lets this CI job's git (and so uv and SwiftPM) fetch the tagged Platform libraries from the
# private https://github.com/dmfenton/platform.git with the read-only FENTON_PLATFORM_DEPLOY_KEY.
# A copy of platform's .github/actions/platform-git-access, which this public repository cannot
# use. Job-scoped: the key lives in RUNNER_TEMP (emptied per job) and git reads the URL rewrite
# from GITHUB_ENV, never from the runner account's global config.
# Usage (step env KEY=${{ secrets.FENTON_PLATFORM_DEPLOY_KEY }}): bash scripts/ci/platform-git-access.sh
set -euo pipefail
[[ -n "${KEY:-}" ]] || { echo "::error::platform-git-access: FENTON_PLATFORM_DEPLOY_KEY is empty" >&2; exit 1; }
key="$RUNNER_TEMP/fenton-platform-deploy-key"
hosts="$RUNNER_TEMP/github_known_hosts"
(umask 077 && printf '%s\n' "$KEY" > "$key")
# GitHub's published ed25519 host key, SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
printf '%s\n' 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' > "$hosts"
{
  echo "GIT_SSH_COMMAND=ssh -i $key -o IdentitiesOnly=yes -o UserKnownHostsFile=$hosts -o StrictHostKeyChecking=yes"
  echo "GIT_CONFIG_COUNT=1"
  echo "GIT_CONFIG_KEY_0=url.ssh://git@github.com/dmfenton/platform.git.insteadOf"
  echo "GIT_CONFIG_VALUE_0=https://github.com/dmfenton/platform.git"
  echo "PLATFORM_SSH_KEY=$key"
  echo "PLATFORM_KNOWN_HOSTS=$hosts"
} >> "$GITHUB_ENV"
