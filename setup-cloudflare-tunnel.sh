#!/usr/bin/env bash
# setup-cloudflare-tunnel.sh
# Run this ONCE on the server (school machine or home server) to create the tunnel.
# After this, the tunnel token goes into your .env as CLOUDFLARE_TUNNEL_TOKEN.
set -euo pipefail

echo "── Installing cloudflared ───────────────────────────────────────────────"
curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared
cloudflared --version

echo ""
echo "── Login to Cloudflare (browser will open) ──────────────────────────────"
cloudflared tunnel login

echo ""
echo "── Creating tunnel ──────────────────────────────────────────────────────"
cloudflared tunnel create attendance-app

TUNNEL_ID=$(cloudflared tunnel list | grep attendance-app | awk '{print $1}')
echo "Tunnel ID: $TUNNEL_ID"

echo ""
read -rp "Enter your domain (e.g. attendanceai.com): " DOMAIN

echo "── Creating DNS routes ───────────────────────────────────────────────────"
cloudflared tunnel route dns attendance-app "$DOMAIN"
cloudflared tunnel route dns attendance-app "api.$DOMAIN"
cloudflared tunnel route dns attendance-app "pb.$DOMAIN"
cloudflared tunnel route dns attendance-app "errors.$DOMAIN"

echo ""
echo "── Updating cloudflare-tunnel.yml ───────────────────────────────────────"
sed -i "s/<YOUR_TUNNEL_ID>/$TUNNEL_ID/g" cloudflare-tunnel.yml
sed -i "s/YOUR_DOMAIN/$DOMAIN/g" cloudflare-tunnel.yml

echo ""
echo "✅  Done! Now:"
echo "   1. Go to https://one.dash.cloudflare.com → Zero Trust → Networks → Tunnels"
echo "   2. Click 'attendance-app' → Overview → copy the tunnel token"
echo "   3. Add it to your .env:  CLOUDFLARE_TUNNEL_TOKEN=<paste here>"
echo "   4. Run: docker compose -f docker-compose.prod.yml up -d"
