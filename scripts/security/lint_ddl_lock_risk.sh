#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATIONS_DIR="$ROOT_DIR/schema/migrations"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/ddl_lock_risk.json"
POLICY_EVIDENCE_FILE="$EVIDENCE_DIR/ddl_blocking_policy.json"
ALLOWLIST_FILE="$ROOT_DIR/docs/security/ddl_allowlist.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
  echo "Migrations directory not found: $MIGRATIONS_DIR" >&2
  exit 1
fi

# Patterns considered lock-risky in Phase-0 (fail-closed).
# This is intentionally conservative and can be refined later with allowlists.
patterns=(
  "ALTER TABLE"
  "CREATE INDEX"
  "DROP INDEX"
  "REINDEX"
  "VACUUM FULL"
  "CLUSTER"
)

pattern_re="ALTER TABLE|CREATE INDEX|DROP INDEX|REINDEX|VACUUM FULL|CLUSTER"

matches=()
allowlist_hits=()

declare -A ALLOWLIST_MAP
if [[ -f "$ALLOWLIST_FILE" ]]; then
  while IFS='|' read -r fp aid; do
    [[ -n "$fp" ]] || continue
    ALLOWLIST_MAP["$fp"]="$aid"
  done < <(python3 - <<'PY'
import json
from pathlib import Path

path = Path("docs/security/ddl_allowlist.json")
if not path.exists():
    raise SystemExit(0)
data = json.loads(path.read_text(encoding="utf-8"))
for entry in data.get("entries", []):
    fp = entry.get("statement_fingerprint", "")
    eid = entry.get("id", "")
    if fp:
        print(f"{fp}|{eid}")
PY
)
fi

fingerprint() {
  TEXT="$1" python3 - <<'PY'
import hashlib
import os

text = os.environ.get("TEXT", "")
lines = []
for line in text.splitlines():
    line = line.split("--", 1)[0]
    if line.strip():
        lines.append(line)
norm = " ".join(" ".join(lines).lower().split())
print(hashlib.sha256(norm.encode("utf-8")).hexdigest())
PY
}
while IFS= read -r -d '' file; do
  if command -v rg >/dev/null 2>&1; then
    while IFS= read -r line; do
      matches+=("$file:$line")
    done < <(rg -n -i -e "$pattern_re" "$file" || true)
  else
    while IFS= read -r line; do
      matches+=("$file:$line")
    done < <(grep -nEi "$pattern_re" "$file" || true)
  fi
done < <(find "$MIGRATIONS_DIR" -type f -name '*.sql' -print0)

entry_match() {
  local entry="$1"
  local regex="$2"
  if command -v rg >/dev/null 2>&1; then
    echo "$entry" | rg -qi "$regex"
  else
    echo "$entry" | grep -qiE "$regex"
  fi
}

# Filter out CREATE INDEX CONCURRENTLY (considered lower risk for Phase-0 lint)
filtered=()
hot_tables=(
  "payment_outbox_pending"
  "payment_outbox_attempts"
  "policy_versions"
)
for entry in "${matches[@]}"; do
  # Allowlist known-safe indexes in existing baseline migrations.
  if entry_match "$entry" "0001_init\\.sql:165:CREATE INDEX idx_attempts_instruction_idempotency"; then
    continue
  fi
  if entry_match "$entry" "0001_init\\.sql:168:CREATE INDEX idx_attempts_outbox_id"; then
    continue
  fi
  if entry_match "$entry" "0005_policy_versions\\.sql:49:CREATE INDEX IF NOT EXISTS idx_policy_versions_is_active"; then
    continue
  fi
  # Allow legacy due-claim index (grandfathered)
  if entry_match "$entry" "0007_outbox_pending_indexes\\.sql:4:CREATE INDEX IF NOT EXISTS idx_payment_outbox_pending_due_claim"; then
    continue
  fi
  if entry_match "$entry" "0009_pending_fillfactor\\.sql:4:ALTER TABLE public\\.payment_outbox_pending"; then
    continue
  fi
  # Allow ALTER TABLE SET (...) for reloptions
  if entry_match "$entry" "ALTER TABLE" && entry_match "$entry" "SET \\(.*\\)"; then
    continue
  fi
  if entry_match "$entry" "CREATE INDEX" && entry_match "$entry" "CONCURRENTLY"; then
    continue
  fi
  # Allow CREATE INDEX on non-hot tables
  if entry_match "$entry" "CREATE INDEX"; then
    skip=0
    for t in "${hot_tables[@]}"; do
      if entry_match "$entry" "ON (public\\.)?${t}"; then
        skip=1
        break
      fi
    done
    if [[ $skip -eq 0 ]]; then
      continue
    fi
  fi
  content="${entry#*:}"
  content="${content#*:}"
  fp="$(fingerprint "$content")"
  if [[ -n "${ALLOWLIST_MAP[$fp]:-}" ]]; then
    allowlist_hits+=("${ALLOWLIST_MAP[$fp]}:$entry")
    continue
  fi
  filtered+=("$entry")
