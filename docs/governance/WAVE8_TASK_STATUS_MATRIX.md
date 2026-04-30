# Wave 8 Task Status Matrix

**Status:** Evidence-Backed Classification
**Date:** 2026-04-29
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

### Legacy TSK-P2-W8-CRYPTO-* Tasks

| Task ID | Classification | Evidence Basis | Notes |
|---------|---------------|----------------|-------|
| (None found) | N/A | No legacy crypto tasks exist | No legacy crypto artifacts discovered |

### Superseded Tasks

| Task ID | Classification | Superseded By | Reason |
|---------|---------------|--------------|--------|
| TSK-P2-W8-DB-007 | Non-Executable | TSK-P2-W8-DB-007a, TSK-P2-W8-DB-007b, TSK-P2-W8-DB-007c | Split into domain-specific tasks per Wave 8 governance truth |

## New Wave 8 Tasks (True Implementation Track)

| Task ID | Classification | Evidence Basis | Notes |
|---------|---------------|----------------|-------|
| TSK-P2-W8-GOV-001 | In Progress | This task creates governance truth | Currently implementing |
| TSK-P2-W8-ARCH-001 | Planned | Depends on GOV-001 | Not started |
| TSK-P2-W8-ARCH-002 | Planned | Depends on ARCH-001 | Not started |
| TSK-P2-W8-ARCH-003 | Planned | Depends on ARCH-001, ARCH-002 | Not started |
| TSK-P2-W8-ARCH-004 | Planned | Depends on ARCH-002, ARCH-003 | Not started |
| TSK-P2-W8-ARCH-005 | Planned | Depends on ARCH-002, ARCH-003, ARCH-004 | Not started |
| TSK-P2-W8-ARCH-006 | Planned | Depends on ARCH-002, ARCH-003, ARCH-004, ARCH-005 | Not started |
| TSK-P2-W8-SEC-000 | Planned | Depends on ARCH-003, ARCH-006 | Not started |
| TSK-P2-W8-SEC-001 | Planned | Depends on ARCH-003, ARCH-006, SEC-000 | Not started |
| TSK-P2-W8-DB-001 | Planned | Depends on ARCH-005 | Not started |
| TSK-P2-W8-DB-002 | Planned | Depends on DB-001, ARCH-002, ARCH-003 | Not started |
| TSK-P2-W8-DB-003 | Planned | Depends on ARCH-001, DB-001, DB-002 | Not started |
| TSK-P2-W8-DB-004 | Planned | Depends on ARCH-002, DB-003 | Not started |
| TSK-P2-W8-DB-005 | Planned | Depends on ARCH-003, ARCH-005 | Not started |
| TSK-P2-W8-DB-006 | Planned | Depends on DB-004, DB-005, SEC-001 | Not started |
| TSK-P2-W8-DB-007a | Planned | Depends on DB-006 | Not started |
| TSK-P2-W8-DB-007b | Planned | Depends on DB-006 | Not started |
| TSK-P2-W8-DB-007c | Planned | Depends on DB-006 | Not started |
| TSK-P2-W8-DB-008 | Planned | Depends on DB-006, DB-007a, DB-007b, DB-007c | Not started |
| TSK-P2-W8-DB-009 | Planned | Depends on DB-004, DB-006, DB-007a, DB-007b, DB-007c | Not started |
| TSK-P2-W8-QA-001 | Planned | Depends on DB-004, DB-006 | Not started |
| TSK-P2-W8-QA-002 | Planned | Depends on DB-006, DB-007a, DB-007b, DB-007c, DB-008, DB-009, QA-001 | Not started |

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
