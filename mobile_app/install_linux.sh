#!/bin/bash
# Install AttendanceAI Linux Desktop App System-Wide
# Usage: sudo ./install_linux.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AttendanceAI Linux Installer        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Please run as root: sudo ./install_linux.sh${NC}"
    exit 1
fi

# Check if build exists
if [ ! -d "build/linux/x64/release/bundle" ]; then
    echo -e "${RED}✗ Build not found. Please run ./build_linux.sh first${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing AttendanceAI...${NC}"
echo ""

# Install directory
INSTALL_DIR="/opt/attendanceai"
BIN_DIR="/usr/local/bin"
DESKTOP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor"

# Create install directory
echo -e "${YELLOW}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"

# Copy application files
echo -e "${YELLOW}Copying application files...${NC}"
cp -r build/linux/x64/release/bundle/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/attendanceai"

# Create symlink in bin
echo -e "${YELLOW}Creating executable symlink...${NC}"
ln -sf "$INSTALL_DIR/attendanceai" "$BIN_DIR/attendanceai"

# Install desktop entry
echo -e "${YELLOW}Installing desktop entry...${NC}"
cp linux/attendanceai.desktop "$DESKTOP_DIR/"
chmod 644 "$DESKTOP_DIR/attendanceai.desktop"

# Install icons (if they exist)
if [ -f "linux/icons/128x128/attendanceai.png" ]; then
    echo -e "${YELLOW}Installing application icons...${NC}"
    for size in 16 32 48 64 128 256 512; do
        if [ -f "linux/icons/${size}x${size}/attendanceai.png" ]; then
            mkdir -p "$ICON_DIR/${size}x${size}/apps"
            cp "linux/icons/${size}x${size}/attendanceai.png" "$ICON_DIR/${size}x${size}/apps/"
        fi
    done
    
    # Update icon cache
    gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
else
    echo -e "${YELLOW}⚠ No custom icons found. Using default icon.${NC}"
fi

# Update desktop database
echo -e "${YELLOW}Updating desktop database...${NC}"
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${YELLOW}You can now:${NC}"
echo -e "  1. Launch from application menu: Search for 'AttendanceAI'"
echo -e "  2. Run from terminal: ${GREEN}attendanceai${NC}"
echo -e "  3. Create desktop shortcut from your file manager"
echo ""
echo -e "${YELLOW}To uninstall:${NC}"
echo -e "  sudo ./uninstall_linux.sh"
echo ""
