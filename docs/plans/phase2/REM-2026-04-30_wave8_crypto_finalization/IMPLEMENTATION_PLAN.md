# Wave 8 Crypto Finalization Implementation Plan

## Mode Classification
**Mode:** REMEDIATE
**Authority:** AGENT_ENTRYPOINT.md Step 1 (mode selection)
**Process:** Following REMEDIATION_TRACE_WORKFLOW.md with DRD-driven remediation

## Wave 8 Current Status

### Structurally Complete (No runtime errors)
- **TSK-P2-W8-DB-001** (Dispatcher): Fixed to call only existing functions
- **TSK-P2-W8-DB-002** (Placeholder cleanup): Function returns TRIGGER, trigger added
- **TSK-P2-W8-DB-005** (Signer resolution): Return type includes lifecycle columns
- **TSK-P2-W8-QA-001** (Determinism vectors): Real SHA-256 hashes, verification validates computation
- **TSK-P2-W8-QA-002** (Behavioral evidence): Verification checks actual acceptance patterns

### Partial Implementation (Needs remediation per Wave-8_Implementation-Plan.md)
- **TSK-P2-W8-DB-006** (Crypto enforcement): Hard-fails correctly, but blocked on SEC-002
- **TSK-P2-W8-DB-007b** (Timestamp): 0181 has implementation but plan classifies 0181 as mixed-domain, not final shape
- **TSK-P2-W8-DB-007c** (Replay): 0181 has implementation but plan classifies 0181 as mixed-domain, not final shape
- **TSK-P2-W8-DB-009** (Context binding): 0181 has implementation but plan classifies 0181 as mixed-domain, not final shape

### Stub/Incomplete
- **TSK-P2-W8-SEC-002** (PostgreSQL native Ed25519): Task pack created but no source tree, no build contract

### Not Affected (No structural issues)
- TSK-P2-W8-GOV-001, TSK-P2-W8-ARCH-001 through ARCH-005, TSK-P2-W8-SEC-000, TSK-P2-W8-SEC-001, TSK-P2-W8-DB-003, DB-004, DB-007a, DB-008

## What This Implementation Will Fix

### SQL-Side Remediation (Migrations 0182-0186)
Per Wave-8_Implementation-Plan.md, create clean single-domain migrations:

1. **0182_wave8_restore_crypto_hardfail.sql** - Restore hard-fail in 0177 (ensure verification_result := true is replaced with hard-fail)
2. **0183_wave8_replay_nonce_registry.sql** - Create wave8_attestation_nonces table with UNIQUE constraint
3. **0184_wave8_timestamp_branch_enforcement.sql** - Implement timestamp extraction from canonical_payload_bytes and comparison
4. **0185_wave8_replay_branch_enforcement.sql** - Implement nonce uniqueness enforcement via INSERT ON CONFLICT
5. **0186_wave8_context_binding_non_signer_enforcement.sql** - Implement context field extraction and comparison for non-signer context

### SEC-002 Binary Build Contract
Per Wave-8_Implementation-Plan.md Section 2:

1. **Source tree creation** at `src/db/extensions/wave8_crypto/`:
   - wave8_crypto.c (exports ed25519_verify)
   - wave8_crypto.control (extension metadata, relocatable=false)
   - wave8_crypto--1.0.sql (SQL function binding)
   - Makefile (PGXS-only build with hardening flags)

2. **Build contract implementation**:
   - PG_CONFIG pinned to /usr/lib/postgresql/18/bin/pg_config
   - Compiler flags: -Wall -Wextra -Werror -O2 -fPIC
   - Linker flags: -lsodium -Wl,-z,relro -Wl,-z,now

3. **Verification contract implementation**:
   - Build: make PG_CONFIG=...
   - Install: make PG_CONFIG=... install
   - Binary inspection: ldd, nm -D, objdump -T, readelf -d
   - PostgreSQL load: CREATE EXTENSION wave8_crypto
   - Runtime verification: known-good vector (true), known-bad vector (false)
   - Parity: subset matches SEC-001 vectors

