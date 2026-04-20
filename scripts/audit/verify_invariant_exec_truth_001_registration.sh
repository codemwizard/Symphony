#!/usr/bin/env bash
# verify_invariant_exec_truth_001_registration.sh
#
# Owner role: INVARIANTS_CURATOR (REM-04)
# Purpose: Attest that INV-EXEC-TRUTH-001 is correctly registered in
#          docs/invariants/INVARIANTS_MANIFEST.yml and INVARIANTS_IMPLEMENTED.md,
#          that the declared enforcement path resolves to a file on disk, and
#          that the declared verification-evidence file is fresh (its run_hash
#          was produced at or after the currently checked-in
#          scripts/db/verify_execution_truth_anchor.sh fingerprint).
#
# Emits: evidence/phase2/tsk_p2_preauth_003_rem_04.json
#
# This script is a pure filesystem + text gate. It does NOT execute the DB-layer
# verifier (that is the responsibility of REM-05 / pre_ci.sh). It reads the
# upstream REM-05 evidence JSON to derive a freshness proof.
#
# Path authority: scripts/audit/** is INVARIANTS_CURATOR territory per AGENTS.md.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p2_preauth_003_rem_04.json"
MANIFEST="$ROOT_DIR/docs/invariants/INVARIANTS_MANIFEST.yml"
IMPLEMENTED="$ROOT_DIR/docs/invariants/INVARIANTS_IMPLEMENTED.md"
ANCHOR_SCRIPT="$ROOT_DIR/scripts/db/verify_execution_truth_anchor.sh"
UPSTREAM_EVIDENCE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_05.json"

mkdir -p "$EVIDENCE_DIR"

TS_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TASK_ID="TSK-P2-PREAUTH-003-REM-04"

FAIL_REASONS=()
CHECKS_JSON_PARTS=()
EXEC_TRACE=()

record() {
  # record <name> <true|false> <detail>
  local name="$1" passed="$2" detail="$3"
  CHECKS_JSON_PARTS+=("\"$name\":{\"passed\":$passed,\"detail\":$(printf '%s' "$detail" | python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))')}")
  EXEC_TRACE+=("$name=$passed")
  if [[ "$passed" != "true" ]]; then
    FAIL_REASONS+=("$name: $detail")
  fi
}

# ---------------------------------------------------------------------------
# Check 1: manifest_present — INV-EXEC-TRUTH-001 appears in manifest with
# status=implemented.
# ---------------------------------------------------------------------------
MANIFEST_PRESENT=false
if [[ -f "$MANIFEST" ]]; then
  if python3 - "$MANIFEST" <<'PY' >/dev/null 2>&1
import sys, yaml
with open(sys.argv[1]) as fh:
    docs = yaml.safe_load(fh)
if not isinstance(docs, list):
    sys.exit(2)
for block in docs:
    if not isinstance(block, dict):
        continue
    aliases = block.get("aliases") or []
    if block.get("id") == "INV-EXEC-TRUTH-001" or "INV-EXEC-TRUTH-001" in aliases:
        if block.get("status") == "implemented":
            sys.exit(0)
        sys.exit(3)
sys.exit(4)
PY
  then
    MANIFEST_PRESENT=true
    record "manifest_present" true "INV-EXEC-TRUTH-001 found with status=implemented"
  else
    record "manifest_present" false "INV-EXEC-TRUTH-001 absent or status!=implemented"
  fi
else
  record "manifest_present" false "manifest file missing at $MANIFEST"
fi

# ---------------------------------------------------------------------------
# Check 2: implemented_registry_present — row referencing the invariant
# (canonical id INV-179 and/or the semantic aliases I-EXEC-TRUTH-01 /
# INV-EXEC-TRUTH-001) appears in INVARIANTS_IMPLEMENTED.md and points at
# the anchor verifier. The registry table uses INV-179 | I-EXEC-TRUTH-01
# per phase1_enforced_invariants convention (id | alias); accepting any
# of the three identifiers keeps the check alias-agnostic.
# ---------------------------------------------------------------------------
IMPLEMENTED_REGISTRY_PRESENT=false
if [[ -f "$IMPLEMENTED" ]]; then
  if grep -Eq 'INV-179|I-EXEC-TRUTH-01|INV-EXEC-TRUTH-001' "$IMPLEMENTED" \
     && grep -q 'scripts/db/verify_execution_truth_anchor.sh' "$IMPLEMENTED"; then
    IMPLEMENTED_REGISTRY_PRESENT=true
    record "implemented_registry_present" true "row references anchor verifier"
  else
    record "implemented_registry_present" false "row missing or does not reference anchor verifier"
  fi
else
  record "implemented_registry_present" false "implemented registry file missing at $IMPLEMENTED"
fi

# ---------------------------------------------------------------------------
# Check 3: enforcement_path_resolves — the declared enforcement path
# (scripts/db/verify_execution_truth_anchor.sh) exists and is executable.
# ---------------------------------------------------------------------------
ENFORCEMENT_PATH_RESOLVES=false
if [[ -x "$ANCHOR_SCRIPT" ]]; then
  ENFORCEMENT_PATH_RESOLVES=true
  record "enforcement_path_resolves" true "$ANCHOR_SCRIPT is executable"
elif [[ -f "$ANCHOR_SCRIPT" ]]; then
  record "enforcement_path_resolves" false "$ANCHOR_SCRIPT exists but is not executable"
