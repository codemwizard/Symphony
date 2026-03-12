# Symphony Storage and Integrity Position

Status: AUTHORITATIVE (Phase-1 Position)
Owner: Architecture/Security/Governance
Effective date: 2026-03-11

## 1. Decision Summary

Symphony adopts two linked decisions:

1. Storage backend decision:
   - Move sandbox object-storage usage from MinIO to SeaweedFS S3 gateway.
   - Primary driver: MinIO license restrictions and long-term governance risk.

2. Integrity model decision:
   - Symphony explicitly positions its Phase-1 trust model as a tamper-evident architecture.
   - Symphony does not claim permanent immutable storage as its primary guarantee.

## 2. Why This Change Exists

The previous framing mixed two different concerns:

- Storage characteristics (object lock/retention behavior by backend)
- Integrity guarantees (whether evidence divergence is detected and attested)

These are not the same. Backend storage choices are infrastructure decisions; integrity guarantees must come from the system architecture.

## 3. MinIO to SeaweedFS Position

### 3.1 Driver

- MinIO licensing constraints create policy and commercial risk for long-term deployment posture.
- SeaweedFS is adopted as the preferred FOSS storage alternative for sandbox S3-compatible usage.

### 3.2 Scope

- This decision governs sandbox and Phase-1 storage plumbing.
- This decision is not, by itself, a claim about integrity guarantees.

### 3.3 What SeaweedFS changes

- Changes infrastructure endpoint, operational model, and retention configuration shape.
- Does not become Symphony’s root trust claim.
- Must preserve archive/restore operational outcomes and verifier coverage.

### 3.4 Phase-1 RTO Discipline and Exception Rule

- The default Phase-1 restore-time objective is 4 hours (14400 seconds).
- Storage cutover and restore proofs must record measured elapsed time against that cap.
- If measured restore or cutover work exceeds the default cap, promotion requires an
  explicit human signoff reference; exceeded-RTO evidence without signoff is not promotable.
- `TSK-P1-STOR-001` remains the backend-neutral cutover gate for smoke IO, archive run,
  restore drill, retention controls, and integrity parity.
- `TSK-P1-INT-009B` is the measured restore-time proof task and must bind its evidence to
  `TSK-P1-STOR-001` output rather than redefining trust claims.

## 4. Integrity Stance (Authoritative)

Symphony’s Phase-1 guarantee is:

**Tamper-evident integrity, not storage-level permanence guarantees.**

The integrity claim is grounded in:

- signed artifacts
- append-only event history
- verifiable chain-of-custody
- mismatch/tamper detection
- explicit acknowledgement-state monitoring

## 5. Required Language Standard

### 5.1 Approved language

- “tamper-evident evidence trail”
- “signed offline/pre-rail bridge”
- “explicit acknowledgement dependency”
- “integrity verification and divergence detection”

### 5.2 Prohibited/unsupported language (unless separately proven)

- “permanent immutable storage”
- “WORM-grade by default”
- “cannot be changed”
- “storage backend alone guarantees integrity”

## 6. Tamper-Evident vs Tamper-Resistant (Required Clarification)

- Tamper-evident: the system can detect and attest divergence from governed original state.
- Tamper-resistant: the system/storage prevents modification attempts.

Phase-1 Symphony claim is tamper-evident integrity. Tamper-resistance may exist in specific controls, but is not the primary global claim.

## 7. Trust Boundary Statement

Symphony governs:

- instruction creation
- policy evaluation
- signed instruction egress
- evidence preservation
- acknowledgement monitoring

External payment execution remains outside Symphony custody boundary; therefore execution completion is tracked via explicit acknowledgement and is never silently assumed.

## 8. Offline Signed Egress Position

The offline/pre-rail signed instruction flow is a deliberate Phase-1 control path, not a workaround.

It provides:

- governed release before live rail integration
- verifiable handoff integrity
- visibility of acknowledgement gaps (`AWAITING_EXECUTION` when unresolved)

Known limit:

- If partner acknowledgement is missing, settlement finality is not assumed.

## 9. Required Changes in Symphony Artifacts

1. Documentation updates:
   - Replace MinIO/WORM-centric trust wording with tamper-evident integrity wording in storage, audit, and demo docs.

2. Verifier updates:
   - Shift checks from backend-specific object-lock declarations to integrity checks:
     - signature validity
     - chain consistency
     - append-only integrity
     - tamper detection
     - acknowledgement visibility

3. Evidence schema updates:
   - Prefer semantic integrity fields such as:
     - `integrity_signature_verified`
     - `integrity_chain_verified`
     - `tamper_detection_triggered`
     - `acknowledgement_status_visible`
   - Do not treat backend name as trust proof.

4. Storage migration task scope:
   - SeaweedFS migration tasks remain infra substitution and operational reliability work.
   - They are not the root-of-trust implementation.
   - Acceptance must stay backend-neutral: smoke IO, archive run, restore drill,
     retention controls, and integrity verifier parity are the governing outcomes.

## 10. Governance and Audit Implication

This position improves:

- claim truthfulness
- regulatory defensibility
- verifier quality
- separation of architecture guarantees from infrastructure choices

Any future claim of permanent immutability must be separately validated and evidenced as an additional control, not implied by this position.
