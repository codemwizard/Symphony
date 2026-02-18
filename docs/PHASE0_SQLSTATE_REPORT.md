# Phase‑0 SQLSTATE Report (Revised)

## 1) Current State (as implemented)

### Do we have SQLSTATE enforcement today?
**Partially.** We use explicit SQLSTATEs in a few triggers/functions and rely on built‑in constraint SQLSTATEs. There is **no system‑wide SQLSTATE mapping** and **no SQLSTATE‑aware test suite** that asserts role‑boundary vs invariant error codes.

### Explicit custom SQLSTATEs currently in schema

| Area | Enforcement | SQLSTATE | Location |
|------|-------------|----------|----------|
| Append‑only outbox attempts | Trigger | `P0001` | `schema/migrations/0001_init.sql` |
| Append‑only ingress attestations | Trigger | `P0001` | `schema/migrations/0011_ingress_attestations.sql` |
| Append‑only revocation tables | Trigger | `P0001` | `schema/migrations/0012_revocation_tables.sql` |
| Outbox lease loss | Function | `P7002` | `schema/migrations/0002_outbox_functions.sql` |
| Invalid completion state | Function | `P7003` | `schema/migrations/0002_outbox_functions.sql` |

### Implicit SQLSTATEs via constraints

| Constraint type | SQLSTATE | Examples |
|-----------------|----------|----------|
| UNIQUE | `23505` | idempotency, single‑active policy, terminal uniqueness |
| CHECK | `23514` | JSON payload type, checksum non‑empty, bounds |
| NOT NULL | `23502` | required columns |
| FK | `23503` | references (where defined) |

### Role boundary SQLSTATEs
- Privilege posture is enforced by REVOKE + CI gate checks, but **no explicit tests assert `42501`** (insufficient privilege) today.

### Current gaps
1) No SQLSTATE‑aware tests (role boundary vs invariant triggers).
2) No reusable invariant helper (`raise_invariant()`).
3) Partial coverage of append‑only / state‑transition enforcement beyond outbox + ingress + revocation.

---

## 2) Revised Phase‑0 SQLSTATE Model (3‑Class)

### Class A — Platform / Infra
Meaning: platform could not safely execute.
- Examples: transient DB errors, serialization/deadlock, built‑in constraint errors (`235xx`, `40001`, `40P01`).
- Handling: fail‑closed; retry only when explicitly transient.

### Class B — Policy / Business‑Rule Invariants (`P7xxx`)
Meaning: invariant violation with audit‑grade semantics.
- Must be stable, documented, and mapped.
- Handling: fail‑closed, non‑retryable unless policy changes.

### Class C — Developer / Safety Guardrails (`P9xxx`)
Meaning: forbidden call‑path or programming error.
- Handling: panic‑level evidence and incident workflow.

#### Recommended ranges
- `P71xx` = Outbox invariants
- `P72xx` = Ingress invariants
- `P73xx` = Policy governance invariants
- `P74xx` = Revocation correctness invariants
- `P90xx` = Developer guardrails

---

## 3) Phase‑0 Contract Table (Stop CI Phantom Evidence)

Create a machine‑readable contract to define what evidence is required and when:

- `docs/PHASE0/phase0_contract.yml` (machine)
- `docs/PHASE0/PHASE0_CONTRACT.md` (human)

Minimum columns:
- `task_id`
- `status` (`roadmap | planned | in_progress | completed`)
- `verification_mode` (`local | ci | both | none`)
- `evidence_required` (`true|false`)
- `evidence_globs` (list)
- `notes`

**Evidence gate should enforce only:**
`status = completed AND evidence_required = true`.

---

## 4) Evidence Enforcement Rule (Phase‑0 invariant)

**Invariant:** Any verification script must emit the evidence file it claims.

Minimum JSON fields (per evidence file):
- `task_id`
- `timestamp_utc`
- `git_sha`
- `result: pass|fail`
- `details: {...}`

---

## 5) SQLSTATE Mapping + Drift Checks

### Mapping file
Create `docs/contracts/sqlstate_map.yml`:

```yaml
version: 1
ranges:
  P71xx: outbox_invariants
  P72xx: ingress_invariants
  P73xx: policy_invariants
  P74xx: revocation_invariants
  P90xx: developer_guardrails
codes:
  P7002:
    canonical: P7102
    class: B
    subsystem: outbox
    meaning: lease token mismatch on attempt completion
    retryable: false
  P7003:
    canonical: P7103
    class: B
    subsystem: outbox
    meaning: invalid completion state
    retryable: false
  P7102:
    class: B
    subsystem: outbox
    meaning: lease token mismatch on attempt completion
    retryable: false
  P7103:
    class: B
    subsystem: outbox
    meaning: invalid completion state
    retryable: false
```

### Drift check
Add `scripts/audit/check_sqlstate_map_drift.sh`:
- Validate mapping file format
- Ensure all `P7xxx/P9xxx` used in migrations/docs exist in the map
- Emit `evidence/phase0/sqlstate_map_drift.json`

---

## 6) Remap `P7002/P7003`?

**Preferred (Phase‑0):** Remap to `P7102/P7103` with legacy aliases in the map. If remap is deferred, reserve `P70xx` as legacy and start new codes at `P71xx`.

---

## 7) Implementation Plan Summary (Phase‑0)

1) Add `raise_invariant()` helper
2) Add SQLSTATE‑aware tests (role boundary → `42501`, invariants → `P0001` / `P7xxx`)
3) Introduce `phase0_contract.yml` and update evidence gate logic
4) Add `sqlstate_map.yml` + drift check
5) Decide on `P7002/P7003` remap policy

---

## 8) Outcome

This revision makes Phase‑0 **mechanically verifiable** without CI hallucinating evidence requirements. It also standardizes SQLSTATE semantics to be audit‑grade and future‑proof.
