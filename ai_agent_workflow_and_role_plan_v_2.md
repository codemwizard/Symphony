# AI‑Agent Workflow and Role Plan — v2 (Merged)

**Status:** Canonical (supersedes v1 and Draft)

This document merges:
- **AI‑Agent‑Workflow‑and‑Role‑Plan.txt** (governance anchor)
- **AI‑Agent‑Workflow‑and‑Role‑Plan‑Draft.txt / Draft2** (operational improvements)

It preserves all non‑negotiable governance constraints while incorporating safe operational enhancements. Where conflicts existed, **governance, invariants, and phase discipline take precedence**.

---

## 1. Purpose and Non‑Negotiables

Symphony uses AI agents to accelerate delivery **without weakening regulatory guarantees**.

Non‑negotiable principles:
- Invariants are first‑class contractual objects
- Phase discipline is strict and irreversible
- Evidence is mandatory, append‑only, and reproducible
- CI and pre‑CI parity is enforced
- AI agents are constrained actors, not autonomous authorities

No AI agent may:
- invent or rename invariant IDs
- bypass a control plane
- weaken an existing invariant
- merge regulated changes without human approval

---

## 2. Phase Discipline (Hard Constraints)

### Phase Authority Model

| Phase | Agent Permissions |
|-----|------------------|
| Phase‑0 | No structural changes; invariants immutable |
| Phase‑1 | Promote roadmap invariants to runtime enforcement |
| Phase‑2 | Extend enforcement and scale; never redefine Phase‑0/1 |

Rules:
- An invariant may only move **forward** in status
- Phase‑1 may *activate* but never *reinterpret* Phase‑0 claims
- Phase‑2 may not introduce partial backports

Agents must **halt and escalate** if a task risks violating phase boundaries.

---

## 3. Invariant Ownership and Authority Matrix (Restored)

Invariants are owned by control planes. Agents interact with invariants only through their assigned authority.

| Control Plane | Invariant Authority | Blocking Power |
|--------------|-------------------|----------------|
| Integrity | Schema safety, ordering, append‑only guarantees | Blocks all |
| Security | PII, access control, secrets, authz | Blocks runtime |
| Governance | Policy presence, remediation trace, approvals | Blocks merge |

### Agent‑Invariant Interaction Rules
- Agents may **propose** changes affecting invariants
- Only verifiers may **enforce** invariant outcomes
- Evidence artifacts are the only acceptable proof of compliance

---

## 4. AI Agent Roles (Authoritative Set)

### 4.1 DB / Schema Agent
- Owns migrations, constraints, triggers
- Enforces expand/contract discipline
- Cannot modify evidence semantics

### 4.2 Runtime / Orchestration Agent
- Implements state machines, workers, retries
- Must rely on DB‑level enforcement for safety
- Cannot bypass constraints

### 4.3 Security Guardian Agent
- Owns PII boundaries, authz, secrets posture
- Reviews any code touching sensitive data paths

### 4.4 Compliance / Invariant Mapper Agent
- Maps requirements → invariants → verifiers → evidence
- Updates manifests and contracts **only after code + evidence exist**

### 4.5 Evidence & Audit Agent
- Ensures deterministic evidence emission
- Validates reproducibility and hashing

### 4.6 Human Approver (Mandatory Role)
- Required for:
  - schema changes
  - invariant promotions
  - policy changes
- Approval recorded as evidence

---

## 5. Workflow Lifecycle (End‑to‑End)

1. **Task Declaration**
   - Task references invariant(s) explicitly
   - Phase and control plane impact declared

2. **Agent Execution**
   - Agent works only within its authority
   - All changes are local and verifiable

3. **Verifier Integration**
   - Verifier proves invariant holds
   - Evidence emitted on PASS and FAIL

4. **CI / pre‑CI Enforcement**
   - Ordered checks enforced
   - No hidden CI behavior

5. **Human Approval (if required)**
   - Recorded as evidence

6. **Merge and Contract Update**
   - Manifest/contract updated last

---

## 6. Remediation Trace Lifecycle (Restored)

Remediation is a first‑class workflow.

Rules:
- Every failure opens a remediation trace
- Every remediation links to:
  - failing evidence
  - fix commit(s)
  - passing evidence
- Remediation cannot be closed without new evidence

Agents must **not** silently fix failures.

---

## 7. Stop Conditions and Escalation (Hard Rules)

An agent **must stop and escalate** if:
- an invariant ID is unclear or missing
- a phase boundary is at risk
- evidence cannot be emitted deterministically
- a control plane conflict exists
- human approval is required but unavailable

No retries, no workarounds.

---

## 8. AI‑Assisted Development Governance

AI assistance is allowed with constraints:
- Prompt hash, model ID, and diff recorded
- Human approval required for regulated surfaces
- AI output treated as untrusted until verified

AI agents **do not own decisions** — they propose changes.

---

## 9. Operational Enhancements (From Draft — Non‑Governance‑Critical)

The following are permitted optimizations and do **not** alter governance semantics:
- Adaptive CI timeouts
- Batch‑aware retry logic
- Parallel verifier execution where ordering allows

These may not:
- change invariant meaning
- weaken failure visibility
- hide evidence

---

## 10. Final Rule of Engagement

> **Speed is allowed. Ambiguity is not.**

AI agents exist to accelerate delivery **within a mechanically enforced governance envelope**.

If a choice exists between velocity and proof, **proof wins**.

