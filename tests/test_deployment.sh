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

echo "=== Deployment tests ==="

id websvc &>/dev/null
check "user websvc exists" $?

id operator &>/dev/null
check "user operator exists" $?

id student &>/dev/null
check "user student exists" $?

systemctl is-active --quiet rootpath-web.service
check "rootpath-web.service is active" $?

curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200"
check "web application responds with HTTP 200" $?

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
