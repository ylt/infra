#!/bin/sh
set -e

# Configuration from environment
L2TP_SERVER="${L2TP_SERVER:-vpn-gateway.vpn-gateway.svc.cluster.local}"
L2TP_SECRET="${L2TP_SECRET:-vpn-shared-secret}"
L2TP_USERNAME="${L2TP_USERNAME:-vpnclient}"
L2TP_SERVER_NAME="${L2TP_SERVER_NAME:-vpn-gateway}"
# Subnets to keep routed through the original gateway (cluster network)
KEEP_ROUTES="${KEEP_ROUTES:-10.0.0.0/8}"

echo "Connecting to L2TP server: ${L2TP_SERVER}"

# Get original gateway before ppp0 changes routes
ORIG_GW=$(ip route | grep "^default" | awk '{print $3}')
ORIG_DEV=$(ip route | grep "^default" | awk '{print $5}')
echo "Original gateway: ${ORIG_GW} via ${ORIG_DEV}"

# Resolve L2TP server IP
L2TP_SERVER_IP=$(getent hosts ${L2TP_SERVER} | awk '{print $1}')
if [ -z "$L2TP_SERVER_IP" ]; then
    echo "ERROR: Could not resolve ${L2TP_SERVER}"
    exit 1
fi
echo "L2TP server IP: ${L2TP_SERVER_IP}"

# Add persistent route to L2TP server (so control connection survives ppp0 coming up)
ip route add ${L2TP_SERVER_IP}/32 via ${ORIG_GW} dev ${ORIG_DEV}
echo "Added host route to L2TP server"

# Add routes to keep cluster traffic local
for subnet in ${KEEP_ROUTES}; do
    ip route add ${subnet} via ${ORIG_GW} dev ${ORIG_DEV} || true
    echo "Added route for ${subnet}"
done

# Create xl2tpd client config
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 0

[lac vpn]
lns = ${L2TP_SERVER}
pppoptfile = /etc/ppp/options.l2tpd.client
ppp debug = yes
length bit = yes
redial = yes
redial timeout = 5
max redials = 5
EOF

# Create ppp options
cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
idle 1800
mtu 1410
mru 1410
defaultroute
replacedefaultroute
usepeerdns
debug
connect-delay 5000
name ${L2TP_USERNAME}
password ${L2TP_SECRET}
EOF

chmod 600 /etc/ppp/options.l2tpd.client

# Create chap-secrets for authentication
cat > /etc/ppp/chap-secrets <<EOF
${L2TP_USERNAME} ${L2TP_SERVER_NAME} ${L2TP_SECRET} *
EOF
chmod 600 /etc/ppp/chap-secrets

# Start xl2tpd in foreground
echo "Starting xl2tpd client..."
xl2tpd -D -c /etc/xl2tpd/xl2tpd.conf -p /var/run/xl2tpd/xl2tpd.pid -C /var/run/xl2tpd/l2tp-control &
XL2TPD_PID=$!

# Wait for control socket to be created
echo "Waiting for xl2tpd control socket..."
for i in $(seq 1 10); do
    if [ -e /var/run/xl2tpd/l2tp-control ]; then
        echo "Control socket ready"
        break
    fi
    sleep 1
done

if [ ! -e /var/run/xl2tpd/l2tp-control ]; then
    echo "ERROR: Control socket not created"
    exit 1
fi

# Trigger the connection
echo "Triggering L2TP connection..."
echo "c vpn" > /var/run/xl2tpd/l2tp-control

# Wait for ppp interface
echo "Waiting for ppp0 interface..."
for i in $(seq 1 60); do
    if ip link show ppp0 2>/dev/null; then
        echo "ppp0 interface is up"
        ip addr show ppp0
        ip route
        break
    fi
    # Show xl2tpd status periodically
    if [ $((i % 10)) -eq 0 ]; then
        echo "Still waiting for ppp0... (attempt $i/60)"
    fi
    sleep 1
done

if ! ip link show ppp0 2>/dev/null; then
    echo "ERROR: ppp0 interface did not come up after 60s"
    exit 1
fi

# Keep running
echo "L2TP tunnel established, keeping alive..."
wait $XL2TPD_PID
