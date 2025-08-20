#!/bin/bash
set -euo pipefail

VERSION="0.2.0"
BUILD_DIR="build"
APP_NAME="notify.app"
BINARY_NAME="notify"
BUNDLE_ID="com.notify.cli"

echo "🔨 Building notify v${VERSION}"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "Building universal binary..."
swift build --configuration release --arch arm64 --arch x86_64

APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Creating app bundle structure..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Copying binary..."
cp ".build/apple/Products/Release/${BINARY_NAME}" "${MACOS_DIR}/${BINARY_NAME}"

echo "Creating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleName</key>
	<string>${BINARY_NAME}</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleExecutable</key>
	<string>${BINARY_NAME}</string>
	<key>LSUIElement</key>
	<true/>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
</dict>
</plist>
EOF

echo "Setting permissions..."
chmod +x "${MACOS_DIR}/${BINARY_NAME}"

if command -v codesign >/dev/null 2>&1; then
    echo "Code signing..."
    codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || {
        echo "⚠️  Code signing failed, continuing without signature"
    }
fi

echo "Creating archive..."
cd "${BUILD_DIR}"
tar -czf "${BINARY_NAME}-${VERSION}-darwin.tar.gz" "${APP_NAME}"
cd ..

echo "✅ Build complete!"
echo "App bundle: ${BUILD_DIR}/${APP_NAME}"
echo "Archive: ${BUILD_DIR}/${BINARY_NAME}-${VERSION}-darwin.tar.gz"

if [[ "${1:-}" == "--install" ]]; then
    echo "Installing to /Applications..."
    sudo rm -rf "/Applications/${APP_NAME}"
    sudo cp -R "${APP_DIR}" "/Applications/"
    
    echo "Creating symlink..."
    sudo mkdir -p /usr/local/bin
    sudo ln -sf "/Applications/${APP_NAME}/Contents/MacOS/${BINARY_NAME}" "/usr/local/bin/${BINARY_NAME}"
    
    echo "✅ Installation complete!"
    echo "You can now use: ${BINARY_NAME} --help"
fi