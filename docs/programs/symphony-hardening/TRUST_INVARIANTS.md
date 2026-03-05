# Trust Invariants

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

This document defines the 12 hard invariants used for hardening execution and audit review.

## INV-HARD-01
- invariant_id: INV-HARD-01
- plain_language_statement: Inquiry behavior is policy-driven per rail and never hardcoded per deployment.
- enforcement_layer: runtime, CI
- violation_impact_description: Rail-specific timeout drift causes inconsistent settlement handling and dispute exposure.
- test_mapping: scripts/audit/verify_tsk_hard_011.sh

## INV-HARD-02
- invariant_id: INV-HARD-02
- plain_language_statement: Approved intent is cryptographically sealed before execution.
- enforcement_layer: DB, runtime
- violation_impact_description: Outbound payload can diverge from approved adjustment details.
- test_mapping: scripts/audit/verify_tsk_hard_013.sh

## INV-HARD-03
- invariant_id: INV-HARD-03
- plain_language_statement: Terminal records are immutable except explicitly defined append-only annotations.
- enforcement_layer: DB
- violation_impact_description: Historical facts can be rewritten, invalidating compliance evidence.
- test_mapping: scripts/audit/verify_tsk_hard_020.sh

## INV-HARD-04
- invariant_id: INV-HARD-04
- plain_language_statement: Approval and execution writes are lock-protected and idempotent.
- enforcement_layer: DB, runtime
- violation_impact_description: Race conditions create duplicate approvals/executions.
- test_mapping: scripts/audit/verify_tsk_hard_021.sh

## INV-HARD-05
- invariant_id: INV-HARD-05
- plain_language_statement: Offline Safe Mode blocks execution while preserving auditable event capture.
- enforcement_layer: runtime, policy
- violation_impact_description: Payments can be attempted when critical dependencies are unavailable.
- test_mapping: scripts/audit/verify_tsk_hard_094.sh

## INV-HARD-06
- invariant_id: INV-HARD-06
- plain_language_statement: Decision-point evidence is emitted for every material gate and outcome.
- enforcement_layer: runtime, CI
- violation_impact_description: Auditors cannot reconstruct why a transition was allowed or blocked.
- test_mapping: scripts/audit/verify_tsk_hard_030.sh

## INV-HARD-07
- invariant_id: INV-HARD-07
- plain_language_statement: Re-entry execution allocates collision-safe references with registry linkage.
- enforcement_layer: runtime, DB
- violation_impact_description: Duplicate rails references create unresolvable reconciliation ambiguity.
- test_mapping: scripts/audit/verify_tsk_hard_031.sh

## INV-HARD-08
- invariant_id: INV-HARD-08
- plain_language_statement: Privacy erasure preserves ledger truth via tokenized audit-safe placeholders.
- enforcement_layer: DB, runtime
- violation_impact_description: Either PII leaks after purge or audits lose continuity.
- test_mapping: scripts/audit/verify_tsk_hard_040.sh

## INV-HARD-09
- invariant_id: INV-HARD-09
- plain_language_statement: Long-horizon replay can validate evidence chains over multi-year windows.
- enforcement_layer: runtime, operations
- violation_impact_description: Historical investigations fail due to unverifiable archival boundaries.
- test_mapping: scripts/audit/verify_tsk_hard_099.sh

## INV-HARD-10
- invariant_id: INV-HARD-10
- plain_language_statement: DR and cutover ceremonies produce immutable continuity proof artifacts.
- enforcement_layer: operations, CI
- violation_impact_description: Recovery claims cannot be validated during regulator review.
- test_mapping: scripts/audit/verify_tsk_hard_070.sh

## INV-HARD-11
- invariant_id: INV-HARD-11
- plain_language_statement: Policy activation is versioned, attributable, and non-editable in place.
- enforcement_layer: policy, DB
- violation_impact_description: Runtime behavior cannot be tied to an approved policy version.
- test_mapping: scripts/audit/verify_tsk_hard_011a.sh

## INV-HARD-12
- invariant_id: INV-HARD-12
- plain_language_statement: Wave exit gates fail closed unless all required artifacts validate.
- enforcement_layer: CI
- violation_impact_description: Program can be marked complete with missing or invalid controls.
- test_mapping: scripts/audit/verify_program_wave1_exit_gate.sh
