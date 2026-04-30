# Wave 8 Crypto Finalization Amendment v3

## Summary

Adopt the current amendment as the controlling Wave 8 crypto closure plan, with four final hardening additions on the `SEC-002` side:

1. pin `PG_CONFIG` by absolute path
2. require compiler/linker hardening flags
3. require ABI evidence via `objdump` and `readelf`, not just `ldd`/`nm`
4. require `binutils` in WSL and CI toolchains

This keeps the SQL-side remediation exactly as already corrected, and turns `SEC-002` into a fully auditable PostgreSQL binary supply-chain task instead of a vague “write some C” task.

Repo-grounded assumptions remain:

- `0177` hard-fails correctly
- `0178` and `0179` reintroduce `verification_result := true`
- `0180` is present but placeholder-driven
- `0181` exists but is mixed-domain and should not be the final remediation shape
- `SEC-002` is still a stub and must be repaired before implementation
- the top-level Wave 8 control doc must exist before these amendments can be applied as authoritative policy

## Implementation Changes

### 1. Keep the SQL-side remediation unchanged

Retain the already-correct structure:

- `DB-007b` and `DB-007c` depend on substrate tasks, not `DB-006`
- `DB-009` owns non-signer context binding only
- signer authority stays exclusively in `DB-006`
- `0177`–`0181` remain immutable forward-only history
- the remediation migration chain remains:
  - `0182_wave8_restore_crypto_hardfail.sql`
  - `0183_wave8_replay_nonce_registry.sql`
  - `0184_wave8_timestamp_branch_enforcement.sql`
  - `0185_wave8_replay_branch_enforcement.sql`
  - `0186_wave8_context_binding_non_signer_enforcement.sql`

No further SQL-side restructuring is needed.

### 2. Define `SEC-002` as a deterministic binary build contract

Add a dedicated mandatory section under the Wave 8 plan and `TSK-P2-W8-SEC-002`:

> **SEC-002 Binary Build Contract**  
> `SEC-002` is not complete when C source exists. `SEC-002` is complete only when a reproducible PGXS-built `wave8_crypto.so` is produced, installed into PostgreSQL 18 extension paths, loaded via `CREATE EXTENSION`, linked to pinned libsodium, and proven against frozen parity vectors with evidence.

#### Source contract

Required authoritative tree:

```text
src/db/extensions/wave8_crypto/
  wave8_crypto.c
  wave8_crypto.control
  wave8_crypto--1.0.sql
  Makefile
```

Required ownership:

- `wave8_crypto.c`
  - exports PostgreSQL-callable `ed25519_verify(bytea, bytea, bytea) returns boolean`
  - owns only binary crypto verification
  - does not own signer resolution, replay, timestamp, or context binding

- `wave8_crypto.control`
  - defines extension metadata
  - sets `relocatable = false`

- `wave8_crypto--1.0.sql`
  - binds SQL function to the shared-object symbol
  - defines the exact SQL callable surface

- `Makefile`
  - defines the PGXS-only authoritative build path

Forbidden:

- CMake
- ad hoc shell build scripts as the authoritative build path
- direct `gcc`/`clang` command pipelines outside PGXS

#### Build contract

The only admissible build path is:

```bash
export PG_CONFIG=/usr/lib/postgresql/18/bin/pg_config
make PG_CONFIG="$PG_CONFIG"
make PG_CONFIG="$PG_CONFIG" install
```

Do not rely on ambient `PATH` resolution for `pg_config`.

Required assertions:

```bash
"$PG_CONFIG" --version | grep "PostgreSQL 18"
"$PG_CONFIG" --pkglibdir
"$PG_CONFIG" --sharedir
"$PG_CONFIG" --pgxs
```

Required Makefile contract:

```make
EXTENSION = wave8_crypto
MODULES = wave8_crypto
DATA = wave8_crypto--1.0.sql
PG_CONFIG = /usr/lib/postgresql/18/bin/pg_config

PG_CPPFLAGS += -I/usr/include -Wall -Wextra -Werror -O2 -fPIC
SHLIB_LINK += -lsodium -Wl,-z,relro -Wl,-z,now

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
```

This is mandatory, not illustrative.

#### Toolchain contract

**WSL / Ubuntu 24.04 developer build**

Required packages:

```bash
build-essential
clang
make
pkg-config
ca-certificates
jq
binutils
libsodium-dev
postgresql-18
postgresql-client-18
postgresql-server-dev-18
```

**CI build + proof environment**

Required packages:

```bash
build-essential
clang
make
pkg-config
jq
binutils
libsodium-dev
postgresql-18
postgresql-client-18
postgresql-server-dev-18
postgresql-18-pgtap
```

CI must perform:

- build
- install
- extension load
- known-good vector
- known-bad vector
- parity subset
- evidence generation

Compile success alone is inadmissible.

**Ubuntu 24.04 server runtime**

Preferred runtime packages for prebuilt-artifact deployment:

```bash
postgresql-18
postgresql-client-18
libsodium23
```

Optional for post-deploy verification:

```bash
postgresql-18-pgtap
```

Policy remains:
- build in CI
- ship artifact
- install artifact
- load extension
- do not compile in production unless recovery requires it

