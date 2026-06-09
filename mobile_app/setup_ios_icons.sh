#!/bin/bash
# Setup iOS App Icons
# Usage: ./setup_ios_icons.sh /path/to/your/icon.png

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   iOS Icon Setup                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if icon path provided
if [ -z "$1" ]; then
    echo -e "${RED}✗ Please provide the path to your icon image${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./setup_ios_icons.sh /path/to/your/icon.png"
    echo ""
    echo -e "${YELLOW}Requirements:${NC}"
    echo -e "  - Square image (1:1 aspect ratio)"
    echo -e "  - Minimum 1024x1024 pixels (required by Apple)"
    echo -e "  - PNG format with NO transparency"
    echo -e "  - Simple design that works at small sizes"
    echo ""
    exit 1
fi

ICON_PATH="$1"

# Check if file exists
if [ ! -f "$ICON_PATH" ]; then
    echo -e "${RED}✗ Icon file not found: $ICON_PATH${NC}"
    exit 1
fi

# Check for ImageMagick or sips (macOS built-in)
if command -v sips &> /dev/null; then
    CONVERTER="sips"
    echo -e "${GREEN}✓ Using sips (macOS built-in)${NC}"
elif command -v convert &> /dev/null; then
    CONVERTER="imagemagick"
    echo -e "${GREEN}✓ Using ImageMagick${NC}"
else
    echo -e "${RED}✗ No image converter found${NC}"
    echo ""
    echo -e "${YELLOW}Install ImageMagick:${NC}"
    echo -e "  brew install imagemagick"
    exit 1
fi

echo -e "${GREEN}✓ Found icon: $ICON_PATH${NC}"
echo ""

# iOS icon sizes (all required by Apple)
# Format: "size@scale filename"
declare -a ICONS=(
    "20@2x Icon-App-20x20@2x.png"
    "20@3x Icon-App-20x20@3x.png"
    "29@2x Icon-App-29x29@2x.png"
    "29@3x Icon-App-29x29@3x.png"
    "40@2x Icon-App-40x40@2x.png"
    "40@3x Icon-App-40x40@3x.png"
    "60@2x Icon-App-60x60@2x.png"
    "60@3x Icon-App-60x60@3x.png"
    "76@1x Icon-App-76x76@1x.png"
    "76@2x Icon-App-76x76@2x.png"
    "83.5@2x Icon-App-83.5x83.5@2x.png"
    "1024@1x Icon-App-1024x1024@1x.png"
)

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo -e "${YELLOW}Generating iOS app icons...${NC}"
echo ""

# Create directory if it doesn't exist
mkdir -p "$ICON_DIR"

# Generate each icon size
for icon_spec in "${ICONS[@]}"; do
    size_scale=$(echo $icon_spec | cut -d' ' -f1)
    filename=$(echo $icon_spec | cut -d' ' -f2)
    
    # Parse size and scale
    base_size=$(echo $size_scale | cut -d'@' -f1)
    scale=$(echo $size_scale | cut -d'@' -f2 | sed 's/x//')
    
    # Calculate actual pixel size
    pixel_size=$(echo "$base_size * $scale" | bc | cut -d'.' -f1)
    
    output_path="$ICON_DIR/$filename"
    
    if [ "$CONVERTER" = "sips" ]; then
        sips -z $pixel_size $pixel_size "$ICON_PATH" --out "$output_path" > /dev/null 2>&1
    else
        convert "$ICON_PATH" -resize ${pixel_size}x${pixel_size} "$output_path"
    fi
    
    echo -e "${GREEN}  ✓ Created ${pixel_size}x${pixel_size} ($filename)${NC}"
done

# Create Contents.json
cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-App-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

echo ""
echo -e "${GREEN}✓ All iOS icons generated successfully!${NC}"
echo -e "${GREEN}✓ Contents.json created${NC}"
echo ""
echo -e "${YELLOW}Icon location:${NC}"
echo -e "  $ICON_DIR/"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Clean and rebuild: ${GREEN}flutter clean && ./build_ios.sh${NC}"
echo -e "  2. Or open in Xcode: ${GREEN}open ios/Runner.xcworkspace${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} The 1024x1024 icon is required for App Store submission"
echo ""
