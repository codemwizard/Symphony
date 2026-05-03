---
exception_id: EXC-002
inv_scope: change-rule
expiry: 2026-05-10
follow_up_ticket: TSK-RLS-ARCH-REM-001
reason: Bug fix implementation requires creating schema/rollbacks/ directory and 0095 rollback files. These are not migration files but rollback artifacts required by the original task plan.
author: cascade_agent
created_at: 2026-05-03
---

# Exception: Rollback files creation for bug fix

This exception covers the creation of rollback files in schema/rollbacks/ as part of bug fix implementation.

## Reason

Bug fix for TSK-RLS-ARCH-REM-001 requires creating schema/rollbacks/ directory and 0095 rollback files. These are not migration files but rollback artifacts:
- schema/rollbacks/0095_pre_snapshot.sql - Pre-migration policy snapshot
- schema/rollbacks/0095_rollback.sql - Rollback script for manual use

These files are required by the original task plan and by scripts/audit/verify_rls_arch_rem_001.sh and scripts/db/phase0_rls_enumerate.py.

## Evidence

structural_change: True
confidence_hint: 0.7
primary_reason: migration_file_added_or_deleted
reason_types: migration_file_added_or_deleted

Matched files:
- schema/rollbacks/0095_pre_snapshot.sql
- schema/rollbacks/0095_rollback.sql

## Mitigation

- Files are rollback artifacts, not migration files
- Located in schema/rollbacks/ directory, not schema/migrations/
- Required by existing verification scripts
- Part of approved bug fix implementation with Stage A approval
- Exception expires in 7 days to allow for completion of bug fix process
