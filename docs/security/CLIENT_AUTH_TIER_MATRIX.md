# Symphony Client Authentication Tier Matrix

**Document ID:** SEC-AUTH-TIER-MATRIX-0001  
**Status:** Controlled (Operational Assignment Register)  
**Owner:** CTO (final sign-off), with Compliance review input  
**Applies to:** All external participants connecting to Symphony ingress APIs  
**Related:** 
- `docs/security/CLIENT_AUTH_TIERS.md`
- `docs/security/ZERO_TRUST_POSTURE.md`
- `docs/security/AUTH_IDENTITY_BOUNDARY.md`

---

## 1. Purpose

This document is the **operational assignment register** for Symphony’s client authentication policy.

It maps each participant/client to:

- current assigned authentication tier
- justification for the assignment
- target tier (upgrade path)
- review date
- approval metadata

This ensures Symphony’s market pragmatism (supporting lower-capability clients) is governed, reviewable, and auditable.

---

## 2. Tier Ordering (Canonical)

The tier ordering is **security-first** and must not be changed without formal architecture review.

- **Tier 1 (highest assurance):** mTLS (client certificate) + revocation enforcement
- **Tier 2 (medium assurance):** API key + signed JWT (short-lived claims)
- **Tier 3 (baseline assurance):** API key + trusted headers (`x-tenant-id`, `x-participant-id`) with strict header/body consistency checks

> **Important:** Tier numbering is intentionally aligned to assurance strength:
> Tier 1 is strongest, Tier 3 is weakest.  
> This ordering is canonical and is checked by CI.

---

## 3. Policy Rules for Assignment

### 3.1 Assignment principles
1. **Default target posture is Tier 1** unless participant capability constraints justify lower tier.
2. Lower tiers are permitted only where:
   - participant technical capability is limited,
   - onboarding timeline would otherwise be blocked,
   - risk is accepted by CTO,
   - compensating controls are documented.
3. Every Tier 2 / Tier 3 assignment must include:
   - explicit justification,
   - target upgrade tier,
   - review date,
   - named approver.

### 3.2 Compensating controls (required for Tier 3)
For Tier 3 clients, all of the following must be documented as applicable:
- IP allowlisting / network restrictions
- API key rotation cadence
- rate limiting / anomaly detection
- tenant/participant header-body consistency enforcement
- per-client monitoring and incident escalation path
- migration plan toward Tier 2 or Tier 1

---

## 4. Assignment Register (Template + Current Entries)

> Replace placeholder rows with actual participants.  
> This file may include participant names because it is an internal controlled document.  
> Do **not** publish externally without redaction if confidentiality applies.

### 4.1 Column definitions
- **participant_code**: Symphony internal participant identifier
- **participant_name**: Legal or operational participant name
- **rail_type**: `BANK`, `MMO`, `PSP`, `MFI`, etc.
- **assigned_tier**: `TIER_1_MTLS`, `TIER_2_JWT`, `TIER_3_APIKEY_HEADERS`
- **justification**: Why this tier is currently assigned
- **compensating_controls**: Summary of controls applied (especially for Tier 2/3)
- **target_tier**: Intended future tier
- **target_date**: Planned upgrade date (or `TBD`)
- **review_date**: Next mandatory review date
- **status**: `ACTIVE`, `MIGRATING`, `EXCEPTION_APPROVED`, `SUSPENDED`
- **approved_by**: Final approver (CTO)
- **compliance_reviewed_by**: Optional/required compliance reviewer
- **notes**: Free-form operational notes

### 4.2 Assignment table

| participant_code | participant_name | rail_type | assigned_tier | justification | compensating_controls | target_tier | target_date | review_date | status | approved_by | compliance_reviewed_by | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `TEMPLATE_BANK_001` | `<Bank Name>` | BANK | `TIER_1_MTLS` | Bank supports client cert lifecycle and mTLS onboarding | Cert issuance, revocation checks, TLS policy enforcement | `TIER_1_MTLS` | N/A | 2026-03-31 | ACTIVE | `<CTO Name>` | `<Compliance Name>` | Template row — replace |
| `TEMPLATE_MMO_001` | `<MMO Name>` | MMO | `TIER_2_JWT` | mTLS not yet operational at participant edge; JWT supported | API key + signed JWT, short expiry, rate limits, IP allowlist | `TIER_1_MTLS` | 2026-06-30 | 2025-12-31 | MIGRATING | `<CTO Name>` | `<Compliance Name>` | Template row — replace |
| `TEMPLATE_MERCHANT_001` | `<Merchant / Aggregator>` | PSP | `TIER_3_APIKEY_HEADERS` | Low technical capability; sandbox onboarding unblock | API key rotation, strict header/body match, monitoring, IP restriction | `TIER_2_JWT` | TBD | 2025-11-30 | EXCEPTION_APPROVED | `<CTO Name>` | `<Compliance Name>` | Template row — replace |

---

## 5. Review and Escalation Rules

### 5.1 Mandatory review cadence
- **Tier 1:** review annually
- **Tier 2:** review every 6 months
- **Tier 3:** review every 90 days (mandatory)

### 5.2 Escalation triggers (must prompt immediate review)
- credential compromise or suspected credential misuse
- repeated auth failures / anomaly alerts
- participant upgrades infrastructure and can support higher tier
- regulator request / audit finding
- material change in rail integration or transaction volume

---

## 6. Evidence and CI Expectations

This document is governance-controlled and must be checked by CI.

CI verifier must confirm:
1. Document exists.
2. Canonical tier ordering is present and correct:
   - Tier 1 = mTLS
   - Tier 2 = signed JWT
   - Tier 3 = API key + headers
3. Assignment table exists with required columns.
4. No row uses non-canonical tier names.
5. Every Tier 2 / Tier 3 row includes non-empty:
   - justification
   - target_tier
   - review_date
   - approved_by
6. File is valid UTF-8 and non-empty.

Evidence artifact target:
- `evidence/phase1/client_auth_tiers_docs.json`

---

## 7. Approval and Change Control

- **Final sign-off authority:** CTO
- **Compliance input:** required for policy interpretation and legal/regulatory alignment
- **Change control:** Any change to tier definitions or ordering requires architecture review and version bump of `CLIENT_AUTH_TIERS.md`
- **Operational row updates:** may occur without policy version bump, but must retain review trace

---

## 8. Notes for BoZ Submission Context

This matrix demonstrates that Symphony:
- deliberately models authentication assurance levels,
- documents accepted limitations,
- applies compensating controls,
- and maintains a governed upgrade path toward stronger identity assurance.

This is evidence of intentional trust-boundary design, not ad hoc market compromise.
## Language Scope
This policy applies to all backend implementation languages in Symphony, including:
- C# (.NET)
- Python
