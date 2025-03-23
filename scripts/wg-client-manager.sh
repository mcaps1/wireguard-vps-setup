#!/bin/bash

set -e

WG_INTERFACE="wg0"
WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/$WG_INTERFACE.conf"
CLIENT_CONFIG_DIR="$WG_DIR/clients"
CLIENT_IP_PREFIX="10.0.0."
LOG_FILE="$WG_DIR/client-manager.log"
SERVER_PUBLIC_KEY=$(grep "PrivateKey" "$WG_CONF" | awk '{print $3}' | wg pubkey)
WG_PORT="51820"

get_next_ip() {
    IP=2
    while grep -q "AllowedIPs = ${CLIENT_IP_PREFIX}${IP}/32" "$WG_CONF"; do
        IP=$((IP + 1))
    done
    echo "$IP"
}

add_client() {
    read -p "Enter client name: " CLIENT_NAME
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
    CLIENT_IP="${CLIENT_IP_PREFIX}$(get_next_ip)/32"

    echo "Adding client: $CLIENT_NAME ($CLIENT_IP)"

    cat >> "$WG_CONF" <<EOL

# $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP
EOL

    CLIENT_CONF="$CLIENT_CONFIG_DIR/${CLIENT_NAME}.conf"
    cat > "$CLIENT_CONF" <<EOL
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = ${CLIENT_IP}
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = <YOUR_PUBLIC_IP_OR_DOMAIN>:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOL

    chmod 600 "$CLIENT_CONF"

    echo "$(date) - Added client: $CLIENT_NAME, IP: $CLIENT_IP" >> "$LOG_FILE"

    echo "Client config saved at: $CLIENT_CONF"
    qrencode -t ansiutf8 < "$CLIENT_CONF"

    systemctl restart "wg-quick@$WG_INTERFACE"
}

remove_client() {
    read -p "Enter client name to remove: " CLIENT_NAME
    sed -i "/# $CLIENT_NAME/,/AllowedIPs/d" "$WG_CONF"
    rm -f "$CLIENT_CONFIG_DIR/${CLIENT_NAME}.conf"
    echo "$(date) - Removed client: $CLIENT_NAME" >> "$LOG_FILE"
    systemctl restart "wg-quick@$WG_INTERFACE"
    echo "$CLIENT_NAME removed."
}

disable_client() {
    read -p "Enter client name to disable: " CLIENT_NAME
    sed -i "/# $CLIENT_NAME/{n;s/AllowedIPs = .*/AllowedIPs = 0.0.0.0\/32/}" "$WG_CONF"
    echo "$(date) - Disabled client: $CLIENT_NAME" >> "$LOG_FILE"
    systemctl restart "wg-quick@$WG_INTERFACE"
}

enable_client() {
    read -p "Enter client name to re-enable: " CLIENT_NAME
    CLIENT_IP_LINE=$(grep -n "# $CLIENT_NAME" "$WG_CONF" | cut -d: -f1)
    if [ "$CLIENT_IP_LINE" ]; then
        read -p "Enter desired IP (e.g., 10.0.0.X): " DESIRED_IP
        sed -i "$((CLIENT_IP_LINE + 1))s/AllowedIPs = .*/AllowedIPs = $DESIRED_IP\/32/" "$WG_CONF"
        echo "$(date) - Enabled client: $CLIENT_NAME, IP: $DESIRED_IP/32" >> "$LOG_FILE"
        systemctl restart "wg-quick@$WG_INTERFACE"
    fi
}

show_log() {
    cat "$LOG_FILE"
}

menu() {
    echo "========= WireGuard Client Manager ========="
    echo "1. Add Client"
    echo "2. Remove Client"
    echo "3. Disable Client"
    echo "4. Enable Client"
    echo "5. Show Log"
    echo "6. Exit"
    echo "============================================"
}

while true; do
    menu
    read -p "Choose an option: " OPTION
    case "$OPTION" in
        1) add_client ;;
        2) remove_client ;;
        3) disable_client ;;
        4) enable_client ;;
        5) show_log ;;
        6) exit ;;
        *) echo "Invalid option!" ;;
    esac
done
