# Implementation Plan for TSK-P2-W8-SEC-002

## Task Metadata
- **Task ID**: TSK-P2-W8-SEC-002
- **Title**: PostgreSQL native Ed25519 verification primitive
- **Owner Role**: SECURITY_GUARDIAN
- **Primary Enforcement Domain**: PostgreSQL binary build contract
- **Status**: in_progress
- **Depends On**: TSK-P2-W8-SEC-001
- **Blocks**: TSK-P2-W8-DB-006

## Objective
Provide a PostgreSQL native Ed25519 signature verification primitive as a C extension using libsodium. This enables DB-006 (cryptographic enforcement) to perform actual Ed25519 verification instead of placeholder acceptance.

## Scope
- Extension source code (wave8_crypto.c, wave8_crypto.control, wave8_crypto--1.0.sql, Makefile)
- PGXS build system with pinned PostgreSQL 18 configuration
- Install path verification
- PostgreSQL load test
- Binary linkage and ABI inspection (ldd, nm, objdump, readelf)
- Parity subset verification (known-good and known-bad Ed25519 test vectors)
- Binary evidence artifact emission

## Exclusions
- DB-006 trigger integration (handled by TSK-P2-W8-DB-006)
- Signer cross-bind (handled by signer lifecycle tasks)
- Replay/timestamp/context enforcement (handled by DB-007b/007c/009)
- Application-side .NET primitive behavior (separate concern)

## Implementation Steps

### Step 1: Create Extension Source Tree
- Create `src/db/extensions/wave8_crypto/wave8_crypto.c` with ed25519_verify() function
- Create `src/db/extensions/wave8_crypto/wave8_crypto.control` with extension metadata
- Create `src/db/extensions/wave8_crypto/wave8_crypto--1.0.sql` with SQL binding
- Create `src/db/extensions/wave8_crypto/Makefile` with PGXS build configuration

### Step 2: Configure Build System
- Pin PG_CONFIG to `/usr/lib/postgresql/18/bin/pg_config`
- Add compiler hardening flags: `-Wall -Wextra -Werror -O2 -fPIC`
- Add linker hardening flags: `-lsodium -Wl,-z,relro -Wl,-z,now`
- Ensure PostgreSQL 18 header compatibility (varatt.h inclusion)

### Step 3: Create Verification Artifacts
- Create `evidence_schemas/r_020_sec002_binary_build.schema.json` for binary build evidence
- Create `scripts/audit/verify_tsk_p2_w8_sec_002.sh` for 10-step verification contract
- Update `tasks/TSK-P2-W8-SEC-002/meta.yml` with build-artifact scope and invariants

### Step 4: Execute Verification
- Run toolchain verification (pg_config, make, ldd, nm, objdump, readelf, psql, libsodium)
- Build extension with PGXS
- Install extension to PostgreSQL 18 directories
- Run binary inspection (ldd, nm, objdump, readelf)
- Load extension in PostgreSQL instance
- Run runtime verification (known-good and known-bad Ed25519 test vectors)

## Invariants
- Build must be reproducible on pinned PostgreSQL 18 environment
- Extension must load and function correctly
- All cryptographic operations must use libsodium
- Compiler flags must include hardening options: `-Wall -Wextra -Werror -O2 -fPIC -Wl,-z,relro -Wl,-z,now`
- PG_CONFIG must be explicitly set to `/usr/lib/postgresql/18/bin/pg_config` during build
- Extension must handle TOASTed bytea data correctly using `PG_DETOAST_DATUM`, `VARDATA`, `VARSIZE`

## Verifiers
- `scripts/audit/verify_tsk_p2_w8_sec_002.sh` - 10-step binary build and runtime verification
- `scripts/db/verify_wave8_migrations.sh` - SQL migration verification (0182-0186)
- Integration with `scripts/dev/pre_ci.sh` for CI parity

## Evidence
- `evidence/phase2/tsk_p2_w8_sec_002.json` - Consolidated JSON evidence for SEC-002 binary build and verification
- Schema: `evidence_schemas/r_020_sec002_binary_build.schema.json`

## Proof Boundary
- Binary proof boundary must be crossed on an admissible build surface (PostgreSQL 18)
- pre_ci evidence is insufficient for SEC-002 admissibility
- Runtime verification requires a running PostgreSQL instance with libsodium available
- Extension load and Ed25519 verification must be tested against actual test vectors

## Anti-Fraud Rules
- Evidence must be generated on pinned PostgreSQL 18 build surface
- No partial or inadmissible evidence accepted
- Binary inspection outputs must be captured and verified
- Runtime verification must use known-good and known-bad Ed25519 test vectors
