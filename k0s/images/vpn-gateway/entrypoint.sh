#!/bin/sh
set -e

# Configuration from environment
VPN_INTERFACE="${VPN_INTERFACE:-tun0}"
L2TP_IP_RANGE="${L2TP_IP_RANGE:-172.20.0}"
L2TP_SECRET="${L2TP_SECRET:-vpn-shared-secret}"
L2TP_LOCAL_NAME="${L2TP_LOCAL_NAME:-vpn-gateway}"
DNS_SERVER="${DNS_SERVER:-10.96.0.10}"

# Wait for VPN interface
echo "Waiting for VPN interface ${VPN_INTERFACE}..."
while ! ip link show "$VPN_INTERFACE" 2>/dev/null; do
  sleep 1
done
echo "VPN interface ${VPN_INTERFACE} is up"

# Create xl2tpd config
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701
auth file = /etc/ppp/chap-secrets

[lns default]
ip range = ${L2TP_IP_RANGE}.10-${L2TP_IP_RANGE}.250
local ip = ${L2TP_IP_RANGE}.1
require chap = yes
refuse pap = yes
require authentication = yes
name = ${L2TP_LOCAL_NAME}
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

# Create ppp options
cat > /etc/ppp/options.xl2tpd <<EOF
require-mschap-v2
ms-dns ${DNS_SERVER}
noccp
auth
hide-password
idle 1800
mtu 1410
mru 1410
nodefaultroute
debug
proxyarp
connect-delay 5000
EOF

# Create chap-secrets
cat > /etc/ppp/chap-secrets <<EOF
# client    server          secret          IP
*           ${L2TP_LOCAL_NAME}    ${L2TP_SECRET}    *
EOF
chmod 600 /etc/ppp/chap-secrets

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# NAT for L2TP clients through VPN
iptables -t nat -A POSTROUTING -s ${L2TP_IP_RANGE}.0/24 -o "$VPN_INTERFACE" -j MASQUERADE

# Allow forwarding
iptables -A FORWARD -i ppp+ -o "$VPN_INTERFACE" -j ACCEPT
iptables -A FORWARD -i "$VPN_INTERFACE" -o ppp+ -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "NAT configured for L2TP clients via ${VPN_INTERFACE}"

# Start xl2tpd
echo "Starting xl2tpd..."
exec xl2tpd -D -c /etc/xl2tpd/xl2tpd.conf
