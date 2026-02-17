# Appendix A: Zambia Constraints -> Invariant Bindings (Phase-1)

Date: 2026-02-16
Owner: Architecture / Platform
Policy authority: `docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md`

## 1) Role of This Document
This is a constraint-binding appendix.

It does not define process policy. It maps market/regional realities to enforceable engineering bindings.

## 2) Binding Rule (Mandatory)
No row may contain vague placeholders like "to be introduced" unless all of the following are present:
1. `new_invariant_ids`
2. `reserved_gate_ids`
3. `reserved_verifier_paths`
4. `reserved_evidence_paths`
5. `implementing_task_ids`

If any are missing, the row is invalid.

## 3) Current Scope
This appendix is limited to Phase-1 constrained execution and existing implemented bindings.

It does not authorize broader product-surface expansion.

Diff parity status:
- True parity for parity-critical enforcement is already being implemented as range-only semantics.
- Established baseline: `TSK-P0-152`, `TSK-P0-154`, `TSK-P0-155`.
- Active Phase-1 hardening follow-on: `TSK-P1-027`.

## 4) Binding Matrix (Existing, Active)
| constraint_id | constraint | invariant_ids | gate_ids | verifier_commands | evidence_paths | owner_role | phase_target | binding_status |
|---|---|---|---|---|---|---|---|---|
| CZM-001 | Transaction reliability under intermittent network/power must not create duplicate side effects | `INV-011`,`INV-012`,`INV-013`,`INV-014` | Existing DB verification chain in CI/pre-CI | `bash scripts/db/tests/test_idempotency_zombie.sh` and `bash scripts/db/verify_invariants.sh` | `evidence/phase0/idempotency_zombie.json` and `evidence/phase0/outbox_mvcc_posture.json` | Platform/DB | P0/P1 | ACTIVE |
| CZM-002 | Regulator-facing finality posture must be deterministic and non-mutable post-terminal | `INV-114` | `INT-G25` | `bash scripts/db/verify_instruction_finality_invariant.sh` | `evidence/phase1/instruction_finality_invariant.json` | Runtime/DB | P1 | ACTIVE |
| CZM-003 | PII decoupling + erasure survivability must preserve operational integrity | `INV-115` | `INT-G26` | `bash scripts/db/verify_pii_decoupling_hooks.sh` | `evidence/phase1/pii_decoupling_invariant.json` | Security/Compliance | P1 | ACTIVE |
| CZM-004 | Rail truth-anchor continuity must be enforceable and auditable | `INV-116` | `INT-G27` | `bash scripts/db/verify_rail_sequence_truth_anchor.sh` | `evidence/phase1/rail_sequence_truth_anchor.json` | Runtime/DB | P1 | ACTIVE |
| CZM-005 | Governance and approval traceability for regulated-surface changes must remain enforceable | `INV-105`,`INV-077` | `INT-G28` | `bash scripts/audit/verify_agent_conformance.sh` and `bash scripts/audit/verify_evidence_harness_integrity.sh` and `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh` | `evidence/phase1/agent_conformance_architect.json` and `evidence/phase1/approval_metadata.json` and `evidence/phase1/phase1_contract_status.json` | Evidence/Audit | P1 | ACTIVE |

## 5) External Source Usage Rule for MCP-Assisted Tasks
When an agent task uses MCP/web sources and task meta marks `external_sources_used=true`, `PLAN.md` must include:

```yaml
sources:
  - url: "<source>"
    retrieved_at_utc: "<timestamp>"
    purpose: "<why needed>"
```

Verification requirement:
- Missing `sources:` block under this condition is policy non-compliance.

## 6) Reserved Binding Template (Future Work Only)
Use only when proposing new bindings; do not merge with blanks:

| constraint_id | new_invariant_ids | reserved_gate_ids | reserved_verifier_paths | reserved_evidence_paths | implementing_task_ids | phase_target |
|---|---|---|---|---|---|---|
| EXAMPLE | `INV-XXX` | `INT-GXX` | `scripts/...` | `evidence/phase1/...json` | `TSK-P1-...` | P1 |

## 7) Measurable Review Checklist
A reviewer can validate this appendix by checking:
1. Every ACTIVE row references existing invariant IDs.
2. Every ACTIVE row references existing verifier command paths.
3. Every ACTIVE row references evidence paths present in contracts/verifiers.
4. No row contains vague placeholders without full reservation metadata.

## 8) Source Anchors (Context Retrieval)
- Bank of Zambia directives index: https://www.boz.zm/directives.htm
- BOZ National Payment Systems Annual Report 2023: https://www.boz.zm/NPSAnnualReport2023.pdf
- ZECHL National Financial Switch overview: https://www.zechl.com.zm/national-financial-switch/
- Symphony Phase-1 contract: `docs/PHASE1/phase1_contract.yml`
- Symphony invariants manifest: `docs/invariants/INVARIANTS_MANIFEST.yml`

## 9) MCP Agent Rollout Tasks (Phase-1)
Planned rollout tasks:
1. `TSK-P1-028` MCP Architect Agent Bootstrap (policy-constrained, advisory-only).
2. `TSK-P1-029` MCP Implementer Agent Bootstrap (policy-constrained with non-bypass guardrails).
3. `TSK-P1-030` MCP Requirements & Policy Integrity Agent (third role; requirements-to-invariants/gates/evidence mapping and loophole hardening).