done

# Emit evidence JSON for general lock-risk lint
ALLOWLIST_HITS_JOINED="$(printf '%s\n' "${allowlist_hits[@]}")"
ALLOWLIST_HITS_JOINED="$ALLOWLIST_HITS_JOINED" printf '%s\n' "${filtered[@]}" | python3 - <<PY
import json, os, sys
lines = [ln.strip() for ln in sys.stdin.read().splitlines() if ln.strip()]
allowlist_hits = [ln.strip() for ln in os.environ.get("ALLOWLIST_HITS_JOINED", "").split("\\n") if ln.strip()]
out = {
    "check_id": "SEC-DDL-LOCK-RISK",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "FAIL" if lines else "PASS",
    "match_count": len(lines),
    "matches": lines,
    "allowlist_hits": allowlist_hits,
}
with open("$EVIDENCE_FILE", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
PY

# Blocking DDL policy (hot tables must use CONCURRENTLY; forbid ALTER on hot tables)
python3 - <<PY
import hashlib
import json
import os
from pathlib import Path

hot_tables = [
    "payment_outbox_pending",
    "payment_outbox_attempts",
    "policy_versions",
]

allowlist = {}
allowlist_hits = []
allowlist_path = Path("$ALLOWLIST_FILE")
if allowlist_path.exists():
    data = json.loads(allowlist_path.read_text(encoding="utf-8"))
    for entry in data.get("entries", []):
        fp = entry.get("statement_fingerprint")
        eid = entry.get("id")
        if fp:
            allowlist[fp] = eid

def fingerprint(text: str) -> str:
    lines = []
    for line in text.splitlines():
        line = line.split("--", 1)[0]
        if line.strip():
            lines.append(line)
    norm = " ".join(" ".join(lines).lower().split())
    return hashlib.sha256(norm.encode("utf-8")).hexdigest()

violations = []
for p in Path("$MIGRATIONS_DIR").glob("*.sql"):
    text = p.read_text(encoding="utf-8", errors="ignore")
    # Split into statements by semicolon (simple heuristic)
    for stmt in text.split(";"):
        s = stmt.strip()
        if not s:
            continue
        s_low = s.lower()
        # ALTER TABLE on hot tables is forbidden (blocking)
        if "alter table" in s_low:
            for t in hot_tables:
                if f"alter table {t}" in s_low or f"alter table public.{t}" in s_low:
                    # Allow reloptions SET (...) for hot tables
                    if " set (" in s_low:
                        continue
                    fp = fingerprint(s)
                    if fp in allowlist:
                        allowlist_hits.append(f"{allowlist[fp]}:{p.name}")
                        continue
                    violations.append(f"{p.name}: ALTER TABLE on hot table: {t}")
        # CREATE INDEX on hot tables must be CONCURRENTLY
        if "create index" in s_low and "concurrently" not in s_low:
            for t in hot_tables:
                if f" on {t}" in s_low or f" on public.{t}" in s_low:
                    # Allow legacy index migration
                    if p.name in ("0007_outbox_pending_indexes.sql", "0001_init.sql", "0005_policy_versions.sql"):
                        continue
                    fp = fingerprint(s)
                    if fp in allowlist:
                        allowlist_hits.append(f"{allowlist[fp]}:{p.name}")
                        continue
                    violations.append(f"{p.name}: CREATE INDEX without CONCURRENTLY on hot table: {t}")

out = {
    "check_id": "SEC-DDL-BLOCKING-POLICY",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "FAIL" if violations else "PASS",
    "violations": violations,
    "allowlist_hits": allowlist_hits,
}
Path("$POLICY_EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ ${#filtered[@]} -gt 0 ]]; then
  echo "Lock-risk lint failed: risky DDL patterns found." >&2
  printf '%s\n' "${filtered[@]}" >&2
  exit 1
fi

if python3 - <<PY
import json
from pathlib import Path
data = json.loads(Path("$POLICY_EVIDENCE_FILE").read_text())
print("fail" if data.get("status") == "FAIL" else "pass")
PY
then
  :
fi

if [[ "$(python3 - <<PY
import json
from pathlib import Path
data = json.loads(Path("$POLICY_EVIDENCE_FILE").read_text())
print(data.get("status", "PASS"))
PY
)" == "FAIL" ]]; then
  echo "Blocking DDL policy failed. See $POLICY_EVIDENCE_FILE" >&2
  exit 1
fi

echo "Lock-risk lint passed. Evidence: $EVIDENCE_FILE and $POLICY_EVIDENCE_FILE"
