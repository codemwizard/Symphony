# Wave 4-8 Task Pack Assessment

## Scope

This assessment reviews the extracted Wave 4-8 task collections using these canonical sources:
- `docs/plans/phase2/WAVE_IMPLEMENTATION_PLAN.md`
- `docs/plans/phase2/ATOMIC_TASK_BREAKDOWN_PLAN.md`
- `docs/tasks/phase2_pre_atomic_dag.yml`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md`
- `tasks/_template/meta.yml`
- `AGENT_ENTRYPOINT.md`
- `AGENTS.md`

The objective is to determine whether the current task packs faithfully represent the extracted work and whether they are ready to drive implementation without drift.

## Executive Summary

Wave 4-8 task IDs already exist in the repository, so no new task IDs were required to cover the extracted collections. The primary gap is not missing IDs; it is task-pack drift.

The main drift patterns are:
- task packs that exist by ID but do not semantically match the extracted wave definition
- task packs marked `completed` in `meta.yml` even though they are still scaffolding or planning artifacts
- `PLAN.md` and `EXEC_LOG.md` files that do not fully comply with the latest template/process rules
- DAG drift inside task metadata, especially where task packs reference nonexistent or superseded dependencies
- Phase 2 human task indexing that was incomplete before this assessment

## Wave-by-Wave Assessment

### Wave 4

Extracted collection:
- `TSK-P2-PREAUTH-004-00`
- `TSK-P2-PREAUTH-004-01`
- `TSK-P2-PREAUTH-004-02`

Assessment:
- All three IDs exist.
- The current packs are present but are not fully compliant with the latest task template/process.
- `TSK-P2-PREAUTH-004-00` treats the plan file itself as evidence rather than a proper evidence artifact, which is weaker than the current evidence-contract standard.
- The current `PLAN.md` files use older formatting and do not cleanly match the strict `PLAN_TEMPLATE.md` structure.
- The packs are adequate as scaffolds but should not be treated as implementation-complete task contracts.

Conclusion:
- Coverage by ID exists.
- Full implementation readiness is not yet established.

### Wave 5

Extracted collection:
- `TSK-P2-PREAUTH-005-00` through `TSK-P2-PREAUTH-005-08`

Assessment:
- All extracted IDs exist.
- The wave is structurally present and the sequencing matches the canonical DAG.
- This is the highest-risk wave, so the main concern is not missing IDs but whether each trigger task proves the exact trigger behavior, attachment point, failure code, and evidence freshness.
- The current packs appear closer to extracted intent than Waves 6 and 8, but they still need strict implementation-readiness review before being treated as execution contracts.

Conclusion:
- Coverage by ID exists.
- Task packs should be treated as planned scaffolds pending hardening and implementation proof.

### Wave 6

Extracted collection:
- `TSK-P2-PREAUTH-006A-00` through `TSK-P2-PREAUTH-006A-04`
- `TSK-P2-PREAUTH-006B-00` through `TSK-P2-PREAUTH-006B-04`
- `TSK-P2-PREAUTH-006C-00` through `TSK-P2-PREAUTH-006C-03`

Assessment:
- All extracted IDs exist.
- This wave has the most important semantic drift.
- The canonical extraction defines `006B-01` and `006B-02` around `derive_data_authority()` and `enforce_data_authority_integrity()` plus a separate verifier task and a separate MIGRATION_HEAD task.
- The current `006B-*` packs instead describe a different family of trigger functions, which means the IDs exist but do not faithfully implement the extracted group.
- The current `006C-*` packs also drift from the extracted handler-specific implementation defined in the atomic breakdown.
- Historical phantom references to `TSK-P2-PREAUTH-006B-05` show that Wave 6 has experienced DAG drift and should be normalized back to the canonical `006B-04 -> 006C-00` transition.
- Some Wave 6 packs assign work to `ARCHITECT` while touching application/runtime code paths that do not match the stricter agent/path authority in `AGENTS.md`.

Conclusion:
- Coverage by ID exists.
- Semantic alignment is not reliable for Wave 6.
- This wave needs a targeted task-pack rewrite before implementation should proceed.

### Wave 7

Extracted collection:
- `TSK-P2-PREAUTH-007-00` through `TSK-P2-PREAUTH-007-05`

Assessment:
- All extracted IDs exist.
- The overall wave structure matches the extracted collection.
- The main risks are governance-quality risks: runtime invariant ID assignment, exact invariant manifest field requirements, and correct CI wiring to the intended verifier entry points.
- Several packs appear plausible but still need enforcement-path confirmation against the canonical verifier names and evidence expectations.

Conclusion:
- Coverage by ID exists.
- The wave is reasonably aligned structurally, but still needs implementation-readiness hardening.

### Wave 8

Extracted collection:
- `TSK-P2-REG-001-00` through `TSK-P2-REG-001-02`
- `TSK-P2-REG-002-00` through `TSK-P2-REG-002-02`
- `TSK-P2-REG-004-00` through `TSK-P2-REG-004-01`
- `TSK-P2-REG-003-00` through `TSK-P2-REG-003-07`

Assessment:
- All extracted IDs exist.
- The current packs cover the expected IDs, but they show notable sequencing drift against the extracted migration story.
- The canonical extraction keeps the PostGIS spatial gate within migration `0125`, while the current packs fan that work out across `0126` through `0130` task descriptions.
- That difference is material because Wave 8 sequencing is tightly bound to forward-only migration governance and MIGRATION_HEAD expectations.
- The current packs therefore need normalization before a coding agent should treat them as authoritative contracts.

Conclusion:
- Coverage by ID exists.
- Wave 8 requires semantic reconciliation to the extracted migration sequencing before implementation begins.

## Missing Task Count

No missing task IDs were found for the extracted Wave 4-8 collections. The extracted groups are already represented in the repository by ID.

What was missing was:
- complete Phase 2 human-task indexing for all extracted Wave 4-8 tasks
- reliable semantic alignment between several existing task packs and the extracted canonical definitions
- consistent implementation-readiness quality across `meta.yml`, `PLAN.md`, and `EXEC_LOG.md`

## Coding-Agent Implementation Plan

A coding agent implementing Wave 4-8 should follow this order exactly:

1. Treat all Wave 4-8 packs as `planned` scaffolds until each pack passes a fresh readiness review.
2. Normalize Wave 6 task-pack semantics to the extracted `006A/006B/006C` breakdown before touching runtime code.
3. Normalize Wave 8 task-pack migration sequencing to the extracted `REG-*` breakdown before touching `schema/migrations/**`.
4. For each task in a wave:
   - verify `meta.yml` against `tasks/_template/meta.yml`
   - verify `PLAN.md` against `docs/contracts/templates/PLAN_TEMPLATE.md`
   - verify `EXEC_LOG.md` remains append-only and contains remediation markers when required
   - run `python3 scripts/audit/verify_plan_semantic_alignment.py --plan <PLAN> --meta <META>`
   - run `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy`
   - run `bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>`
5. Only after the pack is `resume-ready` should implementation proceed in DAG order.
6. For regulated-surface tasks, ensure approval metadata exists before writing regulated files.
7. Execute each task's verifier and emit fresh evidence before advancing to the next task.
8. Run `bash scripts/dev/pre_ci.sh` at the wave boundary after all tasks in that wave have passed their own verification.

## Priority Remediation Order

The recommended remediation order for task-pack correctness is:
- Wave 6 first, because it has the strongest semantic drift and DAG contamination risk.
- Wave 8 second, because migration sequencing and regulatory enforcement are tightly coupled.
- Wave 4 third, to harden the first wave in this requested scope before downstream implementation.
- Wave 7 fourth, to ensure invariant/CI wiring reflects the corrected lower layers.
- Wave 5 last within the assessment scope, because its task count is complete and its drift is less obvious from the current packs than Waves 6 and 8.

## Notes

Two source filenames named in the user request could not be located by exact name in the repository index during this assessment:
- `Tasks4-8-scaffolding.md`
- `wave6-implementation-instructions-8d2b89.md`

This assessment therefore used the in-repo canonical planning sources listed above rather than inventing content from unavailable files.
