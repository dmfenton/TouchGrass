# Release Process

This document describes the release process for Touch Grass.

## Semantic Versioning

We use semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

## Release Methods

### Method 1: Local Release Script (Recommended)

1. Ensure all changes are committed and pushed
2. Run the release script with your desired version:
   ```bash
   ./release.sh 1.0.0
   ```
3. Edit the generated release notes in `releases/v1.0.0/RELEASE_NOTES.md`
4. Push the tag:
   ```bash
   git push origin v1.0.0
   ```
5. Create GitHub release using the CLI:
   ```bash
   gh release create v1.0.0 \
     --title "Touch Grass v1.0.0" \
     --notes-file "releases/v1.0.0/RELEASE_NOTES.md" \
     "releases/v1.0.0/Touch-Grass-v1.0.0.zip"
   ```

### Method 2: GitHub Actions (Automated)

1. Ensure all changes are committed and pushed
2. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
3. GitHub Actions will automatically:
   - Build the app
   - Create a ZIP archive
   - Generate checksums
   - Create a draft release
4. Go to GitHub releases, edit the draft, and publish

### Method 3: Manual Release

1. Build the app:
   ```bash
   ./build.sh
   ```
2. Create ZIP archive:
   ```bash
   cd build/Release
   zip -r "Touch-Grass.zip" "Touch Grass.app"
   ```
3. Create release on GitHub:
   - Go to https://github.com/YOUR_USERNAME/touchgrass/releases/new
   - Create a new tag (e.g., v1.0.0)
   - Upload the ZIP file
   - Add release notes

## Release Checklist

- [ ] All tests pass
- [ ] Code is committed and pushed
- [ ] Version number is updated (if doing manual release)
- [ ] Release notes are written
- [ ] Tag is created and pushed
- [ ] Release is published on GitHub
- [ ] Verify download and installation works

## Distribution Notes

### Code Signing
- For wide distribution, you'll need an Apple Developer account ($99/year)
- Without code signing, users will see a warning and need to right-click → Open the app
- The release script will use your Local.xcconfig if available

### Notarization
- For the best user experience, notarize your app with Apple
- This requires an Apple Developer account
- See: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

### Homebrew (Future)
Once the app is stable and has users, consider:
- Creating a Homebrew formula for easy installation
- Publishing to Homebrew Cask: `brew install --cask touch-grass`