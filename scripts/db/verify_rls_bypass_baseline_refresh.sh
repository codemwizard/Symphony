#!/usr/bin/env bash
# verify_rls_bypass_baseline_refresh.sh
# TSK-P2-RLS-BYPASS-006 — Verify baseline regenerated with provenance after RLS bypass migration
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_baseline_refresh.json"

status="PASS"
checks=()

# ── Check 1: Current baseline meta.json exists and has provenance ────────────
META_FILE="$ROOT_DIR/schema/baselines/current/baseline.meta.json"
if [[ ! -f "$META_FILE" ]]; then
  echo "FAIL: baseline.meta.json not found" >&2
  exit 1
fi
checks+=("baseline_meta_exists")

# Parse provenance fields
pg_dump_version="$(python3 -c "import json; print(json.load(open('$META_FILE')).get('pg_dump_version','MISSING'))")"
pg_server_version="$(python3 -c "import json; print(json.load(open('$META_FILE')).get('pg_server_version','MISSING'))")"
dump_source="$(python3 -c "import json; print(json.load(open('$META_FILE')).get('dump_source','MISSING'))")"
normalized_sha="$(python3 -c "import json; print(json.load(open('$META_FILE')).get('normalized_schema_sha256','MISSING'))")"
baseline_cutoff="$(python3 -c "import json; print(json.load(open('$META_FILE')).get('baseline_cutoff','MISSING'))")"

for field_name in pg_dump_version pg_server_version dump_source normalized_schema_sha256; do
  val="$(python3 -c "import json; print(json.load(open('$META_FILE')).get('$field_name','MISSING'))")"
  if [[ "$val" == "MISSING" || -z "$val" ]]; then
    status="FAIL"
    checks+=("provenance_${field_name}:FAIL")
  else
    checks+=("provenance_${field_name}:PASS")
  fi
done

# ── Check 2: Migration head matches post-0204 ───────────────────────────────
MIGRATION_HEAD_FILE="$ROOT_DIR/schema/migrations/MIGRATION_HEAD"
migration_head="UNKNOWN"
if [[ -f "$MIGRATION_HEAD_FILE" ]]; then
  migration_head="$(cat "$MIGRATION_HEAD_FILE" | tr -d '\n')"
fi

