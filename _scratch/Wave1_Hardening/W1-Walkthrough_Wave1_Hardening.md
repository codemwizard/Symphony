# W1-Walkthrough_Wave1_Hardening

## Phase Overview
**Phase Name**: Wave1_Hardening
**Phase Key**: W1
**Goal**: Implement core security hardening and ingress durability for Wave 1 assignments (TSK-P1-211 to 215).

## Changes Made

### 1. Ingress & Durability (TSK-P1-211, TSK-P1-212)
- **Problem**: Ingress logic was relying on deprecated non-persistent mocks or incorrect schema constraints.
- **Solution**: Restored `db_psql` ingress as the canonical path and corrected the `ON CONFLICT` target for billable clients to ensure deterministic idempotent writes.
- **Files**:
  - [Stores.cs](file:///home/mwiza/workspace/Symphony/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs)
  - [0074_billable_clients_client_key_constraint.sql](file:///home/mwiza/workspace/Symphony/schema/migrations/0074_billable_clients_client_key_constraint.sql)

### 2. Runtime Secret Hardening (TSK-P1-215)
- **Problem**: Sensitive keys were resolved directly from environment variables, bypassing OpenBao.
- **Solution**: Introduced `ISecretProvider` abstraction with an `OpenBaoSecretProvider` implementation. Configured the application to resolve secrets at startup with strict fail-closed semantics for the hardened profile.
- **Files**:
  - [SecretProviders.cs](file:///home/mwiza/workspace/Symphony/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/SecretProviders.cs)
  - [RuntimeSecrets.cs](file:///home/mwiza/workspace/Symphony/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/RuntimeSecrets.cs)
  - [Program.cs](file:///home/mwiza/workspace/Symphony/services/ledger-api/dotnet/src/LedgerApi/Program.cs)

### 3. Supplier Registry Persistence (TSK-P1-214)
- **Problem**: Supplier policy data was only in-memory, leading to data loss on restart.
- **Solution**: Implemented persistence logic in `SupplierPolicyStore` and wired the `NpgsqlDataSource` for DB read-through.
- **Files**:
  - [0075_supplier_registry_and_programme_allowlist.sql](file:///home/mwiza/workspace/Symphony/schema/migrations/0075_supplier_registry_and_programme_allowlist.sql)
  - [SignedInstructionAndSupplierHandlers.cs](file:///home/mwiza/workspace/Symphony/services/ledger-api/dotnet/src/LedgerApi/Commands/SignedInstructionAndSupplierHandlers.cs)

## Verification Results

### Automated Tests
The following unit tests were implemented and passed:
- `SecretProviderTests.cs`: Validated `OpenBaoSecretProvider` auth logic, `EnvironmentSecretProvider` fallback, and `RuntimeSecrets` resolution.

### Verifier Evidence
All Wave 1 verifiers passed successfully:
- [tsk_p1_211_billable_clients_constraint_fix.json](file:///home/mwiza/workspace/Symphony/evidence/phase1/tsk_p1_211_billable_clients_constraint_fix.json)
- [tsk_p1_212_npgsql_ingress_store_fix.json](file:///home/mwiza/workspace/Symphony/evidence/phase1/tsk_p1_212_npgsql_ingress_store_fix.json)
- [tsk_p1_213_demo_017_verifier_realignment.json](file:///home/mwiza/workspace/Symphony/evidence/phase1/tsk_p1_213_demo_017_verifier_realignment.json)
- [tsk_p1_214_supplier_registry_persistence.json](file:///home/mwiza/workspace/Symphony/evidence/phase1/tsk_p1_214_supplier_registry_persistence.json)
- [tsk_p1_215_openbao_secret_provider.json](file:///home/mwiza/workspace/Symphony/evidence/phase1/tsk_p1_215_openbao_secret_provider.json)

### Pre-CI Validation
The full `scripts/dev/pre_ci.sh` suite passed with **Exit Code 0**, confirming that the hardened architecture satisfies all project invariants, including:
- Correct YAML task metadata.
- Suppressed DDL lock-risk triggers for approved migrations.
- Updated database baseline alignment.

## Governance Compliance
- **Evidence Churn**: Cleaned per `EVIDENCE_CHURN_CLEANUP_POLICY.md`.
- **DDL Compliance**: All mutations allowlisted and approved.
- **Verification**: 100% verifier coverage for all Wave 1 tasks.
