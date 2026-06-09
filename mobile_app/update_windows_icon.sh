#!/bin/bash
# Update Windows App Icon
# Usage: ./update_windows_icon.sh /path/to/your/icon.png

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Windows Icon Updater                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if icon path provided
if [ -z "$1" ]; then
    echo -e "${RED}✗ Please provide the path to your icon image${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./update_windows_icon.sh /path/to/your/icon.png"
    echo ""
    echo -e "${YELLOW}Supported formats:${NC}"
    echo -e "  - PNG (recommended)"
    echo -e "  - JPG/JPEG"
    echo -e "  - ICO (will copy directly)"
    echo ""
    echo -e "${YELLOW}Icon requirements:${NC}"
    echo -e "  - Square image (1:1 aspect ratio)"
    echo -e "  - Minimum 256x256 pixels"
    echo -e "  - Simple design that works at small sizes"
    echo ""
    exit 1
fi

ICON_PATH="$1"
ICON_DIR="windows/runner/resources"
TARGET_ICO="$ICON_DIR/app_icon.ico"

# Check if file exists
if [ ! -f "$ICON_PATH" ]; then
    echo -e "${RED}✗ Icon file not found: $ICON_PATH${NC}"
    exit 1
fi

# Get file extension
EXT="${ICON_PATH##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

echo -e "${GREEN}✓ Found icon: $ICON_PATH${NC}"
echo ""

# Backup existing icon
if [ -f "$TARGET_ICO" ]; then
    echo -e "${YELLOW}Backing up existing icon...${NC}"
    cp "$TARGET_ICO" "$TARGET_ICO.backup"
    echo -e "${GREEN}✓ Backup created: $TARGET_ICO.backup${NC}"
    echo ""
fi

# Handle ICO files directly
if [ "$EXT_LOWER" = "ico" ]; then
    echo -e "${YELLOW}Copying ICO file...${NC}"
    cp "$ICON_PATH" "$TARGET_ICO"
    echo -e "${GREEN}✓ Icon updated!${NC}"
else
    # Try to convert using ImageMagick
    if command -v convert &> /dev/null; then
        echo -e "${YELLOW}Converting to ICO format using ImageMagick...${NC}"
        convert "$ICON_PATH" -define icon:auto-resize=256,128,64,48,32,16 "$TARGET_ICO"
        echo -e "${GREEN}✓ Icon converted and updated!${NC}"
    else
        echo -e "${YELLOW}⚠ ImageMagick not found${NC}"
        echo ""
        echo -e "${YELLOW}Please convert your icon to .ico format manually:${NC}"
        echo -e "  1. Go to: https://convertio.co/png-ico/"
        echo -e "  2. Upload: $ICON_PATH"
        echo -e "  3. Select sizes: 16, 32, 48, 64, 128, 256"
        echo -e "  4. Download the .ico file"
        echo -e "  5. Run: ./update_windows_icon.sh /path/to/downloaded.ico"
        echo ""
        echo -e "${YELLOW}Or install ImageMagick:${NC}"
        echo -e "  Ubuntu/Debian: sudo apt-get install imagemagick"
        echo -e "  macOS: brew install imagemagick"
        echo -e "  Windows: choco install imagemagick"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Icon update complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Clean previous builds: ${GREEN}flutter clean${NC}"
echo -e "  2. Rebuild the app: ${GREEN}./build_windows.sh${NC}"
echo -e "  3. Check the new icon in: ${GREEN}build/windows/x64/runner/Release/${NC}"
echo ""
