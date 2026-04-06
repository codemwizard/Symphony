#!/usr/bin/env bash
set -euo pipefail

if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_249_runtime_value_stabilization.json"
TMP_DIR="$(mktemp -d /tmp/tsk_p1_249.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

export SYMPHONY_EVIDENCE_DETERMINISTIC=1
export PRE_CI_CONTEXT=1
export PRE_CI_RUN_ID="rem-0000000000000000"
export SYMPHONY_ENV=development

mkdir -p "$TMP_DIR/scripts/lib" "$TMP_DIR/evidence/phase1"
cp "$ROOT/scripts/lib/evidence.sh" "$TMP_DIR/scripts/lib/evidence.sh"
mkdir -p "$TMP_DIR/src"
cat >"$TMP_DIR/src/ok.ts" <<'EOF'
const payload = { status: "ok" };
EOF

PII_EVIDENCE="$ROOT/evidence/phase0/pii_leakage_payloads.json"
DOTNET_EVIDENCE="$TMP_DIR/evidence/phase1/dotnet_lint_quality.json"

PII_LINT_ROOTS="$TMP_DIR/src" PII_LINT_EXCLUDE_GLOBS="" bash "$ROOT/scripts/audit/lint_pii_leakage_payloads.sh" >/dev/null
DOTNET_LINT_ROOT="$TMP_DIR" bash "$ROOT/scripts/security/lint_dotnet_quality.sh" >/dev/null

export ROOT
export EVIDENCE
export PII_EVIDENCE
export DOTNET_EVIDENCE

python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT"])
pii_evidence = Path(os.environ["PII_EVIDENCE"])
dotnet_evidence = Path(os.environ["DOTNET_EVIDENCE"])

checks = []
errors = []

def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))

conformance_script = (root / "scripts/audit/verify_agent_conformance.sh").read_text(encoding="utf-8")
checks.append({
    "check": "verify_agent_conformance_checked_at_clamped",
    "pass": 'datetime.fromtimestamp(0, tz=timezone.utc).isoformat()' in conformance_script,
})
checks.append({
    "check": "verify_agent_conformance_git_commit_clamped",
    "pass": '"0000000000000000000000000000000000000000"' in conformance_script,
})

no_tx_script = (root / "scripts/db/tests/test_no_tx_migrations.sh").read_text(encoding="utf-8")
checks.append({
    "check": "no_tx_migrations_does_not_emit_temp_db",
    "pass": '"temp_db"' not in no_tx_script and '"temp_db":' not in no_tx_script,
})

openbao_script = (root / "scripts/security/openbao_smoke_test.sh").read_text(encoding="utf-8")
checks.append({
    "check": "openbao_audit_does_not_emit_audit_log_bytes",
    "pass": '"audit_log_bytes"' not in openbao_script,
})

pii_data = read_json(pii_evidence)
dotnet_data = read_json(dotnet_evidence)

checks.append({
    "check": "pii_lint_roots_do_not_leak_tmp",
    "pass": all("/tmp/" not in item for item in pii_data.get("roots", [])),
    "observed": pii_data.get("roots", []),
})
checks.append({
    "check": "pii_lint_git_sha_clamped",
    "pass": pii_data.get("git_sha") == "0000000000000000000000000000000000000000",
    "observed": pii_data.get("git_sha"),
})
checks.append({
    "check": "dotnet_quality_omits_output_lines",
    "pass": "output_lines" not in dotnet_data,
})
checks.append({
    "check": "dotnet_quality_has_command_summary",
    "pass": "command_summary" in dotnet_data,
    "observed": sorted(dotnet_data.get("command_summary", {}).keys()),
})
checks.append({
    "check": "dotnet_quality_git_sha_clamped",
    "pass": dotnet_data.get("git_sha") == "0000000000000000000000000000000000000000",
    "observed": dotnet_data.get("git_sha"),
})

for item in checks:
    if not item["pass"]:
        errors.append(item["check"])

status = "PASS" if not errors else "FAIL"

out = {
    "check_id": "TSK-P1-249",
    "task_id": "TSK-P1-249",
    "timestamp_utc": "1970-01-01T00:00:00Z",
    "git_sha": "0000000000000000000000000000000000000000",
    "status": status,
    "checks": checks,
    "targeted_files": [
        "scripts/audit/verify_agent_conformance.sh",
        "scripts/audit/lint_pii_leakage_payloads.sh",
        "scripts/security/lint_dotnet_quality.sh",
        "scripts/db/tests/test_no_tx_migrations.sh",
        "scripts/security/openbao_smoke_test.sh",
    ],
    "observed_paths": [
        "scripts/audit/verify_agent_conformance.sh",
        "scripts/audit/lint_pii_leakage_payloads.sh",
        "scripts/security/lint_dotnet_quality.sh",
        "scripts/db/tests/test_no_tx_migrations.sh",
        "scripts/security/openbao_smoke_test.sh",
        str(pii_evidence.relative_to(root)),
        "tmp/dotnet_lint_quality.json",
    ],
    "observed_hashes": {
        "scripts/audit/verify_agent_conformance.sh": __import__("hashlib").sha256((root / "scripts/audit/verify_agent_conformance.sh").read_bytes()).hexdigest(),
        "scripts/audit/lint_pii_leakage_payloads.sh": __import__("hashlib").sha256((root / "scripts/audit/lint_pii_leakage_payloads.sh").read_bytes()).hexdigest(),
        "scripts/security/lint_dotnet_quality.sh": __import__("hashlib").sha256((root / "scripts/security/lint_dotnet_quality.sh").read_bytes()).hexdigest(),
        "scripts/db/tests/test_no_tx_migrations.sh": __import__("hashlib").sha256((root / "scripts/db/tests/test_no_tx_migrations.sh").read_bytes()).hexdigest(),
        "scripts/security/openbao_smoke_test.sh": __import__("hashlib").sha256((root / "scripts/security/openbao_smoke_test.sh").read_bytes()).hexdigest(),
    },
    "command_outputs": [
        "PII deterministic probe written to evidence/phase0/pii_leakage_payloads.json",
        "dotnet deterministic probe written to temporary evidence/phase1/dotnet_lint_quality.json",
    ],
    "execution_trace": [
        "run deterministic PII lint probe with overridden roots",
        "run deterministic dotnet lint probe against empty root",
        "inspect targeted source files for forbidden dynamic fields",
        "inspect generated evidence for sanitized deterministic payloads",
    ],
    "errors": errors,
}

Path(os.environ["EVIDENCE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    raise SystemExit(1)
PY

echo "PASS: TSK-P1-249 verified."
