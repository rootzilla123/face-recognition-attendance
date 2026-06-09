#!/bin/bash
# Build APK script with options
# Usage: ./build_apk.sh [debug|release|both]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BUILD_TYPE=${1:-release}

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Mobile App APK Builder              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"
echo ""

# Check current configuration
echo -e "${YELLOW}Checking configuration...${NC}"
if grep -q "localhost\|10.0.2.2\|192.168" lib/core/utils/server_config.dart; then
    echo -e "${RED}⚠ WARNING: App is configured for LOCAL development!${NC}"
    echo ""
    read -p "Do you want to switch to PRODUCTION config? (y/n): " switch_prod
    if [ "$switch_prod" = "y" ]; then
        ./configure_production.sh
    else
        echo -e "${YELLOW}Building with LOCAL configuration...${NC}"
    fi
else
    echo -e "${GREEN}✓ Production configuration detected${NC}"
fi

echo ""

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Build function
build_apk() {
    local type=$1
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}Building $type APK...${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    if [ "$type" = "debug" ]; then
        flutter build apk --debug
        APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    else
        flutter build apk --release
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    fi
    
    if [ -f "$APK_PATH" ]; then
        SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo ""
        echo -e "${GREEN}✓ Build successful!${NC}"
        echo -e "${GREEN}  Location: $APK_PATH${NC}"
        echo -e "${GREEN}  Size: $SIZE${NC}"
        
        # Copy to assets folder for easy access
        cp "$APK_PATH" "assets/AttendanceAI-$type.apk"
        echo -e "${GREEN}  Copied to: assets/AttendanceAI-$type.apk${NC}"
    else
        echo -e "${RED}✗ Build failed!${NC}"
        exit 1
    fi
}

# Build based on type
case $BUILD_TYPE in
    debug)
        build_apk "debug"
        ;;
    release)
        build_apk "release"
        ;;
    both)
        build_apk "debug"
        echo ""
        build_apk "release"
        ;;
    *)
        echo -e "${RED}Invalid build type: $BUILD_TYPE${NC}"
        echo "Usage: ./build_apk.sh [debug|release|both]"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ All builds complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Install on device:"
echo "     adb install $APK_PATH"
echo ""
echo "  2. Or copy APK to device and install manually"
echo ""
echo -e "${YELLOW}APK locations:${NC}"
ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || echo "  No APKs found"
echo ""
