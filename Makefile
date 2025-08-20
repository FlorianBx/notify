.PHONY: all build clean install uninstall test release help

VERSION = 0.1
BUILD_DIR = build
APP_NAME = notify.app
BINARY_NAME = notify
INSTALL_PATH = /Applications/$(APP_NAME)
SYMLINK_PATH = /usr/local/bin/$(BINARY_NAME)

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

all: build ## Build the project (default target)

clean: ## Remove build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf .build

build: ## Build the app bundle
	@echo "🔨 Building $(BINARY_NAME) v$(VERSION)..."
	@./build.sh

install: build ## Build and install to /Applications
	@echo "📦 Installing $(APP_NAME)..."
	@sudo rm -rf "$(INSTALL_PATH)"
	@sudo cp -R "$(BUILD_DIR)/$(APP_NAME)" "/Applications/"
	@sudo mkdir -p /usr/local/bin
	@sudo ln -sf "$(INSTALL_PATH)/Contents/MacOS/$(BINARY_NAME)" "$(SYMLINK_PATH)"
	@echo "✅ Installation complete!"
	@echo "You can now use: $(BINARY_NAME) --help"

uninstall: ## Uninstall from /Applications
	@echo "🗑️  Uninstalling $(APP_NAME)..."
	@sudo rm -rf "$(INSTALL_PATH)"
	@sudo rm -f "$(SYMLINK_PATH)"
	@echo "✅ Uninstallation complete!"

test: ## Run tests
	@echo "🧪 Running tests..."
	@swift test

release: clean build ## Clean build and create release archive
	@echo "📦 Creating release archive..."
	@cd $(BUILD_DIR) && tar -czf "$(BINARY_NAME)-$(VERSION)-darwin.tar.gz" "$(APP_NAME)"
	@echo "✅ Release archive created: $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-darwin.tar.gz"
	@echo "SHA256:"
	@cd $(BUILD_DIR) && shasum -a 256 "$(BINARY_NAME)-$(VERSION)-darwin.tar.gz"

dev-install: ## Install development version
	@echo "🔧 Installing development version..."
	@./build.sh --install

verify: ## Verify installation
	@echo "🔍 Verifying installation..."
	@if [ -f "$(SYMLINK_PATH)" ]; then \
		echo "✅ Binary found at $(SYMLINK_PATH)"; \
		$(SYMLINK_PATH) --version 2>/dev/null || echo "⚠️  Binary exists but may not be working"; \
	else \
		echo "❌ Binary not found at $(SYMLINK_PATH)"; \
	fi
	@if [ -d "$(INSTALL_PATH)" ]; then \
		echo "✅ App bundle found at $(INSTALL_PATH)"; \
	else \
		echo "❌ App bundle not found at $(INSTALL_PATH)"; \
	fi