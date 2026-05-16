# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- `scripts/audit/verify_tsk_p2_w8_sec_002.sh` is attempting a host-level `sudo make install`
  during `pre_ci`, which is not admissible in non-interactive gate execution.
- The verifier likely does not need host root install at all because the built
  extension artifacts already exist in `src/db/extensions/wave8_crypto/` after
  `make`.

## Root Cause
- SEC-002 was written to require `sudo make install` onto the host PostgreSQL 18
  extension directories before binary inspection and container loading.
- In `pre_ci`, the verifier runs non-interactively, so `sudo` fails with
  `a terminal is required to read the password`.
- The host install step was unnecessary for the gate path: the verifier can
  inspect the built `.so` directly from the source tree and copy the built
  `.so`, `.control`, and `.sql` artifacts into the DB container without
  performing a privileged host install.

## Fix Sequence
1. Remove the SEC-002 verifier's dependency on `sudo make install`.
2. Replace install-time behavior with non-root artifact validation against:
   - `src/db/extensions/wave8_crypto/wave8_crypto.so`
   - `src/db/extensions/wave8_crypto/wave8_crypto.control`
   - `src/db/extensions/wave8_crypto/wave8_crypto--1.0.sql`
3. Change binary inspection steps (`ldd`, `nm`, `objdump`, `readelf`) to inspect
   the built `.so` in the source tree instead of an installed host path.
4. Change extension loading to copy the built source-tree artifacts directly into
   the DB container's PostgreSQL extension directories before `CREATE EXTENSION`.
5. Re-run `scripts/audit/verify_tsk_p2_w8_sec_002.sh`, then rerun
   `scripts/dev/pre_ci.sh` with `SKIP_DOTNET_QUALITY_LINT=1`.
