#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/git_diff_semantics.json"
cd "$ROOT_DIR"

echo "==> Diff semantics parity verifier"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

# Parity-critical scripts: these must use shared range-only diff helper.
critical=(
  "scripts/audit/enforce_change_rule.sh"
  "scripts/audit/verify_baseline_change_governance.sh"
  "scripts/audit/verify_remediation_trace.sh"
  "scripts/audit/verify_invariants_local.sh"
  "scripts/audit/preflight_structural_staged.sh"
  "scripts/audit/prepare_invariants_curator_inputs.sh"
)

export ROOT_DIR EVIDENCE_FILE
python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
evidence_file = Path(os.environ["EVIDENCE_FILE"])
critical = [
    "scripts/audit/enforce_change_rule.sh",
    "scripts/audit/verify_baseline_change_governance.sh",
    "scripts/audit/verify_remediation_trace.sh",
    "scripts/audit/verify_invariants_local.sh",
    "scripts/audit/preflight_structural_staged.sh",
    "scripts/audit/prepare_invariants_curator_inputs.sh",
]

errors = []
checked = []
base_ref = os.environ.get("BASE_REF", "refs/remotes/origin/main")
head_ref = os.environ.get("HEAD_REF", "HEAD")
merge_base = ""

try:
    import subprocess
    p = subprocess.run(
        ["git", "merge-base", base_ref, head_ref],
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if p.returncode == 0:
        merge_base = p.stdout.strip()
except Exception:
    merge_base = ""

for rel in critical:
    path = root / rel
    if not path.exists():
        errors.append(f"missing_file:{rel}")
        continue
    txt = path.read_text(encoding="utf-8", errors="ignore")
    checked.append(rel)

    if "scripts/lib/git_diff.sh" not in txt and "scripts/audit/lib/git_diff.sh" not in txt:
        errors.append(f"missing_git_diff_helper_source:{rel}")

    if re.search(r"\bgit\s+merge-base\b", txt):
        errors.append(f"forbidden_direct_merge_base:{rel}")

    # For parity-critical scripts, raw git diff usage should be replaced by shared helper APIs.
    if re.search(r"\bgit\s+diff\b", txt):
        errors.append(f"forbidden_direct_git_diff:{rel}")

out = {
    "check_id": "GIT-DIFF-SEMANTICS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "diff_mode": "range",
    "base_ref": base_ref,
    "head_ref": head_ref,
    "merge_base": merge_base,
    "checked_scripts": checked,
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ Diff semantics parity verification failed")
    for e in errors:
        print(f" - {e}")
    raise SystemExit(1)
print(f"Diff semantics parity verification passed. Evidence: {evidence_file}")
PY
