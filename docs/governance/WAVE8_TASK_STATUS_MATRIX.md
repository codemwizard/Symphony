# Wave 8 Task Status Matrix

**Status:** Evidence-Backed Classification (100% Complete)
**Date:** 2026-05-05
**Related Tasks:** TSK-P2-W8-GOV-001

## Classification Criteria

Tasks are classified based on evidence-backed completion status, not inherited status text or planning claims.

### Categories

- **Scaffold**: Task pack exists but has no implementation or verification evidence.
- **Partial**: Task has some implementation but fails verification or lacks required evidence.
- **True-Complete**: Task has full implementation, passes all verifiers, and has complete evidence artifacts.

## Legacy Wave 8 Artifacts Classification

### TSK-P2-REG-* Tasks (Wave 8 Regulatory Extensions)

| Task ID | Classification | Evidence Basis | Notes |
|---------|---------------|----------------|-------|
| TSK-P2-REG-001-00 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-001-01 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-001-02 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-002-00 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-002-01 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-002-02 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-00 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-01 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-02 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-03 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-04 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-05 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-06 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-003-07 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-004-00 | Scaffold | No implementation evidence | Planning only |
| TSK-P2-REG-004-01 | Scaffold | No implementation evidence | Planning only |

### Current TSK-P2-W8-* Tasks (Evidence-Based Classification)

**Fully Implemented Tasks (23/23)**

| Task ID | Classification | Evidence Basis | Notes |
|---------|---------------|----------------|-------|
| TSK-P2-W8-GOV-001 | True-Complete | ADRs, truth table, and rubric exist and are verified | Governance truth established |
| TSK-P2-W8-ARCH-001 | True-Complete | Contract documented and verified | Canonical attestation payload contract functional |
| TSK-P2-W8-ARCH-002 | True-Complete | Contract documented and verified | Signer cross-bind contract functional |
| TSK-P2-W8-ARCH-003 | True-Complete | Contract documented and verified | Context-binding contract functional |
| TSK-P2-W8-ARCH-004 | True-Complete | Contract documented and verified | Evidence-admissibility contract functional |
| TSK-P2-W8-ARCH-005 | True-Complete | Contract documented and verified | Dispatcher-topology contract functional |
| TSK-P2-W8-ARCH-006 | True-Complete | Contract documented and verified | SQLSTATE error mapping contract functional |
| TSK-P2-W8-SEC-000 | True-Complete | .NET 10 environment fidelity proven, semantic fidelity proven | Environment and primitive honesty functional |
| TSK-P2-W8-SEC-001 | True-Complete | Verification primitive implemented, contract bytes verified | Cryptographic primitive functional |
| TSK-P2-W8-SEC-002 | True-Complete | PostgreSQL extension built, installed, and verified | Real Ed25519 implementation with libsodium |
| TSK-P2-W8-DB-001 | True-Complete | Migration 0172, dispatcher topology verification passed | Dispatcher topology enforcement functional |
| TSK-P2-W8-DB-002 | True-Complete | Migration 0173, signer cross-bind verification passed | Signer cross-bind enforcement functional |
| TSK-P2-W8-DB-003 | True-Complete | Migration 0174, payload schema verification passed | Payload schema enforcement functional |
| TSK-P2-W8-DB-004 | True-Complete | Migration 0175, canonicalization verification passed | Canonicalization enforcement functional |
| TSK-P2-W8-DB-005 | True-Complete | Migration 0176, SQLSTATE mapping verification passed | Error mapping enforcement functional |
| TSK-P2-W8-DB-006 | True-Complete | Migration 0177, trigger enforcement, verification passed | Database cryptographic enforcement functional |
| TSK-P2-W8-DB-007a | True-Complete | Migration 0178, signature verification, verification passed | Signature verification functional |
| TSK-P2-W8-DB-007b | True-Complete | Migration 0178, timestamp enforcement, verification passed | Scope and timestamp enforcement functional |
| TSK-P2-W8-DB-007c | True-Complete | Migration 0178, replay prevention, verification passed | Replay law enforcement functional |
| TSK-P2-W8-DB-008 | True-Complete | Migration 0179, audit log enforcement, verification passed | Audit logging functional |
| TSK-P2-W8-DB-009 | True-Complete | Migration 0180, context binding, verification passed | Context binding enforcement functional |
| TSK-P2-W8-QA-001 | True-Complete | Attestation test vectors verified across surfaces | Quality assurance functional |
| TSK-P2-W8-QA-002 | True-Complete | End-to-end attestation lifecycle verified | Integration testing functional |

### Legacy TSK-P2-W8-CRYPTO-* Tasks

| Task ID | Classification | Evidence Basis | Notes |
|---------|---------------|----------------|-------|
| (None found) | N/A | No legacy crypto tasks exist | No legacy crypto artifacts discovered |

### Superseded Tasks

| Task ID | Classification | Superseded By | Reason |
|---------|---------------|--------------|--------|
| TSK-P2-W8-DB-007 | Non-Executable | TSK-P2-W8-DB-007a, TSK-P2-W8-DB-007b, TSK-P2-W8-DB-007c | Split into domain-specific tasks per Wave 8 governance truth |

## Evidence Requirements for True-Complete Classification

A task may only be classified as "True-Complete" when:

1. All deliverables specified in the task's PLAN.md exist.
2. The task-specific verifier script passes.
3. Evidence file contains all required proof fields (task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace).
4. Regulated surface compliance is satisfied (if applicable).
5. Remediation trace compliance is satisfied (if applicable).
6. The task satisfies the Wave 8 Closure Rubric.

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_CLOSURE_RUBRIC.md
- WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md
- WALKTHROUGH_WAVE8_SEC_VERIFICATION.md
