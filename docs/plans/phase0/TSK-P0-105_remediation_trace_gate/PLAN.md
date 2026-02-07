# PLAN — Remediation Trace Gate (Option 2, Low Noise)

## Task IDs
- TSK-P0-105
- TSK-P0-106
- TSK-P0-107
- TSK-P0-108

## Context
The repo currently allows “fix CI” remediation without a durable forensic record that:
- points to the originating task or gate,
- records root cause and verified resolution steps,
- and is discoverable for the next recurrence.

This plan implements a mechanical remediation-trace gate with Option 2 semantics (noise-controlled), plus normative documentation and tests.

## Scope
- Add a remediation-trace verifier that enforces the presence of a casefile or an explicitly-marked fix plan/log when production-affecting surfaces change.
- Add a normative workflow document for remediation casefiles.
- Register a new invariant (`INV-105`) and wire enforcement into local pre-push via `scripts/dev/pre_ci.sh` (through ordered checks).
- Add tests for the remediation-trace verifier.

## Non-Goals
- No change to business logic or DB schema.
- No mandatory remediation traces for all documentation changes; only enforcement/policy surfaces trigger the gate.
- No attempt to classify “bugfix vs feature” from commit messages; enforcement is diff-based.

## Files / Paths Touched
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `scripts/audit/verify_remediation_trace.sh`
- `scripts/audit/verify_remediation_workflow_doc.sh`
- `scripts/audit/run_invariants_fast_checks.sh`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANTS_IMPLEMENTED.md`
- `docs/invariants/INVARIANTS_QUICK.md`
- `docs/tasks/PHASE0_TASKS.md`
- `docs/PHASE0/phase0_contract.yml`
- `tasks/TSK-P0-105/meta.yml`
- `tasks/TSK-P0-106/meta.yml`
- `tasks/TSK-P0-107/meta.yml`
- `tasks/TSK-P0-108/meta.yml`
- `scripts/audit/tests/test_verify_remediation_trace.py`
- `.codex/agents/*.md` (agent prompt reinforcement)

## Gates / Verifiers
- `scripts/audit/verify_remediation_workflow_doc.sh` -> `evidence/phase0/remediation_workflow_doc.json`
- `scripts/audit/verify_remediation_trace.sh` -> `evidence/phase0/remediation_trace.json`

## Expected Failure Modes
- Production-affecting change with no remediation casefile or explicit fix plan/log in the diff.
- Remediation casefile exists but required fields are missing.
- Gate computes wrong diff range (staged vs range); false negatives.
- Evidence file missing.

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/run_phase0_ordered_checks.sh`
- `scripts/dev/pre_ci.sh`

## Dependencies
- None.

## Remediation Markers (for gate bootstrap)
This plan file intentionally includes the minimum remediation markers so that the gate can be introduced without a chicken-and-egg failure.

failure_signature: P0.REMEDIATION_TRACE_BOOTSTRAP
origin_task_id: TSK-P0-105
origin_gate_id: REMEDIATION-TRACE
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: PASS

