# Defect Remediation Document (DRD)

## Metadata
- **Date:** 2026-04-30
- **Remediation Target:** Wave 8 Ed25519 Verification and Baseline Drift
- **Status:** Completed
- **Phase:** Phase 2

## Identified Defects

1. **Incorrect Exception Handling in `wave8_crypto` C Extension**
   - **Location:** `src/db/extensions/wave8_crypto/wave8_crypto.c:93-98`
   - **Issue:** The `ed25519_verify` C function was returning an internal error (`XX000`) instead of returning `false` upon encountering an invalid signature. The libsodium `crypto_sign_verify_detached` function returns `-1` to indicate an invalid signature, which is not an internal libsodium error but a valid outcome. The SQL binding assumed a boolean return, rendering the intended signature verification check and its associated `P7809` SQLSTATE unreachable.
   - **Fix:** Removed the `if (result < 0)` block that threw the exception. Directly returning `PG_RETURN_BOOL(result == 0);` to accurately propagate the cryptographic validity check.

2. **Incorrect SQLSTATE for Context Binding Violations**
   - **Location:** `schema/migrations/0187_wave8_integrate_ed25519_verification.sql`
   - **Issue:** Migration 0187 erroneously used `P7812` (provider path unavailable) instead of `P7814` (branch provenance mismatch) for context binding violations.
   - **Fix:** Updated the four context binding failure conditions (entity_id, execution_id, policy_decision_id, interpretation_version_id) to correctly emit the `P7814` error code, restoring parity with prior migrations (0181, 0186) and aligning with `sqlstate_map.yml`.

3. **Baseline Metadata and Baseline Hash Divergence**
   - **Location:** `schema/baselines/current/baseline.meta.json` and `docs/decisions/ADR-2026-04-30-wave8-baseline-update.md`
   - **Issue:** The schema baseline was regenerated in a previous remediation, but the metadata files continued to store the old, invalid baseline hash (`8ca013d5...`). This caused a mismatch that would break the CI baseline drift verification gate.
   - **Fix:** Regenerated the database schema dump completely from an ephemeral database to capture the SQLSTATE changes made in 0187. Recomputed the canonical SHA-256 hash.
   - **New Hash:** `e57fa8a5c7f424f5998c9a551fdb0683e7267c2ece47807ea40763a1190b16c7`
   - **Action:** Updated `baseline.meta.json` and the Wave 8 ADR to reflect this canonical hash.

## Consequences & Mitigation
- The DB verifier and pre_ci baseline drift scripts will now properly assert using the updated and structurally valid ephemeral hash.
- Invalid Ed25519 signatures now appropriately raise `P7809` via the SQL trigger surface, restoring full cryptographic enforcement without emitting false-positive internal DB exceptions.
- Context binding failure alerting streams will now properly isolate events tagged with `P7814`.
