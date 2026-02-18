# Phase-0 Execution Plan

## 1) Objectives and non-goals

### Objectives
- Assign `assigned_agent` in all Phase-0 task meta files based on project-level agent permissions in `.codex/agents/**`.
- Formalize the pager-gate approach so that all qualifying tasks use a consistent, mechanical validation pattern (schema + validator + evidence artifact + CI gate).
- Keep invariants-first posture and ensure no weakening of existing DB/security invariants.

### Non-goals
- No implementation of Phase-1/2 runtime services.
- No changes to DB migrations or runtime DDL.
- No edits to application code paths outside Phase-0 planning and guardrails.

## 2) Exact files/directories to touch

Planned edits (only):
- `tasks/TSK-P0-001/meta.yml`
- `tasks/TSK-P0-002/meta.yml`
- `tasks/TSK-P0-003/meta.yml`
- `tasks/TSK-P0-004/meta.yml`
- `tasks/TSK-P0-005/meta.yml`
- `tasks/TSK-P0-006/meta.yml`
- `tasks/TSK-P0-007/meta.yml`
- `tasks/TSK-P0-008/meta.yml`
- `tasks/TSK-P0-009/meta.yml`
- `tasks/TSK-P0-010/meta.yml`
- `tasks/TSK-P0-011/meta.yml`
- `tasks/TSK-P0-012/meta.yml`
- `tasks/TSK-P0-013/meta.yml`
- `tasks/TSK-P0-014/meta.yml`
- `tasks/TSK-P0-015/meta.yml`
- `tasks/TSK-P0-016/meta.yml`
- `tasks/TSK-P0-017/meta.yml`
- `tasks/TSK-P0-018/meta.yml`
- `docs/tasks/PHASE0_TASKS.md`

No other files will be modified.

## 3) Step-by-step tasks (execution order)

1) Map tasks to agents using project-level agent definitions:
   - Source: `.codex/agents/*.md` for allowed paths.
   - Output: assign `assigned_agent` in each `tasks/TSK-P0-###/meta.yml`.

2) Apply consistent pager-gate pattern to all qualifying tasks:
   - Qualifying tasks: those that introduce or enforce a guardrail via docs/policy/rules files (routing fallback, batching rules, evidence schema, compliance/threat linkage).
   - Pattern: require file + validate schema + emit evidence + CI fails on invalid input.

3) Update task entries in `docs/tasks/PHASE0_TASKS.md` if needed to reflect the pager-gate pattern uniformly (no new scope).

4) Update `tasks/TSK-P0-###/meta.yml` to:
   - set `assigned_agent` to the mapped agent name.
   - ensure `Work`, `Acceptance Criteria`, `Verification Commands`, `Evidence Artifact(s)`, `Failure Modes` are aligned to the pager-gate pattern where applicable.

## 4) New invariants needed and verification

Potential new invariants (if not already in task list):
- INV-028: Evidence schema validation (verify via `scripts/audit/validate_evidence_schema.sh`).
- INV-029: Evidence provenance required (verify via `scripts/audit/generate_evidence.sh` + schema validation).
- INV-030: Structural change linkage to threat/compliance docs (verify via `scripts/audit/enforce_change_rule.sh`).

Each new invariant must:
- be added to `docs/invariants/INVARIANTS_MANIFEST.yml` by the Invariants Curator later, not in this plan.
- reference a specific script/test that hard-fails when violated.

## 5) Existing invariants impacted (and proof we won’t weaken them)

Impacted invariants (indirect only):
- INV-001..INV-018: No changes planned to DB migrations, roles, or privileges.
- INV-008: SECURITY DEFINER search_path hardening remains untouched.

Proof of non-weakening:
- This plan only edits task metadata and Phase-0 task definitions; no code, DDL, or privilege changes.
- No scripts or CI gates are modified in this step.

## 6) Verification commands after each milestone

Milestone A (agent mapping + meta updates):
- No runtime commands required; verify by manual inspection of `tasks/TSK-P0-###/meta.yml`.

Milestone B (pager-gate alignment in task definitions):
- No runtime commands required; verify by manual inspection of `docs/tasks/PHASE0_TASKS.md`.

If desired post-change sanity check:
- `rg "assigned_agent" tasks/TSK-P0-* -g 'meta.yml'`

## 7) Rollback strategy (git checkpoints)

- Before edits: create a git checkpoint (optional) `git status` and `git diff` to confirm clean state.
- If rollback needed: `git checkout -- docs/tasks/PHASE0_TASKS.md tasks/TSK-P0-*/meta.yml`.

