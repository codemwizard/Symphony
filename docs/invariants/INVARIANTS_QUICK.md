# Invariants Quick Reference (Implemented Only)

_Generated from `docs/invariants/INVARIANTS_MANIFEST.yml` (do not edit by hand)._

| ID | Severity | Title | Owners | Verification |
|---|---|---|---|---|
| INV-001 | P0 | Applied migrations are immutable (checksum ledger) | ["team-db"] | scripts/db/migrate.sh checksum check; run via scripts/db/verify_invariants.sh |
| INV-002 | P0 | Migration files must not contain top-level BEGIN/COMMIT | ["team-db"] | scripts/db/lint_migrations.sh; run via scripts/db/verify_invariants.sh |
| INV-003 | P0 | Fix forward only: changes via new migrations, never by editing applied ones | ["team-db"] | scripts/db/migrate.sh checksum immutability (same as INV-001); run via scripts/db/verify_invariants.sh |
| INV-005 | P0 | Deny-by-default privileges (revoke-first posture) | ["team-platform"] | schema/migrations/0004_privileges.sql + scripts/db/ci_invariant_gate.sql; run via scripts/db/verify_invariants.sh |
| INV-006 | P0 | No runtime DDL: PUBLIC/runtime roles must not have CREATE on schema public | ["team-platform"] | scripts/db/ci_invariant_gate.sql (schema CREATE privilege check); run via scripts/db/verify_invariants.sh |
| INV-007 | P0 | Runtime roles are NOLOGIN templates; services assume them via SET ROLE | ["team-platform"] | schema/migrations/0003_roles.sql creates roles NOLOGIN; run via scripts/db/verify_invariants.sh |
| INV-008 | P0 | SECURITY DEFINER functions must pin search_path to pg_catalog, public | ["team-platform"] | scripts/db/lint_search_path.sh; run via scripts/db/verify_invariants.sh |
| INV-010 | P0 | Runtime roles have no direct DML on core tables; writes happen via DB API functions | ["team-platform"] | scripts/db/ci_invariant_gate.sql (role privilege posture) + schema/migrations/0004_privileges.sql |
| INV-011 | P0 | Outbox enqueue is idempotent on (instruction_id, idempotency_key) | ["team-db"] | schema/migrations/0002_outbox_functions.sql unique constraint + enqueue_payment_outbox(); scripts/db/verify_invariants.sh |
| INV-012 | P0 | Outbox claim uses FOR UPDATE SKIP LOCKED and only due/unleased or expired rows | ["team-db"] | schema/migrations/0002_outbox_functions.sql claim_outbox_batch(); scripts/db/verify_invariants.sh |
| INV-013 | P0 | Strict lease fencing: completion requires matching claimed_by + lease_token and non-expired lease | ["team-db"] | schema/migrations/0002_outbox_functions.sql complete_outbox_attempt(); scripts/db/verify_invariants.sh |
| INV-014 | P0 | payment_outbox_attempts is append-only; no UPDATE/DELETE | ["team-db"] | schema/migrations/0001_init.sql append-only trigger + scripts/db/ci_invariant_gate.sql |
| INV-015 | P0 | Outbox retry ceiling is finite | ["team-db"] | schema/migrations/0002_outbox_functions.sql (GUC retry ceiling) + scripts/db/ci_invariant_gate.sql |
| INV-016 | P0 | policy_versions exists and supports boot query shape (is_active=true) | ["team-platform"] | schema/migrations/0005_policy_versions.sql (status/is_active) + scripts/db/ci_invariant_gate.sql |
| INV-017 | P0 | policy_versions.checksum is NOT NULL | ["team-platform"] | schema/migrations/0005_policy_versions.sql (checksum NOT NULL) + scripts/db/ci_invariant_gate.sql |
| INV-018 | P0 | Single ACTIVE policy row enforced by unique predicate index | ["team-platform"] | schema/migrations/0005_policy_versions.sql (single ACTIVE index) + scripts/db/ci_invariant_gate.sql |
