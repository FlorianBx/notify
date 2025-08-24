#!/bin/bash

# Build the project
echo "Building notify..."
swift build -c release

# Create app bundle
echo "Creating app bundle..."
mkdir -p /usr/local/bin/notify.app/Contents/MacOS

# Create Info.plist
cat > /usr/local/bin/notify.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.notify.cli</string>
    <key>CFBundleName</key>
    <string>notify</string>
    <key>CFBundleExecutable</key>
    <string>notify</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF

# Copy binary
echo "Installing notify..."
cp .build/release/notify /usr/local/bin/notify.app/Contents/MacOS/

# Create symlink for easy CLI access
ln -sf /usr/local/bin/notify.app/Contents/MacOS/notify /usr/local/bin/notify

echo "Installation complete!"
echo "You can now use 'notify' from the command line."
echo ""
echo "IMPORTANT: On first run, macOS will ask for notification permissions."
echo "Please allow notifications in System Settings > Notifications > notify"