# PLAN — Remediation Trace Gate CI Miss (Casefile)

## Context
CI failed the remediation-trace gate:
- Gate: `REMEDIATION-TRACE` (`bash scripts/audit/verify_remediation_trace.sh`)
- Error: `missing_remediation_trace_doc` (no remediation casefile or fix task plan/log with required markers present in the PR diff)

This casefile exists to provide a durable audit trail for the failure and the remediation.

## Scope
- Ensure this PR includes a remediation trace artifact (this casefile) so the gate is satisfied in CI.
- Ensure the intended fix plan/log (TSK-P0-118) includes required remediation markers so future diffs can satisfy the gate via a normal task plan/log.
- Explain why local `pre_ci` did not catch the CI failure mode.

## Root Cause (Provisional)
- The remediation-trace verifier only considers remediation docs that are present in the *diff range*.
- Locally, `origin/main` can be stale or differ from CI's `origin/main`, causing the gate to pass due to unrelated historical plan/logs being present in the local range.
- In CI, the diff is computed against the real PR base, and no satisfying remediation doc was found in that diff.

## Fix
- Add a remediation casefile under `docs/plans/phase0/REM-*` containing the required remediation markers.
- Ensure the in-scope task plan/log includes the required markers as well.

## Verification
- `bash scripts/audit/verify_remediation_trace.sh`
- `scripts/dev/pre_ci.sh`

failure_signature: CI.REMEDIATION_TRACE.MISSING_CASEFILE
origin_gate_id: REMEDIATION-TRACE
repro_command: bash scripts/audit/verify_remediation_trace.sh
verification_commands_run: bash scripts/audit/verify_remediation_trace.sh; scripts/dev/pre_ci.sh
final_status: PASS

