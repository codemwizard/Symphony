# SEC-003 PLAN

Task: SEC-003
Owner role: SUPERVISOR
Depends on: FP-001
failure_signature: PHASE1.SEC.003.REQUIRED

## objective
Weak trust-assumption reduction

## scope
- Correct forwarded-header trust assumptions and spoofable client identity handling.
- Tighten tenant/object authorization on high-risk read/report surfaces.
- Document any retained shared-key trust as temporary with compensating controls and expiry.

## acceptance_criteria
- Trusted-proxy behavior is explicit or risky fallback is disabled.
- High-risk read surfaces require tenant/object scope.
- Residual shared-key trust shortcuts are isolated and time-bounded.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task SEC-003 --evidence evidence/security/sec_003_trust_boundary_corrections.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not redesign the full trust plane in this task.
- Do not broaden auth contract changes beyond justified security fixes.

## evidence_output
- `evidence/security/sec_003_trust_boundary_corrections.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task SEC-003 --evidence evidence/security/sec_003_trust_boundary_corrections.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
