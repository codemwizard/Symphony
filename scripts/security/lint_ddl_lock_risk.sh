#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATIONS_DIR="$ROOT_DIR/schema/migrations"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/ddl_lock_risk.json"
POLICY_EVIDENCE_FILE="$EVIDENCE_DIR/ddl_blocking_policy.json"

mkdir -p "$EVIDENCE_DIR"

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

matches=()

while IFS= read -r -d '' file; do
  while IFS= read -r line; do
    matches+=("$file:$line")
  done < <(rg -n -i \
      -e "ALTER TABLE" \
      -e "CREATE INDEX" \
      -e "DROP INDEX" \
      -e "REINDEX" \
      -e "VACUUM FULL" \
      -e "CLUSTER" \
      "$file" || true)

done < <(find "$MIGRATIONS_DIR" -type f -name '*.sql' -print0)

# Filter out CREATE INDEX CONCURRENTLY (considered lower risk for Phase-0 lint)
filtered=()
hot_tables=(
  "payment_outbox_pending"
  "payment_outbox_attempts"
  "policy_versions"
)
for entry in "${matches[@]}"; do
  # Allowlist known-safe indexes in existing baseline migrations.
  if echo "$entry" | rg -qi "0001_init\\.sql:165:CREATE INDEX idx_attempts_instruction_idempotency"; then
    continue
  fi
  if echo "$entry" | rg -qi "0001_init\\.sql:168:CREATE INDEX idx_attempts_outbox_id"; then
    continue
  fi
  if echo "$entry" | rg -qi "0005_policy_versions\\.sql:49:CREATE INDEX IF NOT EXISTS idx_policy_versions_is_active"; then
    continue
  fi
  # Allow legacy due-claim index (grandfathered)
  if echo "$entry" | rg -qi "0007_outbox_pending_indexes\\.sql:4:CREATE INDEX IF NOT EXISTS idx_payment_outbox_pending_due_claim"; then
    continue
  fi
  if echo "$entry" | rg -qi "0009_pending_fillfactor\\.sql:4:ALTER TABLE public\\.payment_outbox_pending"; then
    continue
  fi
  # Allow ALTER TABLE SET (...) for reloptions
  if echo "$entry" | rg -qi "ALTER TABLE" && echo "$entry" | rg -qi "SET \\(.*\\)"; then
    continue
  fi
  if echo "$entry" | rg -qi "CREATE INDEX" && echo "$entry" | rg -qi "CONCURRENTLY"; then
    continue
  fi
  # Allow CREATE INDEX on non-hot tables
  if echo "$entry" | rg -qi "CREATE INDEX"; then
    skip=0
    for t in "${hot_tables[@]}"; do
      if echo "$entry" | rg -qi "ON (public\\.)?${t}"; then
        skip=1
        break
      fi
    done
    if [[ $skip -eq 0 ]]; then
      continue
    fi
  fi
  filtered+=("$entry")
done

# Emit evidence JSON for general lock-risk lint
printf '%s\n' "${filtered[@]}" | python3 - <<PY
import json, sys
lines = [ln.strip() for ln in sys.stdin.read().splitlines() if ln.strip()]
out = {
    "status": "fail" if lines else "pass",
    "match_count": len(lines),
    "matches": lines,
}
with open("$EVIDENCE_FILE", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
PY

# Blocking DDL policy (hot tables must use CONCURRENTLY; forbid ALTER on hot tables)
python3 - <<PY
import json
from pathlib import Path

hot_tables = [
    "payment_outbox_pending",
    "payment_outbox_attempts",
    "policy_versions",
]

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
                    violations.append(f"{p.name}: ALTER TABLE on hot table: {t}")
        # CREATE INDEX on hot tables must be CONCURRENTLY
        if "create index" in s_low and "concurrently" not in s_low:
            for t in hot_tables:
                if f" on {t}" in s_low or f" on public.{t}" in s_low:
                    # Allow legacy index migration
                    if p.name in ("0007_outbox_pending_indexes.sql", "0001_init.sql", "0005_policy_versions.sql"):
                        continue
                    violations.append(f"{p.name}: CREATE INDEX without CONCURRENTLY on hot table: {t}")

out = {"status": "fail" if violations else "pass", "violations": violations}
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
print("fail" if data.get("status") == "fail" else "pass")
PY
then
  :
fi

if [[ "$(python3 - <<PY
import json
from pathlib import Path
data = json.loads(Path("$POLICY_EVIDENCE_FILE").read_text())
print(data.get("status", "pass"))
PY
)" == "fail" ]]; then
  echo "Blocking DDL policy failed. See $POLICY_EVIDENCE_FILE" >&2
  exit 1
fi

echo "Lock-risk lint passed. Evidence: $EVIDENCE_FILE and $POLICY_EVIDENCE_FILE"