else
  record "enforcement_path_resolves" false "$ANCHOR_SCRIPT does not exist"
fi

# ---------------------------------------------------------------------------
# Check 4: verification_evidence_fresh — REM-05 evidence JSON exists, parses,
# status==PASS, and its verification_tool_version matches the SHA-256 of the
# anchor script on disk (i.e. the evidence was emitted by the currently
# checked-in verifier, not a stale pre-rewrite version).
# ---------------------------------------------------------------------------
VERIFICATION_EVIDENCE_FRESH=false
UPSTREAM_EVIDENCE_HASH=""
if [[ -f "$UPSTREAM_EVIDENCE" ]]; then
  UPSTREAM_EVIDENCE_HASH="$(sha256sum "$UPSTREAM_EVIDENCE" | awk '{print $1}')"
  if [[ -x "$ANCHOR_SCRIPT" || -f "$ANCHOR_SCRIPT" ]]; then
    CURRENT_TOOL_HASH="$(sha256sum "$ANCHOR_SCRIPT" | awk '{print $1}')"
    EVIDENCE_TOOL_HASH="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d.get("verification_tool_version",""))' "$UPSTREAM_EVIDENCE" 2>/dev/null || echo '')"
    EVIDENCE_STATUS="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d.get("status",""))' "$UPSTREAM_EVIDENCE" 2>/dev/null || echo '')"
    if [[ "$EVIDENCE_STATUS" == "PASS" && "$EVIDENCE_TOOL_HASH" == "$CURRENT_TOOL_HASH" ]]; then
      VERIFICATION_EVIDENCE_FRESH=true
      record "verification_evidence_fresh" true "REM-05 evidence status=PASS, tool_hash matches checked-in verifier ($CURRENT_TOOL_HASH)"
    elif [[ "$EVIDENCE_STATUS" != "PASS" ]]; then
      record "verification_evidence_fresh" false "REM-05 evidence status=$EVIDENCE_STATUS (expected PASS)"
    else
      record "verification_evidence_fresh" false "REM-05 evidence tool_hash=$EVIDENCE_TOOL_HASH, current=$CURRENT_TOOL_HASH (stale)"
    fi
  else
    record "verification_evidence_fresh" false "anchor script unreadable; cannot compute tool hash"
  fi
else
  record "verification_evidence_fresh" false "upstream evidence missing at $UPSTREAM_EVIDENCE"
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
FAIL_REASONS_JSON="[$(printf '"%s",' "${FAIL_REASONS[@]}" | sed 's/,$//' | sed 's/"/\\"/g')]"
[[ "$FAIL_REASONS_JSON" == "[]" ]] || FAIL_REASONS_JSON="[$(for r in "${FAIL_REASONS[@]}"; do printf '%s\n' "$r"; done | python3 -c 'import json,sys; print(json.dumps([l.rstrip() for l in sys.stdin]))' | sed 's/^/,/' | tr -d '\n' | sed 's/^,//')]"

python3 - "$EVIDENCE_FILE" "$TASK_ID" "$GIT_SHA" "$TS_UTC" "$STATUS" \
  "$MANIFEST" "$IMPLEMENTED" "$ANCHOR_SCRIPT" "$UPSTREAM_EVIDENCE" \
  "$MANIFEST_PRESENT" "$IMPLEMENTED_REGISTRY_PRESENT" "$ENFORCEMENT_PATH_RESOLVES" \
  "$VERIFICATION_EVIDENCE_FRESH" "$UPSTREAM_EVIDENCE_HASH" \
  "$CHECKS_JSON" "$EXEC_TRACE_JSON" <<'PY'
import hashlib, json, os, sys, subprocess
(evidence_file, task_id, git_sha, ts_utc, status,
 manifest, implemented, anchor, upstream,
 manifest_present, impl_reg_present, enforcement_resolves,
 evidence_fresh, upstream_hash, checks_json, trace_json) = sys.argv[1:]

def sha_file(p):
    try:
        h = hashlib.sha256()
        with open(p, 'rb') as fh:
            for chunk in iter(lambda: fh.read(65536), b''):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return ''

observed_paths = {
    "manifest": manifest,
    "implemented_registry": implemented,
    "enforcement": anchor,
    "upstream_evidence": upstream,
}
observed_hashes = {
    "manifest": sha_file(manifest),
    "implemented_registry": sha_file(implemented),
    "enforcement": sha_file(anchor),
    "upstream_evidence": sha_file(upstream),
}
command_outputs = {
    "anchor_script_exists": os.path.isfile(anchor),
    "anchor_script_executable": os.access(anchor, os.X_OK),
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
    "manifest_present": manifest_present == "true",
    "enforcement_path_resolves": enforcement_resolves == "true",
    "verification_evidence_fresh": evidence_fresh == "true",
    "upstream_evidence_hash": upstream_hash,
}
with open(evidence_file, 'w') as fh:
    json.dump(out, fh, indent=2, sort_keys=True)
    fh.write('\n')
print(f"wrote {evidence_file}: status={status}")
PY

if [[ "$STATUS" == "PASS" ]]; then
  echo "[verify_invariant_exec_truth_001_registration] PASS"
  exit 0
fi
echo "[verify_invariant_exec_truth_001_registration] FAIL:" >&2
for r in "${FAIL_REASONS[@]}"; do echo "  - $r" >&2; done
exit 1
