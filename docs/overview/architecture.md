# Symphony Architecture

## System Layers

```
┌─────────────────────────────────────────┐
│           API Gateway (future)          │
├─────────────────────────────────────────┤
│     Services (outbox-relayer, api)      │
├─────────────────────────────────────────┤
│   Packages (db, bootstrap, common)      │
├─────────────────────────────────────────┤
│     PostgreSQL 18 (schema/migrations)   │
└─────────────────────────────────────────┘
```

## Key Components

| Component | Purpose | Status |
|-----------|---------|--------|
| `schema/migrations/` | Database DDL | ✅ Phase 0 |
| `scripts/db/` | Migration tooling | ✅ Phase 0 |
| `packages/node/db/` | Node.js DB adapter | 🔜 Phase 1 |
| `services/outbox-relayer/` | Payment dispatch | 🔜 Phase 1 |

## Database Roles

- `symphony_control` - Admin operations
- `symphony_executor` - Outbox processing
- `symphony_ingest` - Payment ingestion
- `symphony_readonly` - Read-only access
- `symphony_auditor` - Audit log access

## Invariants

See [INVARIANTS_QUICK.md](../invariants/INVARIANTS_QUICK.md) for the enforced invariants.
