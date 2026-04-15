#!/usr/bin/env bash
set -euo pipefail

if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_248_git_sha_clamp.json"
WORKTREE_DIR="$(mktemp -d /tmp/tsk_p1_248_worktree.XXXXXX)"
SIGN_OUT="evidence/phase1/tsk_p1_248_signed_probe.json"

cleanup() {
  git -C "$ROOT" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  rm -rf "$WORKTREE_DIR"
}
trap cleanup EXIT

git -C "$ROOT" worktree add --detach "$WORKTREE_DIR" HEAD >/dev/null
git -C "$WORKTREE_DIR" config user.name "TSK-P1-248 verifier"
git -C "$WORKTREE_DIR" config user.email "tsk-p1-248@example.invalid"

run_probe() {
  local stage="$1"
  (
    cd "$WORKTREE_DIR"
    export SYMPHONY_EVIDENCE_DETERMINISTIC=1
    export PRE_CI_RUN_ID="rem-0000000000000000"
    export PRE_CI_CONTEXT=1
    export SYMPHONY_ENV=development
    rm -f "$SIGN_OUT"
    source scripts/lib/evidence.sh
    helper_sha="$(git_sha)"
    helper_ts="$(evidence_now_utc)"
    python3 scripts/audit/sign_evidence.py \
      --write \
      --out "$SIGN_OUT" \
      --task "TSK-P1-248-PROBE" \
      --status "PASS" \
      --source-file scripts/lib/evidence.sh \
      --command-output "$stage" >/dev/null
    python3 - <<'PY' "$stage" "$helper_sha" "$helper_ts" "$SIGN_OUT"
import json
import sys

stage, helper_sha, helper_ts, sign_out = sys.argv[1:5]
signed = json.load(open(sign_out, encoding="utf-8"))
print(json.dumps({
    "stage": stage,
    "helper_git_sha": helper_sha,
    "helper_timestamp_utc": helper_ts,
    "signed_git_sha": signed["git_sha"],
    "signed_timestamp_utc": signed["timestamp_utc"],
    "signed_run_id": signed["pre_ci_run_id"],
    "signed_signature": signed["_signature"],
}, sort_keys=True))
PY
  )
}

before_json="$(run_probe before_commit)"
git -C "$WORKTREE_DIR" commit --allow-empty -m "TSK-P1-248 deterministic proof commit" >/dev/null
after_json="$(run_probe after_commit)"

export BEFORE_JSON="$before_json"
export AFTER_JSON="$after_json"
export EVIDENCE
export ROOT

python3 - <<'PY'
import json
import os
from pathlib import Path

before = json.loads(os.environ["BEFORE_JSON"])
after = json.loads(os.environ["AFTER_JSON"])
root = Path(os.environ["ROOT"])

checks = []
errors = []

expected_sha = "0000000000000000000000000000000000000000"
expected_ts = "1970-01-01T00:00:00Z"
expected_run_id = "rem-0000000000000000"

for label, payload in (("before_commit", before), ("after_commit", after)):
    checks.append({
        "check": f"{label}_helper_git_sha_clamped",
        "pass": payload["helper_git_sha"] == expected_sha,
        "observed": payload["helper_git_sha"],
    })
    checks.append({
        "check": f"{label}_helper_timestamp_clamped",
        "pass": payload["helper_timestamp_utc"] == expected_ts,
        "observed": payload["helper_timestamp_utc"],
    })
    checks.append({
        "check": f"{label}_signed_git_sha_clamped",
        "pass": payload["signed_git_sha"] == expected_sha,
        "observed": payload["signed_git_sha"],
    })
    checks.append({
        "check": f"{label}_signed_timestamp_clamped",
        "pass": payload["signed_timestamp_utc"] == expected_ts,
        "observed": payload["signed_timestamp_utc"],
    })
    checks.append({
        "check": f"{label}_run_id_clamped",
        "pass": payload["signed_run_id"] == expected_run_id,
        "observed": payload["signed_run_id"],
    })

stable_fields = ("helper_git_sha", "helper_timestamp_utc", "signed_git_sha", "signed_timestamp_utc", "signed_run_id")
for field in stable_fields:
    if before[field] != after[field]:
        errors.append(f"field_changed_across_commit:{field}")

if not (root / "scripts/lib/evidence.sh").exists():
    errors.append("missing_source:scripts/lib/evidence.sh")
if not (root / "scripts/audit/sign_evidence.py").exists():
    errors.append("missing_source:scripts/audit/sign_evidence.py")

status = "PASS" if not errors and all(item["pass"] for item in checks) else "FAIL"

out = {
    "check_id": "TSK-P1-248",
    "task_id": "TSK-P1-248",
    "timestamp_utc": expected_ts,
    "git_sha": expected_sha,
    "status": status,
    "checks": checks,
    "before_commit": before,
    "after_commit": after,
    "observed_paths": [
        "scripts/lib/evidence.sh",
        "scripts/audit/sign_evidence.py",
        "scripts/dev/pre_ci.sh",
    ],
    "observed_hashes": {
        "scripts/lib/evidence.sh": __import__("hashlib").sha256((root / "scripts/lib/evidence.sh").read_bytes()).hexdigest(),
        "scripts/audit/sign_evidence.py": __import__("hashlib").sha256((root / "scripts/audit/sign_evidence.py").read_bytes()).hexdigest(),
        "scripts/dev/pre_ci.sh": __import__("hashlib").sha256((root / "scripts/dev/pre_ci.sh").read_bytes()).hexdigest(),
    },
    "command_outputs": [
        "git worktree add --detach <tmp> HEAD",
        "python3 scripts/audit/sign_evidence.py --write ...",
        "git commit --allow-empty -m \"TSK-P1-248 deterministic proof commit\"",
        "python3 scripts/audit/sign_evidence.py --write ...",
    ],
    "execution_trace": [
        "create detached worktree",
        "run deterministic bash helper probe",
        "run deterministic signer probe",
        "create empty commit to change HEAD",
        "repeat probes and compare stable fields",
    ],
    "errors": errors,
}

Path(os.environ["EVIDENCE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    raise SystemExit(1)
PY

echo "PASS: TSK-P1-248 verified."
