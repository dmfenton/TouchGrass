# Touch Grass

Native Swift wellness apps: macOS menu bar at the repository root; iPhone/iPad in `ios/`.
Keep changes modular and functional. Use explicit enum states, quiet logs, and typed boundaries.
Preserve unrelated changes. Check branch, HEAD, and worktree status before editing.

## Setup and validation

- `bash scripts/codex-worktree-setup.sh` resolves the immutable shared Platform package, generates iOS, and enables the tracked validation hook for this worktree.
- `bash scripts/ios-check.sh`: compile, simulator tests, SwiftLint fixes and strict lint, core coverage, signing source checks.
- Set `TOUCHGRASS_SIMULATOR` to an installed simulator destination if the default is unavailable.
- `bash scripts/test.sh` tests the existing Mac target. Never swallow test or lint failures.
- `ios/project.yml` is the iOS project source of truth; commit its generated project alongside changes.
- Pin `FentonDesignSystem` through `.github/fenton-mobile.lock`; reuse its components, tokens, and semantic theme.
- Do not add a backend, agent, identity, or Platform process without a concrete remote requirement.
- Keep calendar and progress data on-device. Never log private events or commit signing material.
- Test clock boundaries, calendar conflicts, denied permissions, persistence, and foreground refresh.
- Enforce at least 95% coverage on scheduling/progress logic; use simulator interaction for UI verification.

## Release and signing

- Release only when authorized. An upload is not TestFlight delivery: verify Apple processing and tester-group assignment.
- Never distribute unsigned or ad-hoc native artifacts. Mac distribution requires Developer ID Application;
  TestFlight requires Apple distribution signing and the correct provisioning profile.
- Never change the interactive user's default keychain or global keychain search list.
- Never lock, delete, replace, or reset login.keychain-db. Any CI cleanup must target its own dedicated keychain.
- Keep bundle IDs and signing team stable. Preserve privacy permissions and verify actual runtime resource access.
- iOS bundle ID: `com.dmfenton.TouchGrass`; signing team: `PG5D259899`.
- See `docs/ios-release.md` for the release contract and prerequisites.

## Code review rules

Review persistence loss, notification schedule races, calendar privacy, signing identity, and false release-success claims.
Require real tests and no swallowed failures. Never weaken a gate just to get a release through.