#### Install contract

Required install-path verification:

```bash
"$PG_CONFIG" --pkglibdir
"$PG_CONFIG" --sharedir
```

Required artifact locations:

- `$(PG_CONFIG --pkglibdir)/wave8_crypto.so`
- `$(PG_CONFIG --sharedir)/extension/wave8_crypto.control`
- `$(PG_CONFIG --sharedir)/extension/wave8_crypto--1.0.sql`

Required load boundary:

```sql
CREATE EXTENSION wave8_crypto;
SELECT ed25519_verify(...);
```

Binary existence without PostgreSQL loadability is not admissible.

#### Verification contract

`SEC-002` must prove all of:

1. `make PG_CONFIG=...` succeeds
2. `make PG_CONFIG=... install` succeeds
3. `ldd wave8_crypto.so` shows pinned libsodium linkage
4. `nm -D wave8_crypto.so | grep ed25519_verify`
5. `objdump -T wave8_crypto.so`
6. `readelf -d wave8_crypto.so`
7. `CREATE EXTENSION wave8_crypto` succeeds
8. `SELECT ed25519_verify(good)` returns `true`
9. `SELECT ed25519_verify(bad)` returns `false`
10. frozen parity subset matches `SEC-001`

This is the admissibility bar.

#### Artifact evidence contract

`TSK-P2-W8-SEC-002` evidence must include:

- `task_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `pg_version`
- `pg_config_path`
- `pkglibdir`
- `sharedir`
- `libsodium_version`
- `extension_checksum`
- `corpus_checksum`
- `ldd_output`
- `nm_output`
- `objdump_output`
- `readelf_output`
- `create_extension_output`
- `known_good_result`
- `known_bad_result`
- `parity_subset_results`
- `command_outputs`
- `execution_trace`

### 3. Update `TSK-P2-W8-SEC-002` ownership and scope

Repair `TSK-P2-W8-SEC-002` as a build-artifact task pack with this explicit scope:

- extension source
- PGXS build
- install path
- PostgreSQL load test
- binary linkage and ABI inspection
- parity subset verification
- binary evidence artifact emission

Explicit exclusions:

- DB-006 trigger integration
- signer cross-bind
- replay, timestamp, or context enforcement
- application-side `.NET` primitive behavior already covered by `SEC-001`

Ownership split remains:

- `SEC-000` = runtime/provider honesty for `.NET`
- `SEC-001` = `.NET` primitive correctness
- `SEC-002` = PostgreSQL binary correctness + loadability
- `DB-006` = authoritative SQL enforcement using the SEC-002 primitive

### 4. Keep one signer surface

Retain the prior schema decision:

- extend `wave8_signer_resolution`
- do not create `authorized_signer_registry`

`SEC-002` must include the schema-extension step for:

- `authority_class`
- `authorized_scopes`
- `revocation_log`
- `replacement_id`

Final signer cross-bind remains in `DB-006`, not `DB-009`.

### 5. Add one CI guard for extension drift

Add a narrow CI gate for `SEC-002`:

- fail if PGXS is not used
- fail if `PG_CONFIG` is not the absolute PostgreSQL 18 path
- fail if `wave8_crypto.so` is not loadable via `CREATE EXTENSION`
- fail if libsodium linkage is missing
- fail if ABI evidence (`objdump`/`readelf`) is missing
- fail if parity evidence or corpus checksum is missing

This is the extension-side equivalent of banning `verification_result := true` in SQL remediation.

## Test Plan

### SQL-side checks
- `0182` restores hard-fail only
- `0183` creates replay substrate only
- `0184` enforces timestamp only
- `0185` enforces replay only
- `0186` enforces non-signer context binding only

### SEC-002 build-contract checks
- required source tree exists exactly under `src/db/extensions/wave8_crypto/`
- `PG_CONFIG` is pinned by absolute path to PostgreSQL 18
- build runs through PGXS only
- compiler/linker flags include the required hardening flags
- `wave8_crypto.so` is installed to the correct PostgreSQL extension paths
- `ldd` shows libsodium linkage
- `nm -D` shows exported verify symbol
- `objdump -T` and `readelf -d` are captured and recorded
- `CREATE EXTENSION wave8_crypto` succeeds
- known-good vector returns `true`
- known-bad vector returns `false`
- parity subset matches `SEC-001`
- evidence JSON contains the full binary/build/install/runtime proof set

### Governance checks
- `0178`–`0181` remain classified as drifted/partial artifacts
- `SEC-002` cannot be marked complete by source presence alone
- CI blocks non-PGXS, wrong-`pg_config`, non-loadable, or non-evidenced extension outputs

## Assumptions and defaults

- The SQL-side amendment is accepted as final and does not need further structural change.
- The only remaining ambiguity is the PostgreSQL binary supply-chain contract for `SEC-002`.
- PostgreSQL 18 is the required build/load ABI target.
- PGXS is the only admissible build system.
- `pg_config` must be pinned by absolute path, not ambient `PATH`.
- `libsodium` is the chosen crypto dependency and must be linked, inspected, and evidenced.
- `binutils` is mandatory in WSL and CI because `nm`, `objdump`, and `readelf` are required evidence producers.
