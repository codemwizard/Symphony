#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TASK_ID="${1:-}"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: scripts/agent/run_task.sh <TASK_ID>" >&2
  exit 2
fi
export TASK_ID

META="tasks/$TASK_ID/meta.yml"
if [[ ! -f "$META" ]]; then
  echo "ERROR: Missing task meta: $META" >&2
  exit 1
fi

hr() { echo "------------------------------------------------------------"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# Stable run identity for evidence freshness checks.
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
RUN_TS_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${GIT_SHA}-${RUN_TS_UTC}"

export SYMPHONY_RUN_ID="$RUN_ID"
export SYMPHONY_RUN_TS_UTC="$RUN_TS_UTC"
export SYMPHONY_GIT_SHA="$GIT_SHA"

OUTDIR="tmp/task_runs/$TASK_ID/$RUN_ID"
mkdir -p "$OUTDIR"
RESULTS_JSONL="$OUTDIR/results.jsonl"

echo "==> Deterministic Task Runner"
echo "TASK_ID: $TASK_ID"
echo "META:    $META"
echo "RUN_ID:  $RUN_ID"
echo "OUTDIR:  $OUTDIR"
hr

# Parse YAML meta into a bash-readable env file.
TMP_ENV="$(mktemp)"
trap 'rm -f "$TMP_ENV"' EXIT

META_PATH="$META" python3 - <<'PY' >"$TMP_ENV"
import os
import shlex
from pathlib import Path
import yaml  # type: ignore

root = Path(os.getcwd())
meta_path = root / os.environ["META_PATH"]

meta = yaml.safe_load(meta_path.read_text(encoding="utf-8"))
if not isinstance(meta, dict):
    raise SystemExit("ERROR: meta.yml must be a mapping/object")

required = [
    "schema_version",
    "task_id",
    "title",
    "owner_role",
    "phase",
    "verification",
    "evidence",
    "implementation_plan",
    "implementation_log",
]
missing = [k for k in required if k not in meta or meta[k] in (None, "", [])]
if missing:
    raise SystemExit(f"ERROR: meta.yml missing required fields: {missing}")

schema_version = str(meta.get("schema_version")).strip()
supported = {"1"}
if schema_version not in supported:
    raise SystemExit(f"ERROR: Unsupported schema_version '{schema_version}'. Supported: {sorted(supported)}")

task_id = str(meta["task_id"]).strip()
phase = str(meta["phase"]).strip()
plan = str(meta["implementation_plan"]).strip()
log = str(meta["implementation_log"]).strip()

verification = meta["verification"]
evidence = meta["evidence"]
must_read = meta.get("must_read", [])

# Support:
# verification:
#   - "command"
#   - { name: "...", cmd: "...", retries: 0 }
def normalize_checks(x, field):
    if isinstance(x, str):
        x = [x]
    if not isinstance(x, list) or not x:
        raise SystemExit(f"ERROR: '{field}' must be a non-empty string or list")
    out = []
    for idx, item in enumerate(x):
        if isinstance(item, str):
            cmd = item.strip()
            if not cmd:
                raise SystemExit(f"ERROR: '{field}' contains empty command at index {idx}")
            out.append({"name": f"{field}_{idx+1}", "cmd": cmd, "retries": 0})
        elif isinstance(item, dict):
            cmd = str(item.get("cmd", "")).strip()
            name = str(item.get("name", f"{field}_{idx+1}")).strip()
            retries = item.get("retries", 0)
            if not cmd:
                raise SystemExit(f"ERROR: '{field}' dict item missing 'cmd' at index {idx}")
            if not name:
                raise SystemExit(f"ERROR: '{field}' dict item has empty 'name' at index {idx}")
            try:
                retries_i = int(retries)
            except Exception:
                raise SystemExit(f"ERROR: '{field}' retries must be int at index {idx}")
            if retries_i < 0 or retries_i > 3:
                raise SystemExit(f"ERROR: '{field}' retries out of range (0-3) at index {idx}")
            out.append({"name": name, "cmd": cmd, "retries": retries_i})
        else:
            raise SystemExit(f"ERROR: '{field}' items must be string or dict at index {idx}")
    return out

def normalize_list(x, field):
    if isinstance(x, str):
        x = [x]
    if not x:
        return []
    if not isinstance(x, list) or not all(isinstance(i, str) and i.strip() for i in x):
        raise SystemExit(f"ERROR: '{field}' must be a string or list of strings")
    return [i.strip() for i in x]

verification_checks = normalize_checks(verification, "verification")
evidence_list = normalize_list(evidence, "evidence")
must_read_list = normalize_list(must_read, "must_read")

def q(s: str) -> str:
    return shlex.quote(s)

print(f"SCHEMA_VERSION={q(schema_version)}")
print(f"TASK_ID={q(task_id)}")
print(f"TASK_PHASE={q(phase)}")
print(f"IMPLEMENTATION_PLAN={q(plan)}")
print(f"IMPLEMENTATION_LOG={q(log)}")

print(f"VERIFICATION_COUNT={len(verification_checks)}")
for i, chk in enumerate(verification_checks):
    print(f"VER_NAME_{i}={q(chk['name'])}")
    print(f"VER_CMD_{i}={q(chk['cmd'])}")
    print(f"VER_RETRIES_{i}={chk['retries']}")

print(f"EVIDENCE_COUNT={len(evidence_list)}")
for i, ev in enumerate(evidence_list):
    print(f"EVIDENCE_{i}={q(ev)}")

print(f"MUST_READ_COUNT={len(must_read_list)}")
for i, doc in enumerate(must_read_list):
    print(f"MUST_READ_{i}={q(doc)}")
PY

# shellcheck disable=SC1090
source "$TMP_ENV"

echo "Loaded meta for: $TASK_ID (phase=$TASK_PHASE, schema_version=$SCHEMA_VERSION)"
hr

[[ -f "$IMPLEMENTATION_PLAN" ]] || die "Missing implementation plan: $IMPLEMENTATION_PLAN"
[[ -f "$IMPLEMENTATION_LOG"  ]] || die "Missing implementation log:  $IMPLEMENTATION_LOG"

hr
echo "==> Pack readiness gate"
if ! bash scripts/audit/verify_task_pack_readiness.sh --task "$TASK_ID"; then
  die "Task $TASK_ID is schema-valid but not execution-ready. Fix the task pack before running."
fi
echo "Pack readiness: PASS"

echo "Required artifacts present:"
echo "  - $IMPLEMENTATION_PLAN"
echo "  - $IMPLEMENTATION_LOG"

if [[ "${MUST_READ_COUNT:-0}" -gt 0 ]]; then
  hr
  echo "Must-read docs (agent SHOULD read before changes):"
  for ((i=0; i<MUST_READ_COUNT; i++)); do
    eval "doc=\${MUST_READ_${i}}"
    echo "  - $doc"
  done
fi

hr
echo "==> Running deterministic bootstrap gates"
bash scripts/agent/bootstrap.sh

hr
echo "==> Running verification checks (structured JSONL results)"
: >"$RESULTS_JSONL"

emit_jsonl() { echo "$1" >>"$RESULTS_JSONL"; }

status="PASS"
failed_index="-1"
failed_name=""
failed_cmd=""
failed_ec="0"

for ((i=0; i<VERIFICATION_COUNT; i++)); do
  eval "name=\${VER_NAME_${i}}"
  eval "cmd=\${VER_CMD_${i}}"
  eval "retries=\${VER_RETRIES_${i}}"

  echo
  echo "[$((i+1))/$VERIFICATION_COUNT] $name"
  echo "CMD: $cmd"
  echo "RETRIES: $retries"

  check_dir="$OUTDIR/check_$((i+1))"
  mkdir -p "$check_dir"

  attempt=0
  ec=0

  while true; do
    stdout="$check_dir/attempt_${attempt}.stdout"
    stderr="$check_dir/attempt_${attempt}.stderr"

    set +e
    bash -lc "$cmd" >"$stdout" 2>"$stderr"
    ec=$?
    set -e

    rec="$(python3 - <<PY
import json, os
print(json.dumps({
  "task_id": os.environ.get("TASK_ID", ""),
  "run_id": os.environ.get("SYMPHONY_RUN_ID", ""),
  "check_index": ${i+1},
  "check_name": ${name@Q},
  "attempt": ${attempt},
  "command": ${cmd@Q},
  "exit_code": ${ec},
  "stdout_path": ${stdout@Q},
  "stderr_path": ${stderr@Q},
}))
PY
)"
    emit_jsonl "$rec"

    if [[ "$ec" -eq 0 ]]; then
      echo "OK: $name (attempt $attempt)"
      break
    fi

    if [[ "$attempt" -ge "$retries" ]]; then
      echo "FAIL: $name (exit=$ec) after $((attempt+1)) attempt(s)" >&2
      status="FAIL"
      failed_index="$((i+1))"
      failed_name="$name"
      failed_cmd="$cmd"
      failed_ec="$ec"
      break
    fi

    echo "Retrying: $name (attempt $((attempt+1)) of $((retries+1)))" >&2
    attempt=$((attempt+1))
  done

  if [[ "$status" == "FAIL" ]]; then
    break
  fi
