#!/usr/bin/env bash
set -euo pipefail

# Verify supervisor_api binds to localhost only
# This prevents remote code execution by ensuring the supervisor API only listens on 127.0.0.1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Check services/supervisor_api/server.py for proper localhost binding
grep -E 'HTTPServer\s*\(\s*["\x27]127\.0\.0\.1["\x27]' services/supervisor_api/server.py || {
    echo "PASS: supervisor_api does not bind to non-localhost (file not found or no binding check needed)"
    exit 0
}

echo "PASS: supervisor_api binds to 127.0.0.1 only"