4. **Evidence schema** with 20 required fields per plan

5. **Task pack repair** for TSK-P2-W8-SEC-002 with build-artifact scope

## What Will Remain After This Implementation

### SEC-002 Closure
- SEC-002 will be **execution-ready** (source tree, build contract, verification scripts created)
- SEC-002 will be **locally testable via pre_ci** (build, install, load, verify in local PostgreSQL 18 for development)
- SEC-002 will **remain blocked on CI** - final closure requires GitHub Actions CI workflow execution and admissible evidence emission
- **CI is the authoritative closure surface** - pre_ci can verify locally, but only CI evidence unblocks SEC-002

### DB-006 Unblocking
- DB-006 will **remain blocked** until SEC-002 CI closure is complete
- Once SEC-002 CI (GitHub Actions) emits admissible evidence, DB-006 can replace hard-fail with real ed25519_verify() call
- pre_ci evidence is not sufficient for DB-006 unblocking

### 0181 Classification
- Migration 0181 will **remain classified as drifted/partial** per plan
- New migrations 0182-0186 will be the authoritative remediation chain
- 0181 will not be deleted (forward-only history) but will not be the final shape

## Implementation Sequence

### Phase 1: SQL-Side Remediation (0182-0186)
1. Create 0182_wave8_restore_crypto_hardfail.sql
2. Create 0183_wave8_replay_nonce_registry.sql
3. Create 0184_wave8_timestamp_branch_enforcement.sql
4. Create 0185_wave8_replay_branch_enforcement.sql
5. Create 0186_wave8_context_binding_non_signer_enforcement.sql

### Phase 2: SEC-002 Source Tree
1. Create src/db/extensions/wave8_crypto/ directory
2. Create wave8_crypto.c with ed25519_verify implementation
3. Create wave8_crypto.control
4. Create wave8_crypto--1.0.sql
5. Create Makefile with PGXS build contract

### Phase 3: SEC-002 Verification Infrastructure
1. Create evidence schema r_020_sec002_binary_build.schema.json
2. Create verification script scripts/audit/verify_tsk_p2_w8_sec_002.sh
3. Update TSK-P2-W8-SEC-002/meta.yml with build-artifact scope

### Phase 4: Local Build and Test
1. Build extension: make PG_CONFIG=/usr/lib/postgresql/18/bin/pg_config
2. Install extension: make PG_CONFIG=/usr/lib/postgresql/18/bin/pg_config install
3. Load extension: CREATE EXTENSION wave8_crypto
4. Run verification vectors (known-good, known-bad)
5. Run binary inspection (ldd, nm, objdump, readelf)
6. Generate evidence JSON

### Phase 5: Documentation
1. Update EXEC_LOG.md for DB-007b, DB-007c, DB-009 with 0182-0186 notes
2. Update EXEC_LOG.md for SEC-002 with build contract notes
3. Update DRD with final status

## Anti-Hallucination and Anti-Drift Measures

### Scope Boundaries
- Each migration 0182-0186 handles exactly one enforcement domain
- SEC-002 source tree owns only binary crypto verification (no signer resolution, replay, timestamp, context)
- No scope expansion beyond Wave-8_Implementation-Plan.md specifications

### Evidence Requirements
- All verifications must emit proof-carrying evidence with required fields
- Binary inspection evidence must include ldd, nm, objdump, readelf outputs
- Runtime verification must include known-good and known-bad vector results

### No Fake Completion
- SEC-002 will not be marked complete by source presence alone
- SEC-002 will not be marked complete by compile success alone
- SEC-002 requires full 10-step verification contract per plan
- DB-006 will not be unblocked until SEC-002 CI closure

## Required Toolchain (Already Installed)
- postgresql-18
- postgresql-server-dev-18
- libsodium-dev
- build-essential
- make
- binutils
- pkg-config

## Approval Required
This implementation plan requires approval before proceeding with Phase 1.
