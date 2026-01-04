#!/bin/sh
set -e

# Configuration
WG_CONFIG="${WG_CONFIG:-/config/wg0.conf}"
KEEP_ROUTES="${KEEP_ROUTES:-10.0.0.0/8}"

echo "WireGuard Client Sidecar"
echo "========================"

# Check config exists
if [ ! -f "$WG_CONFIG" ]; then
    echo "ERROR: WireGuard config not found at $WG_CONFIG"
    exit 1
fi

# Get original gateway before WireGuard takes over
ORIG_GW=$(ip route | grep "^default" | awk '{print $3}')
ORIG_DEV=$(ip route | grep "^default" | awk '{print $5}')
echo "Original gateway: ${ORIG_GW} via ${ORIG_DEV}"

# Extract hub endpoint from config
HUB_ENDPOINT=$(grep -i "^Endpoint" "$WG_CONFIG" | head -1 | cut -d= -f2 | tr -d ' ' | cut -d: -f1)
if [ -n "$HUB_ENDPOINT" ]; then
    # Resolve hostname if needed
    HUB_IP=$(getent hosts "$HUB_ENDPOINT" 2>/dev/null | awk '{print $1}' || echo "$HUB_ENDPOINT")
    echo "Hub endpoint: ${HUB_ENDPOINT} -> ${HUB_IP}"

    # Add route to hub via original gateway (so WireGuard traffic doesn't loop)
    ip route add "${HUB_IP}/32" via "$ORIG_GW" dev "$ORIG_DEV" 2>/dev/null || true
    echo "Added host route to hub"
fi

# Add routes to keep cluster traffic local
for subnet in $KEEP_ROUTES; do
    ip route add "$subnet" via "$ORIG_GW" dev "$ORIG_DEV" 2>/dev/null || true
    echo "Added route for ${subnet}"
done

# Bring up WireGuard interface
echo "Starting WireGuard..."
wg-quick up "$WG_CONFIG"

# Show status
echo ""
echo "WireGuard interface status:"
wg show

echo ""
echo "Routing table:"
ip route

echo ""
echo "WireGuard tunnel established, keeping alive..."

# Keep running
exec sleep infinity
