#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EVIDENCE_DIR="$ROOT/evidence/phase0"
OUT="$EVIDENCE_DIR/repo_structure.json"

cd "$ROOT"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

required_dirs=(
  "src"
  "tests"
  "tools"
  "services"
  "packages"
  "schema"
  "schema/migrations"
  "schema/seeds"
  "scripts"
  "scripts/audit"
  "scripts/db"
  "scripts/security"
  "docs"
  "docs/agents"
  "docs/architecture"
  "docs/invariants"
  "docs/tasks"
  "docs/operations"
  "docs/decisions"
  "docs/overview"
  "infra"
  "infra/docker"
  "tasks"
  ".github"
  ".github/workflows"
  ".codex/agents"
  ".codex/rules"
  ".cursor/agents"
  ".cursor/rules"
)

required_files=(
  "docs/agents/ARCHITECT_PHASE0_PROMPT.md"
  "docs/PHASE0/phase-0-foundation.md"
  "docs/invariants/INVARIANTS_MANIFEST.yml"
  "docs/invariants/INVARIANTS_IMPLEMENTED.md"
  "docs/invariants/INVARIANTS_ROADMAP.md"
  "docs/invariants/INVARIANTS_QUICK.md"
  ".github/workflows/invariants.yml"
)

required_refs=(
  "docs/PHASE0/phase-0-foundation.md::scripts/audit/verify_repo_structure.sh"
  "docs/PHASE0/phase-0-foundation.md::./evidence/phase0/repo_structure.json"
  "docs/agents/ARCHITECT_PHASE0_PROMPT.md::verify_repo_structure.sh"
)

missing_dirs=()
for d in "${required_dirs[@]}"; do
  if [[ ! -d "$ROOT/$d" ]]; then
    missing_dirs+=("$d")
  fi
done

missing_files=()
for f in "${required_files[@]}"; do
  if [[ ! -f "$ROOT/$f" ]]; then
    missing_files+=("$f")
  fi
done

missing_refs=()
for ref in "${required_refs[@]}"; do
  file="${ref%%::*}"
  pattern="${ref#*::}"
  if [[ ! -f "$ROOT/$file" ]]; then
    missing_refs+=("$ref (file missing)")
    continue
  fi
  if command -v rg >/dev/null 2>&1; then
    if ! rg -q --fixed-strings "$pattern" "$ROOT/$file"; then
      missing_refs+=("$ref")
    fi
  else
    if ! grep -F -q "$pattern" "$ROOT/$file"; then
      missing_refs+=("$ref")
    fi
  fi
done

status_ok=1
if [[ "${#missing_dirs[@]}" -gt 0 || "${#missing_files[@]}" -gt 0 || "${#missing_refs[@]}" -gt 0 ]]; then
  status_ok=0
fi

req_dirs_file="$EVIDENCE_DIR/required_dirs.txt"
req_files_file="$EVIDENCE_DIR/required_files.txt"
req_refs_file="$EVIDENCE_DIR/required_refs.txt"
missing_dirs_file="$EVIDENCE_DIR/missing_dirs.txt"
missing_files_file="$EVIDENCE_DIR/missing_files.txt"
missing_refs_file="$EVIDENCE_DIR/missing_refs.txt"

printf '%s\n' "${required_dirs[@]}" > "$req_dirs_file"
printf '%s\n' "${required_files[@]}" > "$req_files_file"
printf '%s\n' "${required_refs[@]}" > "$req_refs_file"
printf '%s\n' "${missing_dirs[@]}" > "$missing_dirs_file"
printf '%s\n' "${missing_files[@]}" > "$missing_files_file"
printf '%s\n' "${missing_refs[@]}" > "$missing_refs_file"

REQ_DIRS_FILE="$req_dirs_file" \
REQ_FILES_FILE="$req_files_file" \
REQ_REFS_FILE="$req_refs_file" \
MISSING_DIRS_FILE="$missing_dirs_file" \
MISSING_FILES_FILE="$missing_files_file" \
MISSING_REFS_FILE="$missing_refs_file" \
OUT="$OUT" \
OK="$status_ok" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def read_list(path: str) -> list[str]:
    p = Path(path)
    if not p.exists():
        return []
    return [line.strip() for line in p.read_text(encoding="utf-8", errors="ignore").splitlines() if line.strip()]

out_path = os.environ["OUT"]

data = {
    "check_id": "REPO-STRUCTURE",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if os.environ.get("OK") == "1" else "FAIL",
    "ok": os.environ.get("OK") == "1",
    "required_dirs": read_list(os.environ["REQ_DIRS_FILE"]),
    "required_files": read_list(os.environ["REQ_FILES_FILE"]),
    "required_refs": read_list(os.environ["REQ_REFS_FILE"]),
    "missing_dirs": read_list(os.environ["MISSING_DIRS_FILE"]),
    "missing_files": read_list(os.environ["MISSING_FILES_FILE"]),
    "missing_refs": read_list(os.environ["MISSING_REFS_FILE"]),
}

Path(out_path).parent.mkdir(parents=True, exist_ok=True)
Path(out_path).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if [[ "$status_ok" -ne 1 ]]; then
  echo "Repo structure verification failed. See $OUT for details."
  exit 1
fi

echo "Repo structure verification OK. Evidence: $OUT"
