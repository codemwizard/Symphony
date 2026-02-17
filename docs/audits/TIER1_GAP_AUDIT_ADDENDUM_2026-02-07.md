# Tier-1 Gap Audit Addendum (Phase-0)

Date: 2026-02-07

This addendum extends `docs/audits/TIER1_GAP_AUDIT_2026-02-06.md` to cover:
- ISO/IEC 27001:2022 and ISO/IEC 27002:2022 expectations (mapped to Phase-0 mechanical enforcement and remaining gaps).
- ISO 20022 expectations for payments messaging (integrity, validation, semantics, non-repudiation) and Phase-0-safe prerequisites.
- Zero Trust Architecture assessment (in the sense of NIST SP 800-207 concepts, not a compliance claim).
- The repo’s exact forward-only “blue/green” migration mechanics and the preparatory invariants required to make rollback-by-routing safe.

## Important Scope Note
This document is an audit-style gap analysis for a Tier-1 posture. It does not claim certification or compliance with any standard.

## ISO/IEC 27001:2022 and ISO/IEC 27002:2022 (Addendum Mapping)

### Why these matter to Symphony’s Phase-0 business posture
If Symphony’s near-term value proposition is “risk certainty” and “audit-grade evidence packs,” Tier-1 buyers will align their due diligence to an ISMS (ISO 27001) and to a recognized controls catalog (ISO 27002). Even in Phase-0, they expect:
- A clear control story (policy + ownership + verification evidence).
- Explicit gaps with planned remediation.
- Tight governance around privileged access, change control, and traceability.

### What the repo already does that aligns well
The following repo properties are strong “mechanical control” indicators that support an ISO-aligned story:
- Change control and traceability for schema changes:
  - Forward-only migration process with checksum ledger (`scripts/db/migrate.sh`) and immutability invariants (see `docs/invariants/INVARIANTS_MANIFEST.yml` `INV-001..INV-003`).
  - Baseline drift detection (`INV-004`) and baseline governance checks (see `docs/decisions/ADR-0011-rebaseline-dayzero-schema.md`).
- Least privilege and hardening:
  - Revoke-first posture and “no runtime DDL” enforcement (`INV-005`, `INV-006`).
  - SECURITY DEFINER hardening via `SET search_path = pg_catalog, public` lint (`INV-008`).
- Evidence discipline:
  - Evidence metadata (git SHA + schema fingerprint) and schema validation (`INV-020`, `INV-028`), plus CI gate wiring.
- “Safe operations” posture:
  - DDL lock-risk lint + allowlist governance (`INV-022`, `docs/security/ddl_allowlist.json`, `SEC-DDL-001/002` in `docs/security/SECURITY_MANIFEST.yml`).

### ISO/IEC 27001:2022 gaps that should be explicitly declared in Phase-0
ISO 27001 is an ISMS standard: the “control” story is not only technical, it also includes governance, risk treatment, and management review. The repo is strong on technical gates, but Phase-0 appears to be missing (or only partially covered by docs) the following “ISMS artifacts” that Tier-1 programs commonly request even if the system is pre-production:
- ISMS scope statement and context:
  - In-scope services, environments, and data classes.
  - Interfaces and external dependencies.
- Risk assessment and risk treatment plan (even as a Phase-0 stub):
  - A minimal risk register with ownership and remediation milestones.
- Formalized policy stubs that are referenced by manifests and mechanically checked for presence:
  - Key management policy for evidence signing.
  - Logging retention and review policy (beyond a plan narrative).
  - Secure SDLC policy (including SAST coverage expectations).

Phase-0 “Tier-1 grade” expectation is not certification, but an evidence-oriented structure that can evolve into an ISMS. Mechanical gates should fail closed if required policy artifacts are missing, similar to how evidence gates work today.

### ISO/IEC 27002:2022 control mapping (where the repo is strong vs where it is thin)
ISO 27002:2022 is a controls catalog; buyers often want to see a mapping. The repo already contains a partial mapping via `docs/security/SECURITY_MANIFEST.yml` (it references “ISO 27001/27002 (A.8, A.12)” in multiple controls), but to be credible it should be made more systematic.

Strong signals (mechanical enforcement exists):
- Access control and privilege management (DB role posture):
  - `INV-005..INV-010`, `SEC-DB-002` in `docs/security/SECURITY_MANIFEST.yml`.
- Secure configuration management and change control:
  - DDL risk and allowlist governance (`INV-022`, `SEC-DDL-001/002`).
- Cryptography/key management foundation (partial):
  - OpenBao AppRole smoke test exists (`SEC-IAM-001`), but evidence signing key lifecycle is not mechanically specified or enforced in Phase-0.

Thin or missing (should be planned explicitly):
- Asset inventory and data classification:
  - There is no Phase-0 mechanical artifact enumerating “what data exists” (PII, payment metadata, secrets, logs) and its handling/retention requirements.
