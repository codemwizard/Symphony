# REM-2026-05-18_structural_change_rule1_remediation

failure_signature: PRECI.STRUCTURAL.CHANGE_RULE.EXCEPTION_BYPASS
origin_gate_id: PRECI.STRUCTURAL.CHANGE_RULE
severity: L1
first_observed_utc: 2026-05-18T13:40:00Z
repro_command: PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations
scope_boundary:
- in_scope: approval metadata parity for the active branch approval bundle
- in_scope: remediation trace for the structural gate follow-up
- in_scope: docs/invariants linkage needed to satisfy Rule 1 without exception files
- out_of_scope: Phase 3 runtime code, migrations, verifiers, and historical evidence churn outside approval metadata

## Problem Statement

The last structural commit succeeded only because staged exception files under
`docs/invariants/exceptions/` satisfied Rule 1 by bypass. The intended outcome
for this branch is a real invariants linkage update in `docs/invariants/**`
with `INV-###` tokens, not another exception-path closeout. During follow-up
verification, `PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh`
also failed with `CONFORMANCE_011_APPROVAL_MISMATCH`, so approval parity must
be repaired before the structural linkage remediation can be treated as
compliant.

## initial_hypotheses

- The active branch approval markdown, sidecar JSON, and
  `evidence/phase1/approval_metadata.json` drifted out of sync during the
  Phase 4 preparation update.
- Rule 1 can be satisfied with a narrow truthful roadmap note that cites the
  already-registered Phase 3 structural invariants `INV-301` through
  `INV-310`, without reopening old exception files.

## Plan

1. Align the active Stage A branch approval markdown, sidecar JSON, and
   `evidence/phase1/approval_metadata.json` so agent conformance passes.
2. Add a small `docs/invariants/**` update containing `INV-301` through
   `INV-310` linkage for the Phase 3 structural batch.
3. Re-run the targeted gates in order:
   - `PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations`
   - `bash scripts/audit/run_invariants_fast_checks.sh`
   - `bash scripts/audit/preflight_structural_staged.sh`
4. Commit only the remediation files needed to replace the exception-path
   bypass with real Rule 1 linkage.

## Final Closeout

final_root_cause: The active Stage A approval markdown, sidecar JSON, and
  evidence/phase1/approval_metadata.json had drifted out of parity during the
  Phase 4 preparation update, which blocked agent conformance. In parallel, the
  last structural commit relied on touched exception files rather than a direct
  docs/invariants linkage update, so Rule 1 closed through the exception path.
final_solution_summary: Updated the active branch approval bundle and approval
  metadata to one consistent Stage A record, opened a remediation casefile, and
  added a narrow INV-301 through INV-310 linkage note in
  docs/invariants/INVARIANTS_ROADMAP.md so the staged structural follow-up no
  longer depends on exception-file closure.
verification_commands_run:
- PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations
- bash scripts/audit/run_invariants_fast_checks.sh
- bash scripts/audit/preflight_structural_staged.sh

final_status: PASS
