#!/usr/bin/env bash
# Rootpath - backup helper (runs as root via sudo, restricted to operator)
# Legitimate purpose: back up a file from /opt/rootpath/data into /opt/rootpath/backups
set -uo pipefail

BACKUP_DIR="/opt/rootpath/backups"
DATA_DIR="/opt/rootpath/data"
mkdir -p "$BACKUP_DIR"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# VULNERABLE: the filename argument is not validated or restricted to
# DATA_DIR. A caller can supply a path traversal or an absolute path
# to read/copy arbitrary files as root.
cp "$DATA_DIR/$1" "$BACKUP_DIR/$1.bak"
echo "Backed up $1 to $BACKUP_DIR/$1.bak"