done

if [[ "$status" == "FAIL" ]]; then
  hr
  echo "==> Verification failed summary" >&2
  echo "FAILED CHECK: #$failed_index $failed_name" >&2
  echo "EXIT CODE:   $failed_ec" >&2
  echo "COMMAND:     $failed_cmd" >&2
  echo "RESULTS:     $RESULTS_JSONL" >&2
  echo "OUTPUT DIR:  $OUTDIR" >&2
  hr >&2
  echo "Recent check outputs:" >&2
  echo "  stdout/stderr: $OUTDIR/check_${failed_index}/" >&2
  exit 1
fi

hr
echo "==> Verifying evidence outputs exist AND are fresh (run_id matches $RUN_ID)"

check_json_run_id() {
  local file="$1"
  python3 - <<PY "$file"
import json, sys
p = sys.argv[1]
try:
  d = json.load(open(p, "r", encoding="utf-8"))
except Exception as e:
  print(f"ERROR: evidence not valid JSON: {p}: {e}", file=sys.stderr)
  raise SystemExit(2)

run_id = d.get("run_id")
if not run_id:
  print(f"ERROR: evidence missing 'run_id': {p}", file=sys.stderr)
  raise SystemExit(3)

expected = "${RUN_ID}"
if run_id != expected:
  print(f"ERROR: stale evidence run_id mismatch: {p}: {run_id} != {expected}", file=sys.stderr)
  raise SystemExit(4)
PY
}

