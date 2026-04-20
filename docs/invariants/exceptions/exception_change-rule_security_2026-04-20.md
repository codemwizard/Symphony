---
exception_id: EXC-20260420-EXEC-TRUTH-REM05
inv_scope: change-rule
expiry: 2026-10-20
follow_up_ticket: TSK-P2-PREAUTH-003-REM-04
reason: REM-05 adds the anchor verifier and degradation smoke harness. The structural detector flags them as "security" because they reference SECURITY DEFINER / search_path hardening (scenarios #6 and #7 of the smoke harness deliberately weaken those to prove the verifier fails closed). The invariant cannot be registered in INVARIANTS_MANIFEST.yml as implemented until this REM-05 evidence exists — that is the precondition REM-04 will satisfy inside this same PR (bug-fix constraint B4).
author: db_foundation
created_at: 2026-04-20
---

# Exception: security-surface structural change without invariants linkage (REM-05 anchor verifier + smoke harness)

## Reason

`scripts/db/verify_execution_truth_anchor.sh` is the anchor integrity verifier for INV-EXEC-TRUTH-001. It inspects `pg_proc.prosecdef` and `pg_proc.proconfig` to confirm both trigger functions are `SECURITY DEFINER` with `search_path=pg_catalog, public`. The structural detector classifies this as a "security" change because the script includes literal references to these primitives.

`scripts/db/tests/test_execution_truth_anchor_smoke.sh` is the degradation harness. Scenarios 6 and 7 deliberately flip `SECURITY DEFINER → SECURITY INVOKER` and `RESET search_path` (then restore) to prove the verifier fails closed on each surface. The detector sees these ALTER FUNCTION statements and classifies the harness as "security" as well.

Both files are owned by DB_FOUNDATION (`scripts/db/**`) per AGENTS.md path authority. They do not touch `scripts/dev/**`, `scripts/audit/**`, or any production/CI wiring — that is deferred to REM-05B under SECURITY_GUARDIAN.

Per REM-04 `stop_conditions`, flipping INV-EXEC-TRUTH-001 to `status: implemented` before REM-05 evidence exists is an explicit anti-pattern (bug-fix constraint B4 carried from PR #187 merge cycle). This exception allows the verifier + smoke harness to land in the same PR while REM-04 registers the invariant in a later commit.

## Evidence

structural_change: true
confidence_hint: 1.0
primary_reason: security
reason_types: security, ddl

Matched files:
- scripts/db/verify_execution_truth_anchor.sh
- scripts/db/tests/test_execution_truth_anchor_smoke.sh

## Mitigation

- DB_FOUNDATION path authority respected: no edits to `scripts/dev/**` or `scripts/audit/**`.
- The smoke harness ALTER FUNCTION statements are paired (degrade → restore) and wrapped in `apply_sql`/`run_scenario` helpers with a post-suite sanity check (`bash "$VERIFIER"` must rc=0 after all restores). If any restore fails, the harness aborts with `exit 2`.
- No production code path invokes the smoke harness; it is invoked only by REM-05B in CI against a disposable test database.
- Verifier emits self-certifying evidence with three integrity fields (`verification_tool_version`, `verification_input_snapshot`, `verification_run_hash`) so a compromised verifier cannot silently pass.
- Invariant linkage is registered via REM-04 in this same PR.

## Closure Criteria

- `docs/invariants/INVARIANTS_MANIFEST.yml` contains an `INV-EXEC-TRUTH-001` block with `status: implemented`, `enforcement_path` pointing at the verifier, and a pinned `verification_tool_version` SHA-256.
- `docs/invariants/INVARIANTS_IMPLEMENTED.md` contains the matching row.
- `evidence/phase2/tsk_p2_preauth_003_rem_04.json` present and fresh (run_id matches the git HEAD SHA that merged this PR).
