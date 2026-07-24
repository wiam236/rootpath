#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*" >&2; }
die() { printf "[-] %s\n" "$*" >&2; exit 1; }

log "Updating package index..."
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update -qq || die "apt-get update failed"

log "Installing required packages (python3, pip, venv, iputils-ping)..."
apt-get install -y -qq python3 python3-venv python3-pip iputils-ping curl || die "apt-get install failed"

log "Package provisioning complete."
