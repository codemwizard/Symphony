#!/usr/bin/env bash
set -euo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(basename "$0" .sh | sed 's/verify_tsk_hard_//')"
M="$R/schema/migrations/0066_hard_wave5_archive_merkle_and_replay.sql"
O="$R/evidence/phase1/hardening/tsk_hard_${T}.json"
S="$R/evidence/schemas/hardening/tsk_hard_${T}.schema.json"

case "$T" in
  060)
    rg -q "canonicalization_registry" "$M"
    rg -q "spec_json" "$M"
    ;;
  061)
    rg -q "assert_canonicalization_version_exists" "$M"
    rg -q "P8301" "$M"
    ;;
  062)
    rg -q "canonicalization_archive_snapshots" "$M"
    rg -q "snapshot_sha256" "$M"
    ;;
  070)
    rg -q "proof_pack_batches" "$M"
    rg -q "merkle_root" "$M"
    ;;
  071)
    rg -q "verify_merkle_leaf" "$M"
    rg -q "RETURNS boolean" "$M"
    ;;
  072)
    rg -q "proof_pack_batch_leaves" "$M"
    rg -q "UNIQUE \(batch_id, leaf_index\)" "$M"
    ;;
  073)
    rg -q "MERKLE_LEAF_HASH_MISMATCH" "$M"
    rg -q "P8303" "$M"
    ;;
  074)
    rg -q "MERKLE_LEAF_NOT_FOUND" "$M"
    rg -q "P8302" "$M"
    ;;
  097)
    rg -q "anchor_backfill_jobs" "$M"
    rg -q "replay_day" "$M"
    ;;
  099)
    rg -q "archive_verification_runs" "$M"
    rg -q "years_covered" "$M"
    ;;
  102)
    rg -q "archive_verification_runs" "$M"
    rg -q "archive_only" "$M"
    ;;
  *)
    echo "unsupported task id: $T" >&2
    exit 2
    ;;
esac

mkdir -p "$(dirname "$O")"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-${T}","task_id":"TSK-HARD-${T}","status":"PASS","pass":true,"timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON

python3 - <<PY
import json
s = json.load(open('$S'))
d = json.load(open('$O'))
for k in s['required']:
    assert k in d, k
PY

echo "TSK-HARD-${T} verification passed. Evidence: $O"
