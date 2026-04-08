# GF-W1-UI-009 PLAN — Wire Program.cs to serve canonical recipient landing page

Task: GF-W1-UI-009
Owner: SUPERVISOR
Depends on: GF-W1-UI-008
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-009.PROGRAMCS_WIRING_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Change the GET /pilot-demo/evidence-link route in Program.cs to serve the new
`src/recipient-landing/index.html` instead of `index-2.html`. One-line file path change.
No other modifications to Program.cs.

---

## Pre-conditions

- [ ] GF-W1-UI-008 is status=completed (canonical recipient landing page exists)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — Canonical file paths
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, route conventions
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirement 4.6
5. `.kiro/specs/symphony-ui-canonical/design.md` — Route mapping
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 9 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Change file path for evidence-link route |
| `tasks/GF-W1-UI-009/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_009.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If Program.cs still references index-2.html for evidence-link route** → STOP
- **If any changes to Program.cs beyond the file path** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Change file path
**What:** `[ID gf_w1_ui_009_work_01]` Change file path in evidence-link route handler.
**How:** Find `GET /pilot-demo/evidence-link` route. Change `index-2.html` to `index.html` in the file path. No other changes.
**Done when:** `grep -q "index.html"` succeeds and `grep "index-2.html"` finds zero matches in evidence-link context.

### Step 2: Emit evidence
```bash
# [ID gf_w1_ui_009_work_01]
test -f services/ledger-api/dotnet/src/LedgerApi/Program.cs \
  && grep -q "index.html" services/ledger-api/dotnet/src/LedgerApi/Program.cs \
  && cat services/ledger-api/dotnet/src/LedgerApi/Program.cs \
  | grep "evidence-link" \
  > evidence/phase1/gf_w1_ui_009.json || exit 1

# [ID gf_w1_ui_009_work_01] — negative test
test -z "$(grep 'index-2.html' services/ledger-api/dotnet/src/LedgerApi/Program.cs | grep 'evidence-link')" \
  || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_009_work_01]
test -f services/ledger-api/dotnet/src/LedgerApi/Program.cs \
  && grep -q "index.html" services/ledger-api/dotnet/src/LedgerApi/Program.cs \
  && cat services/ledger-api/dotnet/src/LedgerApi/Program.cs \
  | grep "evidence-link" \
  > evidence/phase1/gf_w1_ui_009.json || exit 1

# [ID gf_w1_ui_009_work_01]
test -z "$(grep 'index-2.html' services/ledger-api/dotnet/src/LedgerApi/Program.cs | grep 'evidence-link')" \
  || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_009.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace

---

## Rollback

1. Revert: `git checkout HEAD -- services/ledger-api/dotnet/src/LedgerApi/Program.cs`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Still serves index-2.html | FAIL | Negative grep test |
| Other Program.cs changes | FAIL | Diff check for scope |
