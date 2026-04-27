# Implementation Plan: TSK-P2-W6-REM-17b-alpha

## Mission
Backfill `state_transitions.interpretation_version_id` from `execution_records.interpretation_version_id` via FK on `execution_id`, using the three-phase assert → mutate → reconcile contract.

## Constraints
- Must temporarily disable `bd_01_deny_state_transitions_mutation` trigger during backfill.
- Must re-enable trigger immediately after, even on error.
- Must be idempotent (rerunnable with zero updates on second pass).
- Must not overwrite already-populated values.

## Evidence Paths
- `evidence/phase2/tsk_p2_w6_rem_17b_alpha.json`
