#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die() { printf '[-] %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Rootpath - user provisioning
# Creates the logical accounts required by the lab scenario.
# Idempotent: safe to re-run (e.g. on repeated `vagrant up`).
# ---------------------------------------------------------------------------

create_service_account() {
    local username="$1"
    if id "$username" &>/dev/null; then
        log "User '$username' already exists, skipping creation."
    else
        log "Creating service account '$username' (no login shell)..."
        useradd --system --create-home --shell /usr/sbin/nologin "$username" \
            || die "Failed to create user '$username'"
    fi
}

create_standard_account() {
    local username="$1"
    if id "$username" &>/dev/null; then
        log "User '$username' already exists, skipping creation."
    else
        log "Creating standard account '$username'..."
        useradd --no-user-group --create-home --shell /bin/bash "$username" \
            || die "Failed to create user '$username'"
    fi
}

log "Starting user provisioning..."

create_service_account "websvc"
create_standard_account "operator"
create_standard_account "student"

log "User provisioning complete."
