# Tenant–Client–Member Migration Plan (Phase‑0 Safe)

This plan introduces **tenant, client, and member attribution rails** without forcing runtime changes yet. It is **expand‑first**, **non‑custodial**, and **N‑1 compatible**.

## Guiding Principles (Phase‑0)

- **Tenant boundary is mandatory at ingress.**
- **Member attribution is optional but enforced when present.**
- **Outbox tenant attribution is added as nullable now; enforced later.**
- **No blocking DDL on hot tables.**
- **Forward‑only, no down migrations.**

---

## Migration 0014 — Tenants

```sql
-- 0014_tenants.sql
CREATE TABLE IF NOT EXISTS public.tenants (
  tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_key text NOT NULL UNIQUE,              -- stable ID e.g. "grz-fisp-2026"
  tenant_name text NOT NULL,
  tenant_type text NOT NULL CHECK (tenant_type IN ('NGO','COOPERATIVE','GOVERNMENT','COMMERCIAL')),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenants_status ON public.tenants(status);

REVOKE UPDATE, DELETE ON public.tenants FROM PUBLIC;
```

---

## Migration 0015 — Tenant Clients

```sql
-- 0015_tenant_clients.sql
CREATE TABLE IF NOT EXISTS public.tenant_clients (
  client_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES public.tenants(tenant_id),
  client_key text NOT NULL,                     -- stable identifier (non-secret)
  display_name text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','REVOKED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, client_key)
);

CREATE INDEX IF NOT EXISTS idx_tenant_clients_tenant ON public.tenant_clients(tenant_id);

REVOKE UPDATE, DELETE ON public.tenant_clients FROM PUBLIC;
```

---

## Migration 0016 — Tenant Members

```sql
-- 0016_tenant_members.sql
CREATE TABLE IF NOT EXISTS public.tenant_members (
  member_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES public.tenants(tenant_id),
  member_ref text NOT NULL,                     -- program-specific reference
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','EXITED')),
  tpin_hash bytea NULL,
  msisdn_hash bytea NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, member_ref)
);

CREATE INDEX IF NOT EXISTS idx_tenant_members_tenant ON public.tenant_members(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_members_status ON public.tenant_members(status);

REVOKE UPDATE, DELETE ON public.tenant_members FROM PUBLIC;
```

---

## Migration 0017 — Ingress Attribution (Tenant Required)

```sql
-- 0017_ingress_tenant_attribution.sql
ALTER TABLE public.ingress_attestations
  ADD COLUMN IF NOT EXISTS tenant_id uuid NOT NULL REFERENCES public.tenants(tenant_id),
  ADD COLUMN IF NOT EXISTS client_id uuid NULL REFERENCES public.tenant_clients(client_id),
  ADD COLUMN IF NOT EXISTS client_id_hash text NULL,
  ADD COLUMN IF NOT EXISTS member_id uuid NULL REFERENCES public.tenant_members(member_id),
  ADD COLUMN IF NOT EXISTS participant_id uuid NULL,
  ADD COLUMN IF NOT EXISTS cert_fingerprint_sha256 text NULL,
  ADD COLUMN IF NOT EXISTS token_jti_hash text NULL;

-- Prevent double-accept per tenant/instruction
CREATE UNIQUE INDEX IF NOT EXISTS ux_ingress_attestations_tenant_instruction
  ON public.ingress_attestations(tenant_id, instruction_id);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_tenant_received
  ON public.ingress_attestations(tenant_id, received_at);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_member_received
  ON public.ingress_attestations(member_id, received_at)
  WHERE member_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_cert_fpr
  ON public.ingress_attestations(cert_fingerprint_sha256)
  WHERE cert_fingerprint_sha256 IS NOT NULL;
```

---

## Migration 0018 — Outbox Attribution (Expand‑First)

```sql
-- 0018_outbox_tenant_attribution.sql
ALTER TABLE public.payment_outbox
  ADD COLUMN IF NOT EXISTS tenant_id uuid NULL REFERENCES public.tenants(tenant_id),
  ADD COLUMN IF NOT EXISTS member_id uuid NULL REFERENCES public.tenant_members(member_id);

ALTER TABLE public.payment_outbox_pending
  ADD COLUMN IF NOT EXISTS tenant_id uuid NULL REFERENCES public.tenants(tenant_id);

ALTER TABLE public.payment_outbox_attempts
  ADD COLUMN IF NOT EXISTS tenant_id uuid NULL REFERENCES public.tenants(tenant_id),
  ADD COLUMN IF NOT EXISTS member_id uuid NULL REFERENCES public.tenant_members(member_id);

-- Indexes only if Phase‑1 query shapes require them
CREATE INDEX IF NOT EXISTS idx_payment_outbox_pending_tenant_due
  ON public.payment_outbox_pending(tenant_id, next_attempt_at)
  WHERE tenant_id IS NOT NULL;
```

---

## Migration 0019 — Member/Tenant Consistency Guard

```sql
-- 0019_member_tenant_consistency_guard.sql
CREATE OR REPLACE FUNCTION public.enforce_member_tenant_match()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  m_tenant uuid;
BEGIN
  IF NEW.member_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT tenant_id INTO m_tenant
  FROM public.tenant_members
  WHERE member_id = NEW.member_id;

  IF m_tenant IS NULL THEN
    RAISE EXCEPTION 'member_id not found' USING ERRCODE = '23503';
  END IF;

  IF NEW.tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant_id required when member_id is set' USING ERRCODE = 'P7201';
  END IF;

  IF m_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'member/tenant mismatch' USING ERRCODE = 'P7202';
  END IF;

  RETURN NEW;
END;
$$;

-- Always enforce on ingress_attestations
DROP TRIGGER IF EXISTS trg_ingress_member_tenant_match ON public.ingress_attestations;
CREATE TRIGGER trg_ingress_member_tenant_match
BEFORE INSERT ON public.ingress_attestations
FOR EACH ROW EXECUTE FUNCTION public.enforce_member_tenant_match();

-- Add to outbox_attempts only if member_id is actually used there in Phase‑1
-- DROP TRIGGER IF EXISTS trg_outbox_attempt_member_tenant_match ON public.payment_outbox_attempts;
-- CREATE TRIGGER trg_outbox_attempt_member_tenant_match
-- BEFORE INSERT ON public.payment_outbox_attempts
-- FOR EACH ROW EXECUTE FUNCTION public.enforce_member_tenant_match();
```

---

# Phase‑0 Invariants (Implemented)

- **Tenant attribution exists on ingress attestation (tenant_id NOT NULL).**
- **Member attribution is consistent when present.**
- **Tenant/client/member hierarchy exists as schema rails.**

---

# SQLSTATE Updates Required

Add to `docs/contracts/sqlstate_map.yml`:

```yaml
P7201:
  class: B
  subsystem: ingress
  meaning: tenant_id required when member_id is set
  retryable: false
P7202:
  class: B
  subsystem: ingress
  meaning: member/tenant mismatch
  retryable: false
```

---

# Evidence Hook (Phase‑0)

Add a verifier script that checks:
- tables exist
- columns exist
- constraints/triggers exist
- tenant_id NOT NULL on ingress_attestations
- member/tenant guard present

Evidence file:
- `evidence/phase0/tenant_member_hooks.json`

