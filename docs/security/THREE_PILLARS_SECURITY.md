# Three‑Pillar Security Model (Phase‑0)

## Purpose
Establish explicit **Control Planes** for Security, Integrity, and Governance so the system remains **fail‑closed** and **audit‑ready** as Phase‑0 expands. This model clarifies ownership, scope, and evidence obligations, and prevents “paper compliance” drift.

## Current Implementation (What Exists Today)

### Security (Perimeter & Guardrails)
- **Fast security checks** in `scripts/audit/run_security_fast_checks.sh`:
  - SQL injection lint
  - Privilege regression lint
  - Core boundary lint
  - DDL lock‑risk lint + allowlist governance
  - SECURITY DEFINER dynamic SQL lint
- **OpenBao parity** with declarative audit config and smoke tests.

### Integrity (Mechanical Truths / Invariants)
- **Fast invariants checks** in `scripts/audit/run_invariants_fast_checks.sh`:
  - Manifest validation
  - Docs ↔ manifest drift checks
  - Baseline governance + rebaseline strategy verification
  - SQLSTATE map drift check
  - Phase‑0 implementation plan check
  - Proxy‑resolution invariant (roadmap) check
- **DB invariants** in `scripts/db/verify_invariants.sh`.

### Governance (Evidence & Documentation)
- Evidence contract + Phase‑0 contract enforced in pre‑CI/CI.
- ADRs and governance docs exist, but **compliance mapping is not yet mechanically enforced**.

## Weaknesses / Gaps (Why We Need the Pillars)

1. **No explicit control‑plane boundary**
   - Security, Integrity, and Governance enforcement is implicit, not codified.

2. **Infra & supply‑chain blind spots**
   - Security checks do not yet cover `infra/**`, dependency manifests, or `src/**` static risk patterns.

3. **Evidence harness overlap**
   - The “watch‑the‑watcher” pattern isn’t codified; evidence checks can be weakened without a cross‑plane alarm.

4. **Compliance is documented but not enforced**
   - PCI DSS / NIST / OWASP / ISO mappings are not yet mechanically verified against evidence outputs.

## Proposed Improvements (Phase‑0 Safe)

### 1) Control Planes (Explicit Ownership + Scope)
Introduce a single source of truth:

- `docs/control_planes/CONTROL_PLANES.yml`

Each plane declares:
- **Owner** (agent role)
- **Scope** (paths and responsibility boundaries)
- **Required gates** (scripts + evidence paths)

This makes plane boundaries **explicit**, testable, and auditable.

### 2) “Watch‑the‑Watcher” Enforcement
Add a **control‑plane drift verifier** that ensures:
- All declared gates exist
- Evidence paths match what CI checks expect
- Wrappers reference only approved evidence targets

### 3) Security Plane Expansion (No Runtime Required)
Add static, Phase‑0‑safe guardrails:
- Secrets/credential leak scan
- .NET dependency audit (no npm)
- Secure config lint for infra + workflows
- App‑code insecure pattern lint (static only)

### 4) Governance Plane: Compliance Mapping + Evidence
Expand compliance manifest to include:
- **PCI DSS v4.0**
- **NIST CSF / 800‑53**
- **OWASP ASVS**
- **ISO‑20022**
- **ISO‑27001:2022 / 27002**

Add a verifier that cross‑checks evidence artifacts vs mapping requirements.

## Execution Guarantee (How We Ensure the Agents Run)

**Agents must run as part of pre‑CI and CI**, not only “after tasks are done.”

- **Local pre‑CI** (always, before push):
  - `scripts/dev/pre_ci.sh`
  - runs `scripts/audit/run_security_fast_checks.sh`
  - runs `scripts/audit/run_invariants_fast_checks.sh`
  - runs governance checks if present

- **CI enforcement** (always, on PR/push):
  - `.github/workflows/invariants.yml` executes the same checks
  - Evidence gate uses `docs/PHASE0/phase0_contract.yml` to enforce only completed tasks

**Result:**
- Security, Integrity, and Governance checks run **every change**.
- Task completion is only recognized when evidence exists and the contract is updated.

## How This Strengthens the System

- **Prevents single‑plane drift:** one plane cannot silently weaken another.
- **Hardens supply‑chain and infra:** CI catches risky changes before merge.
- **Improves auditability:** evidence is tied to explicit control‑plane gates.
- **Keeps Phase‑0 safe:** all improvements are static or governance‑level, no runtime coupling.

---

## Summary
The Three‑Pillar model converts “agent helpers” into **control planes** with explicit responsibility boundaries. It makes enforcement mechanical, evidence‑backed, and consistent with Tier‑1 compliance expectations — without expanding Phase‑0 into runtime integration.
