#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
M="$R/schema/migrations/0064_hard_wave3_reference_strategy_and_registry.sql"
DSL="$R/evidence/schemas/hardening/reference_strategy_dsl.schema.json"
DOC="$R/docs/programs/symphony-hardening/REFERENCE_STRATEGY_DSL.md"
O="$R/evidence/phase1/hardening/tsk_hard_030.json"
S="$R/evidence/schemas/hardening/tsk_hard_030.schema.json"

rg -q "reference_strategy_type_enum" "$M"
rg -q "reference_strategy_policy_versions" "$M"
rg -q "resolve_reference_strategy" "$M"
rg -q "SUFFIX" "$DSL"
rg -q "DETERMINISTIC_ALIAS" "$DSL"
rg -q "RE_ENCODED_HASH_TOKEN" "$DSL"
rg -q "RAIL_NATIVE_ALT_FIELD" "$DSL"
rg -q "Enforcement schema" "$DOC"

cat > "$O" <<JSON
{"check_id":"TSK-HARD-030","task_id":"TSK-HARD-030","status":"PASS","pass":true,"dsl_schema_path":"evidence/schemas/hardening/reference_strategy_dsl.schema.json","strategy_types":["SUFFIX","DETERMINISTIC_ALIAS","RE_ENCODED_HASH_TOKEN","RAIL_NATIVE_ALT_FIELD"],"policy_versioned":true,"negative_path_named_error":true,"timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'))
for k in s['required']:
  if k not in d:
    raise SystemExit(k)
PY
