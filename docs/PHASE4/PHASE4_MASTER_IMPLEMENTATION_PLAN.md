# Phase 4 Master Implementation Plan

Status: Prepared, Not Open

## Summary

This plan defines the full Phase 4 task universe without claiming that Phase 4
is already open. Opening work comes first, runtime work follows, and forward
governance closeout leaves Phase 5 in a guarded stub posture.

## Task Universe

| Task ID | Type | Title | Depends On | Notes |
|---|---|---|---|---|
| TSK-P4-CLEAN-001 | cleanup | Phase 4 entry admissibility and Phase 3 carry-forward audit | none | proves whether Phase 4 can be formally opened |
| TSK-P4-ACT-001 | activation | Canonical Phase 4 contract pair | TSK-P4-CLEAN-001 | upgrades the stub contract set |
| TSK-P4-ACT-002 | activation | Phase 4 policy guard | TSK-P4-ACT-001 | codifies AI-free and allowed/prohibited domains |
| TSK-P4-ACT-003 | activation | Phase 4 contract verifier | TSK-P4-ACT-002 | structural and anti-drift verification |
| TSK-P4-ACT-004 | activation | Formal PHASE4-OPENING approval bundle | TSK-P4-ACT-003 | human approval required |
| TSK-P4-ACT-005 | activation | Root envelope switch to Phase 4 | TSK-P4-ACT-004 | separate regulated update after approval |
| TSK-P4-CAP-001 | cap | Settlement finality and rate authority | TSK-P4-ACT-005 | source surface-specific plan |
| TSK-P4-CAP-002 | cap | Statutory allocations and kill criteria | TSK-P4-ACT-005 | source surface-specific plan |
| TSK-P4-WP-001 | runtime | Settlement Finality Engine | TSK-P4-CAP-001 | first runtime work package |
| TSK-P4-WP-002 | runtime | BoZ FX Reference Rate Authority | TSK-P4-WP-001 | deterministic rate binding |
| TSK-P4-WP-003 | runtime | Asset Hard Binding and Currency Legality | TSK-P4-WP-002 | binds assets, rejects illegal currencies |
| TSK-P4-WP-004 | runtime | Statutory Deductions and Allocations | TSK-P4-CAP-002 | OMGE, levy, SOP, and benefit splits |
| TSK-P4-WP-005 | runtime | Statutory Kill Criteria | TSK-P4-WP-004 | automatic halts on invalid settlement conditions |
| TSK-P4-GOV-001 | governance | Phase 5 non-claimable stubs | TSK-P4-WP-005 | mandatory closeout prerequisite |

## Execution Rule

No `TSK-P4-WP-*` task pack is created until `TSK-P4-ACT-005` is complete.

## Closeout Rule

Phase 4 completion is blocked unless `TSK-P4-GOV-001` exists and leaves
`docs/PHASE5/README.md` plus `docs/PHASE5/phase5_contract.yml` in a
non-claimable zero-row state.
