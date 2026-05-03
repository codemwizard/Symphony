# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: OPEN

## Scope
- Diagnose why pre_ci.sh fails at PRECI.DB.ENVIRONMENT with exit code 141 (SIGPIPE).
- All DB components (lint_migrations.sh, verify_invariants.sh, migrate.sh) pass individually.
- Full ephemeral DB reproduction sequence passes end-to-end when isolated.
- Failure is inconsistent: Run 1 failed inside verify_invariants.sh, Run 2 failed during ephemeral setup.

## Initial Hypotheses
- Transient SIGPIPE from resource exhaustion (pre_ci.sh runs 40+ scripts before DB gates).
- The PRECI.DB.ENVIRONMENT context covers lines 513-1352 (last context setter), making attribution imprecise.
- Stale psql session may consume connection slots under ephemeral DB creation.

## Diagnosis Evidence
- lint_migrations.sh: standalone PASS
- verify_invariants.sh on ephemeral DB: PASS
- verify_invariants.sh on persistent DB (port 55432): PASS
- Full ephemeral sequence (create → lint → migrate → seed → verify): PASS
- Exit code 141 = SIGPIPE (broken pipe, not logic error)
