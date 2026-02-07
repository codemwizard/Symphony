# Tier-1 Gap Audit vs Business Goals (Phase-0)

Date: 2026-02-06

## Executive Summary
Symphony is building a regulator-grade payments execution and evidence system. Phase-0 is unusually strong on mechanical governance (forward-only migrations, append-only ledgers, fail-closed CI gates, evidence artifacts, OpenBao parity, privilege hardening). That is the right foundation for a Tier-1 buyer.

However, if the near-term business goal is to sell “risk certainty” and “audit/dispute packs,” the current Phase-0 posture still has several **Tier-1 blockers**:

- **Key management and evidence signing policy is missing**: the repo assumes future KMS/HSM, but lacks a Phase-0 key management policy stub and a mechanical gate that it exists and is referenced.
- **SAST depth and secure SDLC evidence is shallow**: current security checks are primarily pattern/heuristic lints. Tier-1 audit programs typically expect repeatable SAST/secure SDLC controls with documented scope, tuning, and evidence artifacts (even if Phase-0 is “static only”).
- **Audit logging retention and review controls are documented but not enforced**: there is a logging plan document, but no Phase-0 mechanical verifier for retention settings, time sync expectations, or “watch the watcher” operational evidence.
- **Participant registry (legal/rail identity) is not modeled**: there is `participant_id` usage and sequence allocation, but no authoritative participants table suitable for KYB-ish business proofs or IPDR stitching.
- **Detached signature and anchoring hooks for evidence packs are incomplete**: evidence packs exist as schema hooks, but the system does not yet have canonical fields/policy for signing and anchoring packs (Phase-0 hooks can exist even if runtime comes later).

Phase-0 should not implement full runtime integrations, but it should add **the remaining schema and governance hooks** that make later Evidence-as-a-Service and IPDR “real” without schema redesign.

## Business Goals Interpreted From Repo
From Phase-0 docs and the “business invariants” direction, the monetizable product lines are:

- Payment orchestration core (non-custodial middleware) with deterministic execution safety.
- Evidence-as-a-Service: saleable evidence bundles/case packs.
- Dispute packs / Inter-Participant Dispute Resolution (IPDR): stitched lifecycles across participants/rails.
- External proof anchoring: hashed third-party verifications attached to durable attestations.
- Usage/billing ledger: append-only “cash register tape” for billing events.

## What Phase-0 Already Implements (Strengths)
These are Tier-1 positive indicators because they are mechanically enforced:

- Forward-only migrations and no runtime DDL.
- Privilege hardening (revoke-first posture) and SECURITY DEFINER search_path lint.
- Append-only ledgers for outbox attempts and ingress attestations.
- Deterministic evidence harness with CI gate enforcement (Phase-0 contract driven).
- DDL lock-risk lint and allowlist governance.
- Local/CI parity harness (pre-CI, ordered checks) and pinned toolchain gate.

## Tier-1 Gaps (What Should Exist in Phase-0 but Does Not Yet)

### Gap 1: Key management policy stub for evidence signing (Tier-1 blocker)
**Why it matters**: If evidence packs are a product, the integrity of signatures and the lifecycle of keys is foundational. Key management guidance in regulated programs expects documented controls for generation, storage, access, rotation, and revocation.

**Repo state**:
- Architecture docs reference KMS/HSM, but there is no Phase-0 key management policy stub under `docs/security/` and no mechanical gate that it exists.

**Phase-0 fix**:
- Add `docs/security/KEY_MANAGEMENT_POLICY.md` (stub) covering:
  - key ownership and access controls
  - rotation cadence
  - revocation and incident response
  - separation of duties (who can sign, who can rotate)
  - where keys live (OpenBao vs external KMS/HSM)
- Add a verifier (audit script) that fails if the policy stub is missing and not referenced by the security manifest.

Web references:
- NIST key management guidance: NIST SP 800-57 Part 1.

### Gap 2: Evidence signing and anchoring hooks (schema + governance)
**Why it matters**: Tier-1 evidence programs expect tamper-evident, attributable bundles. Even if Phase-0 does not implement runtime signing, it should establish canonical schema hooks.

