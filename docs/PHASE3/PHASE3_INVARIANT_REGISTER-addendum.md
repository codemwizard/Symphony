---
## ADDENDUM: Uncertainty Semantics Invariants
## Addendum-Status: AUTHORITATIVE
## Addendum-Authority: TSK-P3-CAP-014
## Addendum-Date: 2026-05-17

The following invariants are added to the Phase 3 invariant register using
the next available identifiers from the INV-311 through INV-399 reserved
range.

---

### INV-311 — Uncertainty Class Completeness And Non-Default

| Field | Value |
|---|---|
| Constitutional Requirement | Every evidence artifact carrying a measured, estimated, or inferred value declares an explicit uncertainty class; missing declarations produce `U-UNKNOWN-UNCERTAINTY` and are held in draft; `U-UNKNOWN-UNCERTAINTY` is never treated as equivalent to `U-EXACT` |
| Phase Spec Reference | Phase 3 CBAM-driven scope addition; `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` §2 |
| Governing Doctrine | `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| Evidence Path | `evidence/phase3/inv_311_uncertainty_class_completeness.json` |
| Negative Test (unknown-as-exact) | Accept an evidence artifact without an uncertainty class declaration; verify it receives `U-UNKNOWN-UNCERTAINTY`, is held in draft status, and is rejected by any downstream finality gate |
| Negative Test (undeclared class) | Attempt to file an uncertainty record with a class not in the seven declared classes; must fail with SQLSTATE P3011 |
| Proof Limitations | Does not verify substantive correctness of uncertainty values — only that the class is declared and that the non-default rule is enforced at the DB layer |

---

### INV-312 — Authority Transfer Record Completeness

| Field | Value |
|---|---|
| Constitutional Requirement | Every authority transfer involving an uncertainty finding that moves decision rights between Phase 3 surfaces produces a complete `authority_transfer_records` entry citing the declared transfer mode from `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` |
| Phase Spec Reference | Phase 3 CBAM-driven scope addition; `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §2 |
| Governing Doctrine | `docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| Evidence Path | `evidence/phase3/inv_312_authority_transfer_record_completeness.json` |
| Negative Test (missing transfer record) | Trigger an uncertainty finding that routes to `P3-SURF-003`; verify an `authority_transfer_records` entry is produced with mode `AT-EXCLUSIVE` before the legitimacy surface acts |
| Negative Test (undeclared mode) | Attempt to insert an `authority_transfer_records` entry with a mode value not in the four declared modes; must fail with SQLSTATE P3012 |
| Proof Limitations | Verifies structural completeness of transfer records and mode validity; does not independently verify that the correct mode was selected for the question class — that requires a human constitutional review |