#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/git_diff_semantics.json"
cd "$ROOT_DIR"

echo "==> Diff semantics parity verifier"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
source "$ROOT_DIR/scripts/audit/lib/parity_critical_scripts.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

mapfile -t critical < <(parity_critical_scripts)

export ROOT_DIR EVIDENCE_FILE
CRITICAL_JOINED="$(printf '%s\n' "${critical[@]}")"
export CRITICAL_JOINED
python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
evidence_file = Path(os.environ["EVIDENCE_FILE"])
critical = [line.strip() for line in os.environ.get("CRITICAL_JOINED", "").splitlines() if line.strip()]

errors = []
checked = []
base_ref = os.environ.get("BASE_REF", "refs/remotes/origin/main")
head_ref = os.environ.get("HEAD_REF", "HEAD")
merge_base = ""

forbidden_patterns = [
    (r"\bgit\s+diff\s+--cached\b", "forbidden_staged_diff"),
    (r"\bgit\s+status\b", "forbidden_git_status"),
    (r"\bgit\s+ls-files\s+-m\b", "forbidden_git_ls_files_modified"),
    (r"\bgit_changed_files_staged\b", "forbidden_staged_helper_call"),
    (r"\bgit_write_unified_diff_staged\b", "forbidden_staged_helper_call"),
    (r"\bgit_write_unified_diff_staged_path\b", "forbidden_staged_helper_call"),
    (r"\bgit_write_unified_diff_worktree\b", "forbidden_worktree_helper_call"),
    (r"scripts/(audit/lib|lib)/git_diff_dev\.sh", "forbidden_dev_helper_source"),
]

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

    if "scripts/lib/git_diff_range_only.sh" not in txt and "scripts/audit/lib/git_diff_range_only.sh" not in txt:
        errors.append(f"missing_range_only_helper_source:{rel}")

    if re.search(r"\bgit\s+merge-base\b", txt):
        errors.append(f"forbidden_direct_merge_base:{rel}")

    for pattern, tag in forbidden_patterns:
        if re.search(pattern, txt):
            errors.append(f"{tag}:{rel}")

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
    "critical_scripts": critical,
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
