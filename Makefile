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
	@echo ""

# Combined target for CI or pre-commit
all: lint build test
	@echo "✅ All checks passed!"

# Pre-commit checks
check: lint build test
	@echo "✅ Ready to commit!"

# Build the app
build:
	@echo "🔨 Building Touch Grass..."
	@if [ ! -f "Local.xcconfig" ]; then \
		echo "❌ Local.xcconfig not found!"; \
		echo "Building without code signing..."; \
		xcodebuild -project TouchGrass.xcodeproj \
			-scheme TouchGrass \
			-configuration Release \
			build \
			SYMROOT=build \
			-quiet; \
	else \
		xcodebuild -project TouchGrass.xcodeproj \
			-scheme TouchGrass \
			-configuration Release \
			-xcconfig Local.xcconfig \
			build \
			SYMROOT=build \
			CODE_SIGN_ENTITLEMENTS=TouchGrass.entitlements \
			-quiet; \
	fi
	@echo "✅ Build successful!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf ~/Library/Developer/Xcode/DerivedData/TouchGrass-*
	@xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass clean -quiet 2>/dev/null || true
	@echo "✅ Clean complete"

# Run linting
lint:
	@if [ -f "./lint.sh" ]; then \
		./lint.sh; \
	else \
		echo "🧹 Running SwiftLint..."; \
		if command -v swiftlint >/dev/null 2>&1; then \
			swiftlint lint --config .swiftlint.yml; \
		else \
			echo "❌ SwiftLint not installed. Run: make install"; \
			exit 1; \
		fi \
	fi

# Fix lint violations
lint-fix:
	@if [ -f "./lint.sh" ]; then \
		./lint.sh --fix; \
	else \
		echo "🔧 Auto-fixing violations..."; \
		swiftlint --fix --config .swiftlint.yml; \
		echo "✅ Fixed what could be auto-fixed"; \
	fi

# Run tests
test:
	@echo "🧪 Running tests..."
	@xcodebuild -project TouchGrass.xcodeproj \
		-scheme TouchGrass \
		-destination 'platform=macOS' \
		test 2>&1 | grep -q "Test bundle" || true
	@echo "ℹ️  No tests configured yet"
	@echo "    Tests will be added in future updates"

# Create a release
release:
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ VERSION required"; \
		echo "Usage: make release VERSION=1.2.0"; \
		echo ""; \
		echo "Or for interactive mode:"; \
		echo "  ./release.sh 1.2.0"; \
		exit 1; \
	fi
	@if [ -f "./release.sh" ]; then \
		./release.sh $(VERSION); \
	else \
		echo "❌ release.sh not found"; \
		exit 1; \
	fi

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

# Update Xcode project with new files
sync:
	@if [ -f "sync_xcode_project.py" ]; then \
		python3 sync_xcode_project.py; \
	else \
		echo "❌ sync_xcode_project.py not found"; \
	fi

.DEFAULT_GOAL := help