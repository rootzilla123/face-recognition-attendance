#!/bin/bash
# Setup Linux App Icons
# Usage: ./setup_linux_icons.sh /path/to/your/icon.png

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Linux Icon Setup                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if icon path provided
if [ -z "$1" ]; then
    echo -e "${RED}✗ Please provide the path to your icon image${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./setup_linux_icons.sh /path/to/your/icon.png"
    echo ""
    echo -e "${YELLOW}Requirements:${NC}"
    echo -e "  - Square image (1:1 aspect ratio)"
    echo -e "  - Minimum 512x512 pixels recommended"
    echo -e "  - PNG format preferred"
    echo ""
    exit 1
fi

ICON_PATH="$1"

# Check if file exists
if [ ! -f "$ICON_PATH" ]; then
    echo -e "${RED}✗ Icon file not found: $ICON_PATH${NC}"
    exit 1
fi

# Check for ImageMagick
if ! command -v convert &> /dev/null; then
    echo -e "${RED}✗ ImageMagick not found${NC}"
    echo ""
    echo -e "${YELLOW}Install ImageMagick:${NC}"
    echo -e "  Ubuntu/Debian: sudo apt-get install imagemagick"
    echo -e "  Fedora: sudo dnf install ImageMagick"
    echo -e "  Arch: sudo pacman -S imagemagick"
    exit 1
fi

echo -e "${GREEN}✓ Found icon: $ICON_PATH${NC}"
echo ""

# Create icon directories
ICON_DIR="linux/icons"
mkdir -p "$ICON_DIR"

# Generate icons at different sizes
SIZES=(16 32 48 64 128 256 512)

echo -e "${YELLOW}Generating icons at multiple sizes...${NC}"
for size in "${SIZES[@]}"; do
    mkdir -p "$ICON_DIR/${size}x${size}"
    convert "$ICON_PATH" -resize ${size}x${size} "$ICON_DIR/${size}x${size}/attendanceai.png"
    echo -e "${GREEN}  ✓ Created ${size}x${size} icon${NC}"
done

echo ""
echo -e "${GREEN}✓ All icons generated successfully!${NC}"
echo ""
echo -e "${YELLOW}Icon locations:${NC}"
for size in "${SIZES[@]}"; do
    echo -e "  $ICON_DIR/${size}x${size}/attendanceai.png"
done

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Build the app: ${GREEN}./build_linux.sh${NC}"
echo -e "  2. Install system-wide: ${GREEN}sudo ./install_linux.sh${NC}"
echo ""
