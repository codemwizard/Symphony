# Master Invariant -> Symphony Canonical Mapping (Semantic Delta)

Status: proposed
Scope: semantic mapping from "Symphony Master Architectural Invariants" to current `docs/invariants/INVARIANTS_MANIFEST.yml`
Purpose: identify exact gaps and provide implementation-ready "new invariant" definitions with verbatim source text.

## 1) Mapping Summary

| Master Invariant | Symphony Coverage | Canonical IDs with overlap | Gap Action |
|---|---|---|---|
| INV-FLOW-01 Directional Flow Enforcement | Missing | none | New invariant required |
| INV-FLOW-02 No Backward Calls | Missing | none | New invariant required |
| INV-FLOW-03 No OU Bypasses | Missing | none | New invariant required |
| INV-FLOW-04 Atomic OU Ownership | Missing | none | New invariant required |
| INV-FLOW-05 Plane Isolation | Partial | INV-071, INV-072, INV-076 | New invariant required for write-path enforcement |
| INV-PERSIST-01 Persistence Reality | Missing | none | New invariant required (phase-gated) |
| INV-PERSIST-02 Log Immutability | Covered | INV-014, INV-035, INV-036, INV-090, INV-091, INV-093 | No new invariant required; optionally tighten scope note |
| INV-PERSIST-03 Idempotency Integrity (extended) | Partial | INV-011, INV-023 | New invariant required for posting-layer replay idempotency |
| INV-FIN-01 Double-Entry Integrity continuous zero-sum | Missing | none | New invariant required |
| INV-FIN-02 Transaction Determinism | Partial | INV-032, INV-066, INV-127 | New invariant required for full terminal-state semantics |
| INV-FIN-03 Positive-Only Movement | Missing | none | New invariant required |
| INV-FIN-04 Distinct Counterparty | Missing | none | New invariant required |
| INV-FIN-05 Posting Idempotency | Partial | INV-011, INV-023 | New invariant required |
| INV-FIN-06 Currency Explicitness | Missing | none | New invariant required |
| INV-SEC-01 Identity Provenance | Partial | INV-063, INV-119 (governance overlap only) | New invariant required |
| INV-SEC-02 Domain Separation & Logging Discipline | Partial | INV-107, INV-132 | New invariant required |
| INV-SEC-03 Trust Tier Isolation | Missing | none | New invariant required |
| INV-SEC-04 Fail-Closed Environment Gates | Covered | INV-039, INV-132, INV-134 | No new invariant required |
| INV-SEC-05 No Hardcoded Secrets (strict runtime) | Partial | INV-073, INV-132, INV-134 | New invariant required for runtime-only strictness |
| INV-PCI-01 Card Data Non-Presence | Missing | none | New invariant required |
| INV-OPS-01 Observability Is a Control | Partial | INV-092 | New invariant required |
| INV-OPS-02 Audit Precedence | Missing | none | New invariant required |
| INV-OPS-03 Development Parity & Safety | Partial | INV-079, INV-080 | New invariant required |

## 2) New Canonical IDs (Proposed)

Use currently unused ID slots to avoid collision with existing manifest IDs.

| Proposed ID | Master Source |
|---|---|
| INV-045 | INV-FLOW-01 |
| INV-046 | INV-FLOW-02 |
| INV-047 | INV-FLOW-03 |
| INV-049 | INV-FLOW-04 |
| INV-050 | INV-FLOW-05 |
| INV-051 | INV-PERSIST-01 |
| INV-052 | INV-PERSIST-03 |
| INV-053 | INV-FIN-01 |
| INV-054 | INV-FIN-02 |
| INV-055 | INV-FIN-03 |
| INV-056 | INV-FIN-04 |
| INV-057 | INV-FIN-05 |
| INV-058 | INV-FIN-06 |
| INV-059 | INV-SEC-01 |
| INV-074 | INV-SEC-02 |
| INV-082 | INV-SEC-03 |
| INV-083 | INV-SEC-05 |
| INV-084 | INV-PCI-01 |
| INV-085 | INV-OPS-01 |
| INV-086 | INV-OPS-02 |
| INV-087 | INV-OPS-03 |

## 3) New Invariant Definitions (Verbatim Source Text)

The following definitions are copied verbatim from the provided "Master Architectural Invariants" content and should be treated as authoritative wording for new rows.

### INV-045 (from INV-FLOW-01)
- **INV-FLOW-01: Directional Flow Enforcement**
  - Data and identity must flow only in specified directions (Upstream ➔ Downstream).
  - This prevents lateral privilege escalation and secures the trust boundary.

### INV-046 (from INV-FLOW-02)
- **INV-FLOW-02: No Backward Calls (HARDENED)**
  - Backward calls (Downstream ➔ Upstream) are prohibited at **runtime**, not just by convention.
  - Violations MUST cause immediate request termination.
  - **Termination MUST occur before any state mutation, audit commitment, or external side-effect.**

### INV-047 (from INV-FLOW-03)
- **INV-FLOW-03: No OU Bypasses**
  - All external entry points must pass through OU-01 (Identity Control) before reaching functional OUs.

### INV-049 (from INV-FLOW-04)
- **INV-FLOW-04: Atomic OU Ownership (CLARIFIED)**
  - Every table and logic component has exactly one owning OU.
  - Ownership explicitly includes **schema write authority**.
  - Cross-OU reads are allowed ONLY via explicitly versioned, read-only interfaces.

