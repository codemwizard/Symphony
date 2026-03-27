# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT
first_observed_utc: 2026-03-26T18:05:43Z
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: bash scripts/security/lint_security_definer_dynamic_sql.sh
verification_commands_run: bash scripts/security/lint_security_definer_dynamic_sql.sh
final_status: PASS

## Scope
- Record the failing DB/environment sub-gate triggered by the security-definer dynamic SQL lint.
- Remediate the allowlist drift for the new `0095` RLS migration files without changing migration semantics.
- Keep the fix limited to lint registration and remediation trace artifacts.

scope_boundary:
- In scope: `docs/security/security_definer_dynamic_sql_allowlist.txt`, this remediation casefile, targeted lint verification.
- Out of scope: changing `0095` migration behavior, rerunning broad `pre_ci.sh`, unrelated DB verifier failures.

## Initial Hypotheses
- The `0095` migrations use intentional dynamic SQL for policy generation and rollback, but the line fingerprints were never added to the security-definer dynamic SQL allowlist.
- The gate should clear once those exact lines are registered in the allowlist file consumed by `lint_security_definer_dynamic_sql.sh`.

## Final Root Cause
- `scripts/security/lint_security_definer_dynamic_sql.sh` is an allowlist-based detector.
- `schema/migrations/0095_rls_dual_policy_architecture.sql` and `schema/migrations/0095_rollback.sql` introduced intentional dynamic SQL patterns, but `docs/security/security_definer_dynamic_sql_allowlist.txt` did not yet contain their matching entries.

## Final Solution Summary
- Added the exact `0095` match strings reported by the linter to `docs/security/security_definer_dynamic_sql_allowlist.txt`.
- Added a remediation casefile to preserve the failure signature, scope boundary, root cause, and targeted verification outcome.

## Derived Tasks
- None. This remediation is a direct allowlist-drift correction with no additional task decomposition required.
