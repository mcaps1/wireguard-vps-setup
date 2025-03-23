# WireGuard VPS Setup Toolkit

## Overview
This toolkit contains three main scripts:
1. `wg-server-setup.sh` — Sets up WireGuard server with IPv4-only, default port (51820).
2. `wg-client-manager.sh` — Manage clients (add/remove/disable/enable) and generate QR codes.
3. `wg-backup.sh` — Backup and restore all server and client configurations.

## Usage
1. Run `wg-server-setup.sh` to install and configure your server.
2. Use `wg-client-manager.sh` to manage clients interactively.
3. Use `wg-backup.sh` to create or restore backups.

## Requirements
- Ubuntu server with root privileges.
