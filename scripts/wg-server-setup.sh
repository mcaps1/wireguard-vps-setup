#!/bin/bash

set -e

WG_INTERFACE="wg0"
WG_PORT="51820"
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/$WG_INTERFACE.conf"
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
SERVER_IP="10.0.0.1/24"
CLIENT_CONFIG_DIR="$WG_DIR/clients"

echo "Setting up WireGuard Server..."

apt update && apt install -y wireguard qrencode

if [ -f "$WG_CONF" ]; then
    cp "$WG_CONF" "$WG_CONF.bak.$(date +%s)"
fi

mkdir -p "$CLIENT_CONFIG_DIR"

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

cat > "$WG_CONF" <<EOL
[Interface]
Address = $SERVER_IP
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVATE_KEY
SaveConfig = true
EOL

chmod 600 "$WG_CONF"

if command -v ufw >/dev/null 2>&1; then
    ufw allow "$WG_PORT"/udp
    ufw reload
fi

systemctl enable "wg-quick@$WG_INTERFACE"
systemctl start "wg-quick@$WG_INTERFACE"

echo "===================================="
echo "WireGuard Server setup complete!"
echo "Public Key: $SERVER_PUBLIC_KEY"
echo "Config: $WG_CONF"
echo "Clients Directory: $CLIENT_CONFIG_DIR"
echo "Use ./wg-client-manager.sh to add/remove clients."
echo "Use ./wg-backup.sh to backup/restore configs."
echo "===================================="
