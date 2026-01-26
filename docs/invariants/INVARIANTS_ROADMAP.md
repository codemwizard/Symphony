# Symphony Invariants Roadmap (Planned / Reserved)

This document lists invariants that are planned and reserved.
They are **NOT** enforced unless promoted into `docs/invariants/INVARIANTS_IMPLEMENTED.md` with mechanical verification.

Guiding rule:
- If it isn’t mechanically enforced, it stays here.

---

## Policy rotation with grace (Promote → Demote + Grace)

**Already implemented (scaffolding promoted to Implemented):**
- `policy_versions.status` column exists (schema scaffolding)
- `policy_versions.checksum` is required (NOT NULL)
- Unique predicate index enforces a single `status='ACTIVE'` policy row
- `policy_versions.is_active` exists for current boot-query compatibility

**Still planned (behavior + APIs):**
- I-POLICY-ROT-01 Acceptability function (ACTIVE or GRACE not expired)
- I-POLICY-ROT-02 Atomic rotation function with serialization (promote new → ACTIVE, demote old → GRACE)
- I-POLICY-ROT-03 Instruction pinning (policy identity + checksum) at ingress
- I-POLICY-ROT-04 Execution-time enforcement (POLICY_VIOLATION terminal)
- I-POLICY-ROT-05 Reaper transitions expired GRACE → RETIRED

---

## Tenancy / Participants

Reserved invariants:
- I-TENANT-01 Tenant scoping for business tables
- I-TENANT-02 No cross-tenant access by default
- I-PART-01 Participant identity contract

---

## Ingress attestation

Reserved invariants:
- I-ATTEST-01 Immutable acceptance record
- I-ATTEST-02 Replay prevention (idempotent acceptance)
- I-ATTEST-03 Tamper-evident policy link (checksum)

---

## Ledger core (financial ledger)

Reserved invariants:
- I-LEDGER-01 Append-only ledger entries
- I-LEDGER-02 Double-entry balance rules
- I-LEDGER-03 Traceability to instruction/outbox attempts
- I-LEDGER-04 Idempotent posting keys

---

## Cross-cutting

Reserved invariants:
- I-BASELINE-01 Baseline freshness (baseline.sql matches migrations)
- I-ERR-01 Error code registry for DB function errors
- I-PERF-01 Hot-path queries must be indexed and bounded
- I-RET-01 Retention/archival policy for append-only ledgers
