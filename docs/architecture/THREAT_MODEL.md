# Threat Model

## Assets
- Payment instructions and routing decisions
- Ledger journal and postings
- Policy bundles and checksums
- Secrets, keys, certificates
- Audit logs and evidence bundles

## Actors
- External attackers (internet-based)
- Malicious insider
- Compromised service identity
- Supply-chain attacker (dependencies)

## Attack surfaces
- Public API endpoints
- Service-to-service RPC
- Database functions and roles
- Secrets management and key access
- CI/CD and policy promotion pipeline

## STRIDE threats by component

### Edge Gateway
- Spoofing: forged client identity
- Tampering: payload modification
- Repudiation: lack of request logging
- Information disclosure: data leakage in errors
- Denial of service: request floods
- Elevation of privilege: authz bypass

Mitigations:
- mTLS + strong client auth, rate limiting, structured audit logs
- Schema validation and strict error codes
- WAF rules and payload limits

### Ingest Service
- Spoofing: service identity misuse
- Tampering: instruction alteration
- Repudiation: idempotency disputes
- Information disclosure: policy/version leakage
- DoS: hot queue saturation
- EoP: direct table writes

Mitigations:
- Service identity with least privilege and DB API only
- Idempotency enforcement, append-only outbox attempts
- Structured audit logs and policy checksum verification

### Hardening Update 2026-03-05 (TSK-HARD-012)
- Threat: auto-finalization while inquiry is in uncertain/exhausted state can release value without confirmed rail outcome.
- Threat: illegal inquiry lifecycle transitions can bypass containment semantics.
- Mitigations:
- DB-enforced inquiry state enum (`SCHEDULED`, `SENT`, `ACKNOWLEDGED`, `EXHAUSTED`) and guarded transition functions.
- Fail-closed SQLSTATE guard (`P7301`) on auto-finalize attempts from `EXHAUSTED`.
- Policy-resolved `max_attempts` contract check to prevent compiled-in thresholds.

### Orchestration Service
- Tampering: route changes
- Repudiation: retry/dispatch disputes
- Info disclosure: partner secrets
- DoS: worker starvation
- EoP: bypass of policy checks

Mitigations:
- Policy engine enforcement, deterministic retry ceilings
- Secrets isolation per adapter, audit events for decisions
- SKIP LOCKED claims and lease fencing

### Ledger Core
- Tampering: ledger manipulation
- Repudiation: posting disputes
- Info disclosure: ledger data leakage
- EoP: bypassing double-entry constraints

Mitigations:
- Append-only journal, immutable postings
- DB constraints and stored procedures
- Strong audit logging and reconciliation reports

### Policy Service
- Tampering: policy edits
- Repudiation: promotion disputes
- Info disclosure: policy content exposure

Mitigations:
- Signed policy bundles, checksum enforcement
- Promotion workflow with audit logs and approvals

### CI/CD Pipeline
- Tampering: unsafe DDL or privilege changes merged
- Repudiation: missing evidence for invariant claims
- Supply-chain: unreviewed changes to security posture
- Drift risk: inconsistent diff semantics between local gates and CI jobs

Mitigations:
- Mechanical gates: evidence schema validation + required artifact checks
- Security lints: DDL lock-risk lint, SECURITY DEFINER dynamic SQL lint
- Privilege lint hardening for multiline `GRANT CREATE ON SCHEMA public TO ...;` detection
- Canonical diff helper (`scripts/lib/git_diff.sh`) for range/staged/worktree semantics
- Structural change rule: threat/compliance docs updated or timeboxed exception
- Local pre-push uses a CI-user migration parity probe to catch role/bootstrap divergence before remote CI

### Data Plane (PostgreSQL)
- Tampering: direct DML or DDL
- Tampering: post-settlement mutation of finalized payment outcome
- Repudiation: missing evidence on writes
- DoS: lock contention
- DoS: unbounded statement/lock/idle transaction execution
- Integrity drift: anchor-sync completion without valid lease/token or missing anchor reference
- Integrity drift: premature runtime coupling to Phase-0 levy calculation storage hook before policy/runtime activation phase
- EoP: role privilege escalation

