#!/usr/bin/env bash
# scripts/audit/verify_task_meta_schema.sh
#
# PURPOSE
# ───────
# Enforces the Symphony Task Meta Schema v2 standard.
# Runs in two modes:
#   --mode basic  : checks required fields are present and non-empty (original standard)
#   --mode strict : additionally enforces v2 quality bars per field
#
# EXIT CODES
#   0 = all tasks pass
#   1 = one or more tasks fail
#
# EVIDENCE
#   Emits evidence/task_governance/task_meta_schema_conformance.json
#
# USAGE
#   bash scripts/audit/verify_task_meta_schema.sh
#   bash scripts/audit/verify_task_meta_schema.sh --mode strict
#   bash scripts/audit/verify_task_meta_schema.sh --task SEC-B-001 --mode strict

set -euo pipefail

MODE="basic"
TARGET_TASK=""
TASK_ROOT="${TASK_ROOT:-tasks}"
EVIDENCE_OUT="evidence/task_governance/task_meta_schema_conformance.json"
VIOLATIONS=()
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --task) TARGET_TASK="$2"; shift 2 ;;
    --evidence-out) EVIDENCE_OUT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ "$MODE" != "basic" && "$MODE" != "strict" ]]; then
  echo "ERROR: --mode must be 'basic' or 'strict'" >&2
  exit 1
fi

