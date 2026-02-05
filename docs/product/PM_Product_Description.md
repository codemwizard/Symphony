# Symphony Product Description (PM Summary)

This document captures the Product Manager summary of the platform described in the closed‑loop logical architecture and how it fits into Symphony’s current capabilities.

---

## Product Summary (What it is)

Symphony is a **multi‑tenant, closed‑loop financial platform** that enables independent communities (e.g., cooperatives, ROSCAs, village banking groups) to operate with strict tenant isolation on shared infrastructure. Each tenant has its own wallet ecosystem, rules, ledger, and liquidity behavior while leveraging common services and governance controls.

### Core promise
- **Tenant‑scoped closed loop:** funds, transactions, and rules never cross tenant boundaries.
- **Shared infrastructure, strict isolation:** shared compute/messaging/datastores with logical isolation enforced at every layer.
- **Deterministic & auditable:** every balance change is traceable and evidence‑grade.

---

## Logical Architecture (How it works)

### 1) Client Layer
- Mobile wallets, admin UI, partner APIs

### 2) API Gateway Layer
- Auth, rate limiting, tenant resolution

### 3) Tenant Context Boundary (non‑negotiable)
- Every request carries immutable `{tenant_id, user_id, role, permissions}`
- No service executes without tenant context

### 4) Domain Service Layer
- Wallets, transactions, groups, rules
- Shared binaries with tenant‑scoped behavior

### 5) Ledger & Liquidity Layer
- Double‑entry ledger per tenant
- Pool/flush engine for batch settlement

### 6) Data Layer
- Tenant‑partitioned datastores & logs

---

## Fit with Symphony’s Phase‑0 capabilities

### Already aligned
- **Evidence‑grade invariants & gates** (auditability and compliance discipline)
- **Append‑only outbox + idempotency** (ledger safety / deterministic execution)
- **Batching invariants** (supports pool/flush mechanics)
- **OpenBao dev parity** (identity/secret governance for regulated environments)
- **N‑1 compatibility + lock‑risk gates** (safe evolution under strict governance)

### Product positioning
Symphony is the **orchestration + ledger core** of a closed‑loop system: it enforces tenant isolation, policy‑driven access to liquidity, and a deterministic evidence trail, while remaining flexible enough to integrate with external rails during settlement.

---

## Why this matters (Product framing)

The platform enables:
- **Community finance at scale** (shared infra, strict isolation)
- **Rules‑based access to liquidity** (governed by tenant policy)
- **Auditable compliance posture** (evidence by design)

---

## Optional outputs (if needed)

If desired, this can be expanded into:
- One‑pager product vision
- MVP scope
- Capability map vs target user roles

