# Wave 8 False Completion Pattern Catalog

**Status:** Authoritative
**Date:** 2026-04-29
**Related Tasks:** TSK-P2-W8-GOV-001

## Purpose

This catalog explicitly lists false completion patterns that cannot satisfy Wave 8 closure. Any task using these patterns is automatically rejected for closure.

## Banned Patterns

### 1. Detached Function Proof

**Pattern:** Claiming completion based on function existence or type presence without proving the function executes in the authoritative enforcement path.

**Example:**
- Verifier checks that a function exists in PostgreSQL: `SELECT EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'verify_ed25519')`
- Verifier checks that a .NET type exists: `typeof(Ed25519Verifier) != null`
- No actual invocation or execution path proof.

**Why Banned:** Does not prove enforcement at the `asset_batches` boundary. Function may exist but never execute in the authoritative path.

**Correct Pattern:** Verifier must prove the function executes inside the `asset_batches` dispatcher path and causes PostgreSQL to accept or reject a write.

### 2. Grep Proof

**Pattern:** Claiming completion based on grep results showing code patterns without runtime execution evidence.

**Example:**
- `grep -r "verify_signature" schema/migrations/` returns matches
- `grep -r "Ed25519" services/` returns matches
- No actual runtime verification.

**Why Banned:** Code presence does not prove runtime behavior. Code may exist but be dead, commented out, or bypassed.

**Correct Pattern:** Verifier must execute actual runtime behavior and observe PostgreSQL acceptance/rejection.

### 3. Reflection-Only Surface Proof

**Pattern:** Claiming cryptographic surface proof using only reflection or type inspection without actual invocation through the production execution path.

**Example:**
- Reflection check: `Assembly.GetAssembly(typeof(Ed25519)).GetName().Version`
- Type inspection: `typeof(Ed25519).GetMethods()`
- No actual sign/verify invocation on Wave 8-shaped bytes.

**Why Banned:** Reflection proves type presence, not execution path or semantic fidelity. Especially critical for SEC-000 and SEC-001.

**Correct Pattern:** Verifier must prove actual invocation through the first-party execution path inside the pinned SDK/runtime images.

### 4. Toy-Crypto Proof

**Pattern:** Claiming cryptographic completion using toy sign/verify demos that do not prove semantic fidelity on Wave 8-shaped contract bytes.

**Example:**
- Simple sign/verify on arbitrary bytes: `Sign("hello world")`
- No testing on Wave 8-shaped attestation payloads.
- No failure cases (altered bytes, wrong key, malformed signature).

**Why Banned:** Toy demos do not prove semantic fidelity on Wave 8-shaped contract bytes. Especially critical for SEC-000 and SEC-001.

**Correct Pattern:** Verifier must prove sign/verify behavior on Wave 8-shaped contract bytes with altered-byte, wrong-key, and malformed-signature failure cases.

### 5. Garbage-Payload Matrix Fraud

**Pattern:** Claiming closure based on a rejection matrix that uses garbage or malformed payloads that would fail for reasons other than the intended enforcement domain.

**Example:**
- Testing with NULL values that fail type checks, not signature checks.
- Testing with malformed JSON that fails parsing, not cryptographic verification.
- Testing with obviously invalid data that fails basic validation, not domain-specific enforcement.

**Why Banned:** Rejection for wrong reasons does not prove domain-specific enforcement. Garbage payloads fail for many reasons, not the intended enforcement domain.

**Correct Pattern:** Verifier must use valid Wave 8-shaped payloads with specific targeted alterations (wrong key, altered bytes, wrong scope, etc.) to prove domain-specific rejection.

### 6. Fake Crypto Behind Real Trigger Wiring

**Pattern:** Having a real trigger that claims cryptographic enforcement but the actual crypto verification is fake, bypassed, or non-executing.

**Example:**
- Trigger exists and fires on `asset_batches` writes.
- Trigger calls a function that claims to verify signatures.
- Function actually does nothing, always returns true, or uses a fake crypto implementation.
- Real crypto exists but is in a dead code path.

**Why Banned:** Trigger wiring exists but crypto enforcement is fake. Creates illusion of enforcement without actual security.

**Correct Pattern:** Verifier must prove the Ed25519 primitive executes inside the dispatcher path and that branch provenance comes from the same production execution path as the terminal SQLSTATE.

### 7. Superuser-Only Success

**Pattern:** Verification passes only when run as PostgreSQL superuser, but the enforcement fails for non-superuser users.

**Example:**
- Verifier runs as `postgres` superuser.
- Enforcement relies on superuser privileges (e.g., reading system catalogs, bypassing RLS).
- Non-superuser runtime user cannot execute the same enforcement.

**Why Banned:** Superuser-only success does not prove enforcement for the intended runtime user. Creates security vulnerability.

**Correct Pattern:** Verifier must prove enforcement works for the intended runtime user, not just superuser.

### 8. Mirrored-Vector Fraud

**Pattern:** Generating test vectors from the implementation logic rather than from independent contract sources, then claiming the implementation matches the vectors.

**Example:**
- Test vectors are generated by running the implementation on sample inputs.
- Implementation is then verified against its own generated vectors.
- No independent contract source for expected behavior.

**Why Banned:** Creates circular dependency. Implementation matches itself, not an independent contract. Does not prove conformance to authoritative requirements.

**Correct Pattern:** Test vectors must be frozen independently of implementation logic; verifier must fail if runtime vectors are regenerated from implementation.

### 9. Wrapper-Only Branch Markers

**Pattern:** Using wrapper-only branch markers instead of production-path provenance.

**Example:**
- Wrapper function logs "crypto verification started" and "crypto verification completed".
- No proof that the actual Ed25519 primitive executed.
- Branch provenance comes from wrapper, not production path.

**Why Banned:** Wrapper markers prove wrapper execution, not production-path execution. Does not prove actual cryptographic enforcement.

**Correct Pattern:** Branch provenance must come from the same production execution path as the terminal SQLSTATE.

### 10. Advisory-Only Enforcement

**Pattern:** Implementing enforcement as advisory (warning-only) rather than fail-closed.

**Example:**
- Trigger logs a warning when signature verification fails but allows the write.
- Function returns a warning code but does not raise an exception.
- Enforcement is documented as "advisory" or "informational."

**Why Banned:** Advisory enforcement does not prevent invalid writes. Violates Wave 8 fail-closed requirement.

**Correct Pattern:** All Wave 8 enforcement must be fail-closed; invalid writes must be rejected with registered SQLSTATE.

## Pattern Detection Checklist

For each Wave 8 task, verify the absence of all banned patterns:

- [ ] No detached function proof
- [ ] No grep-only proof
- [ ] No reflection-only surface proof (especially for SEC-000/SEC-001)
- [ ] No toy-crypto proof (especially for SEC-000/SEC-001)
- [ ] No garbage-payload matrix fraud
- [ ] No fake crypto behind real trigger wiring
- [ ] No superuser-only success
- [ ] No mirrored-vector fraud
- [ ] No wrapper-only branch markers
- [ ] No advisory-only enforcement

## Pattern Remediation

If a banned pattern is discovered:

1. Stop implementation immediately.
2. Document the pattern in the task's EXEC_LOG.md.
3. Re-design the verifier to use the correct pattern.
4. Re-verify with the corrected approach.
5. Update evidence to reflect the corrected approach.

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_CLOSURE_RUBRIC.md
- WAVE8_PROOF_INTEGRITY_THREAT_REGISTER.md
- WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md
