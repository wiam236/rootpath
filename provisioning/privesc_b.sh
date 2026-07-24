#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*" >&2; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

SCRIPT_DEST="/opt/rootpath/maintenance/backup.sh"
SCRIPT_SRC="/vagrant/provisioning/files/backup.sh"
SUDOERS_FILE="/etc/sudoers.d/rootpath-operator"

log "Installing privilege-escalation path B (unsafe sudo rule)..."

mkdir -p /opt/rootpath/maintenance /opt/rootpath/data /opt/rootpath/backups
cp "$SCRIPT_SRC" "$SCRIPT_DEST"
chown root:root "$SCRIPT_DEST"
chmod 755 "$SCRIPT_DEST"

log "Creating a sample data file for the backup demo..."
echo "This is a sample laboratory file." > /opt/rootpath/data/sample.txt

log "Installing scoped sudoers rule for operator..."
cat > "$SUDOERS_FILE" << 'EOF'
# Rootpath - operator may run the backup script as root, without a password.
# Restricted to this single script (not ALL commands).
operator ALL=(root) NOPASSWD: /opt/rootpath/maintenance/backup.sh
EOF
chmod 440 "$SUDOERS_FILE"

log "Validating sudoers syntax..."
visudo -c -f "$SUDOERS_FILE" || die "Invalid sudoers syntax"

log "Privilege-escalation path B installed."
