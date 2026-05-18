---
## ADDENDUM: CBAM-Driven Capability Boundary Extensions
## Addendum-Status: AUTHORITATIVE
## Addendum-Authority: TSK-P3-CAP-014
## Addendum-Date: 2026-05-17

### New Authorized Capability Domain

The following domain is added to the Authorized Capability Domains list as
item 12:

> **12. Uncertainty And Estimation Semantics**
> Representation, admissibility classification, operator registry governance,
> and replay-visible uncertainty finding production for all evidence-bearing
> surfaces within Phase 3.

### Capability-to-Doctrine Matrix Addition

| Capability Domain | Status | Governing Doctrine | Tasks May Define | Tasks Must Not Define | Blocker Status |
|---|---|---|---|---|---|
| Uncertainty And Estimation Semantics | Authorized | `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`; `UNCERTAINTY_OPERATOR_REGISTRY.md`; `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | uncertainty class schemas, operator registry references, admissibility gates, authority transfer records, replay structures | methodology execution formulas, industrial emissions ontology, new uncertainty classes beyond the seven declared classes, new operators beyond the registered set | Unblocked when all three governing doctrine documents are canonical |

### Prohibited Capability Routing Additions

The following capabilities are added to the Prohibited Capability Routing
table:

| Prohibited Capability | Correct Phase |
|---|---|
| Industrial Carbon Ontology | Phase 5 |
| Supply Chain Carbon Provenance Graph | Phase 5 |
| Embedded Emissions Computation | Phase 5 |
| Shipment-Level Replay Model | Phase 8D |
| Declarant/Importer Separation Model | Phase 8D |
| CBAM Evidence Runtime | Phase 8D |
| Enterprise Evidence API | Phase 8D |
| CBAM, ESRS E1, ISSB S2 Disclosure Adapters | Phase 8D |
| Green Bond Uncertainty Provenance | Phase 8E |

### Required Doctrine Inventory Additions

| Doctrine | Status | Required For |
|---|---|---|
| `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` | Required | uncertainty class definitions, admissibility rules, replay obligations |
| `UNCERTAINTY_OPERATOR_REGISTRY.md` | Required | operator definitions and version governance |
| `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | Required | authority transfer mode declarations for all surfaces involving uncertainty finding handoffs |

### New Prohibited Misinterpretation

**PM-CB-05 — Uncertainty Engine as CBAM Runtime:**
Phase 3's uncertainty engine is constitutional substrate for evidence
admissibility. It is not a CBAM compliance runtime. CBAM evidence packaging,
embedded emissions calculations, and declarant/importer separation are Phase
8D capabilities constitutionally prohibited in Phase 3.

**PM-CB-06 — Unknown Uncertainty as Admissible:**
It is constitutionally prohibited to treat `U-UNKNOWN-UNCERTAINTY` as an
admissible state equivalent to `U-EXACT`. Any implementation, adapter, or
phase that defaults missing uncertainty declarations to exact precision is
constitutionally non-compliant with
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`.