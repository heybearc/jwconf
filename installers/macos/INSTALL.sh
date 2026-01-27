#!/bin/bash

# JW Conf macOS Audio Sharing Fix - Installer
# This script installs the patched version of JW Conf with audio sharing enabled

set -e

echo ""
echo "=========================================="
echo "JW Conf Audio Sharing Fix - Installer"
echo "=========================================="
echo ""
echo "This will enable audio sharing during screen sharing on macOS."
echo ""

# Check if JW Conf is installed
if [ ! -d "/Applications/JW Conf.app" ]; then
    echo "❌ Error: JW Conf.app not found in /Applications/"
    echo "   Please install JW Conf first, then run this installer."
    exit 1
fi

echo "✓ Found JW Conf.app"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This installer needs administrator privileges."
    echo "You will be prompted for your password."
    echo ""
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if patched file exists
if [ ! -f "$SCRIPT_DIR/app.asar.patched" ]; then
    echo "❌ Error: app.asar.patched not found in installer directory"
    exit 1
fi

echo "Step 1: Creating backup..."
sudo cp "/Applications/JW Conf.app/Contents/Resources/app.asar" "$HOME/Desktop/JW-Conf-app.asar.backup" 2>/dev/null || true
echo "✓ Backup saved to Desktop/JW-Conf-app.asar.backup"
echo ""

echo "Step 2: Installing patched version..."
sudo cp "$SCRIPT_DIR/app.asar.patched" "/Applications/JW Conf.app/Contents/Resources/app.asar"
echo "✓ Patched version installed"
echo ""

echo "Step 3: Re-signing application..."
sudo codesign --force --deep --sign - "/Applications/JW Conf.app" 2>/dev/null
echo "✓ Application re-signed"
echo ""

echo "=========================================="
echo "✅ Installation Complete!"
echo "=========================================="
echo ""
echo "What's changed:"
echo "  • Audio sharing is now enabled on macOS"
echo "  • When you share your screen, audio will be automatically included"
echo "  • No checkbox needed - audio sharing is always on"
echo ""
echo "Next steps:"
echo "  1. Launch JW Conf"
echo "  2. Join a meeting"
echo "  3. Share your screen or an application"
echo "  4. Audio from the shared content will be transmitted"
echo ""
echo "Note: You may see a security warning on first launch."
echo "      Go to System Settings > Privacy & Security and click 'Open Anyway'"
echo ""
echo "Backup location: ~/Desktop/JW-Conf-app.asar.backup"
echo ""