**Repo state**:
- Evidence pack primitives exist.
- There is no standard contract for:
  - detached signature fields for packs
  - anchoring fields (batch root hash anchoring lifecycle)

**Phase-0 fix**:
- Add fields to evidence pack schema to support:
  - pack detached signature metadata (algorithm, key id, signature bytes/hash)
  - anchoring metadata (anchor method, anchor tx id / external reference)
- Add a verifier that asserts these columns exist and tables remain append-only.

### Gap 3: Participant registry (rail/legal identity)
**Why it matters**: IPDR and external proof products need stable identity anchors for participants (banks/MMOs/registries) beyond ad hoc TEXT identifiers.

**Repo state**:
- `participant_id TEXT` exists in outbox and ingress.
- No `participants` table.

**Phase-0 fix**:
- Add a `participants` table (append-only or controlled mutation with strong governance) including:
  - participant type (BANK/MMO/REGISTRY)
  - regulator refs
  - optional KYB proof hash references
- Update schema hooks and verifiers accordingly.

### Gap 4: SAST depth and secure SDLC evidence
**Why it matters**: Pattern-based lints are useful, but Tier-1 audit programs often expect either a recognized SAST tool or a documented secure SDLC with repeatable scanning evidence.

**Repo state**:
- Security lints exist for SQL injection, privilege grants, insecure patterns, etc.
- No Semgrep/CodeQL/Snyk-style SAST integration is visible.

**Phase-0 fix**:
- Add a Phase-0 safe control plane gate that:
  - runs a SAST tool in CI (or explicitly records SKIPPED with a timeboxed exception until adopted)
  - emits evidence with tool version + files scanned
- Document control mapping in `docs/security/SECURITY_MANIFEST.yml`.

Web references:
- OWASP ASVS is a common application security verification baseline.

### Gap 5: Audit logging retention, review, and time sync enforcement
**Why it matters**: Logging plans alone are not sufficient for Tier-1 audits. Typical requirements include retention periods, time synchronization, and periodic review.

**Repo state**:
- `docs/security/AUDIT_LOGGING_PLAN.md` exists.
- No mechanical verifier asserts retention values, time sync requirements, or that logs are immutable/anchored.

**Phase-0 fix**:
- Add `docs/security/AUDIT_LOGGING_RETENTION_POLICY.md` with explicit retention durations and review cadence.
- Add a verifier that ensures:
  - the policy exists
  - it is referenced by security manifest
  - the policy contains specific required fields (retention, time sync, review cadence)

Web references:
- NIST SP 800-92 (Guide to Computer Security Log Management).
- PCI DSS v4.0 includes logging/monitoring expectations (retention and review requirements vary by scope).

### Gap 6: Privilege posture and REVOKE hygiene on new business tables
**Why it matters**: Tier-1 systems often apply uniform REVOKE posture and explicitly avoid implicit privilege drift.

**Repo state**:
- Some tables explicitly REVOKE from PUBLIC.
- New business tables should follow the same explicit REVOKE and grant posture.

**Phase-0 fix**:
- Add explicit `REVOKE ALL ON TABLE ... FROM PUBLIC;` for new tables.
- Add grant posture only via DB APIs (Phase-1+), but ensure runtime roles do not gain direct DML.

## Suggested Next Phase-0 Task Cluster (Recommended)
1. Key management policy stub + verifier + manifest mapping.
2. Evidence pack signing/anchoring schema hooks + verifier.
3. Participants registry schema + verifier.
4. SAST gate adoption plan: either Semgrep/CodeQL baseline or a timeboxed exception + evidence.
5. Audit logging retention policy stub + verifier.

## Web Sources
- NIST SP 800-57 Part 1 (Key Management Guidelines): https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final
- NIST SP 800-92 (Computer Security Log Management): https://csrc.nist.gov/publications/detail/sp/800-92/final
- OWASP ASVS (Application Security Verification Standard): https://owasp.org/www-project-application-security-verification-standard/
- PCI DSS v4.0 (overview): https://www.pcisecuritystandards.org/standards/pci-dss/
