# Verify Agent Conformance Specification

## Purpose
- Define deterministic checks performed by `scripts/audit/verify_agent_conformance.sh`.
- Ensure all Phase-1 regulated-surface operations reference `docs/operations/AI_AGENT_OPERATION_MANUAL.md` as the canonical authority.
- Enforce approval metadata requirements before regulated-surface changes are accepted.

## Canonical Inputs
- `AGENTS.md`
- `.codex/agents/*.md`
- `.cursor/agents/*.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`
- `docs/operations/AGENT_ROLE_RECONCILIATION.md`
- `docs/operations/approval_metadata.schema.json`
- `docs/operations/approval_sidecar.schema.json`

## Regulated Surface Definition
- The verifier reads regulated-surface path patterns from `AI_AGENT_OPERATION_MANUAL.md` section:
  `## Definitions (Phase-1 Regulated Surfaces)`.
- If no regulated-surface list is present, verification fails closed.

## Verification Rules
1. Canonical docs must exist and be non-empty.
2. Agent prompts must include canonical references:
   - `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`
   - `docs/operations/AGENT_ROLE_RECONCILIATION.md`
3. Agent prompts must include required headings:
   - `Role`, `Scope`, `Non-Negotiables`, `Verification Commands`, `Evidence Outputs`, `Canonical References`
   - Plus at least one of: `Stop Conditions` or `Escalation`
4. Declared role must match the canonical role set.
5. If regulated surfaces changed, approval metadata is mandatory:
   - `evidence/phase1/approval_metadata.json` must exist.
   - Required fields: `ai.ai_prompt_hash`, `ai.model_id`, `human_approval.approver_id`, `human_approval.approval_artifact_ref`, `human_approval.change_reason`.
6. Approval markdown and sidecar must be cross-linked and value-consistent.
7. Potential raw-PII patterns in approval metadata must fail closed.

## Failure Codes
- `CONFORMANCE_001_CANONICAL_MISSING`
- `CONFORMANCE_002_PROMPT_HEADERS_MISSING`
- `CONFORMANCE_003_ROLE_INVALID`
- `CONFORMANCE_004_CANONICAL_REFERENCE_MISSING`
- `CONFORMANCE_005_STOP_CONDITIONS_INVALID`
- `CONFORMANCE_006_OPERATION_MANUAL_INVALID`
- `CONFORMANCE_007_APPROVAL_METADATA_MISSING`
- `CONFORMANCE_008_APPROVAL_METADATA_INVALID`
- `CONFORMANCE_009_APPROVAL_MARKDOWN_INVALID`
- `CONFORMANCE_010_APPROVAL_SIDECAR_INVALID`
- `CONFORMANCE_011_APPROVAL_MISMATCH`
- `CONFORMANCE_012_PII_LEAK_DETECTED`

## Output Contract
- Evidence output: `evidence/phase1/agent_conformance.json`
- Minimum required fields:
  - `schema_version`
  - `status`
  - `checked_at_utc`
  - `git_commit`
  - `regulated_surface_changes_detected`
  - `approval_required`
  - `approval_metadata_present`
  - `failures`

## Operational Modes
- Diff-aware mode is used when `BASE_REF` (or `GITHUB_BASE_REF`) is available.
- Full-scan fallback is used when no diff base is available.
- In both modes, conformance checks are fail-closed.
