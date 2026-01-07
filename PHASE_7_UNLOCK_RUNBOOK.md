# PHASE 7 UNLOCK CEREMONY RUNBOOK
## Symphony Platform — Financial Execution Enablement

**Document ID:** SYM-RB-P7-001  
**Status:** REQUIRED  
**Audience:** Platform Owner, Security Lead, Compliance Officer, Auditor  
**Change Classification:** Irreversible Scope Expansion  
**Execution Window:** Scheduled, witnessed, logged

---

## 1. PURPOSE
This runbook defines the mandatory ceremony required to unlock **Phase 7 — Financial Execution & Proof-of-Funds**.

Phase 7 introduces:
- Irreversible financial mutations
- Regulatory exposure
- Settlement correctness obligations

Activation is a **governed event**, not a standard deploy.

## 2. PRINCIPLE OF OPERATION
No person, script, or system may unilaterally enable Phase 7. Activation requires:
- Multi-role attestation
- CI-verifiable state
- Immutable audit evidence
- Explicit acknowledgment of expanded liability

## 3. PRECONDITIONS (HARD BLOCKERS)
All items below must be **TRUE** before ceremony begins.

### 3.1 Codebase Preconditions
- `PHASE=6` currently enforced in CI.
- No financial mutation code merged post-freeze.
- All Phase-7 PRs merged but inactive.
- No feature flags referencing Phase 7 enabled.

### 3.2 CI Preconditions
- CI pipeline deployed and passing.
- Invariant scanners active.
- Phase-gating enforcement active.
- Security audit scripts passing.

### 3.3 Operational Preconditions
- Incident response runbook approved.
- Rollback strategy tested.
- Monitoring dashboards live.
- Alerting channels configured.

### 3.4 Legal / Compliance Preconditions
- Declared regulatory scope signed.
- ISO-20022 execution explicitly approved.
- Proof-of-Funds model reviewed.
- Risk acceptance memo signed.

> [!CAUTION]
> If any precondition is false → **Ceremony is aborted.**

---

## 4. ROLES & RESPONSIBILITIES
| Role | Responsibility |
| :--- | :--- |
| **Platform Owner** | Authorizes business risk |
| **Security Lead** | Certifies security posture |
| **Compliance Officer** | Certifies regulatory readiness |
| **Release Captain** | Executes ceremony steps |
| **Auditor (Optional)** | Observes, records evidence |

---

## 5. CEREMONY TIMELINE (EXECUTION ORDER)

### STEP 1 — DECLARATION OF INTENT
**Owner:** Platform Owner
- Read aloud (or record acknowledgment): *“We are initiating Phase 7 unlock. This enables irreversible financial execution.”*
- Confirm date/time window.
- Confirm rollback window.
- **Artifact:** `phase7-intent-declaration.md`

### STEP 2 — FINAL CI ATTESTATION
**Owner:** Security Lead
- **Execute:**
  ```bash
  git checkout main
  git pull
  PHASE=6 npm run ci:full
  ```
- **Verify:**
  - All invariant checks pass.
  - No financial mutations executed.
  - No dev-only paths detected.
  - No bypass flags present.
- **Artifact:** CI run ID, Hash of commit tested.

### STEP 3 — CONFIGURATION LOCK-IN
**Owner:** Release Captain
- **Verify production secrets:** KMS credentials, DB certificates, mTLS certificates.
- Verify no local or fallback config exists.
- Snapshot environment variable set.
- **Artifact:** `phase7-config-snapshot.json` (sealed).

### STEP 4 — PHASE FLIP (THE MOMENT)
**Owner:** Release Captain (Witnessed by Security Lead + Compliance Officer)
- **Execute:**
  ```bash
  export PHASE=7
  git commit -am "PHASE 7 UNLOCK: Financial execution enabled"
  git tag PHASE_7_UNLOCK_$(date +%Y%m%d)
  git push origin main --tags
  ```
- **This is the irreversible act.** From this moment, financial mutations are permitted.
- **Artifact:** Git tag, Commit hash, Timestamp.

### STEP 5 — POST-FLIP CI VERIFICATION
**Owner:** Security Lead
- **Execute:**
  ```bash
  PHASE=7 npm run ci:full
  ```
- **Verify:**
  - Phase-7-only code now executes.
  - Ledger mutation tests pass.
  - Proof-of-Funds invariant holds.
  - ISO-20022 scaffolding active (even if permissive).
- **Artifact:** CI run ID, Proof-of-Funds output.

### STEP 6 — LIVE SYSTEM VALIDATION
**Owner:** Platform Owner
- **Execute controlled test:**
  - Single synthetic transaction.
  - End-to-end ledger entry.
  - Reconciliation check.
  - Audit log verification.
- **Verify:**
  - Zero-sum invariant holds.
  - No hidden balances.
  - Full traceability.
- **Artifact:** Transaction ID, Ledger snapshot, Audit log excerpt.

### STEP 7 — FORMAL ATTESTATION SIGN-OFF (All Parties Required)
Each signer attests: *“I acknowledge that Phase 7 enables financial execution and that required controls are in place.”*

| Role | Name | Signature | Date |
| :--- | :--- | :--- | :--- |
| **Platform Owner** | | | |
| **Security Lead** | | | |
| **Compliance Officer** | | | |
| **Auditor (if present)** | | | |

- **Artifact:** `phase7-attestation.pdf`

---

##  failure HANDLING (NO-SHAME ABORT)
If any step fails:
- Ceremony stops immediately.
- No partial activation allowed.
- Incident logged as prevented activation.
- Root cause analysis performed.
- New ceremony scheduled.

## 7. POST-CEREMONY STATE
Once Phase 7 is unlocked:
- Rollback requires new ceremony.
- Schema changes require reconciliation proof.
- Any invariant failure is a production incident.
- Financial correctness becomes legally material.

## 8. AUDITOR NOTES
This ceremony:
- Establishes intent and accountability.
- Separates architecture readiness from execution risk.
- Prevents “accidental financial systems”.

## 9. FINAL WARNING (NON-NEGOTIABLE)
> [!WARNING]
> **Phase 7 is not a feature. It is a liability boundary.**  
> **Treat it accordingly.**
