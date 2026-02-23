#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

VERIFY_SCRIPT="$ROOT_DIR/scripts/audit/verify_phase0_contract_evidence_status.sh"
if [[ ! -x "$VERIFY_SCRIPT" ]]; then
  echo "ERROR: verify script not executable: $VERIFY_SCRIPT" >&2
  exit 1
fi

# CI parity mode:
# - In GitHub Actions phase0_evidence_status, artifacts are downloaded into
#   sibling folders like phase0-evidence*, phase0-evidence-db.
# - We merge those phase0 payloads into evidence/phase0 deterministically, then
#   run the verifier against that merged root.
shopt -s nullglob
artifact_dirs=(phase0-evidence* phase0-evidence-db)
shopt -u nullglob

has_ci_artifacts=0
for d in "${artifact_dirs[@]}"; do
  if [[ -d "$d/phase0" ]]; then
    has_ci_artifacts=1
    break
  fi
done

if [[ "$has_ci_artifacts" -eq 0 ]]; then
  # Local/dev mode: evidence already produced under evidence/phase0.
  CI_ONLY=1 EVIDENCE_ROOT="evidence/phase0" "$VERIFY_SCRIPT"
  exit 0
fi

MERGED_ROOT="evidence/phase0"
mkdir -p "$MERGED_ROOT"
# CI merge job should validate downloaded artifacts only, not stale checkout files.
find "$MERGED_ROOT" -maxdepth 1 -type f -name '*.json' -delete

declare -A seen

merge_file() {
  local src="$1"
  local base
  base="$(basename "$src")"
  local dst="$MERGED_ROOT/$base"

  if [[ -e "$dst" ]]; then
    if cmp -s "$src" "$dst"; then
      return 0
    fi

    # Deterministic duplicate handling: allow content differences only when
    # semantic contract fields are identical.
    sem_ok="$(
      python3 - <<'PY' "$dst" "$src" 2>/dev/null || true
import json,sys
a,b=sys.argv[1],sys.argv[2]
try:
    da=json.load(open(a,encoding='utf-8'))
    db=json.load(open(b,encoding='utf-8'))
except Exception:
    print("0")
    raise SystemExit(0)
ka=(da.get("check_id"), da.get("status"))
kb=(db.get("check_id"), db.get("status"))
print("1" if ka==kb and ka[1] in ("PASS","FAIL","SKIPPED") else "0")
PY
    )"
    if [[ "$sem_ok" == "1" ]]; then
      return 0
    fi

    echo "ERROR: conflicting artifact evidence for $base" >&2
    echo " - existing: $dst" >&2
    echo " - incoming: $src" >&2
    exit 1
    return 0
  fi

  cp "$src" "$dst"
  seen["$base"]=1
}

for d in "${artifact_dirs[@]}"; do
  [[ -d "$d/phase0" ]] || continue
  while IFS= read -r -d '' f; do
    merge_file "$f"
  done < <(find "$d/phase0" -type f -name '*.json' -print0)
done

CI_ONLY=1 EVIDENCE_ROOT="$MERGED_ROOT" "$VERIFY_SCRIPT"
