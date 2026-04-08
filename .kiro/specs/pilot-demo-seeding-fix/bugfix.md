# Bugfix Requirements Document

## Introduction

This document specifies the requirements for fixing a foreign key constraint violation that occurs during pilot demo seeding. When the LedgerApi starts with pilot-demo runtime profile, the `SeedChungaWorkers()` function fails to insert worker records into the `supplier_registry` table because it uses a tenant ID that doesn't exist in the `public.tenants` table. This prevents the demo from functioning correctly and blocks pilot demo functionality.

The root cause is a tenant ID mismatch: `SeedDemoTenant()` creates a tenant and retrieves the actual tenant ID from the database, while `SeedChungaWorkers()` independently recomputes the tenant ID from a seed string. These IDs may not match, causing the foreign key constraint to fail when workers attempt to insert with the recomputed ID.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN `SeedDemoTenant()` creates a tenant and returns control THEN `SeedChungaWorkers()` recomputes the tenant ID independently from the seed string "ten-zambiagrn"

1.2 WHEN `SeedChungaWorkers()` attempts to insert worker records with the recomputed tenant ID THEN the system throws Npgsql.PostgresException 23503 (foreign key constraint violation) because the tenant ID doesn't exist in `public.tenants`

1.3 WHEN the foreign key constraint violation occurs THEN the error is logged as a warning and worker seeding silently fails without propagating the error

1.4 WHEN `SYMPHONY_UI_TENANT_ID` environment variable is set to a different GUID THEN `SeedChungaWorkers()` may use that GUID which doesn't exist in `public.tenants`, causing the same constraint violation

### Expected Behavior (Correct)

2.1 WHEN `SeedDemoTenant()` creates a tenant and retrieves the actual tenant ID from the database THEN that actual tenant ID SHALL be passed to `SeedChungaWorkers()` for use in worker registration

2.2 WHEN `SeedChungaWorkers()` receives the actual tenant ID as a parameter THEN the system SHALL successfully insert worker records into `supplier_registry` without foreign key constraint violations

2.3 WHEN worker seeding completes successfully THEN the system SHALL log an informational message confirming successful worker seeding

2.4 WHEN `SYMPHONY_UI_TENANT_ID` environment variable is set THEN both `SeedDemoTenant()` and `SeedChungaWorkers()` SHALL use the same tenant ID consistently

### Unchanged Behavior (Regression Prevention)

3.1 WHEN `SeedDemoTenant()` creates a tenant in `tenant_registry` (control plane) THEN the system SHALL CONTINUE TO create the tenant in `public.tenants` (legacy table) via `OnboardAsync`

3.2 WHEN `SeedDemoTenant()` creates a programme for the tenant THEN the system SHALL CONTINUE TO seed legacy `escrow_accounts` and `programs` tables to satisfy foreign key constraints

3.3 WHEN `SeedChungaWorkers()` registers workers THEN the system SHALL CONTINUE TO set `supplier_type = "WORKER"` as required by pilot-demo policy

3.4 WHEN `SeedChungaWorkers()` registers workers THEN the system SHALL CONTINUE TO add workers to the program supplier allowlist

3.5 WHEN seeding functions encounter database schema errors (42P01) THEN the system SHALL CONTINUE TO log critical errors with migration guidance

3.6 WHEN `CreateStableGuid()` is called with the same seed string THEN the system SHALL CONTINUE TO return deterministic GUIDs

3.7 WHEN `SeedDemoInstructions()` runs THEN the system SHALL CONTINUE TO function independently without requiring tenant ID parameter changes
