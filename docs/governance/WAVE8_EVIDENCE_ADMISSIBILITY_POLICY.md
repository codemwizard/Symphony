# Wave 8 Evidence Admissibility Policy

**Status:** Authoritative
**Date:** 2026-04-29
**Related Tasks:** TSK-P2-W8-GOV-001

## Purpose

This policy defines which proof forms are admissible for Wave 8 closure claims. Inadmissible proof patterns cannot satisfy closure requirements.

## Admissible Proof Forms

### 1. Runtime Execution Evidence

**Definition:** Evidence that proves actual runtime behavior at the authoritative boundary.

**Requirements:**
- Verifier executes code and observes PostgreSQL acceptance or rejection at `asset_batches`.
- Evidence includes execution trace, command outputs, observed paths, and observed hashes.
- Branch provenance comes from the same production execution path as the terminal SQLSTATE.

**Admissible For:** All Wave 8 tasks, especially database tasks (DB-001 through DB-009).

### 2. Contract-Conformance Evidence

**Definition:** Evidence that proves implementation conforms to contract-defined semantics.

**Requirements:**
- Implementation uses exact field set, normalization rules, and byte vectors from contract documents.
- SQL canonical bytes match frozen contract vectors exactly.
- No implementation drift from contract requirements.

**Admissible For:** Architecture tasks (ARCH-001 through ARCH-006), database tasks.

### 3. Deterministic Byte Equality Evidence

**Definition:** Evidence that proves multiple surfaces emit identical canonical bytes for the same logical input.

**Requirements:**
- Contract source, frozen runtime, and SQL runtime are compared directly.
- Byte equality is proven, not just hash equality.
- Evidence includes execution trace and observed hashes.

**Admissible For:** QA-001 (Three-surface determinism vectors).

### 4. Cryptographic Semantic Fidelity Evidence

**Definition:** Evidence that proves cryptographic behavior on Wave 8-shaped contract bytes.

**Requirements:**
- Sign/verify behavior is tested on Wave 8-shaped contract bytes.
- Failure cases include altered bytes, wrong keys, malformed signatures, and runtime/provider drift.
- Evidence is generated inside the pinned SDK/runtime images.
- Actual invocation through first-party execution path is proven.

**Admissible For:** SEC-000 (Environment Fidelity Gate), SEC-001 (Ed25519 verification primitive).

### 5. Behavioral Rejection Matrix Evidence

**Definition:** Evidence that proves the full Wave 8 rejection matrix at the authoritative boundary.

**Requirements:**
- Verifier executes all rejection cases: malformed signature, wrong signer, wrong scope, revoked key, expired key, altered payload, altered registry snapshot, altered entity binding, canonicalization mismatch, unavailable crypto.
- Includes valid-signature acceptance case.
- Each case physically causes PostgreSQL to accept or reject a write at `asset_batches`.
- Evidence includes proof-carrying fields for every behavioral case.

**Admissible For:** QA-002 (Behavioral evidence pack).

## Inadmissible Proof Forms

### 1. Detached Function Proof

**Definition:** Claiming completion based on function existence or type presence without proving execution in the authoritative path.

**Status:** INADMISSIBLE
**Reason:** Does not prove enforcement at the authoritative boundary.

### 2. Grep Proof

**Definition:** Claiming completion based on grep results showing code patterns without runtime execution.

**Status:** INADMISSIBLE
**Reason:** Does not prove runtime behavior.

### 3. Reflection-Only Surface Proof

**Definition:** Claiming cryptographic surface proof using only reflection or type inspection without actual invocation.

**Status:** INADMISSIBLE
**Reason:** Does not prove actual execution through the production path.
**Especially Banned For:** SEC-000, SEC-001.

### 4. Toy-Crypto Proof

**Definition:** Claiming cryptographic completion using toy sign/verify demos that do not prove semantic fidelity on Wave 8-shaped bytes.

**Status:** INADMISSIBLE
**Reason:** Does not prove semantic fidelity on Wave 8-shaped contract bytes.
**Especially Banned For:** SEC-000, SEC-001.

### 5. Garbage-Payload Matrix Fraud

**Definition:** Claiming closure based on a rejection matrix using garbage or malformed payloads.

**Status:** INADMISSIBLE
**Reason:** Does not prove domain-specific enforcement.

### 6. Fake Crypto Behind Real Trigger Wiring

**Description:** Having a real trigger that claims cryptographic enforcement but the actual crypto is fake or bypassed.

**Status:** INADMISSIBLE
**Reason:** Does not prove actual cryptographic enforcement.

### 7. Superuser-Only Success

**Definition:** Verification passes only when run as PostgreSQL superuser.

**Status:** INADMISSIBLE
**Reason:** Does not prove enforcement for intended runtime user.

### 8. Mirrored-Vector Fraud

**Definition:** Generating test vectors from implementation logic rather than independent contract sources.

**Status:** INADMISSIBLE
**Reason:** Creates circular dependency; does not prove conformance to independent contract.

### 9. Wrapper-Only Branch Markers

**Definition:** Using wrapper-only branch markers instead of production-path provenance.

**Status:** INADMISSIBLE
**Reason:** Does not prove branch provenance from the same production execution path as the terminal SQLSTATE.

### 10. Advisory-Only Enforcement

**Definition:** Implementing enforcement as advisory (warning-only) rather than fail-closed.

**Status:** INADMISSIBLE
**Reason:** Violates Wave 8 fail-closed requirement.

## Evidence Completeness Requirements

All admissible evidence must include:

- `task_id`: The task identifier
- `git_sha`: The Git commit SHA of the implementation
- `timestamp_utc`: UTC timestamp of verification
- `status`: Pass/fail status
- `checks`: List of verification checks performed
- `observed_paths`: List of file paths observed during verification
- `observed_hashes`: Hashes of observed files
- `command_outputs`: Output of verification commands
- `execution_trace`: Trace of verification execution

Evidence missing any of these fields is INADMISSIBLE.

## Evidence Review Process

Before accepting a closure claim:

1. Verify the proof form is admissible per this policy.
2. Verify evidence completeness (all required fields present).
3. Verify no inadmissible proof patterns are used.
4. Verify the proof satisfies the task's specific acceptance criteria.
5. Verify the proof satisfies the Wave 8 Closure Rubric.

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_CLOSURE_RUBRIC.md
- WAVE8_PROOF_INTEGRITY_THREAT_REGISTER.md
- WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md
