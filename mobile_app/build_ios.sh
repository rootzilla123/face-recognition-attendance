#!/bin/bash
# Build iOS App
# Usage: ./build_ios.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   iOS App Builder                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}✗ iOS builds require macOS${NC}"
    echo -e "${YELLOW}You are running on: $OSTYPE${NC}"
    echo ""
    echo -e "${YELLOW}To build for iOS, you need:${NC}"
    echo -e "  - macOS computer"
    echo -e "  - Xcode installed"
    echo -e "  - Apple Developer account (for App Store)"
    echo ""
    exit 1
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}✗ Xcode not found${NC}"
    echo ""
    echo -e "${YELLOW}Install Xcode from:${NC}"
    echo -e "  - Mac App Store"
    echo -e "  - https://developer.apple.com/xcode/"
    echo ""
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
echo -e "${GREEN}✓ Xcode found: $XCODE_VERSION${NC}"

# Check CocoaPods
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠ CocoaPods not found${NC}"
    echo -e "${YELLOW}Installing CocoaPods...${NC}"
    sudo gem install cocoapods
    echo -e "${GREEN}✓ CocoaPods installed${NC}"
else
    echo -e "${GREEN}✓ CocoaPods found: $(pod --version)${NC}"
fi

echo ""

# Check current configuration
echo -e "${YELLOW}Checking configuration...${NC}"
if grep -q "localhost\|10.0.2.2\|192.168" lib/core/utils/server_config.dart 2>/dev/null; then
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

# Build type selection
echo -e "${YELLOW}Select build type:${NC}"
echo -e "  1) Development build (for testing on your device)"
echo -e "  2) Ad-Hoc build (for TestFlight/internal distribution)"
echo -e "  3) App Store build (for App Store submission)"
echo ""
read -p "Enter choice (1-3): " build_choice

case $build_choice in
    1)
        BUILD_TYPE="debug"
        BUILD_NAME="Development"
        ;;
    2)
        BUILD_TYPE="release"
        BUILD_NAME="Ad-Hoc"
        ;;
    3)
        BUILD_TYPE="release"
        BUILD_NAME="App Store"
        ;;
    *)
        echo -e "${RED}✗ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Building: $BUILD_NAME${NC}"
echo ""

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean
rm -rf ios/Pods
rm -rf ios/.symlinks
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Install CocoaPods dependencies
echo -e "${YELLOW}Installing iOS dependencies (CocoaPods)...${NC}"
cd ios
pod install
cd ..
echo -e "${GREEN}✓ iOS dependencies installed${NC}"
echo ""

# Build iOS app
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Building iOS App...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

if [ "$BUILD_TYPE" = "debug" ]; then
    # Debug build - no code signing required
    flutter build ios --debug --no-codesign
    
    if [ -d "build/ios/iphoneos/Runner.app" ]; then
        echo ""
        echo -e "${GREEN}✓ Debug build successful!${NC}"
        echo -e "${GREEN}  Location: build/ios/iphoneos/Runner.app${NC}"
        echo ""
        echo -e "${YELLOW}To install on your device:${NC}"
        echo -e "  1. Open Xcode: ${GREEN}open ios/Runner.xcworkspace${NC}"
        echo -e "  2. Connect your iPhone"
        echo -e "  3. Select your device in Xcode"
        echo -e "  4. Click Run (▶) button"
        echo ""
        echo -e "${YELLOW}Or use Flutter:${NC}"
        echo -e "  ${GREEN}flutter run -d <device-id>${NC}"
        echo ""
    else
        echo -e "${RED}✗ Build failed!${NC}"
        exit 1
    fi
else
    # Release build - requires code signing
    echo -e "${YELLOW}⚠ Release builds require:${NC}"
    echo -e "  - Apple Developer account"
    echo -e "  - Valid provisioning profile"
    echo -e "  - Code signing certificate"
    echo ""
    echo -e "${YELLOW}Building IPA (this may take a few minutes)...${NC}"
    
    flutter build ipa --release
    
    if [ -f "build/ios/ipa/mobile_app.ipa" ]; then
        echo ""
        echo -e "${GREEN}✓ Release build successful!${NC}"
        echo -e "${GREEN}  Location: build/ios/ipa/mobile_app.ipa${NC}"
        
        # Calculate size
        SIZE=$(du -sh build/ios/ipa/mobile_app.ipa | cut -f1)
        echo -e "${GREEN}  Size: $SIZE${NC}"
        
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        
        if [ "$BUILD_NAME" = "Ad-Hoc" ]; then
            echo -e "  1. Upload to TestFlight:"
            echo -e "     ${GREEN}xcrun altool --upload-app -f build/ios/ipa/mobile_app.ipa -u YOUR_APPLE_ID${NC}"
            echo -e "  2. Or distribute via App Store Connect"
        else
            echo -e "  1. Open App Store Connect: https://appstoreconnect.apple.com"
            echo -e "  2. Upload IPA using Transporter app"
            echo -e "  3. Submit for review"
        fi
        
        echo ""
        echo -e "${YELLOW}Or open in Xcode:${NC}"
        echo -e "  ${GREEN}open ios/Runner.xcworkspace${NC}"
        echo ""
    else
        echo -e "${RED}✗ Build failed!${NC}"
        echo ""
        echo -e "${YELLOW}Common issues:${NC}"
        echo -e "  - Missing provisioning profile"
        echo -e "  - Invalid code signing certificate"
        echo -e "  - Bundle identifier not registered"
        echo ""
        echo -e "${YELLOW}To fix:${NC}"
        echo -e "  1. Open: ${GREEN}open ios/Runner.xcworkspace${NC}"
        echo -e "  2. Select Runner target"
        echo -e "  3. Go to Signing & Capabilities"
        echo -e "  4. Configure your team and provisioning"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ iOS build complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
