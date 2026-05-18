# REM-2026-05-18_structural_change_rule1_remediation EXEC_LOG

- timestamp_utc: 2026-05-18T14:01:25Z
  failure_signature: PRECI.STRUCTURAL.CHANGE_RULE.EXCEPTION_BYPASS
  origin_gate_id: PRECI.STRUCTURAL.CHANGE_RULE
  severity: L1
  repro_command: PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations
  observation: >
    Follow-up remediation started after commit 85927487 passed with the hook
    warning "Rule 1 bypassed via exception file(s) under docs/invariants/exceptions."
    Direct conformance replay also failed with CONFORMANCE_011_APPROVAL_MISMATCH
    for prompt hash, model id, and approver id parity.
  verification_commands_run:
  - PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh
  final_status: IN_PROGRESS

- timestamp_utc: 2026-05-18T14:01:25Z
  root_cause: >
    The active branch approval markdown, sidecar, and approval metadata evidence
    described different approval identities and AI metadata, triggering
    CONFORMANCE_011_APPROVAL_MISMATCH. Separately, the previous structural
    commit touched closed exception files, so Rule 1 passed through the
    exception-path warning instead of through an explicit docs/invariants linkage
    update.
  fix_applied: >
    Realigned approvals/2026-05-18/BRANCH-feat-p3-wave1-lineage=foundations.*
    and evidence/phase1/approval_metadata.json, created this remediation
    casefile, and added an INV-301 to INV-310 linkage note to
    docs/invariants/INVARIANTS_ROADMAP.md.
  verification_commands_run:
  - PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations
  - bash scripts/audit/run_invariants_fast_checks.sh
  - bash scripts/audit/preflight_structural_staged.sh
  verification_results:
  - CONFORMANCE PASS
  - Fast invariants checks PASSED
  - No structural change detected for the staged remediation diff, so no exception-path Rule 1 closure remains in this follow-up commit
  final_status: PASS
