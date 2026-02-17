# Phase-0 Leftovers Implementation Analysis
Date: 2026-02-16
Source reviewed: `Phase0LeftOvers.txt`, `.codex/session/phase0_context.md`, current repository state

## Summary
Most items listed in `Phase0LeftOvers.txt` are already implemented in the current codebase. A smaller set remains partially implemented or roadmap-only.

## Implemented Items (Verified)
1. Due-claim outbox index is implemented.
- `schema/migrations/0007_outbox_pending_indexes.sql:4`

2. Terminal uniqueness index is implemented.
- `schema/migrations/0008_outbox_terminal_uniqueness.sql:2`

3. MVCC fillfactor posture is implemented.
- `schema/migrations/0009_pending_fillfactor.sql:4`

4. LISTEN/NOTIFY wakeup hook and test evidence are implemented.
- `schema/migrations/0010_outbox_notify.sql:91`
- `scripts/db/tests/test_db_functions.sh:132`

5. Ingress attestation table (append-only) is implemented.
- `schema/migrations/0011_ingress_attestations.sql:4`

6. Revocation tables are implemented.
- `schema/migrations/0012_revocation_tables.sql:4`

7. Previously "missing" scripts now exist and are wired.
- `scripts/security/openbao_bootstrap.sh:1`
- `scripts/security/openbao_smoke_test.sh:1`
- `scripts/security/lint_ddl_lock_risk.sh:1`
- `scripts/audit/verify_batching_rules.sh:1`
- `scripts/audit/verify_routing_fallback.sh:1`
- `scripts/audit/run_phase0_ordered_checks.sh:18`

8. Blocking-DDL policy lint is implemented.
- `scripts/security/lint_ddl_lock_risk.sh:180`

## Remaining Gaps / Partial Items
1. DB exhaustion fail-closed runtime verification remains roadmap-only.
- `docs/invariants/INVARIANTS_MANIFEST.yml:347` (`INV-039` status is `roadmap`)
- `scripts/audit/run_invariants_fast_checks.sh:362` (roadmap evidence emission)

2. Core boundary guard exists but is weak in practice because guarded directories are absent.
- Guard scans: `scripts/security/lint_core_boundary.sh:15`
- Current `src/` contains only `.gitkeep`

3. Documentation drift still exists in architecture doc.
- Non-existent service reference remains: `docs/overview/architecture.md:24`

4. Outbox attempts archive partition/retention is not implemented as a mechanical invariant or migration.
- No partitioning migration/verifier found for `payment_outbox_attempts`

5. If strict requirement is `pg_dump`-derived schema hash in evidence, current implementation differs.
- Current fields: `schema_fingerprint` + `migrations_fingerprint`
- `scripts/audit/generate_evidence.sh:17`
- `scripts/audit/generate_evidence.sh:37`

## What Needs To Be Done
1. Promote DB fail-closed invariant from roadmap to implemented.
- Add deterministic verification script and evidence artifact.
- Update `INV-039` status and wire into ordered checks/contract.

2. Strengthen boundary enforcement.
- Re-target `scripts/security/lint_core_boundary.sh` to real runtime paths in this repo, or create canonical core paths and enforce there.

3. Remove remaining architecture doc drift.
- Update `docs/overview/architecture.md` to match current repo topology.

4. Define and enforce outbox attempts retention/partition posture.
- Add doc + invariant + verifier.
- Optional: add migration if early partitioning is desired in current phase.

5. Optional governance hardening.
- Add deterministic `pg_dump`-derived schema hash in evidence if explicitly required.

## Notes
- This analysis was based on static repository inspection.
- Commands were not executed to re-run full local parity (`scripts/dev/pre_ci.sh`) in this report generation step.
