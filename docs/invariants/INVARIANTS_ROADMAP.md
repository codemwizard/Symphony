# Invariants Roadmap

These invariants are `roadmap`. They may have partial evidence (e.g., migrations landed) but are not yet verified end-to-end.

_Generated mechanically from `docs/invariants/INVARIANTS_MANIFEST.yml`._

| ID | Aliases | Severity | Title | Owners | Verification (manifest) | Evidence links |
|---|---|---|---|---|---|---|
| INV-009 | I-SEC-05 | P1 | SECURITY DEFINER functions must avoid dynamic SQL and user-controlled identifiers | team-platform | TODO: add linter or allowlist-based review; no mechanical check found | [`scripts/db/ci_invariant_gate.sql L87-L91`](../../scripts/db/ci_invariant_gate.sql#L87-L91)<br>[`scripts/db/lint_search_path.sh L2-L6`](../../scripts/db/lint_search_path.sh#L2-L6)<br>[`scripts/db/verify_invariants.sh L32-L36`](../../scripts/db/verify_invariants.sh#L32-L36) |
| INV-039 |  | P1 | Fail-closed under DB exhaustion | team-platform | TODO: define and wire fail-closed verification |  |
| INV-048 | I-ZECHL-01 | P1 | Proxy/Alias resolution required before dispatch | team-platform | scripts/audit/verify_proxy_resolution_invariant.sh |  |
| INV-130 | SEC-001, I-SEC-07 | P0 | Admin bind localhost (supervisor_api) | team-security | scripts/audit/verify_supervisor_bind_localhost.sh |  |
| INV-131 | SEC-002, I-SEC-08 | P0 | Admin auth required (supervisor_api) | team-security | scripts/audit/test_admin_endpoints_require_key.sh |  |
| INV-132 | SEC-003, I-SEC-09 | P0 | Fail-closed on missing secrets (signing keys) | team-security | scripts/security/scan_secrets.sh |  |
| INV-133 | SEC-004, I-SEC-10 | P0 | Tenant allowlist default-deny | team-security | scripts/audit/test_tenant_allowlist_deny_all.sh |  |
| INV-159 | I-PILOT-NEUTRAL-01 | P0 | Phase 0/1 schema contains no sector or methodology nouns (platform neutrality) | team-platform, team-db | scripts/audit/verify_core_contract_gate.sh --check neutrality; evidence/phase0/core_contract_gate_neutrality.json |  |
| INV-160 | I-PILOT-ADAPT-01 | P0 | All pilot methodology logic is registered as a Phase 2 adapter, not embedded in Phase 0/1 | team-platform | scripts/audit/verify_core_contract_gate.sh --check adapter-boundary; evidence/phase0/core_contract_gate_adapter_boundary.json |  |
| INV-161 | I-PILOT-VERB-01 | P0 | Phase 0/1 functions use generic platform verbs only — no sector-encoded function names | team-db, team-platform | scripts/audit/verify_core_contract_gate.sh --check function-names; evidence/phase0/core_contract_gate_function_names.json |  |
| INV-162 | I-PILOT-EVID-01 | P0 | Evidence class taxonomy is universal — RAW_SOURCE through ISSUANCE_ARTIFACT enforced by CHECK constraint | team-db | scripts/db/verify_evidence_nodes_schema.sh; evidence/phase0/evidence_nodes_class_constraint.json |  |
| INV-163 | I-PILOT-JX-01 | P0 | jurisdiction_code is a required non-nullable field on all regulatory tables | team-db, team-platform | scripts/db/verify_regulatory_schema_neutrality.sh; evidence/phase0/regulatory_schema_neutrality.json |  |
| INV-164 | I-PILOT-LC-01 | P0 | Asset lifecycle states are limited to the minimal neutral set — no sector-prefixed states | team-db | scripts/db/verify_asset_lifecycle_states.sh; evidence/phase0/asset_lifecycle_states.json |  |
| INV-165 | I-PILOT-REPLAY-01 | P0 | Every decision record references an interpretation_version_id for replayability | team-db, team-platform | scripts/db/verify_interpretation_versioning.sh; evidence/phase0/interpretation_versioning.json |  |
| INV-166 | I-PILOT-PAYLOAD-01 | P0 | Core functions do not interpret sector-specific payload field names | team-db, team-platform | scripts/audit/verify_core_contract_gate.sh --check payload-neutrality; evidence/phase0/core_contract_gate_payload_neutrality.json |  |
| INV-167 | I-PILOT-INTERP-01 | P0 | Interpretation packs have a single active record per domain per jurisdiction per authority level | team-platform | scripts/db/verify_interpretation_pack_uniqueness.sh; evidence/phase0/interpretation_pack_uniqueness.json |  |
| INV-168 | I-PILOT-SCOPE-01 | P0 | Every pilot has a merged SCOPE.md before any pilot task is created | team-platform | scripts/audit/verify_pilot_scope_declarations.sh; evidence/phase0/pilot_scope_declarations.json |  |
| INV-169 | I-GF-REG26-01 | P0 | Regulation 26 separation of duties: validator cannot verify the same project — DB-enforced | team-db, team-platform, team-security | scripts/db/verify_gf_sch_008.sh; evidence/phase0/gf_sch_008.json |  |
| INV-170 | I-GF-UI-FINMEAN-01 | P1 | Financial meaning paired with every metric in supervisory dashboard | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-171 | I-GF-UI-ADDITION-01 | P1 | Additionality explicitly shown as baseline vs actual comparison | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-172 | I-GF-UI-NOGPS-01 | P0 | Raw GPS coordinates never rendered in DOM — neighbourhood labels only | team-platform, team-security | grep-based negative test; evidence/phase1/gf_w1_ui_001.json |  |
| INV-173 | I-GF-UI-BENEFIT-01 | P1 | Benefit-sharing three-way split always visible in monitoring report | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
| INV-174 | I-GF-UI-CREDITS-01 | P1 | Carbon credits as unit of account (1 credit = 1 tCO₂) displayed in UI | team-platform, team-ui | scripts/dev/verify_ui_e2e.sh; evidence/phase1/gf_w1_ui_001.json |  |
