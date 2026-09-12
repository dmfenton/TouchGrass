# iOS release

Touch Grass uses `ios/TouchGrassMobile.xcodeproj`, generated from `ios/project.yml`, and the
existing App Store Connect record **Time to Touch Grass**, Apple ID `6759848550`, bundle
`com.dmfenton.TouchGrass`, team `PG5D259899`.

## Development and quality

`make ios-setup` installs no credentials. It resolves the pinned Fenton shared package and regenerates
Xcode. `make ios-check` compiles, runs unit and UI tests, applies SwiftLint fixes, enforces strict lint,
checks at least 95% scheduling/progress coverage, and checks signing policy. Codex exposes these same
actions through `.codex/environments/environment.toml`. CI fetches Platform with a dedicated read-only
deploy key stored in `FENTON_PLATFORM_DEPLOY_KEY`; private keys never enter the repository.

## Distribution

1. Run the quality gates and merge the reviewed commit to main. Fetch main before release.
2. Use the existing Apple Distribution identity and the `Touch Grass iOS App Store` profile.
   The provisioning profile must include WeatherKit and match this app's exact bundle/team.
3. Run `python3 scripts/release_ios.py --version 0.1.0 --build 1` to archive, verify and export.
4. For an authorized release, add `--upload`. Upload requires a clean checkout at `origin/main`.
5. If Apple processing or tester assignment is interrupted, use the same version/build with
   `--verify-only`. Never repeat an uncertain upload. No prior builds are expired automatically.

Credentials come from the standard `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`,
and `APP_STORE_CONNECT_API_KEY_P8` environment variables, or the existing Apple credential SSM
location selected by `APPLE_CREDENTIAL_PREFIX` (currently `/garden/ci`). The API key is passed only
to Apple and an owner-only temporary key file is deleted automatically. No keychain defaults or search
lists are changed. Missing signing material fails closed. Every archive signature and App Store
profile is verified before export; completion requires Apple's valid processing status and actual
membership in the nonempty Internal tester group.

The simulator cannot prove handset notification delivery or WeatherKit entitlement operation on an
installed device. Verify these on the iPhone after installing the TestFlight build.
