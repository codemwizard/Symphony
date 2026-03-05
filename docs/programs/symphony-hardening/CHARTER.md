# Symphony Hardening Charter

Program Owner: Security & Resilience Office (Symphony)
Approval Authority: Chief Risk and Compliance Officer

## Mission
Deliver an auditable, fail-closed hardening program across DB/API/runtime/operations with deterministic evidence.

## Hard Invariant Baseline
- INV-HARD-01: Inquiry rails are metadata-driven and deterministic per adapter policy.
- INV-HARD-02: Effect sealing binds approved intent to outbound execution payload.
- INV-HARD-03: Terminal-state immutability is fail-closed at DB layer.
- INV-HARD-04: Concurrency controls prevent duplicate approvals/executions.
- INV-HARD-05: Offline Safe Mode blocks unsafe execution and preserves evidence continuity.
- INV-HARD-06: Decision-point evidence is emitted for approvals, gates, and outcomes.
- INV-HARD-07: Reference allocation and collision handling are enforced for re-entry.
- INV-HARD-08: Privacy controls preserve audit truth after subject erasure.
- INV-HARD-09: Long-horizon replay remains verifiable across archival boundaries.
- INV-HARD-10: DR/cutover ceremonies are provable with immutable trail continuity.
- INV-HARD-11: Policy activation and versioning are immutable and attributable.
- INV-HARD-12: Program wave exits are fail-closed and artifact-verified.