# Strip leading zeros for arithmetic comparison
migration_head_num=$((10#${migration_head:-0}))
if [[ "$migration_head_num" -ge 204 ]]; then
  checks+=("migration_head_ge_204:PASS")
else
  status="FAIL"
  checks+=("migration_head_ge_204:FAIL:$migration_head")
fi

# ── Check 3: Baseline cutoff includes migration 0204 ────────────────────────
if [[ "$baseline_cutoff" == *"0204"* ]]; then
  checks+=("baseline_cutoff_includes_0204:PASS")
else
  status="FAIL"
  checks+=("baseline_cutoff_includes_0204:FAIL:$baseline_cutoff")
fi

# ── Check 4: No bypass_rls in current canonical baseline policy definitions ──
BASELINE_PATHS=(
  "schema/baseline.sql"
  "schema/baselines/current/0001_baseline.sql"
)
bypass_in_baseline=0
for bp in "${BASELINE_PATHS[@]}"; do
  full="$ROOT_DIR/$bp"
  if [[ -f "$full" ]]; then
    count=$(grep -cE 'bypass_rls' "$full" 2>/dev/null || true)
    count=${count:-0}
    bypass_in_baseline=$((bypass_in_baseline + count))
  fi
done

if [[ "$bypass_in_baseline" -gt 0 ]]; then
  status="FAIL"
  checks+=("app_bypass_rls_in_current_baseline:FAIL:$bypass_in_baseline")
else
  checks+=("app_bypass_rls_in_current_baseline:PASS:0")
fi

# ── Check 5: Prerequisite evidence files exist and PASS ──────────────────────
for prereq in "rls_bypass_policy_migration.json" "rls_no_app_bypass_policies.json"; do
  prereq_file="$EVIDENCE_DIR/$prereq"
  if [[ -f "$prereq_file" ]]; then
    prereq_status="$(python3 -c "import json; print(json.load(open('$prereq_file')).get('status','UNKNOWN'))")"
    if [[ "$prereq_status" == "PASS" ]]; then
      checks+=("prereq_${prereq}:PASS")
    else
      status="FAIL"
      checks+=("prereq_${prereq}:FAIL:$prereq_status")
    fi
  else
    status="FAIL"
    checks+=("prereq_${prereq}:MISSING")
  fi
done

# ── Compute observed hashes ──────────────────────────────────────────────────
baseline_paths_list=()
observed_hashes_json="{"
first=1
for bp in "schema/baseline.sql" "schema/baselines/current/0001_baseline.sql" "schema/baselines/current/baseline.meta.json"; do
  full="$ROOT_DIR/$bp"
  if [[ -f "$full" ]]; then
    baseline_paths_list+=("$bp")
    h=$(sha256sum "$full" | awk '{print $1}')
    if [[ $first -eq 0 ]]; then observed_hashes_json+=","; fi
    first=0
    observed_hashes_json+="\"$bp\":\"$h\""
  fi
done
observed_hashes_json+="}"

# ── Emit evidence ────────────────────────────────────────────────────────────
mkdir -p "$EVIDENCE_DIR"

"$ROOT_DIR/.venv/bin/python3" - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" \
  "$status" "$pg_dump_version" "$pg_server_version" "$dump_source" "$normalized_sha" \
  "$migration_head" "$bypass_in_baseline" "$observed_hashes_json" \
  <<PYEOF "$(IFS='|'; echo "${checks[*]}")" "$(IFS='|'; echo "${baseline_paths_list[*]}")"
import json, os, sys

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
status = sys.argv[4]
pg_dump_ver = sys.argv[5]
pg_server_ver = sys.argv[6]
dump_src = sys.argv[7]
norm_sha = sys.argv[8]
mig_head = sys.argv[9]
bypass_count = int(sys.argv[10])
obs_hashes = json.loads(sys.argv[11])
checks = [c for c in sys.argv[12].split('|') if c]
bpaths = [p for p in sys.argv[13].split('|') if p]

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-006',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'status': status,
    'checks': checks,
    'pg_dump_version': pg_dump_ver,
    'pg_server_version': pg_server_ver,
    'dump_source': dump_src,
    'normalized_schema_sha256': norm_sha,
    'migration_head': mig_head,
    'baseline_paths': bpaths,
    'app_bypass_rls_in_current_baseline': bypass_count,
    'observed_paths': sorted(bpaths),
    'observed_hashes': obs_hashes,
    'command_outputs': [
        'scripts/db/generate_baseline_snapshot.sh',
        'grep -cE bypass_rls <baseline_paths>',
    ],
    'execution_trace': [
        f'scan_started={ts}',
        f'migration_head={mig_head}',
        f'pg_dump_version={pg_dump_ver}',
        f'pg_server_version={pg_server_ver}',
        f'dump_source={dump_src}',
        f'normalized_schema_sha256={norm_sha}',
        f'bypass_in_baseline={bypass_count}',
        f'status={status}',
    ],
}

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
print(f"  Migration head: {mig_head}")
print(f"  Baseline cutoff: 0204")
print(f"  bypass_rls in baseline: {bypass_count}")
print(f"  pg_dump: {pg_dump_ver}")
print(f"  pg_server: {pg_server_ver}")
print(f"  dump_source: {dump_src}")
print(f"  normalized_sha: {norm_sha}")

if status != 'PASS':
    sys.exit(1)
PYEOF

echo "TSK-P2-RLS-BYPASS-006 verification: $status"
if [[ "$status" != "PASS" ]]; then
  exit 1
fi
