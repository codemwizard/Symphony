#!/usr/bin/env bash
# scripts/audit/verify_gf_task_meta.sh
#
# PURPOSE
# -------
# Dedicated v2 field and GF domain checks for tasks/GF-W1-*/meta.yml.
# This is the enforcement layer for GF task meta quality that was previously
# embedded in the general task meta schema validator (where it broke the
# scope mechanism). Runs explicitly against GF tasks only.
#
# CHECKS
# ------
# 1. v2 required fields: intent (>=50 chars), anti_patterns (>=2),
#    work (>=3), acceptance_criteria (>=2), negative_tests (>=1 required:true)
# 2. GF domain fields: second_pilot_test with required subfields,
#    pilot_scope_ref, must_read including AGENTIC_SDLC_PILOT_POLICY.md
# 3. Evidence contract: evidence entries with must_include (>=5 fields)
#
# USAGE
# -----
# bash scripts/audit/verify_gf_task_meta.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TASK_DIR="tasks"
FAIL_COUNT=0
PASS_COUNT=0
CHECKED=0

fail() {
  local task_id="$1" field="$2" message="$3"
  echo "  FAIL [$task_id] $field: $message"
  ((FAIL_COUNT++)) || true
}

pass() {
  ((PASS_COUNT++)) || true
}

echo "==> GF Task Meta v2 Field Verification"
echo ""

mapfile -t GF_FILES < <(find "$TASK_DIR" -path "*/GF-W1-*/meta.yml" -type f | sort)

if [[ ${#GF_FILES[@]} -eq 0 ]]; then
  echo "No GF task meta files found under $TASK_DIR"
  exit 0
fi

for file in "${GF_FILES[@]}"; do
  task_id=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
print(d.get('task_id', 'UNKNOWN'))
" 2>/dev/null || echo "UNKNOWN")

  ((CHECKED++)) || true
  echo "Checking $task_id..."

  # ── v2 required field: intent (>=50 chars) ─────────────────────────────
  intent_len=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
print(len(str(d.get('intent', '')).strip()))
" 2>/dev/null || echo "0")

  if [[ "$intent_len" -ge 50 ]]; then
    pass
  else
    fail "$task_id" "intent" "Missing or too short (${intent_len} chars, need >= 50)"
  fi

  # ── v2 required field: anti_patterns (>=2) ─────────────────────────────
  ap_count=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = d.get('anti_patterns', [])
print(len(v) if isinstance(v, list) else 0)
" 2>/dev/null || echo "0")

  if [[ "$ap_count" -ge 2 ]]; then
    pass
  else
    fail "$task_id" "anti_patterns" "Must have >= 2 (got $ap_count)"
  fi

  # ── v2 required field: work (>=3) ──────────────────────────────────────
  work_count=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = d.get('work', [])
print(len(v) if isinstance(v, list) else 0)
" 2>/dev/null || echo "0")

  if [[ "$work_count" -ge 3 ]]; then
    pass
  else
    fail "$task_id" "work" "Must have >= 3 work items (got $work_count)"
  fi

  # ── v2 required field: acceptance_criteria (>=2) ───────────────────────
  ac_count=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = d.get('acceptance_criteria', [])
print(len(v) if isinstance(v, list) else 0)
" 2>/dev/null || echo "0")

  if [[ "$ac_count" -ge 2 ]]; then
    pass
  else
    fail "$task_id" "acceptance_criteria" "Must have >= 2 (got $ac_count)"
  fi

  # ── v2 required field: negative_tests (>=1 with required:true) ────────
  neg_req=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
tests = d.get('negative_tests', [])
req = [t for t in tests if isinstance(t, dict) and t.get('required') == True]
print(len(req))
" 2>/dev/null || echo "0")

  if [[ "$neg_req" -ge 1 ]]; then
    pass
  else
    fail "$task_id" "negative_tests" "Must have >= 1 negative test with required:true (got $neg_req)"
  fi

  # ── v2 required field: evidence with must_include (>=5) ────────────────
  ev_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
evs = d.get('evidence', [])
ok = 0
for e in evs:
    if isinstance(e, dict) and 'must_include' in e and len(e['must_include']) >= 5:
        ok += 1
print(ok)
" 2>/dev/null || echo "0")

  if [[ "$ev_ok" -ge 1 ]]; then
    pass
  else
    fail "$task_id" "evidence" "Must have >= 1 evidence entry with must_include (>= 5 fields)"
  fi

  # ── GF domain: second_pilot_test ──────────────────────────────────────
  spt_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
spt = d.get('second_pilot_test')
if spt is None:
    print('missing')
elif isinstance(spt, str):
    # String-form justification (used by governance/freeze tasks)
    print('ok' if len(spt.strip()) >= 20 else 'too_short')
elif isinstance(spt, dict):
    required = ['candidate_sector_1', 'candidate_sector_2', 'unchanged_core_tables',
                'unchanged_core_functions', 'adapter_only_differences',
                'jurisdiction_profile_impact', 'required_core_changes', 'explanation',
                'second_pilot_reviewed_by']
    missing = [k for k in required if k not in spt]
    print('ok' if not missing else 'missing:' + ','.join(missing))
else:
    print('invalid_type')
" 2>/dev/null || echo "missing")

  if [[ "$spt_ok" == "ok" ]]; then
    pass
  else
    fail "$task_id" "second_pilot_test" "Missing or incomplete ($spt_ok)"
  fi

  # ── GF domain: pilot_scope_ref ────────────────────────────────────────
  psr_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
ref = str(d.get('pilot_scope_ref', ''))
ok = 'SCOPE.md' in ref or 'PILOT_' in ref or ref.lower() in ['not_applicable', 'n/a']
print('ok' if ok else 'missing')
" 2>/dev/null || echo "missing")

  if [[ "$psr_ok" == "ok" ]]; then
    pass
  else
    fail "$task_id" "pilot_scope_ref" "Must reference pilot SCOPE.md or be not_applicable"
  fi

  # ── GF domain: must_read includes AGENTIC_SDLC_PILOT_POLICY.md ───────
  mr_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
mr = d.get('must_read', [])
if not isinstance(mr, list):
    print('missing')
else:
    found = any('AGENTIC_SDLC_PILOT_POLICY' in str(x) for x in mr)
    print('ok' if found else 'missing')
" 2>/dev/null || echo "missing")

  if [[ "$mr_ok" == "ok" ]]; then
    pass
  else
    fail "$task_id" "must_read" "Must include AGENTIC_SDLC_PILOT_POLICY.md"
  fi

done

echo ""
echo "============================================================"
echo "GF tasks checked: $CHECKED"
echo "Checks passed: $PASS_COUNT"
echo "Checks failed: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "❌ GF Task Meta v2 Verification: FAIL"
  exit 1
else
  echo "✅ GF Task Meta v2 Verification: PASS"
  exit 0
fi
