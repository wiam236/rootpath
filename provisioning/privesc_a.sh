#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*" >&2; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

SCRIPT_DEST="/opt/rootpath/maintenance/cleanup.sh"
SCRIPT_SRC="/vagrant/provisioning/files/cleanup.sh"
CRON_FILE="/etc/cron.d/rootpath-cleanup"

log "Installing privilege-escalation path A (vulnerable scheduled task)..."

mkdir -p /opt/rootpath/maintenance
cp "$SCRIPT_SRC" "$SCRIPT_DEST"

# VULNERABLE: root owns the file, but the websvc group has write access.
# Any member of the websvc group (i.e. websvc itself) can overwrite the
# script that root will execute on the next cron run.
chown root:websvc "$SCRIPT_DEST"
chmod 774 "$SCRIPT_DEST"

log "Installing cron entry (runs every minute as root)..."
cat > "$CRON_FILE" << 'EOF'
# Rootpath - maintenance cleanup, runs every minute as root.
* * * * * root /opt/rootpath/maintenance/cleanup.sh
EOF
chmod 644 "$CRON_FILE"

log "Privilege-escalation path A installed."