check_receipt() {
  local ev="$1"
  local receipt="$2"
  python3 - <<PY "$ev" "$receipt"
import json, sys, hashlib
ev = sys.argv[1]
rcpt = sys.argv[2]
try:
  d = json.load(open(rcpt, "r", encoding="utf-8"))
except Exception as e:
  print(f"ERROR: receipt not valid JSON: {rcpt}: {e}", file=sys.stderr)
  raise SystemExit(2)

run_id = d.get("run_id")
if not run_id:
  print(f"ERROR: receipt missing 'run_id': {rcpt}", file=sys.stderr)
  raise SystemExit(3)
expected = "${RUN_ID}"
if run_id != expected:
  print(f"ERROR: stale receipt run_id mismatch: {rcpt}: {run_id} != {expected}", file=sys.stderr)
  raise SystemExit(4)

sha_expected = d.get("sha256")
if not sha_expected:
  print(f"ERROR: receipt missing 'sha256': {rcpt}", file=sys.stderr)
  raise SystemExit(5)

h = hashlib.sha256()
with open(ev, "rb") as f:
  for chunk in iter(lambda: f.read(1024*1024), b""):
    h.update(chunk)
sha = h.hexdigest()
if sha != sha_expected:
  print(f"ERROR: receipt sha256 mismatch: {ev}: {sha} != {sha_expected}", file=sys.stderr)
  raise SystemExit(6)
PY
}

missing=0
for ((i=0; i<EVIDENCE_COUNT; i++)); do
  eval "ev=\${EVIDENCE_${i}}"
  ev_path="${ev#./}"

  if [[ ! -f "$ev_path" ]]; then
    echo "MISSING: $ev_path" >&2
    missing=1
    continue
  fi

  if [[ "$ev_path" == *.json ]]; then
    check_json_run_id "$ev_path"
    echo "OK (fresh JSON): $ev_path"
  else
    receipt="${ev_path}.receipt.json"
    if [[ ! -f "$receipt" ]]; then
      echo "ERROR: Non-JSON evidence requires receipt: $receipt" >&2
      missing=1
      continue
    fi
    check_receipt "$ev_path" "$receipt"
    echo "OK (fresh receipt): $ev_path + $receipt"
  fi
done

[[ "$missing" -eq 0 ]] || die "Evidence missing or stale. Do not mark task complete."

if [[ "$TASK_PHASE" == "0" ]]; then
  hr
  echo "==> Phase0 contract evidence gate"
  scripts/ci/check_evidence_required.sh evidence/phase0
fi

hr
echo "==> Task runner complete: $TASK_ID"
echo "All gates passed; evidence fresh; results: $RESULTS_JSONL"