Mitigations:
- Revoke-first posture, no runtime DDL
- SECURITY DEFINER functions with pinned search_path
- CI invariant gates for privileges and append-only rules
- DDL lock-risk lint and blocking policy enforcement
- SECURITY DEFINER dynamic SQL lint
- Instruction finality table with fail-closed trigger semantics (update/delete blocked with SQLSTATE `P7003`)
- Timeout posture verifier enforces bounded `lock_timeout`, `statement_timeout`, and `idle_in_transaction_session_timeout` (INT-G32 / INV-117)
- Ingress hot-path index verifier enforces tenant/instruction/correlation query path index posture (INT-G33 / INV-118)
- Anchor-sync operational state machine enforces lease-token worker fencing, anchored-before-complete gating, and deterministic expired-lease repair in DB functions.
- Phase-0 levy schema hooks are storage-only (`levy_rates`, `ingress_attestations.levy_applicable`) with explicit runtime-read/write prohibition until Phase-2 and verifier enforcement to prevent scope creep.
- Phase-0 levy calculation records hook (`levy_calculation_records`) is storage-only and verifier-guarded against runtime references/index drift until Phase-2 activation.
- Elevation of privilege: authz bypass

Mitigations:
- mTLS + strong client auth, rate limiting, structured audit logs
- Schema validation and strict error codes
- WAF rules and payload limits

### Ingest Service
- Spoofing: service identity misuse
- Tampering: instruction alteration
- Repudiation: idempotency disputes
- Information disclosure: policy/version leakage
- DoS: hot queue saturation
- EoP: direct table writes

Mitigations:
- Service identity with least privilege and DB API only
- Idempotency enforcement, append-only outbox attempts
- Structured audit logs and policy checksum verification

### Orchestration Service
- Tampering: route changes
- Repudiation: retry/dispatch disputes
- Info disclosure: partner secrets
- DoS: worker starvation
- EoP: bypass of policy checks

Mitigations:
- Policy engine enforcement, deterministic retry ceilings
- Secrets isolation per adapter, audit events for decisions
- SKIP LOCKED claims and lease fencing

### Ledger Core
- Tampering: ledger manipulation
- Repudiation: posting disputes
- Info disclosure: ledger data leakage
- EoP: bypassing double-entry constraints

Mitigations:
- Append-only journal, immutable postings
- DB constraints and stored procedures
- Strong audit logging and reconciliation reports

### Policy Service
- Tampering: policy edits
- Repudiation: promotion disputes
- Info disclosure: policy content exposure

Mitigations:
- Signed policy bundles, checksum enforcement
- Promotion workflow with audit logs and approvals

### CI/CD Pipeline
- Tampering: unsafe DDL or privilege changes merged
- Repudiation: missing evidence for invariant claims
- Supply-chain: unreviewed changes to security posture
- Drift risk: inconsistent diff semantics between local gates and CI jobs

Mitigations:
- Mechanical gates: evidence schema validation + required artifact checks
- Security lints: DDL lock-risk lint, SECURITY DEFINER dynamic SQL lint
- Privilege lint hardening for multiline `GRANT CREATE ON SCHEMA public TO ...;` detection
- Canonical diff helper (`scripts/lib/git_diff.sh`) for range/staged/worktree semantics
- Structural change rule: threat/compliance docs updated or timeboxed exception
- Local pre-push uses a CI-user migration parity probe to catch role/bootstrap divergence before remote CI

### Data Plane (PostgreSQL)
- Tampering: direct DML or DDL
- Tampering: post-settlement mutation of finalized payment outcome
- Repudiation: missing evidence on writes
- DoS: lock contention
- DoS: unbounded statement/lock/idle transaction execution
- Integrity drift: anchor-sync completion without valid lease/token or missing anchor reference
- Integrity drift: premature runtime coupling to Phase-0 levy calculation storage hook before policy/runtime activation phase
- EoP: role privilege escalation

