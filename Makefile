# Touch Grass Makefile
# Common development tasks

.PHONY: help build clean lint lint-fix test release run install setup check all

# Default target shows help
help:
	@echo "Touch Grass Development Tasks"
	@echo ""
	@echo "Quick Start:"
	@echo "  make setup      - Set up development environment"
	@echo "  make build      - Build the app"
	@echo "  make run        - Build and run the app"
	@echo "  make lint       - Check code style"
	@echo "  make test       - Run tests"
	@echo ""
	@echo "All Targets:"
	@echo "  make all        - Run lint, build, and test"
	@echo "  make build      - Build the app (requires Local.xcconfig)"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make lint       - Run SwiftLint checks"
	@echo "  make lint-fix   - Auto-fix SwiftLint violations"
	@echo "  make test       - Run tests"
	@echo "  make release    - Create a release (VERSION=x.y.z)"
	@echo "  make run        - Build and run the app"
	@echo "  make install    - Install dependencies (SwiftLint, etc.)"
	@echo "  make setup      - Complete development setup"
	@echo "  make check      - Pre-commit checks (lint + build + test)"
	@echo "  make xcode-add  - Instructions for adding files to Xcode"
	@echo "  make audio      - Generate exercise audio files"
	@echo "  make version    - Show current app version"
	@echo ""

# Combined target for CI or pre-commit
all: lint build test
	@echo "✅ All checks passed!"

# Pre-commit checks
check: lint build test
	@echo "✅ Ready to commit!"

# Build the app
build:
	@scripts/build.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf ~/Library/Developer/Xcode/DerivedData/TouchGrass-*
	@xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass clean -quiet 2>/dev/null || true
	@echo "✅ Clean complete"

# Run linting
lint:
	@echo "🧹 Running SwiftLint..."
	@swiftlint lint --quiet || (echo "❌ Lint failed. Run 'make lint-fix' to auto-fix some violations" && exit 1)
	@echo "✅ Lint passed!"

# Fix lint violations
lint-fix:
	@echo "🔧 Auto-fixing SwiftLint violations..."
	@swiftlint --fix
	@echo "✅ Fixed what could be auto-fixed. Running lint check..."
	@swiftlint lint --quiet || echo "⚠️  Some violations remain that need manual fixing"

# Run tests
test:
	@scripts/test.sh

# Run tests verbosely
test-verbose:
	@scripts/test.sh --verbose

# Create a release
release:
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ VERSION required"; \
		echo "Usage: make release VERSION=1.2.0"; \
		echo ""; \
		echo "Or for interactive mode:"; \
		echo "  scripts/release.sh 1.2.0"; \
		exit 1; \
	fi
	@scripts/release.sh $(VERSION)

# Run the app after building
run: build
	@echo "🌱 Launching Touch Grass..."
	@killall "Touch Grass" 2>/dev/null || true
	@sleep 0.5
	@open "build/Release/Touch Grass.app"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "❌ Homebrew not installed"; \
		echo "Install from: https://brew.sh"; \
		exit 1; \
	fi
	@command -v swiftlint >/dev/null 2>&1 || (echo "Installing SwiftLint..." && brew install swiftlint)
	@command -v create-dmg >/dev/null 2>&1 || (echo "Installing create-dmg..." && brew install create-dmg)
	@command -v gh >/dev/null 2>&1 || (echo "Installing GitHub CLI..." && brew install gh)
	@echo "✅ Dependencies installed"

# Development setup
setup: install
	@echo "🛠 Setting up development environment..."
	@if [ ! -f "Local.xcconfig" ]; then \
		echo ""; \
		echo "⚠️  Local.xcconfig not found!"; \
		echo ""; \
		echo "Create Local.xcconfig with:"; \
		echo "  DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE"; \
		echo "  PRODUCT_BUNDLE_IDENTIFIER = com.yourname.touchgrass"; \
		echo "  CODE_SIGN_STYLE = Automatic"; \
		echo "  CODE_SIGN_IDENTITY = Apple Development"; \
		echo ""; \
		echo "Find your Team ID:"; \
		echo "  Xcode → Settings → Accounts → View Details"; \
		echo ""; \
	else \
		echo "✅ Local.xcconfig found"; \
	fi
	@if [ -f ".swiftlint.yml" ]; then \
		echo "✅ SwiftLint configured"; \
	else \
		echo "⚠️  No .swiftlint.yml found"; \
	fi
	@echo ""
	@echo "✅ Setup complete! Run 'make build' to build the app"

# Quick rebuild and run
rebuild: clean build run

# Watch for changes and rebuild (requires fswatch)
watch:
	@if command -v fswatch >/dev/null 2>&1; then \
		echo "👀 Watching for changes..."; \
		fswatch -o . -e ".*" -i "\\.swift$$" | xargs -n1 -I{} make build; \
	else \
		echo "❌ fswatch not installed"; \
		echo "Install with: brew install fswatch"; \
		exit 1; \
	fi

# Show current version
version:
	@grep "CFBundleShortVersionString" Info.plist -A1 | tail -1 | cut -d'>' -f2 | cut -d'<' -f1

# Add files to Xcode project
xcode-add:
	@echo "Usage: scripts/add_to_xcode.sh <file1> <file2> ..."
	@echo "Example: scripts/add_to_xcode.sh Views/NewView.swift"

# Generate exercise audio files
audio:
	@scripts/generate_exercise_audio.sh

# Generate all audio files
audio-all:
	@scripts/generate_all_audio.sh

# Check audio status
audio-check:
	@scripts/generate_exercise_audio.sh --check

.DEFAULT_GOAL := help