#!/bin/bash
set -euo pipefail

APP_NAME="URLRouter"
BUILD_DIR="$(pwd)/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
SRC_DIR="$(pwd)/URLRouter"

echo "Building ${APP_NAME}..."

# Clean
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS}" "${RESOURCES}"

# Collect all Swift source files
SWIFT_FILES=$(find "${SRC_DIR}" -name "*.swift" -type f)

# Build universal binary (arm64 + x86_64)
echo "Compiling (arm64)..."
swiftc \
    -o "${MACOS}/${APP_NAME}-arm64" \
    -target arm64-apple-macos14.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -parse-as-library \
    -O \
    ${SWIFT_FILES}

echo "Compiling (x86_64)..."
swiftc \
    -o "${MACOS}/${APP_NAME}-x86_64" \
    -target x86_64-apple-macos14.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -parse-as-library \
    -O \
    ${SWIFT_FILES}

echo "Creating universal binary..."
lipo -create \
    "${MACOS}/${APP_NAME}-arm64" \
    "${MACOS}/${APP_NAME}-x86_64" \
    -output "${MACOS}/${APP_NAME}"
rm "${MACOS}/${APP_NAME}-arm64" "${MACOS}/${APP_NAME}-x86_64"

# Copy Info.plist
cp "${SRC_DIR}/Info.plist" "${CONTENTS}/Info.plist"

# Copy entitlements (used during signing)
ENTITLEMENTS="${SRC_DIR}/${APP_NAME}.entitlements"

# Create PkgInfo
echo -n "APPL????" > "${CONTENTS}/PkgInfo"

# Ad-hoc code sign with entitlements
echo "Signing..."
codesign --force --sign - --entitlements "${ENTITLEMENTS}" "${APP_BUNDLE}"

echo ""
echo "Build complete: ${APP_BUNDLE}"

# Create DMG if --dmg flag is passed
if [[ "${1:-}" == "--dmg" ]]; then
    DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"
    DMG_STAGING="${BUILD_DIR}/dmg-staging"
    echo "Creating DMG..."

    mkdir -p "${DMG_STAGING}"
    cp -r "${APP_BUNDLE}" "${DMG_STAGING}/"
    ln -s /Applications "${DMG_STAGING}/Applications"

    hdiutil create \
        -volname "${APP_NAME}" \
        -srcfolder "${DMG_STAGING}" \
        -ov \
        -format UDZO \
        "${DMG_PATH}"

    rm -rf "${DMG_STAGING}"
    echo "DMG created: ${DMG_PATH}"
fi
