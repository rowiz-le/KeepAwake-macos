#!/bin/bash
# KeepAwake - Build Script
# Compiles and installs the KeepAwake menu bar app

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/KeepAwake.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"

echo "🔨 Building KeepAwake..."

# Create app structure
mkdir -p "$MACOS_DIR"
mkdir -p "$APP_DIR/Contents/Resources"

# Compile
swiftc -o "$MACOS_DIR/KeepAwake" "$SCRIPT_DIR/main.swift" \
    -framework Cocoa \
    -framework IOKit \
    -O \
    -suppress-warnings

echo "✅ Build successful!"
echo "📦 App location: $APP_DIR"

# Ask to install
read -p "📲 Install to /Applications? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp -R "$APP_DIR" /Applications/KeepAwake.app
    echo "✅ Installed to /Applications/KeepAwake.app"
fi

echo "🚀 Run: open /Applications/KeepAwake.app"
