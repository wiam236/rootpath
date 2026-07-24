#!/usr/bin/env bash
set -uo pipefail

PASS=0
FAIL=0

check() {
    local description="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        printf '[PASS] %s\n' "$description"
        PASS=$((PASS+1))
    else
        printf '[FAIL] %s\n' "$description"
        FAIL=$((FAIL+1))
    fi
}

echo "=== Hardened-state tests ==="

# --- Test 1: legitimate ping feature still works ---
response=$(curl -s -X POST -d "host=127.0.0.1" http://localhost/)
echo "$response" | grep -q "bytes from"
check "legitimate ping feature still works" $?

# --- Test 2: command injection is blocked ---
response=$(curl -s -X POST -d "host=127.0.0.1; whoami" http://localhost/)
! echo "$response" | grep -q "websvc"
check "command injection is blocked (no 'websvc' in response)" $?

# --- Test 3: cleanup.sh (path A) is no longer group-writable ---
perms=$(stat -c '%a' /opt/rootpath/maintenance/cleanup.sh)
owner=$(stat -c '%U' /opt/rootpath/maintenance/cleanup.sh)
[ "$owner" = "root" ] && [ "$perms" = "755" ]
check "cleanup.sh ownership/permissions corrected (path A closed)" $?

# --- Test 4: legitimate backup feature still works ---
sudo -u operator sudo /opt/rootpath/maintenance/backup.sh sample.txt &>/dev/null
[ -f /opt/rootpath/backups/sample.txt.bak ]
check "legitimate backup feature still works" $?

# --- Test 5: backup.sh (path B) rejects path traversal ---
sudo -u operator sudo /opt/rootpath/maintenance/backup.sh ../../../../etc/passwd &>/dev/null
[ ! -f /etc/passwd.bak ]
check "backup.sh rejects path traversal (path B closed)" $?

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
