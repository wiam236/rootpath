#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

log "Resetting Rootpath lab to its vulnerable state..."

log "Re-applying privilege-escalation path A (cron)..."
bash /vagrant/provisioning/privesc_a.sh

log "Re-applying privilege-escalation path B (sudo)..."
bash /vagrant/provisioning/privesc_b.sh

log "Re-generating flags..."
bash /vagrant/provisioning/flags.sh

log "Cleaning up any leftover exploitation artifacts..."
rm -f /tmp/rootbash
rm -f /etc/passwd.bak /etc/shadow.bak

log "Restarting the vulnerable web service..."
systemctl restart rootpath-web.service

log "Reset complete. Lab is back to its vulnerable state."
