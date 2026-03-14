# Remediation Plan

Severity: L1

Failures being remediated:
- governance signoff verifier fails because branch approval records `pre_ci_passed: false`
- ledger-api image build fails because Docker build context cannot find `services/ledger-api/.publish/evidence`

Scope:
- docs/operations/DEV_WORKFLOW.md
- docs/operations/LOCAL_HOOK_TOPOLOGY.md
- scripts/audit/verify_tsk_p1_076.sh
- scripts/dev/install_git_hooks.sh
- services/ledger-api/Dockerfile
- scripts/dev/build_demo_images.sh
- scripts/audit/verify_inf_002_container_build_pipeline.sh
- docs/audits/GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md
- approvals/2026-03-13/BRANCH-feat-demo-deployment-hardening-tasks.*
- evidence/phase1/approval_metadata.json
- evidence/phase1/human_governance_review_signoff.json
- docs/plans/phase1/REM-2026-03-14_demo-deployment-hardening-ci-fixes/*

Verification target:
- bash scripts/audit/verify_tsk_p1_076.sh
- bash scripts/audit/verify_human_governance_review_signoff.sh
- bash scripts/dev/build_demo_images.sh
- bash scripts/audit/verify_inf_002_container_build_pipeline.sh --evidence evidence/phase1/inf_002_container_build_pipeline.json
- bash scripts/audit/verify_tsk_p1_063.sh
- bash scripts/dev/pre_ci.sh