### INV-050 (from INV-FLOW-05)
- **INV-FLOW-05: Plane Isolation**
  - The Control Plane must never write to Data Plane tables (`instructions`, `transaction_attempts`).

### INV-051 (from INV-PERSIST-01)
- **INV-PERSIST-01: Persistence Reality (PHASE-7 BLOCKER)**
  - No mock, simulated, or in-memory persistence layers may exist beyond Phase 6 execution.
  - All financial and audit paths require transactional PostgreSQL with role-enforced access.

### INV-052 (from INV-PERSIST-03)
- **INV-PERSIST-03: Idempotency Integrity (EXTENDED)**
  - Uniqueness of `(client_id, client_request_id)` is system-wide.
  - **Financial postings MUST also be idempotent under replay** to prevent double-entries during reconciliation retries.

### INV-053 (from INV-FIN-01)
- **INV-FIN-01: Double-Entry Integrity (PHASE-7 BLOCKER)**
  - Every fund movement must be a zero-sum transaction with a debit and a credit.
  - **The system MUST be able to produce a continuous proof that Sum(All Ledger Accounts) == 0 at any point in time, not just per transaction.**
  - Violation is a fatal integrity failure.

### INV-054 (from INV-FIN-02)
- **INV-FIN-02: Transaction Determinism**
  - Only one `SUCCESS` attempt allowed per instruction.
  - Terminal states (`COMPLETED`, `FAILED`) are mutually exclusive and irreversible.

### INV-055 (from INV-FIN-03)
- **INV-FIN-03: Positive-Only Movement (TWEAKED)**
  - Entry amounts must be strictly positive; debit/credit polarity expresses direction.

### INV-056 (from INV-FIN-04)
- **INV-FIN-04: Distinct Counterparty**
  - Debit and Credit accounts in a single ledger entry must be distinct to prevent "balance wash."

### INV-057 (from INV-FIN-05)
- **INV-FIN-05: Posting Idempotency**
  - A financial posting with the same idempotency key MUST NOT create additional ledger entries under retry or replay.

### INV-058 (from INV-FIN-06)
- **INV-FIN-06: Currency Explicitness (AUDITOR-FACING)**
  - Every financial amount MUST be associated with an explicit ISO 4217 currency code.
  - Cross-currency movements MUST be represented as separate debit/credit pairs linked by a single FX reference.
  - Implicit currency assumptions are forbidden.

### INV-059 (from INV-SEC-01)
- **INV-SEC-01: Identity Provenance (FOUNDATIONAL RUNTIME INVARIANT)**
  - Identity context is immutable once verified. Overriding or re-deriving identity downstream is prohibited.

### INV-074 (from INV-SEC-02)
- **INV-SEC-02: Domain Separation & Logging Discipline**
  - Cryptographic material is purpose-bound (`identity/*`, `audit/*`, `financial/*`).
  - **No raw keys** or HMAC inputs in logs. Metadata only (Key IDs, purpose).

### INV-082 (from INV-SEC-03)
- **INV-SEC-03: Trust Tier Isolation**
  - External JWT identities never cause financial mutation directly.
  - The `jwtToMtlsBridge` is the only permitted crossing point.

### INV-083 (from INV-SEC-05)
- **INV-SEC-05: No Hardcoded Secrets (STRICT RUNTIME INVARIANT)**
  - All sensitive material (HMAC keys, DB credentials, API keys) MUST be injected via environment variables or derived via `KeyManager`.
  - Hardcoded fallbacks (e.g., `|| 'dev-secret'`) are prohibited in production-path logic.

### INV-084 (from INV-PCI-01)
- **INV-PCI-01: Card Data Non-Presence**
  - Raw card credentials MUST NEVER appear in schemas, logs, or traces. Explicitly tied to `instrumentRef` and audit payloads.

### INV-085 (from INV-OPS-01)
- **INV-OPS-01: Observability Is a Control**
  - Tracing, logging, and metrics are security controls.
  - Mandatory correlation (Trace/Audit/Incident IDs).

### INV-086 (from INV-OPS-02)
- **INV-OPS-02: Audit Precedence**
  - Audit records must be committed before external side-effects (API calls) are triggered.

### INV-087 (from INV-OPS-03)
- **INV-OPS-03: Development Parity & Safety (REFRAMED)**
  - This is a **Safety Invariant**: Dev environments must match production semantics (containerized Postgres).
  - Dev keys must be process-stable (deterministic) to ensure cross-service consistency.

## 4) Immediate Agent Checklist

1. Add proposed IDs (INV-045..INV-087 subset above) to `INVARIANTS_MANIFEST.yml` with `status: planned`.
2. For each, create verifier script + evidence schema + evidence artifact path.
3. Wire verifiers into phase-appropriate gate runner(s).
4. Add rows to `INVARIANTS_QUICK.md` and `INVARIANTS_ROADMAP.md`.
5. Do not promote to `implemented` until verifier + schema validation both pass.

## 5) Non-Negotiable for Adoption

- Semantic equivalence must be proven by enforcement, not inferred by title similarity.
- If existing invariant only partially overlaps, keep both until the new invariant is fully enforceable.
