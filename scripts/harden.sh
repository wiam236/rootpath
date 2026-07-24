#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

log "Applying Rootpath hardening profile..."

# ---------------------------------------------------------------------------
log "Fix 1/3: replacing the vulnerable web application with the secure implementation..."
cp /opt/rootpath/app/src/app_secure.py /opt/rootpath/app/src/app.py
chown websvc:websvc /opt/rootpath/app/src/app.py
systemctl restart rootpath-web.service

# ---------------------------------------------------------------------------
log "Fix 2/3: correcting permissions on the cron maintenance script (path A)..."
chown root:root /opt/rootpath/maintenance/cleanup.sh
chmod 755 /opt/rootpath/maintenance/cleanup.sh

# ---------------------------------------------------------------------------
log "Fix 3/3: replacing backup.sh with a safe, argument-validated version (path B)..."
cat > /opt/rootpath/maintenance/backup.sh << 'EOF'
#!/usr/bin/env bash
# Rootpath - backup helper (HARDENED VERSION)
# Only allows plain filenames within DATA_DIR: no slashes, no traversal.
set -uo pipefail

BACKUP_DIR="/opt/rootpath/backups"
DATA_DIR="/opt/rootpath/data"
mkdir -p "$BACKUP_DIR"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename="$1"

# SECURE: reject anything that is not a plain filename.
if [[ "$filename" == *"/"* ]] || [[ "$filename" == ".."* ]]; then
    echo "Error: invalid filename." >&2
    exit 1
fi

if [ ! -f "$DATA_DIR/$filename" ]; then
    echo "Error: file not found in $DATA_DIR." >&2
    exit 1
fi

cp "$DATA_DIR/$filename" "$BACKUP_DIR/$filename.bak"
echo "Backed up $filename to $BACKUP_DIR/$filename.bak"
EOF
chown root:root /opt/rootpath/maintenance/backup.sh
chmod 755 /opt/rootpath/maintenance/backup.sh

log "Hardening complete. All mandatory vulnerabilities have been corrected."
log "Legitimate features (ping, cleanup, backup) remain functional."
