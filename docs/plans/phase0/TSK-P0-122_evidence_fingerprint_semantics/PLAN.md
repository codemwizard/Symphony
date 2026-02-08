# Implementation Plan (TSK-P0-122)

failure_signature: CI.EVIDENCE.SCHEMA_FINGERPRINT.SEMANTIC_MISMATCH
origin_gate_id: INT-G01
repro_command: unzip -l phase0-evidence.zip && inspect phase0/evidence.json schema_fingerprint

## Goal
Make `schema_fingerprint` semantics consistent across all Phase-0 evidence artifacts.

## Problem Statement
Most evidence producers use `schema_fingerprint` from `scripts/lib/evidence.sh` (hash of `schema/baseline.sql`).
`scripts/audit/generate_evidence.sh` was independently implemented and set `schema_fingerprint` to a migrations hash.

That yields two different meanings for the same field within the same CI run.

## Decision (Canonical Semantics)
- `schema_fingerprint`: hash of `schema/baseline.sql` (Phase-0 schema anchor)
- `migrations_fingerprint`: deterministic hash of sorted `schema/migrations/*.sql`

## Scope
In scope:
- Update `scripts/audit/generate_evidence.sh` to follow canonical semantics.
- Preserve the migrations hash as a separate field and file (`schema_hash.txt`).

Out of scope:
- Changing evidence schema requirements (schema already allows additional props).

## Acceptance Criteria
- In CI `phase0-evidence` artifact, all evidence JSON files share the same `schema_fingerprint` value.
- `phase0/evidence.json` includes both `schema_fingerprint` and `migrations_fingerprint`.

## Verification Commands
- `bash scripts/audit/generate_evidence.sh`
- `bash scripts/audit/validate_evidence_schema.sh`

verification_commands_run:
- bash scripts/audit/generate_evidence.sh
- bash scripts/audit/validate_evidence_schema.sh

final_status: PASS
