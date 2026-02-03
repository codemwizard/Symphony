# Phase‑0 Audit Report (Symphony)

**Date:** 2026‑02‑03  
**Scope:** Phase‑0 foundation (DB/migrations, invariants, CI gates, evidence harness, OpenBao dev parity, docs)  
**Inputs:**
- `Product-Requirement-Document_V2.txt`
- `PROXY_RESOLUTION_INTEGRATION_REVIEW.md`
- `Proxy_Request_Invariant.txt`
- Phase‑0 tasks and invariant docs created in this repo
- External guidance on log management and auditability (NIST SP 800‑92; PCI DSS logging intent; NIST key management guidance) citeturn0search1turn1search0turn0search3
- Payment orchestration feature expectations (routing/failover, compliance controls) citeturn0search2

---

## 1) Executive Summary

**Overall posture:** Strong Phase‑0 mechanical gating and evidence discipline. Core invariants, DB checks, evidence anchoring, and OpenBao dev parity are in place. The Phase‑0 base is credible for an evidence‑grade middleware foundation.

**Primary gaps (Phase‑0 appropriate):**
1) **Canonical baseline governance** (provenance + change‑control gate) for `schema/baseline.sql` beyond deterministic dumps.
2) **Audit‑grade logging policy** (retention, time sync, review cadence, failure detection) aligned to standard guidance. citeturn0search1turn1search0
3) **Key management policy** for evidence signing (even if signatures are Phase‑1/2). citeturn0search3
4) **Sealed DDL allowlist governance** (expiration + security review + evidence of allowlist hits).
5) **Local/CI parity check** to prevent workflow drift.

These gaps are governance‑level and **Phase‑0‑sized**: they strengthen audit‑grade posture without pulling runtime features forward.

---

## 2) Phase‑0 Strengths (already implemented)

- **Mechanical invariants**: repository structure, evidence anchoring, N‑1 compatibility, batching/routing fallback validators, security lints, and DB invariant checks are wired into CI.
- **Evidence discipline**: evidence artifacts emitted under `./evidence/phase0/` with fail‑closed gates; CI uploads artifacts.
- **OpenBao dev parity**: bootstrap + AppRole + deny‑test smoke evidence.
- **Append‑only critical ledgers**: outbox attempts and ingress attestations (append‑only enforcement + tests).
- **Baseline drift check**: enforce drift detection (now passing) with schema fingerprinting.
- **Proxy resolution invariant**: roadmap entry added for Phase‑1/2 integration, with Phase‑0 declaration/verification gating.

---

## 3) Audit‑grade Gaps vs PRD + External Standards

### Gap A — Canonical baseline governance (Phase‑0)
**Issue:** The baseline drift check exists, but canonicalization and provenance are not formalized; baseline updates can occur without a deliberate “why” artifact.

**Why it matters:** Auditors prefer immutable, explainable baselines with stable, reproducible generation steps and provenance. This is standard log‑management rigor applied to schema evidence. citeturn0search1

**Phase‑0 fix:**
- Add a canonicalizer (`scripts/db/canonicalize_schema_dump.sh`) and include `pg_dump` provenance fields (dump source, versions, normalized hash).
- Enforce “baseline change requires migration + explanation artifact.”

### Gap B — Audit logging policy (retention, time sync, review cadence)
**Issue:** Phase‑0 includes evidence artifacts but does not define or enforce core audit logging governance. External standards emphasize log management discipline and daily review intent for critical systems. citeturn0search1turn1search0

**Phase‑0 fix:**
- Add a policy doc and verification hooks:
  - log retention (e.g., 12 months, 3 months hot) citeturn0search3
  - time synchronization controls
  - failure detection for logging pipelines

### Gap C — Key management policy for evidence signing
**Issue:** PRD expects signed evidence bundles. Phase‑0 lacks key management policy language or stub controls.

**Why it matters:** Key management guidance is foundational to any evidence signature scheme. citeturn0search3

**Phase‑0 fix:**
- Introduce a key management policy stub (not implementation) and a roadmap invariant that evidence signing must use managed keys with rotation and access controls.

### Gap D — DDL allowlist governance
**Issue:** DDL lint allowlisting exists but needs a **sealed exception process** (expiry + security review + evidence of allowlist hits). This is a common audit concern in high‑assurance environments.

**Phase‑0 fix:**
- Add allowlist metadata (`expires_on`, reason, fingerprint) + CODEOWNERS review + evidence reporting of allowlist hits.

### Gap E — Local/CI parity guardrail
**Issue:** Local checks can drift from CI steps (already seen with CI‑only verification). This is a common cause of Phase‑0 instability.

**Phase‑0 fix:**
- Add `scripts/ci/verify_local_ci_parity.sh` to ensure referenced scripts/evidence paths match between dev and CI.

---

## 4) PRD/Proxy‑Resolution Alignment Assessment

- PRD and proxy review require **durable resolution records** for alias/beneficiary identity to avoid “ghost beneficiary” failures.
- The newly added **roadmap invariant** (proxy/alias resolution before dispatch) is correct for Phase‑0; implementation belongs to Phase‑1/2.

**Missing Phase‑0 governance work:**
- ADR that locks resolve‑before‑enqueue vs resolve‑before‑dispatch decision.
- Schema design hooks (`proxy_resolutions` append‑only + optional cache), explicitly marked as **design** not migrations.
- Static verification gate and evidence emission.

---

## 5) Recommended Phase‑0 Additions (summary)

1) **Canonical baseline generation + provenance evidence**
2) **Baseline change governance gate** (migration + explanation required)
3) **Audit logging policy + verification hooks** (retention, time sync, daily review) citeturn0search3turn0search0
4) **Key management policy stub for evidence signing** citeturn0search2
5) **Sealed DDL allowlist governance**
6) **Local/CI parity verification**
7) **Proxy resolution ADR + schema design + static verification (roadmap)**

---

## 6) Conclusion

Phase‑0 is mechanically robust and aligns with the PRD’s evidence‑grade goals. The remaining gaps are governance‑level and can be fully addressed within Phase‑0 without pulling runtime features forward. Addressing the audit‑grade gaps above will make the Phase‑0 base defensible to regulators and Tier‑1 auditors, while aligning with common payment orchestration expectations like compliance controls, routing resilience, and auditability. citeturn0search2
