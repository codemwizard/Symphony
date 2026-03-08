#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$EVIDENCE_PATH" ]]; then
  echo "Usage: $0 --evidence <path>" >&2
  exit 2
fi

mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

status="PASS"
errors=()
checked=0
invalid=0

while IFS= read -r -d '' meta; do
  checked=$((checked + 1))
  st=$(awk -F': ' '/^status:/ {gsub(/"/,"",$2); print $2; exit}' "$meta" || true)
  st="${st%%#*}"
  st="$(echo "$st" | xargs)"
  if [[ -z "$st" ]]; then
    status="FAIL"
    invalid=$((invalid + 1))
    errors+=("missing_status:${meta#$ROOT_DIR/}")
    continue
  fi
  case "$st" in
    completed|in_progress|planned|ready|blocked|deferred) ;;
    *)
      status="FAIL"
      invalid=$((invalid + 1))
      errors+=("invalid_status:${meta#$ROOT_DIR/}:$st")
      ;;
  esac
done < <(find "$ROOT_DIR/tasks" -mindepth 2 -maxdepth 2 -type f -name meta.yml -print0)

if [[ ! -f "$ROOT_DIR/docs/tasks/phase1_prompts.md" ]]; then
  status="FAIL"
  errors+=("missing_prompt_pack:docs/tasks/phase1_prompts.md")
fi

if ! grep -q '^## TSK-CLEAN-001 — ' "$ROOT_DIR/docs/tasks/phase1_prompts.md"; then
  status="FAIL"
  errors+=("missing_task_section:TSK-CLEAN-001")
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  errors_json="$(printf '%s\n' "${errors[@]}" | python3 -c 'import json,sys; print(json.dumps([line.strip() for line in sys.stdin if line.strip()]))')"
else
  errors_json="[]"
fi

if [[ "$status" == "PASS" ]]; then
  pass_value=True
else
  pass_value=False
fi

python3 - <<PY
import json
from pathlib import Path
p=Path(r"$ROOT_DIR/$EVIDENCE_PATH")
out={
  "check_id":"TSK-CLEAN-001",
  "task_id":"TSK-CLEAN-001",
  "timestamp_utc":"$EVIDENCE_TS",
  "git_sha":"$EVIDENCE_GIT_SHA",
  "schema_fingerprint":"$EVIDENCE_SCHEMA_FP",
  "status":"$status",
  "pass": $pass_value,
  "details":{
    "meta_files_checked": $checked,
    "invalid_meta_files": $invalid,
    "errors": json.loads('''$errors_json''')
  }
}
p.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"TSK-CLEAN-001 verifier status: {out['status']}")
print(f"Evidence: {p}")
raise SystemExit(0 if out["status"]=="PASS" else 1)
PY
