#!/bin/bash

set -e

WG_DIR="/etc/wireguard"
BACKUP_DIR="/root/wireguard-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

backup() {
    tar czvf "$BACKUP_DIR/wg-backup-$TIMESTAMP.tar.gz" "$WG_DIR"
    echo "Backup saved to: $BACKUP_DIR/wg-backup-$TIMESTAMP.tar.gz"
}

restore() {
    ls -lh "$BACKUP_DIR"
    read -p "Enter backup filename to restore: " BACKUP_FILE
    tar xzvf "$BACKUP_DIR/$BACKUP_FILE" -C /
    systemctl restart "wg-quick@wg0"
    echo "Backup restored."
}

echo "1. Backup WireGuard Configs"
echo "2. Restore WireGuard Configs"
read -p "Choose an option: " OPTION
case "$OPTION" in
    1) backup ;;
    2) restore ;;
    *) echo "Invalid option!" ;;
esac
