# GF-W1-UI-001 PLAN — Delete symphony_ui and establish clean CSS baseline

Task: GF-W1-UI-001
Owner: SUPERVISOR
Depends on: pilot-demo-seeding-fix
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-001.CSS_BASELINE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Delete the abandoned `symphony_ui/` directory and establish the canonical CSS design
system in `src/supervisory-dashboard/index.html`. When this task closes, the `:root`
block contains exactly the 17 CSS tokens from the steering file, the page has no
viewport-level scrollbar, and no file in the repository references `symphony_ui/`.
This creates the foundation for all subsequent UI tasks.

---

## Architectural Context

This is the first task in the GF-W1 UI chain. All 9 subsequent tasks depend on the
CSS token system being established here. The `symphony_ui/` directory was a discarded
Next.js skeleton that must be removed to prevent confusion.

---

## Pre-conditions

- [x] pilot-demo-seeding-fix is status=completed (tenant and worker seeding works)
- [x] .kiro/steering/ui-canonical-design.md exists and defines CSS tokens
- [x] .kiro/specs/symphony-ui-canonical/ exists with requirements.md, design.md, tasks.md
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, financial constants, resolveNeighbourhoodLabel, prohibitions
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity, GPS rules, payload shape
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, C# patterns
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — 5 requirements, 28 acceptance criteria
5. `.kiro/specs/symphony-ui-canonical/design.md` — Layout wireframes, financial computations
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 1 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `symphony_ui/` | DELETE | Discarded Next.js skeleton — must not exist |
| `src/supervisory-dashboard/index.html` | MODIFY | Ensure :root contains all 17 CSS tokens |
| `tasks/GF-W1-UI-001/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_001.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If symphony_ui/ directory still exists** → STOP
- **If any of the 17 CSS tokens is missing from :root** → STOP
- **If viewport-level scrollbar is visible** → STOP
- **If any node in the proof graph is orphaned** → STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** → STOP

---

## Implementation Steps

### Step 1: Delete symphony_ui/
**What:** `[ID gf_w1_ui_001_work_01]` Delete the directory `symphony_ui/` entirely.
**How:** `rm -rf symphony_ui/`
**Done when:** `test ! -d symphony_ui` exits 0.

### Step 2: Establish CSS tokens
**What:** `[ID gf_w1_ui_001_work_02]` Ensure `:root {}` contains exactly the 17 tokens from `.kiro/steering/ui-canonical-design.md`.
**How:** Open `src/supervisory-dashboard/index.html`, locate `:root { }`, add any missing tokens verbatim from steering file.
**Done when:** `grep -c '\-\-' src/supervisory-dashboard/index.html` returns ≥ 17 token matches.

### Step 3: Confirm overflow hidden
**What:** `[ID gf_w1_ui_001_work_03]` Confirm `<html>` and `<body>` have `overflow: hidden`.
**How:** Add or verify `overflow: hidden` on both elements.
**Done when:** `grep -q 'overflow.*hidden' src/supervisory-dashboard/index.html` exits 0.

### Step 4: Emit evidence
**What:** Run verifier and write evidence JSON.
**How:**
```bash
# [ID gf_w1_ui_001_work_01] [ID gf_w1_ui_001_work_02] [ID gf_w1_ui_001_work_03]
test ! -d symphony_ui && grep -q "\-\-bg" src/supervisory-dashboard/index.html \
  && grep -q "\-\-bright" src/supervisory-dashboard/index.html \
  && grep -q "overflow.*hidden" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "\-\-body" \
  > evidence/phase1/gf_w1_ui_001.json || exit 1
```
**Done when:** Evidence JSON exists and contains CSS token data.

---

## Verification

```bash
# [ID gf_w1_ui_001_work_01] [ID gf_w1_ui_001_work_02] [ID gf_w1_ui_001_work_03]
test ! -d symphony_ui && grep -q "\-\-bg" src/supervisory-dashboard/index.html \
  && grep -q "\-\-bright" src/supervisory-dashboard/index.html \
  && grep -q "overflow.*hidden" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "\-\-body" \
  > evidence/phase1/gf_w1_ui_001.json || exit 1

# [ID gf_w1_ui_001_work_01]
test -z "$(grep -r 'symphony_ui' src/ .kiro/ || true)" || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_001.json`

Required fields:
- `task_id`: "GF-W1-UI-001"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `observed_paths`: files inspected
- `observed_hashes`: SHA256 of inspected files
- `command_outputs`: raw command output
- `execution_trace`: step-by-step execution record
- `css_tokens_verified`: list of verified token names

---

## Rollback

1. Restore `symphony_ui/` from git history: `git checkout HEAD -- symphony_ui/`
2. Revert CSS token changes: `git checkout HEAD -- src/supervisory-dashboard/index.html`
3. Update status back to `planned` in meta.yml

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| symphony_ui/ still exists | CRITICAL_FAIL | `test ! -d` verification |
| CSS token missing | FAIL | grep for all 17 token names |
| Viewport scrollbar | FAIL | grep for overflow:hidden |
