# Phase 4 Execution Surface Map

Status: Prepared, Not Open

| Surface ID | Title | Owner | Allowed Surfaces | Prohibited Semantics | Future Routing |
|---|---|---|---|---|---|
| P4-SURF-001 | Settlement finality | Runtime / DB / Verifier | runtime, database, migration, verifier, evidence | reversible settlement, AI contribution, registry bridge behavior | external submission routes to Phase 8B |
| P4-SURF-002 | BoZ FX authority | Runtime / Policy / Verifier | deterministic interfaces, policy, verifier, evidence | alternate FX sources, inferred rates, AI-supported binding | pricing/adapters route to Phase 5 |
| P4-SURF-003 | Asset-to-settlement hard binding | Runtime / DB / Verifier | runtime, database, migration, verifier, evidence | loose linkage, eventual attachment, UI-only references | operator explanations route to Phase 6 |
| P4-SURF-004 | Currency legality gates | Runtime / Policy / Verifier | runtime, policy, verifier, evidence | unauthorized currency acceptance, heuristic overrides | external payment integration routes later |
| P4-SURF-005 | Statutory deductions and allocations | Runtime / Policy / Verifier | runtime, policy, verifier, evidence | manual calculation, AI-produced allocation, unbound formulas | disclosure/export packaging routes to Phase 8D |
| P4-SURF-006 | Statutory kill criteria | Runtime / Policy / Verifier | runtime, policy, verifier, evidence | advisory-only kills, AI-derived kills, bypassed finality | external notification routes to Phase 8A |
| P4-SURF-007 | Next-phase anti-drift stubs | Governance / Documentation / Verifier | documentation, verifier | missing future-phase stubs at closeout | opening-ready Phase 5 planning |
