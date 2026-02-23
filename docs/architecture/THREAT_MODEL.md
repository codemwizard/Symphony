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
- Phase-0 levy period format checks are hardened to canonical regex (`^[0-9]{4}-[0-9]{2}# Threat Model

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

## Priority security actions
1) Implement service identity and mTLS for internal calls.
2) Enforce policy checksum verification in ingest/orchestration path.
3) Add append-only ledger schema and invariant tests.
4) Define PCI boundary and tokenization approach.
5) Establish evidence bundle generation and retention.
