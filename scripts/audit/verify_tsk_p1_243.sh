#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

CORE="scripts/audit/runtime_guarded_execution_core.sh"
chmod +x "$CORE"

echo "[Test N1] Unsupported mode"
if bash "$CORE" --mode invalid-mode --repo-root "$ROOT_DIR" 2>/dev/null; then
    echo "Failed N1: Should reject invalid mode"
    exit 1
fi

echo "[Test N2] Outside working tree"
if bash "$CORE" --mode contract-check --repo-root /tmp 2>/dev/null; then
    echo "Failed N2: Should reject outside tree"
    exit 1
fi

echo "[Test N2.1] Missing path"
if bash "$CORE" --mode contract-check --repo-root "$ROOT_DIR/nonexistent-dir-123" 2>/dev/null; then
    echo "Failed N2.1: Should reject missing path"
    exit 1
fi

echo "[Test N3] No implicit evidence writes"
BEFORE_STATE=$(mktemp)
AFTER_STATE=$(mktemp)
ls -laR evidence/ > "$BEFORE_STATE"
bash "$CORE" --mode contract-check --repo-root "$ROOT_DIR"
ls -laR evidence/ > "$AFTER_STATE"

if ! cmp -s "$BEFORE_STATE" "$AFTER_STATE"; then
    echo "Failed N3: Repo-tracked writes occurred without explicit target"
    rm "$BEFORE_STATE" "$AFTER_STATE"
    exit 1
fi
rm "$BEFORE_STATE" "$AFTER_STATE"

echo "[Test P1] Valid Mode Execution"
TMP_EVID="$(mktemp)"
bash "$CORE" --mode repo-guard --repo-root "$ROOT_DIR" --evidence "$TMP_EVID"
rm "$TMP_EVID"

cat << EOF > evidence/phase1/tsk_p1_243_guarded_execution_core.json
{
  "task_id": "TSK-P1-243",
  "git_sha": "$(git rev-parse HEAD)",
  "timestamp_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "PASS",
  "checks": {
    "N1_unsupported_mode": "PASS",
    "N2_outside_tree": "PASS",
    "N3_no_implicit_evidence": "PASS",
    "P1_valid_modes": "PASS"
  },
  "entrypoint_path": "scripts/audit/runtime_guarded_execution_core.sh",
  "supported_modes": ["repo-guard", "contract-check"],
  "repo_root_confinement": "Enforced via absolute path resolving bounding runtime scripts natively.",
  "strict_failure_posture": true,
  "scope_boundary": "Execution core initialized. Repository/Filesystem mapping boundaries remain TSK-P1-244 workload. Evidence payload semantics are TSK-P1-245."
}
EOF

echo "Verification 243 successful"
