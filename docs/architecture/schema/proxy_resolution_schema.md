# Proxy Resolution Schema (Design Hook)

> **Phase‑0 design hook only** — not a migration.

## Purpose
Define the **append‑only** schema required to record proxy/alias resolution outcomes without storing raw PII.

## Tables (proposed)

### `proxy_resolutions`
Append‑only ledger of proxy/alias resolutions.

```sql
-- design-only
CREATE TABLE public.proxy_resolutions (
  resolution_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instruction_id uuid NOT NULL,
  alias_type text NOT NULL,
  alias_hash bytea NOT NULL,
  resolved_participant_ref text NOT NULL,
  resolution_source text NOT NULL,
  evidence_hash bytea NOT NULL,
  resolved_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NULL
);

CREATE INDEX ON public.proxy_resolutions(instruction_id);
CREATE INDEX ON public.proxy_resolutions(resolved_at);
```

**Prohibited fields:** raw MSISDN, raw TPIN, raw national IDs.

### Optional cache: `proxy_resolution_current`
Convenience cache for valid resolutions (may be introduced Phase‑1+).

```sql
-- design-only
CREATE TABLE public.proxy_resolution_current (
  instruction_id uuid PRIMARY KEY,
  resolution_id uuid NOT NULL REFERENCES public.proxy_resolutions(resolution_id),
  alias_hash bytea NOT NULL,
  resolved_participant_ref text NOT NULL,
  expires_at timestamptz NULL
);
```

## Invariant Hook
- **INV‑048** requires a durable resolution record **before dispatch**.
- This design hook is validated by `scripts/audit/verify_proxy_resolution_invariant.sh` (Phase‑0 static check).
