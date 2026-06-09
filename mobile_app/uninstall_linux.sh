#!/bin/bash
# Uninstall AttendanceAI Linux Desktop App
# Usage: sudo ./uninstall_linux.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AttendanceAI Linux Uninstaller      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Please run as root: sudo ./uninstall_linux.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}Uninstalling AttendanceAI...${NC}"
echo ""

# Remove installation directory
if [ -d "/opt/attendanceai" ]; then
    echo -e "${YELLOW}Removing application files...${NC}"
    rm -rf /opt/attendanceai
fi

# Remove symlink
if [ -L "/usr/local/bin/attendanceai" ]; then
    echo -e "${YELLOW}Removing executable symlink...${NC}"
    rm /usr/local/bin/attendanceai
fi

# Remove desktop entry
if [ -f "/usr/share/applications/attendanceai.desktop" ]; then
    echo -e "${YELLOW}Removing desktop entry...${NC}"
    rm /usr/share/applications/attendanceai.desktop
fi

# Remove icons
echo -e "${YELLOW}Removing application icons...${NC}"
for size in 16 32 48 64 128 256 512; do
    if [ -f "/usr/share/icons/hicolor/${size}x${size}/apps/attendanceai.png" ]; then
        rm "/usr/share/icons/hicolor/${size}x${size}/apps/attendanceai.png"
    fi
done

# Update caches
echo -e "${YELLOW}Updating system caches...${NC}"
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Uninstallation complete!${NC}"
echo ""
