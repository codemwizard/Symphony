# Phase‑0 Delta Assessment (Closed‑Loop + Non‑Custodial Requirements)

This document captures the Product Manager delta analysis between the current Phase‑0 foundation and the invariants required to fully support the closed‑loop, non‑custodial model described.

---

## Product Model (Target)

- **Multi‑tenant closed‑loop financial system**
- **Strict tenant isolation** across all services and data
- **Program Manager per tenant** governing cooperative/village‑banking groups
- **Group‑defined policy rules** for access to funds
- **Merchant/Supplier controls**
  - Restricted merchants (only purchase from these)
  - Preferred merchants (discount or priority terms)
- **Closed‑loop liquidity controls** with batch/flush settlement
- **Non‑custodial posture** to meet BoZ sandbox requirements

---

## What Phase‑0 already provides

- Evidence‑grade invariants and CI gates
- Append‑only outbox + idempotency controls
- Batching invariants (pool/flush behavior)
- OpenBao dev parity for secrets/identity governance
- N‑1 compatibility + DDL lock‑risk gates
- Deterministic audit trail discipline

---

## Deltas (What’s missing for the closed‑loop model)

### A) **Non‑Custodial Requirement (BoZ sandbox)**
**Gap:** No explicit invariant stating Symphony never holds custody of funds.

**Phase‑0 invariant needed:**
- “Funds custody must remain with licensed partners or user‑owned accounts; Symphony only orchestrates.”

**Evidence hook (Phase‑0):**
- Static verification (docs + architecture references + policy boundaries).

---

### B) **Program Manager + Cooperative Governance**
**Gap:** No invariant for tenant‑scoped Program Manager role and authority boundaries.

**Phase‑0 invariant needed:**
- “Each tenant must have a Program Manager role with scoped admin controls.”

**Evidence hook:**
- Role definitions + policy schema stub + verification placeholder.

---

### C) **Merchant/Supplier Restrictions**
**Gap:** No invariant enforcing merchant allowlists or preferred merchants.

**Phase‑0 invariant needed:**
- “Merchant restriction/preference rules must be enforced at authorization time.”

**Evidence hook:**
- Policy schema + static validation stub + roadmap gate.

---

### D) **Group‑Agreed Policy Rules**
**Gap:** No invariant requiring group approval for policy changes.

**Phase‑0 invariant needed:**
- “Policy updates require group approval or dual‑control workflow.”

**Evidence hook:**
- ADR + schema design stub + verification placeholder.

---

### E) **Closed‑Loop Liquidity Controls**
**Partial:** Batching invariant exists but not explicitly tied to tenant‑scoped liquidity pools.

**Phase‑0 invariant adjustment:**
- Explicitly define batching/flush thresholds per tenant pool.

---

## Can this be added without breaking Phase‑0?

**Yes.** These are governance‑level invariants and schema‑design hooks that fit Phase‑0:
- No runtime integration required
- Prevents Phase‑1/2 drift
- Supports audit‑grade posture and BoZ sandbox readiness

---

## Information needed to finalize invariants

1) **Non‑custodial scope**
   - Are wallets ledger‑only or tied to external regulated accounts?
2) **Program Manager powers**
   - Override rules? suspend groups? approve disbursements?
3) **Merchant model**
   - Hard restrictions vs optional preferences?
4) **Policy approval method**
   - Quorum? consensus? dual‑control?

---

## Summary

Phase‑0 foundation is strong for auditability and determinism. The remaining deltas are **governance‑level invariants** needed to support closed‑loop, non‑custodial group finance with merchant restrictions and Program Manager oversight. These can be added without compromising the current plan.

