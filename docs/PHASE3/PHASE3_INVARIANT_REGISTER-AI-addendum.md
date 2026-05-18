---
## ADDENDUM: AI Governance Invariant
## Addendum-Status: AUTHORITATIVE
## Addendum-Authority: TSK-P3-CAP-015
## Addendum-Date: 2026-05-17
## Addendum-Sequence: 2 (follows uncertainty semantics invariant addendum)

The following invariant is added to the Phase 3 invariant register using
the next available identifier from the INV-311 through INV-399 reserved
range.

---

### INV-313 — AI Output Admissibility Gate

| Field | Value |
|---|---|
| Constitutional Requirement | Every AI-generated value entering Symphony's evidence corpus carries a registered model ID, a registered model version, an inference log record, and a Phase 3 uncertainty class assigned via a registered confidence-to-uncertainty mapping; no AI output may directly contribute to finality, authorization, or registry submission surfaces |
| Phase Spec Reference | Phase 3 AI governance addition; `AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md` §4, §5, §8 |
| Governing Doctrine | `docs/constitutional/AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md` |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_ai_output_admissibility.sh` |
| Evidence Path | `evidence/phase3/inv_313_ai_output_admissibility.json` |
| Negative Test (unregistered model) | Submit an evidence record citing a model_id not present in the Model Registry; must fail with SQLSTATE P3013 |
| Negative Test (missing inference log) | Submit an uncertainty_measurements record with an AI provenance marker but no corresponding inference_log record; must fail with SQLSTATE P3014 |
| Negative Test (raw confidence bypass) | Attempt to insert a raw model confidence score directly into an evidence record without uncertainty class conversion; must fail with SQLSTATE P3015 |
| Negative Test (finality surface contamination) | Attempt to route an AI-flagged uncertainty finding directly to a Phase 4 statutory calculation without human review admission; must be blocked |
| Proof Limitations | Verifies structural admissibility gate enforcement at DB layer; does not independently verify the substantive quality of model outputs or the correctness of confidence-to-uncertainty mappings — those require human expert review during model certification |