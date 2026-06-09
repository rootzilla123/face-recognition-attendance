#!/bin/bash
# Restore production configuration
# Usage: ./configure_production.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Restoring Production Configuration ===${NC}"
echo ""

CONFIG_FILE="lib/core/utils/server_config.dart"

# Check if backup exists
if [ ! -f "${CONFIG_FILE}.backup" ]; then
    echo -e "${YELLOW}No backup found. Creating production config...${NC}"
fi

# Restore production configuration
cat > "$CONFIG_FILE" << 'EOF'
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _apiKey = 'server_base_url';
  static const _pbKey = 'pocketbase_url';

  // Production defaults — point to Cloudflare tunnel domains.
  // User can override in Settings screen for local dev.
  static const defaultUrl = 'https://shadomfacepro.duckdns.org';
  static const defaultPbUrl = 'https://pb.shadomfacepro.duckdns.org';

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

echo -e "${GREEN}✓ Restored production configuration${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  API URL: https://shadomfacepro.duckdns.org"
echo "  PocketBase URL: https://pb.shadomfacepro.duckdns.org"
echo ""
echo -e "${GREEN}Ready to build production APK:${NC}"
echo "  flutter build apk --release"
echo ""
