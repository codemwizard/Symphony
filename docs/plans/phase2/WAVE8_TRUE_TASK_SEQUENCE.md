# Wave 8 True Task Sequence

Derive the correct sequential implementation order for Wave 8 tasks by analyzing the depends_on and blocks fields from each task's meta.yml file.

## Task Dependency Analysis

Based on the actual meta.yml files, there are **22 tasks** (not 18 as stated in WAVE8_GAP_TO_DOD_TASK_GENERATION_PLAN.md):

### Phase 1: Governance and Architecture (7 tasks)
1. **TSK-P2-W8-GOV-001** - Wave 8 governance truth repair
   - depends_on: none
   - blocks: ARCH-001, ARCH-002, ARCH-003, DB-003

2. **TSK-P2-W8-ARCH-001** - Canonical attestation payload contract
   - depends_on: GOV-001
   - blocks: ARCH-002, DB-003

3. **TSK-P2-W8-ARCH-002** - Transition hash contract
   - depends_on: ARCH-001
   - blocks: ARCH-003, DB-002, DB-004

4. **TSK-P2-W8-ARCH-003** - Signing and replay contract hardening
   - depends_on: ARCH-001, ARCH-002
   - blocks: ARCH-004, ARCH-006, SEC-000, DB-002, DB-005, SEC-001

5. **TSK-P2-W8-ARCH-004** - Data authority derivation contract
   - depends_on: ARCH-002, ARCH-003
   - blocks: ARCH-005

6. **TSK-P2-W8-ARCH-005** - System design patch for authoritative trigger model
   - depends_on: ARCH-002, ARCH-003, ARCH-004
   - blocks: ARCH-006, DB-001, DB-005

7. **TSK-P2-W8-ARCH-006** - SQLSTATE registration
   - depends_on: ARCH-002, ARCH-003, ARCH-004, ARCH-005
   - blocks: SEC-000, SEC-001

### Phase 2: Security Gates (2 tasks)
8. **TSK-P2-W8-SEC-000** - Frozen .NET 10 Ed25519 Environment Fidelity Gate
   - depends_on: ARCH-003, ARCH-006
   - blocks: SEC-001

9. **TSK-P2-W8-SEC-001** - Ed25519 verification primitive
   - depends_on: ARCH-003, ARCH-006, SEC-000
   - blocks: DB-006

### Phase 3: Database Foundation (9 tasks)
10. **TSK-P2-W8-DB-001** - Authoritative Wave 8 dispatcher trigger topology
    - depends_on: ARCH-005
    - blocks: DB-002, DB-003

11. **TSK-P2-W8-DB-002** - Placeholder and legacy posture removal
    - depends_on: DB-001, ARCH-002, ARCH-003
    - blocks: DB-003

12. **TSK-P2-W8-DB-003** - SQL-authoritative canonical payload construction
    - depends_on: ARCH-001, DB-001, DB-002
    - blocks: DB-004

13. **TSK-P2-W8-DB-004** - Deterministic attestation hash recomputation
    - depends_on: ARCH-002, DB-003
    - blocks: SEC-001, DB-006, QA-001

14. **TSK-P2-W8-DB-005** - Authoritative signer-resolution surface
    - depends_on: ARCH-003, ARCH-005
    - blocks: DB-006

15. **TSK-P2-W8-DB-006** - Authoritative trigger integration of cryptographic primitive
    - depends_on: DB-004, DB-005, SEC-001
    - blocks: DB-007a, DB-007b, DB-007c, DB-008, DB-009, QA-001

16. **TSK-P2-W8-DB-007a** - Scope authorization enforcement
    - depends_on: DB-006
    - blocks: DB-008, DB-009

17. **TSK-P2-W8-DB-007b** - Persisted timestamp enforcement
    - depends_on: DB-006
    - blocks: DB-008, DB-009

18. **TSK-P2-W8-DB-007c** - Replay law enforcement
    - depends_on: DB-006
    - blocks: DB-008, DB-009

19. **TSK-P2-W8-DB-008** - Key lifecycle enforcement
    - depends_on: DB-006, DB-007a, DB-007b, DB-007c
    - blocks: QA-002

20. **TSK-P2-W8-DB-009** - Context binding and anti-transplant protection
    - depends_on: DB-004, DB-006, DB-007a, DB-007b, DB-007c
    - blocks: QA-002

### Phase 4: QA Verification (2 tasks)
21. **TSK-P2-W8-QA-001** - Three-surface determinism vectors
    - depends_on: DB-004, DB-006
    - blocks: QA-002

22. **TSK-P2-W8-QA-002** - Behavioral evidence pack
    - depends_on: DB-006, DB-007a, DB-007b, DB-007c, DB-008, DB-009, QA-001
    - blocks: none (final task)

## Sequential Implementation Order

The correct sequential order respecting all dependencies:

1. TSK-P2-W8-GOV-001 (no dependencies)
2. TSK-P2-W8-ARCH-001 (depends on GOV-001)
3. TSK-P2-W8-ARCH-002 (depends on ARCH-001)
4. TSK-P2-W8-ARCH-003 (depends on ARCH-001, ARCH-002)
5. TSK-P2-W8-ARCH-004 (depends on ARCH-002, ARCH-003)
6. TSK-P2-W8-ARCH-005 (depends on ARCH-002, ARCH-003, ARCH-004)
7. TSK-P2-W8-ARCH-006 (depends on ARCH-002, ARCH-003, ARCH-004, ARCH-005)
8. TSK-P2-W8-SEC-000 (depends on ARCH-003, ARCH-006)
9. TSK-P2-W8-SEC-001 (depends on ARCH-003, ARCH-006, SEC-000)
10. TSK-P2-W8-DB-001 (depends on ARCH-005)
11. TSK-P2-W8-DB-002 (depends on DB-001, ARCH-002, ARCH-003)
12. TSK-P2-W8-DB-003 (depends on ARCH-001, DB-001, DB-002)
13. TSK-P2-W8-DB-004 (depends on ARCH-002, DB-003)
14. TSK-P2-W8-DB-005 (depends on ARCH-003, ARCH-005)
15. TSK-P2-W8-DB-006 (depends on DB-004, DB-005, SEC-001)
16. TSK-P2-W8-DB-007a (depends on DB-006)
17. TSK-P2-W8-DB-007b (depends on DB-006)
18. TSK-P2-W8-DB-007c (depends on DB-006)
19. TSK-P2-W8-DB-008 (depends on DB-006, DB-007a, DB-007b, DB-007c)
20. TSK-P2-W8-DB-009 (depends on DB-004, DB-006, DB-007a, DB-007b, DB-007c)
21. TSK-P2-W8-QA-001 (depends on DB-004, DB-006)
22. TSK-P2-W8-QA-002 (depends on DB-006, DB-007a, DB-007b, DB-007c, DB-008, DB-009, QA-001)

## Key Differences from WAVE8_GAP_TO_DOD_TASK_GENERATION_PLAN.md

- **Total tasks**: 22 (not 18)
- **Additional tasks**: ARCH-004, ARCH-005, DB-001, DB-002
- **DB-007 split**: The plan correctly identifies DB-007a, DB-007b, DB-007c as separate tasks (not a single DB-007)
- **Dependency complexity**: The actual dependency graph is more complex than the simplified sequence in the original plan

## Parallel Execution Opportunities

Tasks 16, 17, and 18 (DB-007a, DB-007b, DB-007c) all depend only on DB-006 and can potentially be executed in parallel since they target different enforcement domains (scope, timestamp, replay).
