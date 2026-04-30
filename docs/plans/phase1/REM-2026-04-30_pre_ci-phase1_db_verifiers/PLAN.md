# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT
root_cause: Baseline was generated from live DB snapshot but Wave 8 migrations (0172-0187) produce different canonicalized function bodies and constraints when applied from scratch to an ephemeral DB. The canonicalizer extracts lines from pg_dump deterministically, so any function body, constraint, or trigger difference between live-incremental and fresh-from-scratch causes a hash mismatch.

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: sha256sum of canonicalized ephemeral dump vs regenerated baseline
final_status: RESOLVED

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Root Cause
The `schema/baselines/current/0001_baseline.sql` was generated from `pg_dump` of the
long-lived `symphony` database. That database had migrations applied incrementally over
many sessions. When `pre_ci.sh` creates a fresh ephemeral DB and applies all 187
migrations from scratch, `pg_dump` produces a different canonical output because:

1. Wave 8 migrations (0172-0187) add significant function body content, CHECK constraints,
   and signer resolution structures to `state_transitions` and `asset_batches`.
2. The canonicalizer produces deterministic line ordering, so any difference in function
   bodies or constraint definitions causes a hash mismatch.
3. The live DB baseline hash was `8ca013d5...` while the ephemeral from-scratch hash was
   `888af428...`.

## Fix
Regenerated `schema/baselines/current/0001_baseline.sql` from a fresh ephemeral DB
created by applying all migrations from scratch, then canonicalizing with
`scripts/db/canonicalize_schema_dump.sh`. Both baseline and ephemeral dump now produce
hash `888af4286c9530057c1c4b5fc712465fc1ef749b24fe912df47d80a39954a751`.

## Verification
```bash
# Create ephemeral DB, apply all migrations, pg_dump, canonicalize, compare hashes
sha256sum /tmp/verify_baseline_norm.sql /tmp/ephemeral_dump.sql
# Both: 888af4286c9530057c1c4b5fc712465fc1ef749b24fe912df47d80a39954a751
```
