#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*" >&2; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

APP_SRC="/vagrant/app"
APP_DEST="/opt/rootpath/app"

log "Deploying application files to ${APP_DEST}..."
mkdir -p "${APP_DEST}"
cp -r "${APP_SRC}/src" "${APP_DEST}/"
cp "${APP_SRC}/requirements.txt" "${APP_DEST}/"

log "Creating Python virtual environment..."
if [ ! -d "${APP_DEST}/venv" ]; then
    python3 -m venv "${APP_DEST}/venv" || die "Failed to create venv"
else
    log "Virtual environment already exists, skipping creation."
fi

log "Installing Python dependencies..."
"${APP_DEST}/venv/bin/pip" install --quiet --upgrade pip
"${APP_DEST}/venv/bin/pip" install --quiet -r "${APP_DEST}/requirements.txt" \
    || die "Failed to install Python dependencies"

log "Setting ownership to websvc..."
chown -R websvc:websvc "${APP_DEST}"

log "Installing systemd service unit..."
cp "${APP_SRC}/systemd/rootpath-web.service" /etc/systemd/system/rootpath-web.service

log "Reloading systemd and enabling the service..."
systemctl daemon-reload
systemctl enable rootpath-web.service
systemctl restart rootpath-web.service

log "Service provisioning complete."
