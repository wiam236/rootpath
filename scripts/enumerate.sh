#!/usr/bin/env bash
# Rootpath - custom enumeration tool
# Read-only: does not modify the target system.
# Usage: ./enumerate.sh [-h]

set -uo pipefail   # no -e here: individual checks may legitimately fail

log_section() { printf '\n=== %s ===\n' "$*"; }
info()        { printf '[+] %s\n' "$*"; }
finding()     { printf '[!] %s\n' "$*"; }

usage() {
    cat <<EOF
Rootpath enumeration tool
Usage: $0 [-h]
  -h    show this help and exit

Performs read-only enumeration of the local system: identity, OS,
network, processes, sudo rights, SUID/SGID files, capabilities,
scheduled tasks, and writable privileged paths.
EOF
}

while getopts "h" opt; do
    case "$opt" in
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
log_section "Identity"
info "user: $(whoami)"
info "id: $(id)"
info "home: $HOME"

# ---------------------------------------------------------------------------
log_section "OS / Kernel"
if [ -f /etc/os-release ]; then
    grep -E "^(PRETTY_NAME|VERSION_ID)=" /etc/os-release
fi
info "kernel: $(uname -a)"

# ---------------------------------------------------------------------------
log_section "Environment variables"
env | sort

# ---------------------------------------------------------------------------
log_section "Network: interfaces and routes"
ip addr show 2>/dev/null || ifconfig 2>/dev/null
echo "---"
ip route show 2>/dev/null || route -n 2>/dev/null

log_section "Network: listening ports"
ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null

# ---------------------------------------------------------------------------
log_section "Running processes"
ps aux 2>/dev/null

# ---------------------------------------------------------------------------
log_section "Sudo rights"
if command -v sudo &>/dev/null; then
    sudo -l 2>/dev/null || info "sudo -l not permitted or requires a password"
else
    info "sudo not available"
fi

# ---------------------------------------------------------------------------
log_section "SUID / SGID files (non-standard)"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | while read -r f; do
    echo "$f ($(stat -c '%U:%G %a' "$f" 2>/dev/null))"
done

# ---------------------------------------------------------------------------
log_section "File capabilities"
if command -v getcap &>/dev/null; then
    getcap -r / 2>/dev/null
else
    info "getcap not available"
fi

# ---------------------------------------------------------------------------
log_section "Cron jobs and systemd timers"
info "System crontab:"
cat /etc/crontab 2>/dev/null
echo "---"
info "Cron.d entries:"
ls -la /etc/cron.d/ 2>/dev/null
echo "---"
info "Systemd timers:"
systemctl list-timers --all 2>/dev/null

# ---------------------------------------------------------------------------
log_section "Writable privileged scripts/directories"
# Look for files owned by root or another user, but writable by us.
for d in /opt /etc /usr/local/bin /usr/local/sbin; do
    find "$d" -xdev -writable -type f 2>/dev/null | while read -r f; do
        owner=$(stat -c '%U' "$f" 2>/dev/null)
        if [ "$owner" != "$(whoami)" ]; then
            finding "path: $f"
            echo "    owner: $owner"
            echo "    mode:  $(stat -c '%a' "$f" 2>/dev/null)"
        fi
    done
done

# ---------------------------------------------------------------------------
log_section "PATH writable entries"
echo "$PATH" | tr ':' '\n' | while read -r dir; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        finding "writable PATH directory: $dir"
    fi
done

# ---------------------------------------------------------------------------
log_section "Enumeration complete"
info "Review [!] findings above for potential privilege-escalation paths."
