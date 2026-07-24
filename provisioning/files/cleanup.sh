#!/usr/bin/env bash
# Rootpath - maintenance cleanup task (executed by root via cron)
# Legitimate purpose: remove old temporary files from the app's tmp directory.
set -uo pipefail

TMP_DIR="/opt/rootpath/app/tmp"
mkdir -p "$TMP_DIR"
find "$TMP_DIR" -type f -mtime +7 -delete 2>/dev/null

echo "$(date '+%Y-%m-%d %H:%M:%S') cleanup executed" >> /var/log/rootpath-cleanup.log
