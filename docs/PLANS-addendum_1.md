# Addendum Plan 1 — Baseline Drift, Lint Policy, Docs Drift

## 1) Objectives and non-goals

### Objectives
- Standardize baseline generation using Postgres 18 container tooling to eliminate client/server version drift.
- Make baseline drift detection **canonical** (stable ordering + normalization), auditable, and reproducible.
- Require **intentional baseline refresh** with a human explanation artifact.
- Refine lock-risk lint to be hot-table aware with a **sealed exception** (fingerprinted + expiring allowlist).
- Formalize doc/manifest drift checks as a first-class invariant with evidence emission.
- Add a **local/CI parity guardrail** to prevent script drift.

### Baseline Governance Policy
- Baseline is derived from migrations and must be generated via container `pg_dump`.
- Baseline updates require:
  - at least one migration change in the same PR, and
  - an explanation artifact (ADR or plan log entry) describing why baseline changed.
- Baseline drift checks are fail-closed in CI and emit provenance evidence.

### DDL Exception Governance Policy
- Allowlist entries are fingerprinted and expiring.
- Allowlist changes require security review (CODEOWNERS).
- Evidence must report allowlist usage (hits, files, fingerprints).

### Non-goals
- No runtime DDL policy changes (still prohibited).
- No weakening of append-only or lease-fencing semantics.
- No production KMS or secret-management changes (OpenBao only).
- No Phase-1/Phase-2 runtime feature work.

## 2) Files/directories to touch

- `scripts/db/check_baseline_drift.sh`
- `scripts/db/canonicalize_schema_dump.sh` (new)
- `scripts/db/verify_invariants.sh`
- `schema/baseline.sql`
- `scripts/security/lint_ddl_lock_risk.sh`
- `scripts/security/hot_tables.txt` (new)
- `scripts/security/ddl_allowlist.json` (new)
- `.github/CODEOWNERS` (or existing codeowners file)
- `scripts/ci/verify_local_ci_parity.sh` (new)
- `scripts/audit/run_invariants_fast_checks.sh`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANTS_IMPLEMENTED.md`
- `docs/invariants/INVARIANTS_ROADMAP.md`
- `docs/invariants/INVARIANTS_QUICK.md`
- `docs/Phase_0001-0005/implementation_plan.md`
- `docs/PLANS-addendum_1.md`
- `tasks/TSK-P0-034/meta.yml`

## 3) Step-by-step tasks (execution order)

1) **Canonical schema dump**
   - Create `scripts/db/canonicalize_schema_dump.sh`.
   - Canonicalizer must:
     - remove volatile headers/SET statements
     - normalize ordering (stable sort) and whitespace
     - strip comments/blank lines after normalization
     - be versioned and used everywhere baseline compares occur

2) **Baseline provenance evidence**
   - Extend `scripts/db/check_baseline_drift.sh` to record:
     - `pg_dump_version`, `pg_server_version`
     - `dump_source` (container vs host)
     - `normalized_schema_sha256`
   - Evidence goes to `./evidence/phase0/baseline_drift.json`.

3) **Baseline update governance gate**
   - Add a gate (script or CI step) that fails if:
     - `schema/baseline.sql` changes without a migration change, **or**
     - no explanation artifact changed (ADR/plan note).
   - Require explicit note file (e.g., `docs/decisions/ADR-xxxx-baseline-policy.md` or a plan log entry).

4) **Hot-table list + sealed allowlist**
   - Add `scripts/security/hot_tables.txt` as the single source of hot tables.
   - Add `scripts/security/ddl_allowlist.json` with:
     - migration file
     - statement fingerprint hash
     - reason
     - `expires_on` (or `sunset_migration_id`)
   - Update `scripts/security/lint_ddl_lock_risk.sh` to:
     - read hot tables list
     - match allowlist by fingerprint only
     - fail on expired allowlist entries
     - emit evidence including allowlist hits

5) **Security review enforcement for allowlist**
   - Update `.github/CODEOWNERS` to require Security Guardian review for `ddl_allowlist.json`.

6) **Local/CI parity check**
   - Create `scripts/ci/verify_local_ci_parity.sh` that:
     - validates required scripts exist locally
     - validates CI workflow calls the same scripts
     - validates evidence paths are consistent
   - Run in CI before upload step.

7) **Docs drift check (Invariant)**
   - Keep `scripts/audit/check_docs_match_manifest.py` in fast checks.
   - Emit `./evidence/phase0/invariants_docs_match.json`.

8) **Docs update**
   - Update `docs/Phase_0001-0005/implementation_plan.md` to current state.
   - Regenerate `INVARIANTS_QUICK.md` and ensure Implemented/Roadmap match manifest.

## 4) New invariants needed + verification

### INV-044 — Invariants docs match manifest
- Verification: `scripts/audit/check_docs_match_manifest.py` (run via `scripts/audit/run_invariants_fast_checks.sh`).
- Evidence: `./evidence/phase0/invariants_docs_match.json`.
- Failure condition: Any mismatch between manifest and Implemented/Roadmap docs.

### INV-045 — Canonical baseline generation
- Verification: `scripts/db/check_baseline_drift.sh` must use `scripts/db/canonicalize_schema_dump.sh`.
- Evidence: `./evidence/phase0/baseline_drift.json` includes canonical hash + provenance fields.

### INV-046 — DDL allowlist governance
- Verification: `scripts/security/lint_ddl_lock_risk.sh` reads allowlist with expiry and enforces fingerprints.
- Evidence: `./evidence/phase0/ddl_blocking_policy.json` includes allowlist hits + expiries.

### INV-047 — Local/CI parity
- Verification: `scripts/ci/verify_local_ci_parity.sh` must pass in CI.
- Evidence: `./evidence/phase0/local_ci_parity.json`.

## 5) Existing invariants impacted (and non-weakening proof)

### INV-004 — Baseline snapshot must not drift
- Impact: baseline generation is canonicalized and provenance recorded.
- Proof of non-weakening: still fail-closed; evidence records canonical hash and tool source.

### INV-022 / INV-040 — DDL lock-risk linting
- Impact: lint becomes hot-table aware with sealed allowlist.
- Proof of non-weakening: lint still blocks unsafe DDL; only fingerprinted/expiring allowlist entries can bypass.

### INV-031 / INV-033 (Outbox index/MVCC posture)
- Impact: no functional change; verification stays in DB checks.
- Proof of non-weakening: tests remain required and evidence emitted.

### INV-044/045/046/047 (new)
- Impact: adds mechanical governance for docs drift, baseline canon, allowlist control, and local/CI parity.
- Proof of non-weakening: all checks are fail-closed with evidence emission.
