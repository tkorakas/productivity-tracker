#!/bin/bash

APP_NAME="ProductivityTracker"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
INFO_PLIST="ProductivityTracker/Info.plist"

# 1. Build
echo "Building release..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed. Exiting."
    exit 1
fi

# 2. Create Structure
echo "Creating app bundle..."
if [ -d "$APP_BUNDLE" ]; then
    rm -rf "$APP_BUNDLE"
fi

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy Binary
echo "Copying binary..."
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 3.5 Generate Icon
if [ -f "icon.png" ]; then
    echo "Generating AppIcon.icns..."
    ICONSET_DIR="ProductivityTracker.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Generate various sizes
    sips -z 16 16     icon.png --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32     icon.png --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     icon.png --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64     icon.png --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   icon.png --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256   icon.png --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   icon.png --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512   icon.png --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   icon.png --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 icon.png --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null
    
    # Convert to icns
    iconutil -c icns "$ICONSET_DIR"
    
    # Copy to Resources (iconutil creates ProductivityTracker.icns based on folder name)
    cp "ProductivityTracker.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    
    # Cleanup
    rm -rf "$ICONSET_DIR"
    rm "ProductivityTracker.icns"
else
    echo "Warning: icon.png not found. Skipping icon generation."
fi

# 4. Create Info.plist
echo "Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>dev.tkorakas.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# 6. Ad-hoc code signing
echo "Signing app..."
# Remove extended attributes (quarantine)
xattr -cr "$APP_BUNDLE"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "------------------------------------------------"
echo "✅ $APP_BUNDLE created successfully!"
echo "To install, run: mv $APP_BUNDLE /Applications/"
echo "------------------------------------------------"
