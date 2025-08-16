# Contributing to Touch Grass

Thank you for your interest in contributing to Touch Grass! We love your input! We want to make contributing to this project as easy and transparent as possible.

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/yourusername/touchgrass.git
   cd touchgrass
   ```

2. **Set up development environment**
   ```bash
   make setup
   ```

3. **Create Local.xcconfig for code signing**
   ```xcconfig
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   PRODUCT_BUNDLE_IDENTIFIER = com.yourname.touchgrass
   CODE_SIGN_STYLE = Automatic
   CODE_SIGN_IDENTITY = Apple Development
   ```

4. **Build and run**
   ```bash
   make build
   make run
   ```

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow existing patterns and conventions
   - Add tests for new functionality

3. **Test your changes**
   ```bash
   make test          # Run tests
   make lint          # Check code style
   make check         # Run all checks
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Clear description of changes"
   ```

5. **Push and create a PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Style Guidelines

### Swift
- Use descriptive variable and function names
- Keep functions small and focused
- Use Swift's type system effectively
- Prefer functional programming patterns
- Avoid force unwrapping unless absolutely necessary
- Add comments for complex logic

### Architecture
- Follow the existing SwiftUI + Combine pattern
- Keep views simple and delegate logic to managers
- Use ObservableObject for state management
- Separate concerns (UI, business logic, data)

### Testing
- Write integration tests for user workflows
- Focus on end-to-end testing over unit tests
- Test error conditions and edge cases
- Ensure tests are deterministic

## Pull Request Process

1. **Before submitting**
   - Run `make check` to ensure all tests pass
   - Update documentation if needed
   - Add tests for new features
   - Ensure no code signing identities are committed

2. **PR Description**
   - Clearly describe what changes you made
   - Reference any related issues
   - Include screenshots for UI changes
   - List any breaking changes

3. **Review Process**
   - Maintainers will review your PR
   - Address any feedback or questions
   - Once approved, your PR will be merged

## Testing

We prioritize integration tests that verify complete user workflows:

```bash
make test           # Run all tests
make test-verbose   # Detailed output
```

Tests should focus on:
- Complete user journeys
- Calendar integration
- Meeting detection
- Water tracking
- Exercise flows
- Error recovery

## Common Tasks

### Adding a New Feature
1. Create feature branch
2. Implement feature with tests
3. Update documentation
4. Submit PR

### Fixing a Bug
1. Create issue describing the bug
2. Write a test that reproduces it
3. Fix the bug
4. Ensure test passes
5. Submit PR referencing the issue

### Adding a New Exercise
1. Add exercise data to `Models/Exercise.swift`
2. Generate audio files if needed
3. Test the exercise flow
4. Submit PR

## Release Process

Releases are done manually due to code signing requirements:

1. **Prepare release** (maintainers only)
   ```bash
   make release VERSION=1.2.0
   ```

2. **What happens**
   - Version updated in Info.plist and VERSION
   - App built and signed
   - DMG created
   - GitHub release created
   - Checksums generated

## Getting Help

- Check existing issues and PRs
- Read the documentation
- Ask questions in issues
- Review the codebase for examples

## Code of Conduct

Please note we have a code of conduct. Please follow it in all your interactions with the project.

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes
- README acknowledgments (for significant contributions)

Thank you for contributing to Touch Grass! 🌱