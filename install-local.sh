#!/bin/bash

set -e

echo "📦 Installing notify locally (no sudo required)..."

# Create local bin directory if it doesn't exist
mkdir -p ~/bin

# Copy the app bundle to user's Applications folder
mkdir -p ~/Applications
rm -rf ~/Applications/notify.app
cp -R build/notify.app ~/Applications/

# Create symlink in ~/bin
ln -sf ~/Applications/notify.app/Contents/MacOS/notify ~/bin/notify

# Check if ~/bin is in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "⚠️  ~/bin is not in your PATH"
    echo "Add this line to your shell config (~/.zshrc or ~/.bashrc):"
    echo "export PATH=\"\$HOME/bin:\$PATH\""
    echo ""
    echo "Or run: echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
else
    echo "✅ ~/bin is already in PATH"
fi

echo "✅ Local installation complete!"
echo "App location: ~/Applications/notify.app"
echo "Executable: ~/bin/notify"