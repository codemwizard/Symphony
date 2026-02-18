-- 0022_participants_registry.sql
-- Participant registry schema hook (Phase-0: schema-only; forward-only)

CREATE TABLE IF NOT EXISTS public.participants (
  participant_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  participant_kind TEXT NOT NULL CHECK (
    participant_kind IN ('BANK','MMO','NGO','GOV_PROGRAM','COOP_FEDERATION','ENTERPRISE','INTERNAL')
  ),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

