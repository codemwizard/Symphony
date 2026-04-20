#!/usr/bin/env bash
# verify_invariant_exec_truth_001_security_docs.sh
#
# Owner role: INVARIANTS_CURATOR (REM-04 authors; REM-04B consumes)
# Purpose: Attest that the ARCHITECT-owned registration of INV-EXEC-TRUTH-001
#          in docs/architecture/** is present and points at the correct verifier
#          and evidence artefacts. Consumes the outputs of REM-04B (threat
#          model entry + compliance map rows).
#
# Emits: evidence/phase2/tsk_p2_preauth_003_rem_04b.json
#
# This script is a pure filesystem + grep gate. It does NOT author content in
# docs/architecture/** (that is ARCHITECT path authority, REM-04B). It only
# inspects the two architecture documents for the required markers.
#
# Path authority: scripts/audit/** is INVARIANTS_CURATOR territory per AGENTS.md.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p2_preauth_003_rem_04b.json"
THREAT_MODEL="$ROOT_DIR/docs/architecture/THREAT_MODEL.md"
COMPLIANCE_MAP="$ROOT_DIR/docs/architecture/COMPLIANCE_MAP.md"
ANCHOR_SCRIPT_REL="scripts/db/verify_execution_truth_anchor.sh"
ANCHOR_EVIDENCE_REL="evidence/phase2/tsk_p2_preauth_003_rem_05.json"

mkdir -p "$EVIDENCE_DIR"

TS_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TASK_ID="TSK-P2-PREAUTH-003-REM-04B"

FAIL_REASONS=()
CHECKS_JSON_PARTS=()
EXEC_TRACE=()

record() {
  local name="$1" passed="$2" detail="$3"
  CHECKS_JSON_PARTS+=("\"$name\":{\"passed\":$passed,\"detail\":$(printf '%s' "$detail" | python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))')}")
  EXEC_TRACE+=("$name=$passed")
  if [[ "$passed" != "true" ]]; then
    FAIL_REASONS+=("$name: $detail")
  fi
}

# ---------------------------------------------------------------------------
# Check 1: threat_model_present — execution-record tamper entry present AND
# references INV-EXEC-TRUTH-001.
# ---------------------------------------------------------------------------
THREAT_MODEL_PRESENT=false
if [[ -f "$THREAT_MODEL" ]]; then
  if grep -q 'execution-record tamper' "$THREAT_MODEL" \
     && grep -q 'INV-EXEC-TRUTH-001' "$THREAT_MODEL"; then
    THREAT_MODEL_PRESENT=true
    record "threat_model_present" true "execution-record tamper entry + INV-EXEC-TRUTH-001 present"
  else
    record "threat_model_present" false "threat entry or invariant id missing in $THREAT_MODEL"
  fi
else
  record "threat_model_present" false "$THREAT_MODEL not found"
fi

# ---------------------------------------------------------------------------
# Check 2: threat_model_references_verifier — entry points at the anchor
# verifier or its evidence file.
# ---------------------------------------------------------------------------
THREAT_MODEL_REFS_VERIFIER=false
if [[ -f "$THREAT_MODEL" ]] && grep -q "$ANCHOR_SCRIPT_REL" "$THREAT_MODEL"; then
  THREAT_MODEL_REFS_VERIFIER=true
  record "threat_model_references_verifier" true "references $ANCHOR_SCRIPT_REL"
else
  record "threat_model_references_verifier" false "$ANCHOR_SCRIPT_REL not referenced in threat model"
fi

# ---------------------------------------------------------------------------
# Check 3: compliance_map_present — INV-EXEC-TRUTH-001 appears in compliance
# map.
# ---------------------------------------------------------------------------
COMPLIANCE_MAP_PRESENT=false
if [[ -f "$COMPLIANCE_MAP" ]] && grep -q 'INV-EXEC-TRUTH-001' "$COMPLIANCE_MAP"; then
  COMPLIANCE_MAP_PRESENT=true
  record "compliance_map_present" true "INV-EXEC-TRUTH-001 present in compliance map"
else
  record "compliance_map_present" false "INV-EXEC-TRUTH-001 missing from $COMPLIANCE_MAP"
fi

# ---------------------------------------------------------------------------
# Check 4: compliance_map_references_evidence — a row points at the upstream
# REM-05 evidence artefact.
# ---------------------------------------------------------------------------
COMPLIANCE_MAP_REFS_EVIDENCE=false
if [[ -f "$COMPLIANCE_MAP" ]] && grep -q 'tsk_p2_preauth_003_rem_05' "$COMPLIANCE_MAP"; then
  COMPLIANCE_MAP_REFS_EVIDENCE=true
  record "compliance_map_references_evidence" true "references $ANCHOR_EVIDENCE_REL"
else
  record "compliance_map_references_evidence" false "upstream evidence pointer missing from compliance map"
fi

# ---------------------------------------------------------------------------
# Compose status.
# ---------------------------------------------------------------------------
if [[ ${#FAIL_REASONS[@]} -eq 0 ]]; then
  STATUS="PASS"
else
  STATUS="FAIL"
fi

CHECKS_JSON="{$(IFS=,; echo "${CHECKS_JSON_PARTS[*]}")}"
EXEC_TRACE_JSON="[$(printf '"%s",' "${EXEC_TRACE[@]}" | sed 's/,$//')]"

python3 - "$EVIDENCE_FILE" "$TASK_ID" "$GIT_SHA" "$TS_UTC" "$STATUS" \
  "$THREAT_MODEL" "$COMPLIANCE_MAP" \
  "$THREAT_MODEL_PRESENT" "$COMPLIANCE_MAP_PRESENT" \
  "$THREAT_MODEL_REFS_VERIFIER" "$COMPLIANCE_MAP_REFS_EVIDENCE" \
  "$CHECKS_JSON" "$EXEC_TRACE_JSON" <<'PY'
import hashlib, json, os, sys
(evidence_file, task_id, git_sha, ts_utc, status,
 threat, compliance,
 tm_present, cm_present, tm_refs, cm_refs,
 checks_json, trace_json) = sys.argv[1:]

def sha_file(p):
    try:
        h = hashlib.sha256()
        with open(p, 'rb') as fh:
            for chunk in iter(lambda: fh.read(65536), b''):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return ''

observed_paths = {"threat_model": threat, "compliance_map": compliance}
observed_hashes = {
    "threat_model": sha_file(threat),
    "compliance_map": sha_file(compliance),
}
command_outputs = {
    "threat_model_exists": os.path.isfile(threat),
    "compliance_map_exists": os.path.isfile(compliance),
}
out = {
    "task_id": task_id,
    "git_sha": git_sha,
    "timestamp_utc": ts_utc,
    "status": status,
    "checks": json.loads(checks_json),
    "observed_paths": observed_paths,
    "observed_hashes": observed_hashes,
    "command_outputs": command_outputs,
    "execution_trace": json.loads(trace_json),
    "threat_model_present": tm_present == "true",
    "compliance_map_present": cm_present == "true",
    "threat_model_references_verifier": tm_refs == "true",
    "compliance_map_references_evidence": cm_refs == "true",
}
with open(evidence_file, 'w') as fh:
    json.dump(out, fh, indent=2, sort_keys=True)
    fh.write('\n')
print(f"wrote {evidence_file}: status={status}")
PY

if [[ "$STATUS" == "PASS" ]]; then
  echo "[verify_invariant_exec_truth_001_security_docs] PASS"
  exit 0
fi
echo "[verify_invariant_exec_truth_001_security_docs] FAIL:" >&2
for r in "${FAIL_REASONS[@]}"; do echo "  - $r" >&2; done
exit 1
