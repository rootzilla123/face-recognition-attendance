#!/bin/bash
# Configure mobile app for local testing
# Usage: ./configure_local.sh [YOUR_LOCAL_IP]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Mobile App Local Configuration ===${NC}"
echo ""

# Get local IP
if [ -z "$1" ]; then
    echo -e "${YELLOW}Detecting local IP address...${NC}"
    
    # Try different methods to get local IP
    if command -v ip &> /dev/null; then
        LOCAL_IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)
    elif command -v ifconfig &> /dev/null; then
        LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    else
        echo -e "${RED}Could not detect local IP. Please provide it as argument:${NC}"
        echo "  ./configure_local.sh 192.168.1.100"
        exit 1
    fi
    
    echo -e "${GREEN}Detected IP: $LOCAL_IP${NC}"
    echo ""
    read -p "Is this correct? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        read -p "Enter your local IP address: " LOCAL_IP
    fi
else
    LOCAL_IP=$1
fi

echo ""
echo -e "${GREEN}Configuring for local IP: $LOCAL_IP${NC}"
echo ""

# Backup original file
CONFIG_FILE="lib/core/utils/server_config.dart"
if [ ! -f "${CONFIG_FILE}.backup" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    echo -e "${GREEN}✓ Backed up original config${NC}"
fi

# Update configuration
cat > "$CONFIG_FILE" << EOF
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _apiKey = 'server_base_url';
  static const _pbKey = 'pocketbase_url';

  // LOCAL DEVELOPMENT - configured by configure_local.sh
  static const defaultUrl = 'http://$LOCAL_IP:8001';
  static const defaultPbUrl = 'http://$LOCAL_IP:8090';

  static String _current = defaultUrl;
  static String _pbCurrent = defaultPbUrl;

  static String get baseUrl => _current;
  static String get pbUrl => _pbCurrent;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_apiKey) ?? defaultUrl;
    _pbCurrent = prefs.getString(_pbKey) ?? defaultPbUrl;
  }

  static Future<void> save(String url) async {
    _current = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, url);
  }

  static Future<void> savePbUrl(String url) async {
    _pbCurrent = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pbKey, url);
  }
}
EOF

echo -e "${GREEN}✓ Updated server configuration${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  API URL: http://$LOCAL_IP:8001"
echo "  PocketBase URL: http://$LOCAL_IP:8090"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Start backend services:"
echo "     cd .. && ./start_all.sh"
echo ""
echo "  2. Run the app:"
echo "     flutter run"
echo ""
echo -e "${YELLOW}To restore production config:${NC}"
echo "  ./configure_production.sh"
echo ""
