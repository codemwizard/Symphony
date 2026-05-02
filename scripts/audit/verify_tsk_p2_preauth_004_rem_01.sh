#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> Verifying TSK-P2-PREAUTH-004-REM-01 (Retroactive Approvals)"

FAIL=0

check_file() {
    if [[ -f "$1" ]]; then
        echo "✅ Found $1"
    else
        echo "❌ Missing $1"
        FAIL=1
    fi
}

check_file "approvals/2026-04-21/TSK-P2-PREAUTH-004-01.approval.json"
check_file "approvals/2026-04-21/TSK-P2-PREAUTH-004-02.approval.json"
check_file "approvals/2026-04-21/TSK-P2-PREAUTH-004-03.approval.json"

if [[ $FAIL -eq 1 ]]; then
    exit 1
fi

echo "STATUS: PASS"
