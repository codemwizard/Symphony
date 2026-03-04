# _scratch — Unprocessed Working Notes

This directory holds working notes, session outputs, draft plans, and exploratory
documents that were produced during development but have not yet been reviewed,
classified, or migrated into the canonical documentation tree.

**This directory is gitignored.** Its contents are not committed to the repository.
Keep a local or shared copy (e.g. a shared drive or internal wiki) if the files
need to be preserved across machines.

---

## Purpose

A dedicated future task will parse these files to determine whether any content
should be used to create or update canonical workflows, ADRs, or operational docs.
Until that task runs, nothing in this directory should be treated as authoritative.

---

## Contents

| File | Type | Notes |
|---|---|---|
| `106-103_INV_IMP.txt` | .txt | Invariant implementation notes |
| `3-Pillar_Review.txt` | .txt | Three-pillar review session output |
| `AGENT_TASK_HISTORY.md` | .md | Agent task history log |
| `ai_agent_workflow_and_role_plan_v_2.md` | .md | Agent workflow draft (superseded by canonical ops docs) |
| `AI_AUTOMATION_STRATEGY_REVIEW.md` | .md | Automation strategy review draft |
| `AuditAnswers.txt` | .txt | Audit Q&A session output |
| `Business-Hook_Delta_resolution.txt` | .txt | Business hook delta resolution notes |
| `BusinessInvariantsAddition.txt` | .txt | Business invariants addition session notes |
| `BusinessModelSummary.txt` | .txt | Business model summary draft |
| `BUSINESS_FOUNDATION_HOOKS.md` | .md | Business foundation hooks draft |
| `CI_Noise_Reduction_Option.txt` | .txt | CI noise reduction options explored |
| `client-tenant_schema_migration.txt` | .txt | Client-tenant schema migration notes |
| `client-tenant_schema_migration_approval.txt` | .txt | Migration approval session notes |
| `Closed-Loop-Requirements_From-Logical_Architectural_Diagram-2.txt` | .txt | Requirements extraction from architecture diagram |
| `Codex-prompt-rebuttal.txt` | .txt | Codex prompt rebuttal/refinement notes |
| `conformanceScripts.txt` | .txt | Conformance script exploration notes |
| `Cursor-agentic-setup_Architect-agent-prompt_V2.txt` | .txt | Cursor architect agent prompt draft |
| `Debugprocess.txt` | .txt | Debug process session notes |
| `DETECT_MAP.md` | .md | Detection mapping draft |
| `FutureHardening.txt` | .txt | Future hardening ideas (batch 1) |
| `FutureHardening2.txt` | .txt | Future hardening ideas (batch 2) |
| `GitHub_CI_Diag.txt` | .txt | GitHub CI diagnostics session output |
| `gitpush.txt` | .txt | Git push workflow notes |
| `IMPLEMENTATION.md` | .md | Implementation notes draft |
| `Phase0LeftOvers.txt` | .txt | Phase-0 leftover items noted during closeout |
| `Phase0_Audit-Gap_Closeout_Plan_Draft.txt` | .txt | Phase-0 audit gap closeout plan draft |
| `Phase1-Draft_Plan.md` | .md | Phase-1 draft plan (pre-canonical) |
| `PHASE1_AI_AGENT_ORCHESTRATION_STRATEGY.md` | .md | Phase-1 agent orchestration strategy draft |
| `PHASE1_CODEX_PROMPT_PACK_v2.md` | .md | Phase-1 Codex prompt pack draft |
| `Planned-Skipped_Gates.txt` | .txt | Planned/skipped gates session notes |
| `Product-Requirement-Document_V2.txt` | .txt | Product requirements document draft |
| `prompt.txt` | .txt | Miscellaneous prompt notes |
| `Proxy_Request_Invariant.txt` | .txt | Proxy request invariant notes |
| `PROXY_RESOLUTION_INTEGRATION_REVIEW.md` | .md | Proxy resolution integration review draft |
| `Soverign-Hybrid-Cloud_Refinement-Draft.md` | .md | Sovereign hybrid cloud refinement draft |
| `sqlstates_mapping.md` | .md | SQLSTATE mapping scratch notes |
| `Symphony_BusinessPlan_Implementation.txt` | .txt | Business plan implementation notes |
| `Symphony_Client-Tenant_Invariants.txt` | .txt | Client-tenant invariants session notes |

---

## What to do with these files

When the scratch-parsing task runs, for each file ask:

1. **Is this content already captured in a canonical doc?** If yes, discard.
2. **Does this contain decisions, constraints, or processes not yet documented?**
   If yes, create or update the appropriate doc under `docs/` and discard the scratch file.
3. **Is this a useful historical reference only?** If yes, consider moving it to
   `docs/audits/` with a clear date prefix. Otherwise discard.
4. **Is this pure noise / session transcript?** Discard.

Do not move files from `_scratch/` into `docs/` without reviewing their content
against the canonical docs first.
