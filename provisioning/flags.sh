#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

USER_FLAG="/home/websvc/user.txt"
ROOT_FLAG="/root/root.txt"

log "Generating synthetic flag values..."
USER_TOKEN=$(head -c 16 /dev/urandom | md5sum | cut -d' ' -f1)
ROOT_TOKEN=$(head -c 16 /dev/urandom | md5sum | cut -d' ' -f1)

log "Installing user flag at ${USER_FLAG}..."
echo "ROOTPATH{foothold_confirmed_${USER_TOKEN}}" > "$USER_FLAG"
chown websvc:websvc "$USER_FLAG"
chmod 440 "$USER_FLAG"

log "Installing root flag at ${ROOT_FLAG}..."
echo "ROOTPATH{root_access_confirmed_${ROOT_TOKEN}}" > "$ROOT_FLAG"
chown root:root "$ROOT_FLAG"
chmod 400 "$ROOT_FLAG"

log "Flags installed."
