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

echo "=== Vulnerable-state tests ==="

# --- Test 1: command injection is exploitable via the web app ---
response=$(curl -s -X POST -d "host=127.0.0.1; whoami" http://localhost/)
echo "$response" | grep -q "websvc"
check "command injection: 'whoami' output ('websvc') present in response" $?

# --- Test 2: cleanup.sh (path A) is group-writable by websvc ---
perms=$(stat -c '%a' /opt/rootpath/maintenance/cleanup.sh)
group=$(stat -c '%G' /opt/rootpath/maintenance/cleanup.sh)
[ "$group" = "websvc" ] && [[ "$perms" =~ ^7[67][0-9]$ ]]
check "cleanup.sh is group-writable by websvc (path A present)" $?

# --- Test 3: backup.sh (path B) allows path traversal ---
sudo -u operator sudo /opt/rootpath/maintenance/backup.sh ../../../../etc/passwd &>/dev/null
[ -f /etc/passwd.bak ]
check "backup.sh allows path traversal (path B present)" $?
rm -f /etc/passwd.bak

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
