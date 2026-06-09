#!/bin/bash
# Build Windows Desktop App
# Usage: ./build_windows.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Windows Desktop App Builder         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running on Windows or WSL
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" && ! -f /proc/version ]]; then
    echo -e "${RED}✗ This script should be run on Windows or WSL${NC}"
    exit 1
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"

# Check if Windows desktop is enabled
if ! flutter devices | grep -q "Windows"; then
    echo -e "${YELLOW}⚠ Windows desktop support not enabled${NC}"
    echo -e "${YELLOW}Enabling Windows desktop support...${NC}"
    flutter config --enable-windows-desktop
    echo -e "${GREEN}✓ Windows desktop support enabled${NC}"
fi

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

# Build Windows app
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Building Windows Desktop App...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

flutter build windows --release

if [ -d "build/windows/x64/runner/Release" ]; then
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}  Location: build/windows/x64/runner/Release/${NC}"
    
    # Calculate size
    SIZE=$(du -sh build/windows/x64/runner/Release | cut -f1)
    echo -e "${GREEN}  Size: $SIZE${NC}"
    
    echo ""
    echo -e "${YELLOW}Executable location:${NC}"
    echo -e "  ${GREEN}build/windows/x64/runner/Release/AttendanceAI.exe${NC}"
    
    echo ""
    echo -e "${YELLOW}To run the app:${NC}"
    echo -e "  1. Navigate to: build/windows/x64/runner/Release/"
    echo -e "  2. Double-click: AttendanceAI.exe"
    
    echo ""
    echo -e "${YELLOW}To create an installer:${NC}"
    echo -e "  ./build_windows_installer.sh"
    
    echo ""
    echo -e "${YELLOW}To create a portable ZIP:${NC}"
    echo -e "  cd build/windows/x64/runner/Release"
    echo -e "  zip -r AttendanceAI-Windows-v1.0.0.zip *"
    
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Windows build complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
