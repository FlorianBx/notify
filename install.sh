#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/yourusername/terminal-notifier-swift"
VERSION="2.0.0"
APP_NAME="terminal-notifier.app"
BINARY_NAME="terminal-notifier"
INSTALL_PATH="/Applications/${APP_NAME}"
SYMLINK_PATH="/usr/local/bin/${BINARY_NAME}"
TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "🚀 Installing terminal-notifier-swift v${VERSION}"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This installer only works on macOS"
    exit 1
fi

if [[ $(sw_vers -productVersion | cut -d. -f1) -lt 13 ]]; then
    echo "❌ macOS 13.0 (Ventura) or later required"
    exit 1
fi

if command -v terminal-notifier >/dev/null 2>&1; then
    echo "⚠️  Existing terminal-notifier installation found"
    read -p "Do you want to continue? This may overwrite the existing installation (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
fi

echo "📥 Downloading release..."
cd "$TMP_DIR"
curl -fsSL "${REPO_URL}/releases/download/v${VERSION}/terminal-notifier-${VERSION}-darwin.tar.gz" -o release.tar.gz

echo "📦 Extracting archive..."
tar -xzf release.tar.gz

echo "🔧 Installing to ${INSTALL_PATH}..."
sudo rm -rf "$INSTALL_PATH"
sudo cp -R "$APP_NAME" "/Applications/"

echo "🔗 Creating symlink..."
sudo mkdir -p /usr/local/bin
sudo ln -sf "${INSTALL_PATH}/Contents/MacOS/${BINARY_NAME}" "$SYMLINK_PATH"

echo "🔐 Setting permissions..."
sudo chmod +x "${INSTALL_PATH}/Contents/MacOS/${BINARY_NAME}"

if command -v codesign >/dev/null 2>&1; then
    echo "✍️  Code signing..."
    sudo codesign --force --deep --sign - "$INSTALL_PATH" 2>/dev/null || {
        echo "⚠️  Code signing failed, continuing anyway"
    }
fi

echo "✅ Installation complete!"
echo ""
echo "terminal-notifier-swift has been installed to:"
echo "  App Bundle: $INSTALL_PATH"
echo "  CLI Tool:   $SYMLINK_PATH"
echo ""
echo "You can now use:"
echo "  terminal-notifier --help"
echo "  terminal-notifier -message 'Hello World!'"
echo ""
echo "To uninstall:"
echo "  sudo rm -rf '$INSTALL_PATH'"
echo "  sudo rm -f '$SYMLINK_PATH'"