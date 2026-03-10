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

echo "Compiling..."
swiftc \
    -o "${MACOS}/${APP_NAME}" \
    -target arm64-apple-macos14.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -parse-as-library \
    ${SWIFT_FILES}

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
echo ""
echo "To install, run:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
echo ""
echo "Then open the app and click 'Set as Default Browser' in settings."
