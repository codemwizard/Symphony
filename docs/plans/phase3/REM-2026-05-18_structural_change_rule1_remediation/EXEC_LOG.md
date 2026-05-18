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

- timestamp_utc: 2026-05-18T14:20:00Z
  failure_signature: PRECI.STRUCTURAL.CHANGE_RULE
  origin_gate_id: pre_ci.enforce_change_rule
  severity: L1
  repro_command: BASE_REF=refs/remotes/origin/main HEAD_REF=HEAD bash scripts/audit/enforce_change_rule.sh
  observation: >
    CI-parity branch-range enforcement still failed after the staged Rule 1
    remediation because the full origin/main...HEAD structural batch did not
    include docs/architecture/THREAT_MODEL.md or
    docs/architecture/COMPLIANCE_MAP.md in the committed diff.
  fix_applied: >
    Appended dated Phase-3 branch-range structural governance entries to
    docs/architecture/THREAT_MODEL.md and docs/architecture/COMPLIANCE_MAP.md
    covering migrations 0207..0218, verifier-backed INV-301..INV-310 closure,
    and the preserved fail-closed security posture for the full branch.
  verification_commands_run:
  - BASE_REF=refs/remotes/origin/main HEAD_REF=HEAD bash scripts/audit/enforce_change_rule.sh
  verification_results:
  - First rerun before commit still failed because enforce_change_rule.sh reads committed HEAD, not the staged index
  - After commit 371853c0, BASE_REF=refs/remotes/origin/main HEAD_REF=HEAD bash scripts/audit/enforce_change_rule.sh returned `✅ Change rule OK: no structural changes detected.`
  final_status: PASS
