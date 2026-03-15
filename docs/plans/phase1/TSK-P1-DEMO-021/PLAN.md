# TSK-P1-DEMO-021 Plan

## mission
Convert demo key, OpenBao, TLS, and rotation posture into an executable operator policy for the host-based run.

## constraints
- Full-demo sign-off must fail closed if OpenBao-backed signing truth cannot be proven.
- Any weaker mode must be explicitly labeled rehearsal-only or non-signoff.
- No raw secrets may be permitted in logs, bundles, rendered HTML, or bootstrap payloads.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_021.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-021 --evidence evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/security/KEY_MANAGEMENT_POLICY.md`
- `docs/security/TLS_DEPLOYMENT_GUIDE.md`
- regulated surface applies because `docs/security/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json`
