# Wave 8 Proof Integrity Threat Register

**Status:** Authoritative
**Date:** 2026-04-29
**Related Tasks:** TSK-P2-W8-GOV-001

## Purpose

This register catalogs threats to proof integrity in Wave 8 implementation. Each threat is classified by severity and mitigation strategy.

## Threat Classification

### Critical Threats

These threats directly undermine Wave 8 closure and must be prevented.

#### T1: Detached Function Proof

**Description:** Claiming completion based on function existence or type presence without proving the function executes in the authoritative enforcement path.

**Severity:** Critical
**Impact:** False completion claim
**Mitigation:** Verifier must prove the function executes inside the `asset_batches` dispatcher path and causes PostgreSQL to accept or reject a write.

#### T2: Grep Proof

**Description:** Claiming completion based on grep results showing code patterns without runtime execution evidence.

**Severity:** Critical
**Impact:** False completion claim
**Mitigation:** Verifier must execute actual runtime behavior and observe PostgreSQL acceptance/rejection.

#### T3: Reflection-Only Surface Proof

**Description:** Claiming cryptographic surface proof using only reflection or type inspection without actual invocation through the production execution path.

**Severity:** Critical
**Impact:** False completion claim, especially for SEC-000 and SEC-001
**Mitigation:** Verifier must prove actual invocation through the first-party execution path; reflection-only evidence is inadmissible.

#### T4: Toy-Crypto Proof

**Description:** Claiming cryptographic completion using toy sign/verify demos that do not prove semantic fidelity on Wave 8-shaped contract bytes.

**Severity:** Critical
**Impact:** False completion claim, especially for SEC-000 and SEC-001
**Mitigation:** Verifier must prove sign/verify behavior on Wave 8-shaped contract bytes with altered-byte, wrong-key, and malformed-signature failure cases.

#### T5: Garbage-Payload Matrix Fraud

**Description:** Claiming closure based on a rejection matrix that uses garbage or malformed payloads that would fail for reasons other than the intended enforcement domain.

**Severity:** Critical
**Impact:** False completion claim
**Mitigation:** Verifier must use valid Wave 8-shaped payloads with specific targeted alterations (wrong key, altered bytes, wrong scope, etc.).

#### T6: Fake Crypto Behind Real Trigger Wiring

**Description:** Having a real trigger that claims cryptographic enforcement but the actual crypto verification is fake, bypassed, or non-executing.

**Severity:** Critical
**Impact:** False completion claim, security vulnerability
**Mitigation:** Verifier must prove the Ed25519 primitive executes inside the dispatcher path and that branch provenance comes from the same production execution path as the terminal SQLSTATE.

#### T7: Superuser-Only Success

**Description:** Verification passes only when run as PostgreSQL superuser, but the enforcement fails for non-superuser users.

**Severity:** Critical
**Impact:** False completion claim, security vulnerability
**Mitigation:** Verifier must prove enforcement works for the intended runtime user, not just superuser.

#### T8: Mirrored-Vector Fraud

**Description:** Generating test vectors from the implementation logic rather than from independent contract sources, then claiming the implementation matches the vectors.

**Severity:** Critical
**Impact:** False completion claim
**Mitigation:** Test vectors must be frozen independently of implementation logic; verifier must fail if runtime vectors are regenerated from implementation.

### High Threats

These threats significantly weaken Wave 8 closure but may not directly cause false completion.

#### H1: Advisory-Only Enforcement

**Description:** Implementing enforcement as advisory (warning-only) rather than fail-closed.

**Severity:** High
**Impact:** Weakened enforcement, potential bypass
**Mitigation:** All Wave 8 enforcement must be fail-closed; advisory behavior is inadmissible.

#### H2: Multi-Domain Drift

**Description:** A task spanning multiple enforcement domains without being split into separate packs.

**Severity:** High
**Impact:** Violates single enforcement domain requirement
**Mitigation:** Tasks must be constrained to one primary enforcement domain; split if implementation reveals multiple domains.

#### H3: Boundary Ambiguity

**Description:** Unclear or ambiguous specification of which table or surface is the authoritative boundary.

**Severity:** High
**Impact:** Potential enforcement bypass
**Mitigation:** Explicitly name `asset_batches` as the sole authoritative Wave 8 boundary in all task documentation.

### Medium Threats

These threats affect evidence quality but may not directly cause false completion.

#### M1: Incomplete Evidence

**Description:** Evidence file missing required fields (observed_paths, observed_hashes, command_outputs, execution_trace).

**Severity:** Medium
**Impact:** Reduced evidence quality, harder to audit
**Mitigation:** Verifier must enforce complete evidence with all required fields.

#### M2: Missing Remediation Trace

**Description:** Regulated surface edits without required remediation trace markers.

**Severity:** Medium
**Impact:** Reduced auditability
**Mitigation:** EXEC_LOG.md must carry remediation trace markers for all regulated-surface edits.

## Threat Mitigation Checklist

For each Wave 8 task, verify:

- [ ] No detached function proof
- [ ] No grep-only proof
- [ ] No reflection-only surface proof (especially for SEC-000/SEC-001)
- [ ] No toy-crypto proof (especially for SEC-000/SEC-001)
- [ ] No garbage-payload matrix fraud
- [ ] No fake crypto behind real trigger wiring
- [ ] No superuser-only success
- [ ] No mirrored-vector fraud
- [ ] No advisory-only enforcement
- [ ] Single enforcement domain
- [ ] Explicit boundary specification (asset_batches)
- [ ] Complete evidence with all required fields
- [ ] Remediation trace markers present (if applicable)

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_CLOSURE_RUBRIC.md
- WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md
- WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md
