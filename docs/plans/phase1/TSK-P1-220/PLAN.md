# TSK-P1-220 Plan

Task ID: TSK-P1-220

## dependencies
- TSK-P1-214
- TSK-P1-215
- TSK-P1-216
- TSK-P1-217
- TSK-P1-218

## objective
Create the single supported bootstrap path for the hardened GreenTech4CE demo deployment.

## implementation_directives
- The bootstrap flow must initialize into a truthful hardened state.
- Explicitly forbid the following in the supported hardened flow:
  - manual key generation
  - manual env export sequences
  - manual SQL repair steps
  - manual reseeding as part of the supported hardened flow

## hardening_rules
1. No interim workaround may remain in the supported deployment or onboarding path after this task closes.
2. Hardened GreenTech4CE flows must prefer durable system design over operator memory, shell sequencing, or manual reseeding.
3. Runtime security decisions must not depend on browser-held admin credentials or unaudited environment-variable shortcuts when this task is in scope to remove them.
4. Documentation, gates, and runtime behavior must converge on one supported hardened path; fallback modes may exist only when explicitly marked as developer-only and out of scope.

## acceptance_focus
- Remove the provisional workaround described in task notes, if any.
- Update docs, verifiers, and bootstrap expectations so the permanent design is the only supported design.
- Prove the final state with evidence and fail-closed verification.

## remediation_trace
failure_signature: PHASE1.P1.220.CANONICAL_BOOTSTRAP
repro_command: see task verifier commands in meta.yml
verification_commands_run: []
final_status: planned
origin_task_id: TSK-P1-220
origin_gate_id: PHASE1.P1.220.CANONICAL_BOOTSTRAP