# ── Helper: check field is non-empty list ────────────────────────────────────
check_list_nonempty() {
  local task_id="$1" field="$2" file="$3"
  local val
  val=$(python3 -c "
import yaml, sys
with open('$file') as f:
    d = yaml.safe_load(f)
v = d.get('$field', [])
if isinstance(v, list):
    sys.exit(0 if len(v) > 0 else 1)
elif v:
    sys.exit(0)
else:
    sys.exit(1)
" 2>/dev/null) && return 0 || return 1
}

# ── Helper: check field is present and non-empty string ──────────────────────
check_string_nonempty() {
  local task_id="$1" field="$2" file="$3"
  python3 -c "
import yaml, sys
with open('$file') as f:
    d = yaml.safe_load(f)
v = d.get('$field', '')
sys.exit(0 if (isinstance(v, str) and len(v.strip()) > 0) else 1)
" 2>/dev/null
}

# ── Helper: check list has minimum length ────────────────────────────────────
check_list_min() {
  local task_id="$1" field="$2" min="$3" file="$4"
  python3 -c "
import yaml, sys
with open('$file') as f:
    d = yaml.safe_load(f)
v = d.get('$field', [])
cnt = len(v) if isinstance(v, list) else (1 if v else 0)
sys.exit(0 if cnt >= $min else 1)
" 2>/dev/null
}

# ── Helper: check enum value ─────────────────────────────────────────────────
check_enum() {
  local task_id="$1" field="$2" file="$3"
  shift 3
  local valid_values=("$@")
  python3 -c "
import yaml, sys
with open('$file') as f:
    d = yaml.safe_load(f)
v = str(d.get('$field', ''))
valid = $(printf "'%s'," "${valid_values[@]}" | sed 's/,$//')
sys.exit(0 if v in [$(printf "'%s'," "${valid_values[@]}" | sed 's/,$//')] else 1)
" 2>/dev/null
}

# ── Record violation ──────────────────────────────────────────────────────────
fail() {
  local task_id="$1" field="$2" message="$3"
  VIOLATIONS+=("{\"task_id\": \"$task_id\", \"field\": \"$field\", \"message\": \"$message\"}")
  echo "  FAIL [$task_id] $field: $message"
  ((FAIL_COUNT++)) || true
}

warn() {
  local task_id="$1" field="$2" message="$3"
  echo "  WARN [$task_id] $field: $message"
  ((WARN_COUNT++)) || true
}

pass() {
  ((PASS_COUNT++)) || true
}

# ── Check a single task file ──────────────────────────────────────────────────
check_task() {
  local file="$1"
  local task_id
  task_id=$(python3 -c "import yaml; f=open('$file'); d=yaml.safe_load(f); print(d.get('task_id','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")

  echo "Checking $task_id ($file)..."

  # ── BASIC REQUIRED FIELDS (original standard) ────────────────────────────
  local basic_required_strings=(schema_version phase task_id title owner_role status implementation_plan implementation_log)
  for field in "${basic_required_strings[@]}"; do
    if check_string_nonempty "$task_id" "$field" "$file"; then
      pass
    else
      fail "$task_id" "$field" "Required string field is missing or empty"
    fi
  done

  local basic_required_lists=(touches verification evidence failure_modes)
  for field in "${basic_required_lists[@]}"; do
    if check_list_nonempty "$task_id" "$field" "$file"; then
      pass
    else
      fail "$task_id" "$field" "Required list field is empty (hollow task)"
    fi
  done

  # ── STRICT MODE ADDITIONAL CHECKS (v2 standard) ──────────────────────────
  if [[ "$MODE" == "strict" ]]; then

    # intent: required, min 50 chars
    local intent_len
    intent_len=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = str(d.get('intent', ''))
print(len(v.strip()))
" 2>/dev/null || echo "0")
    if [[ "$intent_len" -ge 50 ]]; then
      pass
    else
      fail "$task_id" "intent" "Missing or too short (got ${intent_len} chars, need >= 50). Describe the problem, risk, and why now."
    fi

    # anti_patterns: required, min 2
    if check_list_min "$task_id" "anti_patterns" 2 "$file"; then
      pass
    else
      fail "$task_id" "anti_patterns" "Must have >= 2 named anti-patterns (governance theater prevention)"
    fi

    # work: required, min 3
    if check_list_min "$task_id" "work" 3 "$file"; then
      pass
    else
      fail "$task_id" "work" "Must have >= 3 work items (each atomic and verifiable)"
    fi

    # acceptance_criteria: required, min 2
    if check_list_min "$task_id" "acceptance_criteria" 2 "$file"; then
      pass
    else
      fail "$task_id" "acceptance_criteria" "Must have >= 2 acceptance criteria, each with CI gate reference"
    fi

    # negative_tests: required, min 1 with required:true
    local neg_count
    neg_count=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
tests = d.get('negative_tests', [])
req = [t for t in tests if isinstance(t, dict) and t.get('required') == True]
print(len(req))
" 2>/dev/null || echo "0")
    if [[ "$neg_count" -ge 1 ]]; then
      pass
    else
      fail "$task_id" "negative_tests" "Must have >= 1 negative test with required:true (proves exploit path is blocked)"
    fi

    # verification: required, min 3 commands
    if check_list_min "$task_id" "verification" 3 "$file"; then
      pass
    else
      fail "$task_id" "verification" "Must have >= 3 verification commands: verifier script + validate_evidence.py + pre_ci.sh"
    fi

    # evidence: must_include field required
    local evidence_ok
    evidence_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
evs = d.get('evidence', [])
if not evs:
    print('0')
    exit()
count = 0
for e in evs:
    if isinstance(e, dict) and 'must_include' in e and len(e['must_include']) >= 5:
        count += 1
    elif isinstance(e, str):
        count = -1  # bare string evidence — no contract
        break
print(count)
" 2>/dev/null || echo "0")
    if [[ "$evidence_ok" == "-1" ]]; then
      fail "$task_id" "evidence" "Evidence entries must be objects with 'path' and 'must_include' (>= 5 fields), not bare strings"
    elif [[ "$evidence_ok" -ge 1 ]]; then
      pass
    else
      fail "$task_id" "evidence" "Evidence must_include must have >= 5 fields (task_id, git_sha, timestamp_utc, status, checks + domain fields)"
    fi

    # failure_modes: min 2, consequence code format
    local fm_with_codes
    fm_with_codes=$(python3 -c "
import yaml, re
with open('$file') as f:
    d = yaml.safe_load(f)
fms = d.get('failure_modes', [])
codes = re.compile(r'=>\s*(FAIL|BLOCKED|CRITICAL_FAIL|FAIL_REVIEW)')
matched = [fm for fm in fms if isinstance(fm, str) and codes.search(fm)]
print(len(matched))
" 2>/dev/null || echo "0")
    if [[ "$fm_with_codes" -ge 2 ]]; then
      pass
    else
      fail "$task_id" "failure_modes" "Must have >= 2 failure modes using consequence code format: '<what goes wrong> => FAIL|BLOCKED|CRITICAL_FAIL|FAIL_REVIEW'"
    fi

    # priority enum check
    local priority_ok
    priority_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = str(d.get('priority', ''))
print('ok' if v in ['CRITICAL','HIGH','NORMAL','LOW'] else 'bad')
" 2>/dev/null || echo "bad")
    if [[ "$priority_ok" == "ok" ]]; then
      pass
    else
      fail "$task_id" "priority" "Must be one of: CRITICAL | HIGH | NORMAL | LOW"
    fi

    # risk_class enum check
    local rc_ok
    rc_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = str(d.get('risk_class', ''))
print('ok' if v in ['SECURITY','GOVERNANCE','INTEGRITY','PERFORMANCE','INFRASTRUCTURE'] else 'bad')
" 2>/dev/null || echo "bad")
    if [[ "$rc_ok" == "ok" ]]; then
      pass
    else
      fail "$task_id" "risk_class" "Must be one of: SECURITY | GOVERNANCE | INTEGRITY | PERFORMANCE | INFRASTRUCTURE"
    fi

    # blast_radius enum check
    local br_ok
    br_ok=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
v = str(d.get('blast_radius', ''))
print('ok' if v in ['DB_SCHEMA','APP_LAYER','CI_GATES','DOCS_ONLY','INFRA'] else 'bad')
" 2>/dev/null || echo "bad")
    if [[ "$br_ok" == "ok" ]]; then
      pass
    else
      fail "$task_id" "blast_radius" "Must be one of: DB_SCHEMA | APP_LAYER | CI_GATES | DOCS_ONLY | INFRA"
    fi

    # must_read: always has AI_AGENT_OPERATION_MANUAL.md
    local has_manual
    has_manual=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
mr = d.get('must_read', [])
print('ok' if any('AI_AGENT_OPERATION_MANUAL' in str(r) for r in mr) else 'missing')
" 2>/dev/null || echo "missing")
    if [[ "$has_manual" == "ok" ]]; then
      pass
    else
      warn "$task_id" "must_read" "docs/operations/AI_AGENT_OPERATION_MANUAL.md should always be first in must_read"
    fi

    # ── GREEN FINANCE PILOT CONTAINMENT CHECKS ───────────────────────────────
    # Applies to tasks tagged domain: green_finance OR pilot: true
    local is_green_task
    is_green_task=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
domain = str(d.get('domain', ''))
pilot  = d.get('pilot', False)
print('yes' if domain == 'green_finance' or str(pilot).lower() == 'true' else 'no')
" 2>/dev/null || echo "no")

    if [[ "$is_green_task" == "yes" ]]; then

      # second_pilot_test must be present, non-trivial, and name two sectors
      local spt_len spt_val
      spt_val=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
print(str(d.get('second_pilot_test', '')).strip())
" 2>/dev/null || echo "")
      spt_len=${#spt_val}

      if [[ "$spt_len" -lt 80 ]]; then
        fail "$task_id" "second_pilot_test" \
          "Green finance task missing or too-brief second_pilot_test (got ${spt_len} chars). Must explicitly name two unrelated sectors and explain why the design works for both."
      else
        # Reject generic single-word answers
        local spt_lower
        spt_lower=$(echo "$spt_val" | tr '[:upper:]' '[:lower:]')
        if echo "$spt_lower" | grep -qE "^(yes|true|n/a|not applicable|applies to all)$"; then
          fail "$task_id" "second_pilot_test" \
            "second_pilot_test is a placeholder answer. Must describe the design working for two concrete different sectors by name."
        else
          pass
        fi
      fi

      # pilot_scope_ref: green tasks must reference a SCOPE.md
      local has_scope_ref
      has_scope_ref=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
ref = str(d.get('pilot_scope_ref', ''))
print('ok' if 'SCOPE.md' in ref or 'PILOT_' in ref else 'missing')
" 2>/dev/null || echo "missing")
      if [[ "$has_scope_ref" == "ok" ]]; then
        pass
      else
        fail "$task_id" "pilot_scope_ref" \
          "Green finance task must reference its pilot SCOPE.md via pilot_scope_ref field (e.g. docs/pilots/PILOT_PWRM001/SCOPE.md)"
      fi

      # must_read: green tasks must include AGENTIC_SDLC_PILOT_POLICY.md
      local has_pilot_policy
      has_pilot_policy=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
mr = d.get('must_read', [])
print('ok' if any('AGENTIC_SDLC_PILOT_POLICY' in str(r) for r in mr) else 'missing')
" 2>/dev/null || echo "missing")
      if [[ "$has_pilot_policy" == "ok" ]]; then
        pass
      else
        fail "$task_id" "must_read" \
          "Green finance tasks must include docs/operations/AGENTIC_SDLC_PILOT_POLICY.md in must_read"
      fi

      # must_read: green tasks must include PILOT_REJECTION_PLAYBOOK.md
      local has_playbook
      has_playbook=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
mr = d.get('must_read', [])
print('ok' if any('PILOT_REJECTION_PLAYBOOK' in str(r) for r in mr) else 'missing')
" 2>/dev/null || echo "missing")
      if [[ "$has_playbook" == "ok" ]]; then
        pass
      else
        fail "$task_id" "must_read" \
          "Green finance tasks must include docs/operations/PILOT_REJECTION_PLAYBOOK.md in must_read"
      fi

      # No sector nouns in task_id or title
      local sector_in_title
      sector_in_title=$(python3 -c "
import yaml, re
with open('$file') as f:
    d = yaml.safe_load(f)
text = (str(d.get('task_id','')) + ' ' + str(d.get('title',''))).lower()
nouns = ['solar_','plastic_','forestry_','agriculture_','mining_','pwrm_',
         'collection_','recycling_','forest_carbon','mine_site','waste_collection']
found = [n for n in nouns if n in text]
print(','.join(found) if found else 'ok')
" 2>/dev/null || echo "ok")
      if [[ "$sector_in_title" == "ok" ]]; then
        pass
      else
        fail "$task_id" "task_id/title" \
          "Sector nouns found in task_id or title: ${sector_in_title}. Phase 0/1 task identifiers must use neutral platform nouns."
      fi

    fi  # end green task checks

  fi  # end strict mode
}

# ── Main: collect files to check ─────────────────────────────────────────────
echo "Symphony Task Meta Schema Verifier (mode: $MODE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -n "$TARGET_TASK" ]]; then
  FILES=("$TASK_ROOT/$TARGET_TASK/meta.yml")
else
  mapfile -t FILES < <(find "$TASK_ROOT" -name "meta.yml" | grep -v "_template" | sort)
fi

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    check_task "$file"
  else
    echo "WARNING: $file not found, skipping"
  fi
done

# ── Emit evidence ─────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$EVIDENCE_OUT")"

GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

VIOLATIONS_JSON="["
for i in "${!VIOLATIONS[@]}"; do
  VIOLATIONS_JSON+="${VIOLATIONS[$i]}"
  [[ $i -lt $((${#VIOLATIONS[@]} - 1)) ]] && VIOLATIONS_JSON+=","
done
VIOLATIONS_JSON+="]"

cat > "$EVIDENCE_OUT" <<EOF
{
  "task_id": "TASK-META-SCHEMA-VERIFIER",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP",
  "mode": "$MODE",
  "status": "$([ $FAIL_COUNT -eq 0 ] && echo PASS || echo FAIL)",
  "checks": [
    {
      "id": "schema-conformance",
      "description": "All task meta.yml files pass v2 schema requirements",
      "status": "$([ $FAIL_COUNT -eq 0 ] && echo PASS || echo FAIL)",
      "details": {
        "tasks_checked": $((PASS_COUNT + FAIL_COUNT)),
        "pass_count": $PASS_COUNT,
        "fail_count": $FAIL_COUNT,
        "warn_count": $WARN_COUNT
      }
    }
  ],
  "violations": $VIOLATIONS_JSON,
  "tasks_checked": $((PASS_COUNT + FAIL_COUNT)),
  "pass_count": $PASS_COUNT,
  "fail_count": $FAIL_COUNT,
  "warn_count": $WARN_COUNT
}
EOF

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:        $MODE"
echo "Tasks:       $((PASS_COUNT + FAIL_COUNT))"
echo "Pass checks: $PASS_COUNT"
echo "Violations:  $FAIL_COUNT"
echo "Warnings:    $WARN_COUNT"
echo "Evidence:    $EVIDENCE_OUT"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo ""
  echo "STATUS: FAIL — $FAIL_COUNT violation(s) found."
  echo "Fix all violations before assigning tasks to agents."
  echo "Reference: docs/operations/TASK_AUTHORING_STANDARD_v2.md"
  exit 1
else
  echo ""
  echo "STATUS: PASS"
  exit 0
fi
