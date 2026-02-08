# Execution Log (TSK-P0-122)

failure_signature: CI.EVIDENCE.SCHEMA_FINGERPRINT.SEMANTIC_MISMATCH
origin_gate_id: INT-G01
repro_command: bash scripts/audit/generate_evidence.sh

Plan: docs/plans/phase0/TSK-P0-122_evidence_fingerprint_semantics/PLAN.md

## Change Applied
- Updated `scripts/audit/generate_evidence.sh`:
  - `schema_fingerprint` now uses `schema/baseline.sql` hash (via `scripts/lib/evidence.sh`).
  - Added `migrations_fingerprint` retaining the deterministic migrations hash.
  - Continued writing the migrations hash to `evidence/phase0/schema_hash.txt`.

## Verification Commands Run
verification_commands_run:
- bash scripts/audit/generate_evidence.sh
- bash scripts/audit/validate_evidence_schema.sh

## Status
final_status: PASS

## Final Summary
- Root cause: `generate_evidence.sh` used a migrations hash as `schema_fingerprint`, while all other evidence producers used the baseline hash.
- Fix: standardize `schema_fingerprint` to baseline and preserve migrations hash as `migrations_fingerprint`.
- Verification: evidence generation and schema validation pass locally; CI artifact should show a single `schema_fingerprint` across evidence JSONs.