- Secure SDLC and vulnerability management evidence:
  - Static lints exist, but a Tier-1 program often expects a consistent SAST baseline (or a timeboxed exception with an explicit compensating control), plus evidence artifacts per run.
- Supplier relationship controls:
  - External dependencies (OpenBao, Postgres, CI toolchain, future adapters) should have documented supplier risk posture and update policy (Phase-0 can be a stub, but it should be explicit).

## ISO 20022 (Payments Messaging) Addendum

### What ISO 20022 is, in Tier-1 buyer terms
ISO 20022 defines a common language for financial messaging. A Tier-1 buyer cares less about the “logo” and more about:
- Deterministic message validation and strict scheme rules (reject ambiguous/malformed messages).
- Traceability across participants and rails (correlation, sequence, provenance).
- Non-repudiation and dispute evidence (signing policy, tamper-evidence).
- Backward compatible change management for message formats.

### What Phase-0 already has that supports ISO 20022 readiness
Symphony’s Phase-0 has “stitching hooks” that are aligned to payment traceability even before adapters exist:
- Correlation identifiers and references for ingress/outbox stitching (added as Phase-0 hooks in migrations).
- Append-only ledgers for attempts and attestations, supporting dispute-grade history.
- A strong migration discipline that supports evolvable schemas without downtime.

### What is missing for ISO 20022 “readiness” (Phase-0 safe)
This is the gap between “we can store correlation IDs” and “we can credibly say we implement ISO 20022 message integrity expectations.”

Recommended Phase-0 additions (docs + tests, not runtime adapters):
- Canonical message schema contract registry:
  - A repo-managed set of message format definitions (e.g., XSD versions) with version pinning and provenance.
- Adapter contract test harness:
  - Deterministic validation tests that take message fixtures and enforce:
    - structural validity (schema)
    - scheme rules (where applicable)
    - semantic constraints used by your orchestration layer
  - Evidence artifacts for these tests should be emitted, similar to other gates.
- “Message handling policy” stub:
  - Rules for rejecting vs quarantining vs accepting-but-flagging messages.
  - Rules for idempotency keys and correlation IDs, including collision and replay behavior.

The repo already acknowledges “ISO 20022 message integrity expectations” as a control (`SEC-INT-001` in `docs/security/SECURITY_MANIFEST.yml`), but Phase-0 currently marks verification as planned. That is acceptable, but for Tier-1 posture it should be backed by an explicit implementation plan and a minimal contract test skeleton.

## Zero Trust Architecture (ZTA) Addendum

### How ZTA applies here
The repo states it is implementing Zero Trust Architecture. For an audit-grade system, this should mean:
- Identity is the primary “perimeter.”
- Explicit policy decision and enforcement points (even if minimal in Phase-0).
- Continuous verification and strong telemetry (at least a plan and hooks in Phase-0).
- Least privilege everywhere, with tight blast-radius control and separation of duties.

### What the repo already aligns with (strong ZTA foundations)
- Deny-by-default database privileges and strong role boundaries (`INV-005..INV-010`).
- Explicit SECRETs access control testing (OpenBao smoke test `SEC-IAM-001`).
- Mechanical gates that reduce configuration drift and prevent dangerous change patterns (DDL lock lint, allowlists).
- Evidence discipline for changes and checks (evidence artifacts, schema fingerprinting).

### ZTA gaps that should be made explicit (and Phase-0-safe ways to close them)
The repo is currently ZTA-leaning in DB and CI governance, but typically missing the “end-to-end ZTA” elements that Tier-1 buyers look for:
- Workload identity and service-to-service authn/z:
  - Phase-0 should at least define the identity model for services (SPIFFE/SPIRE or equivalent, or a documented alternative).
- Policy decision/enforcement decomposition:
  - Define the “policy engine” and “policy enforcement point” architecture and show where it is wired in.
- Telemetry and continuous verification:
  - Phase-0 can add mechanical “telemetry contracts”:
    - required log fields for traceability (correlation_id, participant_id, tenant_id)
    - minimum audit events for key workflows (enqueue, claim, attempt, attest, evidence pack creation)
  - Provide a verifier that these fields/events exist in code paths (even if the sinks are stubbed).

Without these, “Zero Trust” risks reading as a slogan. The repo’s mechanical approach suggests these should be expressed as invariants and verifiers, not only as narrative docs.

## Exact Forward-Only Blue/Green Migration Process (Repo-Specific)

### What “blue/green migration” means in this repo
This repo is designed so rollback is achieved by routing traffic back to the prior version (blue), not by reverting schema.

That only works if:
- Schema changes are forward-only and additive.
- The new application version is compatible with the previous schema during rollout, and the previous version can continue operating against the schema after migrations have been applied (N-1 compatibility).

