---
## ADDENDUM: CBAM-Driven Capability Extensions
## Addendum-Status: PLANNING
## Addendum-Authority: TSK-P3-CAP-014
## Addendum-Date: 2026-05-17

This addendum extends the Phase 3 master implementation plan to register the
CBAM-driven capability additions identified through constitutional review of
the CBAM analysis and subsequent phased scope definition.

### New Execution Surface

| Surface | Title | Authority Class | Replay Criticality | State Mutability | Ontology | Determinism | Doctrine Outcome |
|---|---|---|---|---|---|---|---|
| P3-SURF-013 | Uncertainty And Estimation Semantics Surface | authoritative | replay-derived | supersedable-projection | admissibility-projection | deterministic | IMPLEMENT |

This surface is added to the Execution Surface Universe table. It is the
thirteenth Phase 3 surface. All prior surfaces (P3-SURF-000 through
P3-SURF-012) are unchanged.

### New Task Universe Entries

The following nodes are added to the Wave 5 task universe:

#### Wave 5 Additions

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-013 | P3-SURF-013 | planned | IMPLEMENT | Uncertainty representation, operator registry governance, admissibility classification, and authority transfer record production. |

`TSK-P3-SUPPORT-DOC-001` surface coverage is extended from
`P3-SURF-000 through P3-SURF-011` to `P3-SURF-000 through P3-SURF-013`.

### New Wave 5 Serial Sequence

The updated Wave 5 canonical serial sequence is:

1. `TSK-P3-WP-012`
2. `TSK-P3-WP-011`
3. `TSK-P3-WP-013`
4. `TSK-P3-SUPPORT-DOC-001`

### New Support Domain Entry

| Support Domain | DAG Node | Constitutional Justification | Prohibited Expansion |
|---|---|---|---|
| Uncertainty semantics | TSK-P3-WP-013 | Constitutional uncertainty admissibility and replay for all evidence-bearing surfaces | Methodology execution, industrial ontology, external disclosure, dashboard display |

### New Surface-Specific Implementation Plan Registry Entry

| Plan ID | Expected File | Surface | DAG Node | Status |
|---|---|---|---|---|
| TSK-P3-CAP-014 | `TSK-P3-CAP-014_uncertainty_semantics.md` | P3-SURF-013 | TSK-P3-WP-013 | created-planning |

### New Pre-Condition Doctrine Documents

The following three doctrine documents must be created and canonical before
`TSK-P3-WP-013` may enter `CREATE-TASK`. They are constitutional
pre-conditions, not merely dependencies:

1. `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`
2. `docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md`
3. `docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`

### Future-Phase Routing Additions

The following candidates are added to the Future-Phase Routing table:

| Candidate | Outcome |
|---|---|
| Industrial Carbon Ontology | DEFER to Phase 5 |
| Supply Chain Carbon Provenance Graph | DEFER to Phase 5 |
| Embedded Emissions Computation Engine | DEFER to Phase 5 |
| Shipment-Level Replay Model | DEFER to Phase 8D |
| Declarant/Importer Separation Model | DEFER to Phase 8D |
| CBAM Evidence Runtime | DEFER to Phase 8D |
| Enterprise Evidence API with Scoped Evidence Rooms | DEFER to Phase 8D |
| CBAM, ESRS E1, ISSB S2 Disclosure Adapters | DEFER to Phase 8D |
| Green Bond Uncertainty Provenance | DEFER to Phase 8E |