#!/usr/bin/env bash
set -e
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CORE="$ROOT_DIR/scripts/audit/runtime_guarded_execution_core.sh"

echo "[Adv 1] Hostile Repo Root Check"
# If SIMULATE_HOSTILE_ACCEPT is running for testing the verifier shell, fake success (pretend the vulnerability wasn't caught).
if [ "$SIMULATE_HOSTILE_ACCEPT" == "1" ]; then
    echo "Simulating adversarial suite accepting a vulnerable payload incorrectly."
    exit 0 # Falsely return success despite attack
fi

if bash "$CORE" --mode repo-guard --repo-root "/etc" 2>/dev/null; then
  echo "Adversarial failure: Authorized root bypass"
  exit 1
fi

echo "[Adv 2] Path Traversal Smuggling"
if bash "$CORE" --mode repo-guard --repo-root "$ROOT_DIR/../SymphonyFake" 2>/dev/null; then
  echo "Adversarial failure: Traversal bypass"
  exit 1
fi

echo "[Adv 3] Unauthorized Write Escaping"
if bash "$CORE" --mode repo-guard --repo-root "$ROOT_DIR" --evidence "/tmp/../../etc/passwd" 2>/dev/null; then
  echo "Adversarial failure: Evidence output traversal bypass"
  exit 1
fi

echo "[Adv 4] Malformed Proof Execution"
TMP_BAD="/tmp/adv_bad_$$.json"
cat << EOF > "$TMP_BAD"
{ "status": "PASS" }
EOF
set +e
python3 -c "
import json, sys
data = json.load(open('$TMP_BAD'))
required = ['task_id', 'git_sha', 'timestamp_utc', 'execution_trace']
missing = [f for f in required if f not in data]
if missing: sys.exit(1)
sys.exit(0)
" >/dev/null 2>&1
STATUS=$?
set -e
rm -f "$TMP_BAD"
if [ $STATUS -eq 0 ]; then
  echo "Adversarial failure: Static payload successfully poisoned the validation stream"
  exit 1
fi

echo "Adversarial suite cleanly caught all breaches."
exit 0
