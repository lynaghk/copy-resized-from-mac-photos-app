#!/bin/sh

set -e
cd "$(dirname "$0")"

APP_NAME="Imagetron"


killall ${APP_NAME} || true

rm -rf "${APP_NAME}.app"

swift format format --in-place --recursive .

# Build with Swift Package Manager
echo "Building with Swift Package Manager..."
swift build --product imagetron -c release

# Create app bundle structure
mkdir -p "${APP_NAME}.app/Contents/MacOS"

# Copy compiled binary
cp ".build/release/imagetron" "${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Info.plist" "${APP_NAME}.app/Contents/Info.plist"

echo "Built ${APP_NAME}.app successfully!"
echo ""
echo "To run: open ${APP_NAME}.app"
