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

### Data Plane (PostgreSQL)
- Tampering: direct DML or DDL
- Repudiation: missing evidence on writes
- DoS: lock contention
- EoP: role privilege escalation

Mitigations:
- Revoke-first posture, no runtime DDL
- SECURITY DEFINER functions with pinned search_path
- CI invariant gates for privileges and append-only rules

## Priority security actions
1) Implement service identity and mTLS for internal calls.
2) Enforce policy checksum verification in ingest/orchestration path.
3) Add append-only ledger schema and invariant tests.
4) Define PCI boundary and tokenization approach.
5) Establish evidence bundle generation and retention.
