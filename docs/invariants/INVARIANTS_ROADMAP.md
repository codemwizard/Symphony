# Invariants Roadmap

These invariants are `roadmap`. They may have partial evidence (e.g., migrations landed) but are not yet verified end-to-end.

_Generated mechanically from `docs/invariants/INVARIANTS_MANIFEST.yml`._

## Structural Linkage Notes

- 2026-05-18 Rule 1 remediation: the Phase 3 structural batch on
  `feat/p3-wave1-lineage=foundations` must carry explicit invariants linkage in
  `docs/invariants/**` rather than relying on exception-file closeout alone.
  The governing linkage set for this batch is `INV-301`, `INV-302`, `INV-303`,
  `INV-304`, `INV-305`, `INV-306`, `INV-307`, `INV-308`, `INV-309`, and
  `INV-310`, which already exist in `docs/invariants/INVARIANTS_MANIFEST.yml`
  with their Phase 3 verifier entrypoints.

| ID | Aliases | Severity | Title | Owners | Verification (manifest) | Evidence links |
|---|---|---|---|---|---|---|
| INV-009 | I-SEC-05 | P1 | SECURITY DEFINER functions must avoid dynamic SQL and user-controlled identifiers | team-platform | TODO: add linter or allowlist-based review; no mechanical check found | [`scripts/db/ci_invariant_gate.sql L87-L91`](../../scripts/db/ci_invariant_gate.sql#L87-L91)<br>[`scripts/db/lint_search_path.sh L2-L6`](../../scripts/db/lint_search_path.sh#L2-L6)<br>[`scripts/db/verify_invariants.sh L32-L36`](../../scripts/db/verify_invariants.sh#L32-L36) |
| INV-039 |  | P1 | Fail-closed under DB exhaustion | team-platform | TODO: define and wire fail-closed verification |  |
| INV-048 | I-ZECHL-01 | P1 | Proxy/Alias resolution required before dispatch | team-platform | scripts/audit/verify_proxy_resolution_invariant.sh |  |
| INV-130 | SEC-001, I-SEC-07 | P0 | Admin bind localhost (supervisor_api) | team-security | scripts/audit/verify_supervisor_bind_localhost.sh |  |
| INV-131 | SEC-002, I-SEC-08 | P0 | Admin auth required (supervisor_api) | team-security | scripts/audit/test_admin_endpoints_require_key.sh |  |
| INV-162 | I-PILOT-EVID-01 | P0 | Evidence class taxonomy is universal — RAW_SOURCE through ISSUANCE_ARTIFACT enforced by CHECK constraint | team-db | scripts/db/verify_evidence_nodes_schema.sh; evidence/phase0/evidence_nodes_class_constraint.json |  |
| INV-163 | I-PILOT-JX-01 | P0 | jurisdiction_code is a required non-nullable field on all regulatory tables | team-db, team-platform | scripts/db/verify_regulatory_schema_neutrality.sh; evidence/phase0/regulatory_schema_neutrality.json |  |
| INV-164 | I-PILOT-LC-01 | P0 | Asset lifecycle states are limited to the minimal neutral set — no sector-prefixed states | team-db | scripts/db/verify_asset_lifecycle_states.sh; evidence/phase0/asset_lifecycle_states.json |  |
| INV-168 | I-PILOT-SCOPE-01 | P0 | Every pilot has a merged SCOPE.md before any pilot task is created | team-platform | scripts/audit/verify_pilot_scope_declarations.sh; evidence/phase0/pilot_scope_declarations.json |  |
| INV-170 | I-GF-UI-FINMEAN-01 | P1 | Financial meaning paired with every metric in supervisory dashboard | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-171 | I-GF-UI-ADDITION-01 | P1 | Additionality explicitly shown as baseline vs actual comparison | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-172 | I-GF-UI-NOGPS-01 | P0 | Raw GPS coordinates never rendered in DOM — neighbourhood labels only | team-platform, team-security | grep-based negative test; evidence/phase1/gf_w1_ui_001.json |  |
| INV-173 | I-GF-UI-BENEFIT-01 | P1 | Benefit-sharing three-way split always visible in monitoring report | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-174 | I-GF-UI-CREDITS-01 | P1 | Carbon credits as unit of account (1 credit = 1 tCO₂) displayed in UI | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-301 | I-P3-REGSOV-01 | P0 | Regulatory Sovereignty Partitioning | team-platform, team-invariants | scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh |  |
| INV-302 | I-P3-DEPGRAPH-01 | P0 | Typed Dependency Graph Completeness | team-db, team-platform | scripts/db/verify_p3_typed_dependency_graph.sh |  |
| INV-303 | I-P3-LEGIT-01 | P0 | Recursive Legitimacy Chain Enforced | team-db, team-platform | scripts/db/verify_p3_recursive_legitimacy_engine.sh |  |
| INV-304 | I-P3-CONTRA-01 | P0 | Contradiction Detection Active | team-db, team-platform | scripts/db/verify_p3_contradiction_detection.sh |  |
| INV-305 | I-P3-XSYS-01 | P0 | Cross-System Evidence Exchange Continuity | team-platform, team-db | scripts/audit/verify_p3_cross_system_evidence_continuity.sh |  |
| INV-306 | I-P3-FAILCOMP-01 | P1 | Failure Composition Machine-Readable | team-platform | scripts/audit/verify_p3_failure_composition_engine.sh |  |
| INV-307 | I-P3-AUTHSCOPE-01 | P0 | Authority Scope Engine Enforced | team-db, team-security | scripts/db/verify_p3_authority_scope_engine.sh |  |
| INV-308 | I-P3-COI-01 | P0 | Conflict-of-Interest DB-Layer Enforced | team-db, team-security | scripts/db/verify_p3_conflict_of_interest_enforcement.sh |  |
| INV-309 | I-P3-DNSH-01 | P0 | Spatial Legality and DNSH Gates Generalised | team-db, team-platform, team-security | scripts/db/verify_p3_spatial_legality_dnsh_gates.sh |  |
| INV-310 | I-P3-DWELL-01 | P1 | Dwell-Time Forensic Enforcement (CF-2 Resolution) | team-security, team-platform | scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh |  |