### Mechanical building blocks in the repo
These are the concrete mechanisms used:
- Migration runner with checksum ledger:
  - `scripts/db/migrate.sh` creates/updates `public.schema_migrations` and records a sha256 checksum for every migration applied.
  - A checksum mismatch hard-fails, enforcing immutability (`INV-001..INV-003`).
- Transaction discipline:
  - Each migration is wrapped in its own transaction unless `-- symphony:no_tx` is declared or `CREATE INDEX CONCURRENTLY` is detected (needed for concurrent indexing).
  - “No top-level BEGIN/COMMIT in migration files” is enforced by lint (`INV-002`).
- Post-migration safety:
  - `scripts/db/migrate.sh` checks for invalid/unready indexes in `public` and fails if present.
- N-1 compatibility gate:
  - `scripts/db/n_minus_one_check.sh` spins up temporary “prev” and “curr” databases:
    - `prev` applies all migrations except the latest.
    - `curr` applies all migrations.
  - It then compares the `information_schema.columns` output to ensure the newer schema did not remove tables/columns or introduce incompatible type/nullable changes for existing columns.
  - This is enforced as `INV-021` (“N-1 compatibility gate”).
- Routing fallback invariants:
  - `INV-025` and `INV-026` require and validate routing fallback behavior, supporting rollback-by-routing at the platform layer.

### Step-by-step: how to do a forward-only blue/green rollout
This is the intended operational sequence implied by the scripts and invariants.

1. Prepare migrations as additive changes.
- Prefer:
  - adding new tables/columns
  - adding nullable columns first
  - adding NOT VALID foreign keys, then validating later when safe
  - adding indexes using `CONCURRENTLY` when appropriate (ensure `-- symphony:no_tx`)
- Avoid:
  - dropping columns or tightening nullability on existing columns in the same release as behavioral code changes
  - retyping existing columns in a way that breaks old readers/writers

2. Prove N-1 compatibility before shipping.
- Run the repo’s N-1 gate (`scripts/db/n_minus_one_check.sh`) as a pre-merge/CI gate.
- If the check fails, restructure the migration into a two-phase approach:
  - phase A: additive changes
  - phase B: cleanup/removal in a later release after all workloads are cut over

3. Apply migrations once (forward-only) in the target environment.
- Use `scripts/db/migrate.sh` with the configured strategy:
  - `SCHEMA_MIGRATION_STRATEGY=migrations` for normal forward-only evolution.
  - `SCHEMA_MIGRATION_STRATEGY=baseline_then_migrations` for “baseline + cutoff + subsequent migrations” flows.

4. Deploy green (new app version) and shift traffic gradually.
- Maintain compatibility:
  - green must operate on the migrated schema.
  - blue must continue to operate on the migrated schema if traffic is shifted back.

5. If needed, roll back by routing (not schema rollback).
- Routing fallback invariants (`INV-025`, `INV-026`) are intended to make this safe.
- Because schema is not rolled back, destructive migrations must be postponed until blue is fully retired and no rollback is required.

6. Follow-up migrations (later release).
- After stable cutover, you can:
  - validate previously NOT VALID constraints
  - tighten constraints in a controlled way (ideally behind gates and with evidence)
  - remove deprecated columns/tables only after formal deprecation windows

### Preparatory invariants that must exist (and be kept strict) to make this safe
The following invariants are the “minimum set” that make blue/green forward-only credible in a Tier-1 setting:
- Migration immutability and discipline:
  - `INV-001`, `INV-002`, `INV-003`
  - `INV-004` (baseline drift)
- N-1 compatibility:
  - `INV-021`
- No runtime DDL and least privilege (prevents “schema drift via production code”):
  - `INV-005`, `INV-006`, `INV-010`
  - `INV-008` (SECURITY DEFINER hardening)
- DDL operational safety:
  - `INV-022` (DDL lock-risk lint)
- Rollback-by-routing safety:
  - `INV-025`, `INV-026`
- Evidence discipline (auditability of gates and artifacts):
  - `INV-020`, `INV-028`

If any of these are weakened, “rollback-by-routing” becomes unreliable or becomes a change-management risk.

## External References (Non-Repo)
This addendum used high-level, publicly available sources for standard framing. Full ISO standards text is typically paywalled; therefore, this report does not quote or depend on paywalled text.

References:
- NIST SP 800-207: Zero Trust Architecture
  - https://csrc.nist.gov/pubs/sp/800/207/final
- ISO/IEC 27001 overview
  - https://www.iso.org/standard/82875.html
- ISO/IEC 27002 overview
  - https://www.iso.org/standard/75652.html
- ISO 20022 (official site)
  - https://www.iso20022.org/
- ISO 20022: Message definitions
  - https://www.iso20022.org/iso-20022-message-definitions

