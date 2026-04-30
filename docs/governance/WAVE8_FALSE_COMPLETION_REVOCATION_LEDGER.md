# Wave 8 False Completion Revocation Ledger

**Status:** Active
**Date:** 2026-04-29
**Related Tasks:** TSK-P2-W8-GOV-001

## Purpose

This ledger records Wave 8 completion claims that have been revoked due to failure to satisfy the Wave 8 Governance Truth (WAVE8_GOVERNANCE_REMEDIATION_ADR.md).

## Revocation Criteria

A completion claim is revoked if it fails any of the following:

1. **Boundary Violation**: Claims completion at a boundary other than `asset_batches`.
2. **Contract Drift**: Implementation drifts from contract-defined semantics.
3. **Advisory Fallback**: Uses advisory or warning-only behavior instead of fail-closed enforcement.
4. **Inadmissible Evidence**: Uses proof forms banned by the Wave 8 Evidence Admissibility Policy.
5. **Missing Evidence**: Lacks required proof-carrying evidence fields.
6. **Verification Failure**: Task verifier does not pass.
7. **Regulated Surface Violation**: Edits regulated surfaces without required approval metadata.

## Revoked Claims

### Legacy Wave 8 Regulatory Extensions (TSK-P2-REG-*)

| Task ID | Original Claim | Revocation Date | Revocation Reason | Evidence Basis |
|---------|----------------|-----------------|-------------------|----------------|
| TSK-P2-REG-001-00 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-001-01 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-001-02 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-002-00 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-002-01 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-002-02 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-00 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-01 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-02 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-03 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-04 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-05 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-06 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-003-07 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-004-00 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |
| TSK-P2-REG-004-01 | Planned implementation | 2026-04-29 | No implementation evidence, scaffold only | No evidence artifacts found |

### Superseded Tasks

| Task ID | Original Claim | Revocation Date | Revocation Reason | Evidence Basis |
|---------|----------------|-----------------|-------------------|----------------|
| TSK-P2-W8-DB-007 | Single monolithic DB-007 task | 2026-04-29 | Superseded by domain-specific split (007a/007b/007c) per Wave 8 governance truth | Split required for single enforcement domain compliance |

## Reinstatement Process

A revoked claim may be reinstated only if:

1. The task is re-implemented according to the Wave 8 Closure Rubric.
2. All deliverables specified in the task's PLAN.md are created.
3. The task-specific verifier passes.
4. Complete evidence artifacts are generated with all required fields.
5. Regulated surface and remediation trace compliance are satisfied (if applicable).
6. The task passes the Wave 8 Evidence Admissibility Policy.

## Audit Trail

- **2026-04-29**: Initial ledger created as part of TSK-P2-W8-GOV-001 implementation.
- **2026-04-29**: All TSK-P2-REG-* tasks revoked due to scaffold-only status.
- **2026-04-29**: TSK-P2-W8-DB-007 revoked due to supersession by domain-specific split.

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_TASK_STATUS_MATRIX.md
- WAVE8_CLOSURE_RUBRIC.md
- WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md
