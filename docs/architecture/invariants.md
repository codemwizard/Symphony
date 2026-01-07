# Symphony Master Architectural Invariants

**Status:** 🔒 LOCKED (AUTHORITATIVE ARCHITECTURAL FREEZE)  
**Scope:** Phases 1–7 + Infrastructure

This document is the "Source of Truth" for all system laws. Violations are treated as critical integrity failures and must be blocked at the earliest possible seam (CI, DB, or Runtime).

---

## 1. Foundational Interaction & Flow (INV-FLOW)
- **INV-FLOW-01: Directional Flow Enforcement**
  - Data and identity must flow only in specified directions (Upstream ➔ Downstream).
  - This prevents lateral privilege escalation and secures the trust boundary.
- **INV-FLOW-02: No Backward Calls (HARDENED)**
  - Backward calls (Downstream ➔ Upstream) are prohibited at **runtime**, not just by convention.
  - Violations MUST cause immediate request termination.
  - **Termination MUST occur before any state mutation, audit commitment, or external side-effect.**
- **INV-FLOW-03: No OU Bypasses**
  - All external entry points must pass through OU-01 (Identity Control) before reaching functional OUs.
- **INV-FLOW-04: Atomic OU Ownership (CLARIFIED)**
  - Every table and logic component has exactly one owning OU.
  - Ownership explicitly includes **schema write authority**.
  - Cross-OU reads are allowed ONLY via explicitly versioned, read-only interfaces.
- **INV-FLOW-05: Plane Isolation**
  - The Control Plane must never write to Data Plane tables (`instructions`, `transaction_attempts`).

## 2. Hardened Persistence & Integrity (INV-PERSIST)
- **INV-PERSIST-01: Persistence Reality (PHASE-7 BLOCKER)**
  - No mock, simulated, or in-memory persistence layers may exist beyond Phase 6 execution.
  - All financial and audit paths require transactional PostgreSQL with role-enforced access.
- **INV-PERSIST-02: Log Immutability**
  - Audit and status history logs are append-only.
  - `UPDATE` and `DELETE` privileges are revoked for all roles at the schema level.
- **INV-PERSIST-03: Idempotency Integrity (EXTENDED)**
  - Uniqueness of `(client_id, client_request_id)` is system-wide.
  - **Financial postings MUST also be idempotent under replay** to prevent double-entries during reconciliation retries.

## 3. Financial & Ledger Integrity (INV-FIN)
- **INV-FIN-01: Double-Entry Integrity (PHASE-7 BLOCKER)**
  - Every fund movement must be a zero-sum transaction with a debit and a credit.
  - **The system MUST be able to produce a continuous proof that Sum(All Ledger Accounts) == 0 at any point in time, not just per transaction.**
  - Violation is a fatal integrity failure.
- **INV-FIN-02: Transaction Determinism**
  - Only one `SUCCESS` attempt allowed per instruction.
  - Terminal states (`COMPLETED`, `FAILED`) are mutually exclusive and irreversible.
- **INV-FIN-03: Positive-Only Movement (TWEAKED)**
  - Entry amounts must be strictly positive; debit/credit polarity expresses direction.
- **INV-FIN-04: Distinct Counterparty**
  - Debit and Credit accounts in a single ledger entry must be distinct to prevent "balance wash."
- **INV-FIN-05: Posting Idempotency**
  - A financial posting with the same idempotency key MUST NOT create additional ledger entries under retry or replay.
- **INV-FIN-06: Currency Explicitness (AUDITOR-FACING)**
  - Every financial amount MUST be associated with an explicit ISO 4217 currency code.
  - Cross-currency movements MUST be represented as separate debit/credit pairs linked by a single FX reference.
  - Implicit currency assumptions are forbidden.

## 4. Identity, Security & Cryptographic Gates (INV-SEC)
- **INV-SEC-01: Identity Provenance (FOUNDATIONAL RUNTIME INVARIANT)**
  - Identity context is immutable once verified. Overriding or re-deriving identity downstream is prohibited.
- **INV-SEC-02: Domain Separation & Logging Discipline**
  - Cryptographic material is purpose-bound (`identity/*`, `audit/*`, `financial/*`).
  - **No raw keys** or HMAC inputs in logs. Metadata only (Key IDs, purpose).
- **INV-SEC-03: Trust Tier Isolation**
  - External JWT identities never cause financial mutation directly.
  - The `jwtToMtlsBridge` is the only permitted crossing point.
- **INV-SEC-04: Fail-Closed Environment Gates**
  - Development-grade providers (e.g., `DevelopmentKeyManager`) must perform a fatal exit if loaded in production.
- **INV-SEC-05: No Hardcoded Secrets (STRICT RUNTIME INVARIANT)**
  - All sensitive material (HMAC keys, DB credentials, API keys) MUST be injected via environment variables or derived via `KeyManager`.
  - Hardcoded fallbacks (e.g., `|| 'dev-secret'`) are prohibited in production-path logic.
- **INV-PCI-01: Card Data Non-Presence**
  - Raw card credentials MUST NEVER appear in schemas, logs, or traces. Explicitly tied to `instrumentRef` and audit payloads.

## 5. Observability & Operational Safety (INV-OPS)
- **INV-OPS-01: Observability Is a Control**
  - Tracing, logging, and metrics are security controls.
  - Mandatory correlation (Trace/Audit/Incident IDs).
- **INV-OPS-02: Audit Precedence**
  - Audit records must be committed before external side-effects (API calls) are triggered.
- **INV-OPS-03: Development Parity & Safety (REFRAMED)**
  - This is a **Safety Invariant**: Dev environments must match production semantics (containerized Postgres).
  - Dev keys must be process-stable (deterministic) to ensure cross-service consistency.

---
**Enforcement:** Verified via CI/CD gates, PostgreSQL RBAC, and Fail-Closed Runtime Assertions.
