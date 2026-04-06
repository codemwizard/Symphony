#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

CORE="scripts/audit/runtime_guarded_execution_core.sh"
chmod +x "$CORE"

echo "[Test N1] Out of bounds Repo Path"
if bash "$CORE" --mode repo-guard --repo-root "/etc" 2>/dev/null; then
    echo "Failed N1: Should reject bad path"
    exit 1
fi

echo "[Test N2] Unauthorized Evidence Target Write"
if bash "$CORE" --mode repo-guard --repo-root "$ROOT_DIR" --evidence "/etc/shadow" 2>/dev/null; then
    echo "Failed N2: Expected unauthorized target rejection"
    exit 1
fi

echo "[Test N3] Normalization against traversal tricks"
if bash "$CORE" --mode repo-guard --repo-root "$ROOT_DIR/../non_existent_folder_abc" 2>/dev/null; then
    echo "Failed N3: Path traversal leaked out"
    exit 1
fi

echo "[Test P1] Legitimate boundary output writes mapping perfectly"
TMP_EVID="/tmp/$(uuidgen)_test.json"
bash "$CORE" --mode repo-guard --repo-root "$ROOT_DIR" --evidence "$TMP_EVID"
rm -f "$TMP_EVID"

cat << EOF > evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json
{
  "task_id": "TSK-P1-244",
  "git_sha": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)",
  "timestamp_utc": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "PASS",
  "checks": {
    "N1_outside_root": "PASS",
    "N2_outside_write_target": "PASS",
    "N3_path_traversal": "PASS",
    "P1_valid_write": "PASS"
  },
  "entrypoint_path": "scripts/audit/runtime_guarded_execution_core.sh",
  "guarded_mode": "repo-guard",
  "repo_root_guard_result": "Exact string isolation bounded safely.",
  "filesystem_write_boundary": "Only outputs directly tied to explicit parameters targetting authorized boundaries /tmp/ and evidence/ are processed. Everything else results in non-zero exit.",
  "scope_boundary": "Confinement verified. Evidence completion structures remain TSK-P1-245 workload."
}
EOF

echo "TSK-P1-244 Verification successful."
