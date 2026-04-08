# GF-W1-UI-010 PLAN — End-to-end verification script

Task: GF-W1-UI-010
Owner: SUPERVISOR
Depends on: GF-W1-UI-006, GF-W1-UI-009
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-010.E2E_SCRIPT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create `scripts/dev/verify_ui_e2e.sh` — a curl-only E2E script that submits a complete
WEIGHBRIDGE_RECORD through the real backend, verifies the monitoring report updates, and
confirms the supervisory reveal shows the correct artifact. Four checks (A-D) must all
PASS. No Python, no Node.js — curl only.

---

## Pre-conditions

- [ ] GF-W1-UI-006 is status=completed (monitoring report tab exists)
- [ ] GF-W1-UI-009 is status=completed (Program.cs wired to canonical landing page)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — API endpoints
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity, payload shape
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, port 5001
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirement 5.1
5. `.kiro/specs/symphony-ui-canonical/design.md` — E2E flow
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 10 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/dev/verify_ui_e2e.sh` | CREATE | E2E curl verification script |
| `evidence/phase1/ui_e2e_verification.json` | CREATE | E2E evidence (written by script) |
| `evidence/phase1/gf_w1_ui_010.json` | CREATE | Task evidence artifact |
| `tasks/GF-W1-UI-010/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If script uses anything other than curl for HTTP calls** → STOP
- **If script does not write evidence JSON** → STOP
- **If script exits 0 when any check fails** → STOP (CRITICAL_FAIL)
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Create script shell
**What:** `[ID gf_w1_ui_010_work_01]` Create scripts/dev/verify_ui_e2e.sh using curl only.
**How:** Set env vars, prepare isolated test state, target localhost:5001.
**Done when:** Script exists and is executable, uses curl.

### Step 2: Issue token and submit evidence
**What:** `[ID gf_w1_ui_010_work_02]` Issue evidence link token and submit WEIGHBRIDGE_RECORD.
**How:** POST /v1/evidence-links/issue with WASTE_COLLECTOR, Chunga GPS, test instruction_id. Extract token. POST /v1/evidence-links/submit with PET payload (gross=14.2, tare=1.8, net=12.4).
**Done when:** curl commands for both endpoints present.

### Step 3: Run four checks
**What:** `[ID gf_w1_ui_010_work_03]` Implement checks A-D.
**How:** Check A: HTTP 202. Check B: monitoring-report PET > 0. Check C: TOTAL > 0, additionality > 0. Check D: reveal contains WEIGHBRIDGE_RECORD.
**Done when:** All four check assertions present.

### Step 4: Write evidence and exit
**What:** `[ID gf_w1_ui_010_work_04]` Write evidence JSON and exit appropriately.
**How:** Write to evidence/phase1/ui_e2e_verification.json with per-check PASS/FAIL. Exit 0 if all pass, exit 1 if any fail.
**Done when:** Evidence path and exit logic present.

### Step 5: Emit task evidence
```bash
# [ID gf_w1_ui_010_work_01] [ID gf_w1_ui_010_work_02]
# [ID gf_w1_ui_010_work_03] [ID gf_w1_ui_010_work_04]
test -x scripts/dev/verify_ui_e2e.sh \
  && grep -q "curl" scripts/dev/verify_ui_e2e.sh \
  && grep -q "ui_e2e_verification" scripts/dev/verify_ui_e2e.sh \
  && cat scripts/dev/verify_ui_e2e.sh | grep "WEIGHBRIDGE_RECORD" \
  > evidence/phase1/gf_w1_ui_010.json || exit 1

# [ID gf_w1_ui_010_work_01] — negative test
test -z "$(grep -E 'python|node |npm' scripts/dev/verify_ui_e2e.sh)" \
  || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_010_work_01] [ID gf_w1_ui_010_work_02]
# [ID gf_w1_ui_010_work_03] [ID gf_w1_ui_010_work_04]
test -x scripts/dev/verify_ui_e2e.sh \
  && grep -q "curl" scripts/dev/verify_ui_e2e.sh \
  && grep -q "ui_e2e_verification" scripts/dev/verify_ui_e2e.sh \
  && cat scripts/dev/verify_ui_e2e.sh | grep "WEIGHBRIDGE_RECORD" \
  > evidence/phase1/gf_w1_ui_010.json || exit 1

# [ID gf_w1_ui_010_work_01]
test -z "$(grep -E 'python|node |npm' scripts/dev/verify_ui_e2e.sh)" \
  || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_010.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace

---

## Rollback

1. Delete: `rm scripts/dev/verify_ui_e2e.sh`
2. Delete: `rm evidence/phase1/ui_e2e_verification.json`
3. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Script exits 0 on failure | CRITICAL_FAIL | grep for exit logic |
| Uses non-curl tools | FAIL | Negative grep for python/node |
| Evidence not written | FAIL | grep for evidence path |
