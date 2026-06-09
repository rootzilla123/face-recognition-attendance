#!/bin/bash
# Build Linux Desktop App
# Usage: ./build_linux.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Linux Desktop App Builder           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${RED}✗ This script should be run on Linux${NC}"
    exit 1
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"

# Check if Linux desktop is enabled
if ! flutter devices | grep -q "Linux"; then
    echo -e "${YELLOW}⚠ Linux desktop support not enabled${NC}"
    echo -e "${YELLOW}Enabling Linux desktop support...${NC}"
    flutter config --enable-linux-desktop
    echo -e "${GREEN}✓ Linux desktop support enabled${NC}"
fi

# Check required dependencies
echo ""
echo -e "${YELLOW}Checking system dependencies...${NC}"

MISSING_DEPS=()

if ! pkg-config --exists gtk+-3.0; then
    MISSING_DEPS+=("libgtk-3-dev")
fi

if ! pkg-config --exists glib-2.0; then
    MISSING_DEPS+=("libglib2.0-dev")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo ""
    echo -e "${YELLOW}Install with:${NC}"
    echo -e "  sudo apt-get update"
    echo -e "  sudo apt-get install -y ${MISSING_DEPS[*]}"
    exit 1
fi

echo -e "${GREEN}✓ All dependencies installed${NC}"
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

# Build Linux app
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Building Linux Desktop App...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

flutter build linux --release

if [ -d "build/linux/x64/release/bundle" ]; then
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}  Location: build/linux/x64/release/bundle/${NC}"
    
    # Calculate size
    SIZE=$(du -sh build/linux/x64/release/bundle | cut -f1)
    echo -e "${GREEN}  Size: $SIZE${NC}"
    
    echo ""
    echo -e "${YELLOW}Executable location:${NC}"
    echo -e "  ${GREEN}build/linux/x64/release/bundle/attendanceai${NC}"
    
    echo ""
    echo -e "${YELLOW}To run the app:${NC}"
    echo -e "  ./build/linux/x64/release/bundle/attendanceai"
    
    echo ""
    echo -e "${YELLOW}To install system-wide:${NC}"
    echo -e "  sudo ./install_linux.sh"
    
    echo ""
    echo -e "${YELLOW}To create a portable archive:${NC}"
    echo -e "  cd build/linux/x64/release"
    echo -e "  tar -czf AttendanceAI-Linux-x64-v1.0.0.tar.gz bundle/"
    
    echo ""
    echo -e "${YELLOW}To create a .deb package:${NC}"
    echo -e "  ./build_linux_deb.sh"
    
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Linux build complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
