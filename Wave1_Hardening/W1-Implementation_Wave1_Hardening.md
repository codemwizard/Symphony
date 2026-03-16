# Hardening Wave Implementation Strategy

This plan defines the grouping of 11 tasks (TSK-P1-211 to 221) into waves of 5 to streamline implementation and verification while maintaining strict project standards.

## Wave Groupings

### Wave 1: Foundation & Ingress Hardening
- **TSK-P1-211**: Repair schema conflict-target defect permanently.
- **TSK-P1-212**: Restore `db_psql` ingress and make it canonical.
- **TSK-P1-213**: Align verifier patterns with the current provisioning runbook.
- **TSK-P1-214**: Persist supplier registry and programme allowlist in PostgreSQL.
- **TSK-P1-215**: Integrate runtime secret provider with OpenBao.

### Wave 2: Control Plane & Security Hardening
- **TSK-P1-216**: Separate key domains and prove rotation.
- **TSK-P1-217**: Persist onboarding control-plane state.
- **TSK-P1-218**: Expose server-side onboarding APIs.
- **TSK-P1-219**: Deliver website onboarding console.
- **TSK-P1-220**: Build the one-command bootstrap.

### Wave 3: Finalization
- **TSK-P1-221**: Rewrite docs, readiness, and gates around the hardened architecture.

## Implementation Protocol

For each wave:
1. **Parallel/Sequential Implementation**: Implement each task's core logic and its corresponding unit tests/verifiers.
2. **Functional Verification**: Run specific task verifiers (e.g., `scripts/audit/verify_tsk_p1_N.sh`) immediately upon completion of each task.
3. **Delayed Integrity Check**: Do NOT run `scripts/dev/pre_ci.sh` after individual tasks.
4. **Wave Completion**: Once all tasks in the wave are functionally verified, run `scripts/dev/pre_ci.sh` once for the entire wave.
5. **Phase Documentation**: Update `Walkthrough.md` and `Task.md` for the entire wave.

## Verification Plan

### Automated Tests
- For Each Task: `bash scripts/audit/verify_tsk_p1_[ID].sh`
- For Each Wave: `bash scripts/dev/pre_ci.sh`

### Manual Verification
- Verify that `db_psql` onboarding works end-to-end after Wave 1.
- Confirm OpenBao secret retrieval after Wave 1.
- Proof of rotation after Wave 2.