Mitigations:
- Revoke-first posture, no runtime DDL
- SECURITY DEFINER functions with pinned search_path
- CI invariant gates for privileges and append-only rules
- DDL lock-risk lint and blocking policy enforcement
- SECURITY DEFINER dynamic SQL lint
- Instruction finality table with fail-closed trigger semantics (update/delete blocked with SQLSTATE `P7003`)
- Timeout posture verifier enforces bounded `lock_timeout`, `statement_timeout`, and `idle_in_transaction_session_timeout` (INT-G32 / INV-117)
- Ingress hot-path index verifier enforces tenant/instruction/correlation query path index posture (INT-G33 / INV-118)
- Anchor-sync operational state machine enforces lease-token worker fencing, anchored-before-complete gating, and deterministic expired-lease repair in DB functions.
) for both `levy_calculation_records.reporting_period` and `levy_remittance_periods.period_code` to avoid backslash-escape drift in SQL regex semantics.
- Phase-0 KYC provider registry hook (`kyc_provider_registry`) is storage-only with explicit runtime-read/write prohibition until Phase-2 activation and verifier enforcement to prevent scope creep.
- Perf promotion is fail-closed under `INV-120`: baseline lock + regression enforcement + runtime batching/AOT proof are required before perf-stage progression.
- Escrow state transitions are enforced in DB (`transition_escrow_state`) with stable SQLSTATE rejection for illegal/terminal transitions and append-only escrow event trail (`INV-127`).
- Escrow reservations are ceiling-enforced under concurrency via `authorize_escrow_reservation()` locking `escrow_envelopes` `FOR UPDATE` and failing closed on oversubscription (`INV-128`).
- Phase-1 member-device distribution mapping is enforced via `member_devices` tenant/member denormalization constraints and active-path index posture with deterministic verifier evidence (`TSK-P1-HIER-003`).
- Phase-1 member-device event stream is append-only via trigger-enforced mutation denial and ingress-anchored instruction linkage with deterministic verifier evidence (`TSK-P1-HIER-004`).
- Phase-1 hierarchy verification uses `verify_instruction_hierarchy()` deterministic SQLSTATE gating to fail-closed on tenant/participant/program/entity/member/device link violations (`TSK-P1-HIER-005`, INV-077, INV-119).
- Phase-1 hierarchy SQLSTATE conformance suite (`TSK-P1-HIER-009`) exhaustively verifies declared `verify_instruction_hierarchy()` mappings (`P7299`-`P7303`) and documents reserved gap posture for `P7304`-`P7307`.
- Phase-1 program migration contract suite (`TSK-P1-HIER-010`) enforces additive person-to-program migration semantics with deterministic duplicate-call SQLSTATE handling and append-only migration-event evidence.
- Phase-1 supervisor access mechanisms suite (`TSK-P1-HIER-011`) enforces signed aggregate READ_ONLY report delivery, time-bounded/revocable AUDIT token access to anonymized records, and APPROVAL_REQUIRED self-approval denial via hardened approval functions and endpoint verifiers.
- Phase-1 tenant isolation suite (`TSK-P1-TEN-002`) enforces restrictive + forced RLS across all tenant-scoped tables (`tenant_id`) and verifies cross-tenant leakage denial under role-constrained runtime probes.
- Phase-1 INF-002 container pipeline enforces digest-pinned base images, non-root runtime users, and deterministic rebuild digest checks for `ledger-api`, `executor-worker`, and `db-migration-job` images before progression.
- Phase-1 INF-001 sandbox Postgres HA posture requires operator-style multi-instance cluster declaration, scheduled backups, and PITR recovery proof metadata before infrastructure-stage progression.
- Phase-1 risk formula registry + program migration introduces append-only `risk_formula_registry`, deterministic `programs.default_risk_tier` enforcement, and read-only projection posture (`vw_program_tier_effective`) with verifier-backed evidence (`TSK-P1-HIER-007`).
- Phase-1 SIM-swap alert derivation (`TSK-P1-HIER-008`) is implemented as hardened `SECURITY DEFINER` DB function (`derive_sim_swap_alert`) writing append-only `sim_swap_alerts` rows with one-alert-per-source-event idempotency and non-null `formula_version_id` traceability (`INV-129`).
- Phase-1 incident workflow (`TSK-P1-REG-003`) enforces append-only incident event timelines and blocks report export while status is `OPEN`, reducing premature/regulator-inaccurate disclosure risk while preserving signed 48-hour evidence output.
- Wave-1 hardening (TSK-P1-211..215) enforces fail-closed OpenBao runtime secret resolution, restores safe ingress durability indexing, and locks supplier allowlist structures under RLS.
- Wave-3 hardening (`0064_hard_wave3_reference_strategy_and_registry.sql`) mitigates reference-collision replay and policy-drift risks through deterministic registry allocation, active-policy immutability guards, and bounded canonicalization controls.
- Phase-1 CQRS split (`CQRS-001`, `CQRS-002`) isolates command handlers from query handlers in `ledger-api`, reduces monolithic bootstrap risk, and constrains projection access through distinct command/query role posture so externally consumed reads cannot quietly inherit mutation authority.
- Phase-1 projection cutover (`PROJ-001`, `PROJ-002`) requires deterministic `instruction_status_projection`, `evidence_bundle_projection`, and `incident_case_projection` read models with visible freshness markers (`as_of_utc`, `projection_version`) so evidence/report queries do not read hot operational tables directly.
- Sprint-3 cutover (`CUT-001`..`CUT-004`) treats projection promotion as a fail-closed governance seam: legacy references must be removed, public query surfaces must stay handler-mediated, rollback/runbook discipline must be explicit, and promotion must be blocked unless prerequisite proofs are present.
- Hardening Wave-4 signing controls (`TSK-HARD-050`..`TSK-HARD-054`, `TSK-HARD-011B`, `TSK-HARD-096`) enforce key-class authorization boundaries, unsigned policy-bundle rejection, dependency-gated re-sign sweep execution, archive-only historical verification, and explicit HSM-bypass denial with verifier-backed evidence and SQLSTATE mapping alignment.
- Wave-2 post-review hardening fix (`0068_wave2_finality_and_seal_hardening_fixes.sql`) enforces immutable effect seals, durable finality-conflict containment records (return-state hold semantics), and PUBLIC execute revocation on Wave-1 SECURITY DEFINER control functions.
- Wave-2 hardening (`0076_onboarding_control_plane.sql`, TSK-P1-216, TSK-P1-217) persists operator onboarding state, enabling fully decoupled key domains (`api`, `admin`, `session`, `instruction`, `signing`) and removing dynamic `SYMPHONY_KNOWN_TENANTS` scope-bypass risks. Onboarding control-plane tables are safeguarded by RLS and audit timestamps.
- Phase-1 Green Finance Wave 1 (`GF-W1-FNC-001`..`GF-W1-FNC-007B`) enforces comprehensive DB-layer functional verifiers, execution confinement, cryptographic evidence signatures, and RLS constraint propagation for project structures, asset lifecycles, and verification authorities.
## Priority security actions
1) Implement service identity and mTLS for internal calls.
2) Enforce policy checksum verification in ingest/orchestration path.
3) Add append-only ledger schema and invariant tests.
4) Define PCI boundary and tokenization approach.
5) Establish evidence bundle generation and retention.
- Hardening Wave-5 reference-strategy corrective migration (`0067_hard_wave5_reference_strategy_rotation_and_allocation_race.sql`) restores ACTIVE policy rotation viability, enforces fail-closed raw reference-length rejection (`P7901`) before truncation, and hardens concurrent allocation races by retrying on atomic unique-collision paths.
- Hardening Wave-6 guard patch (`0069_hard_wave6_merkle_and_policy_rotation_guards.sql`) closes Merkle leaf null-expected-hash bypass by fail-closing with `P8303` and preserves reference-policy row immutability during ACTIVE→INACTIVE rotation by forbidding policy/signature metadata rewrites on formerly active rows.
- Hardening Wave-6 immutability follow-up (`0072_hard_wave6_reference_policy_post_deactivation_immutability.sql`) blocks post-rotation policy tampering by enforcing protected-field immutability after ACTIVE→INACTIVE transitions while retaining legal status rotation semantics.
- Wave-F onboarding RLS hardening (`0077_harden_rls_onboarding_control_plane.sql`) enforces FORCE ROW LEVEL SECURITY on onboarding control-plane tables (`onboarding_requests`, `onboarding_steps`, `onboarding_approvals`) to prevent cross-tenant data leakage during operator-initiated tenant provisioning flows. Recipient landing page (`src/recipient-landing/`) is a public-facing static form with no direct DB access.
- Pilot Demo onboarding grant (`0114_grant_onboarding_tables_to_app_role.sql`, TSK-P1-DEMO-031) conditionally creates `symphony_app_role` (NOLOGIN) and grants narrowly scoped SELECT/INSERT/UPDATE on onboarding control-plane tables (`tenant_registry`, `programme_registry`, `programme_policy_binding`). No DELETE or DDL privileges are granted. The role follows revoke-first posture and cannot CREATE or ALTER schemas. Exception: `EXC-20260404-DEMO-031`.
