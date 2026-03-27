# Neutral Host Invariant Register Entries
# Append these entries to docs/invariants/INVARIANTS_MANIFEST.yml
# Next available ID at time of writing: INV-135
# All entries follow the invariant-centric Phase-1 schema.
#
# IMPORTANT: Implementation status is explicitly declared below.
# "status: roadmap" means the verifier script does not yet exist.
#   The entry is a PROMISE, not an enforced control.
# "status: implemented" means the verifier exists, runs in CI, and
#   produces evidence. Only those entries are actual enforcement.
#
# Do not read roadmap entries as active controls. They are not.
# Do not mark an entry "implemented" until the verifier script exists,
# passes against the current codebase, and is wired into CI.
#
# ─────────────────────────────────────────────────────────────────
# SECTION A — IMPLEMENTED (verifier exists, CI-wired, evidence emitted)
# ─────────────────────────────────────────────────────────────────
# None yet. INV-135 through INV-144 are all roadmap status.
# They become implemented as their verifier scripts are built and
# integrated per the CI gate hardening workstream.
#
# ─────────────────────────────────────────────────────────────────
# SECTION B — ROADMAP (declared, verifier pending, NOT enforced yet)
# ─────────────────────────────────────────────────────────────────

- id: INV-135
  aliases: ["I-PILOT-NEUTRAL-01"]
  status: roadmap
  severity: P0
  title: "Phase 0/1 schema contains no sector or methodology nouns (platform neutrality)"
  owners: ["team-platform", "team-db"]
  sla_days: 7
  enforcement: "scripts/audit/verify_core_contract_gate.sh"
  verification: >-
    scripts/audit/verify_core_contract_gate.sh --check neutrality;
    evidence/phase0/core_contract_gate_neutrality.json
  notes: >-
    Enforces Rule 1. Scans all Phase 0/1 migration files for table and column
    names containing prohibited sector nouns (solar_*, plastic_*, forestry_*,
    agriculture_*, mining_*, pwrm_*, collection_*, recycling_*, and equivalents).
    Fails closed if any match is found. Also scans function signatures and
    enum definitions.

- id: INV-136
  aliases: ["I-PILOT-ADAPT-01"]
  status: roadmap
  severity: P0
  title: "All pilot methodology logic is registered as a Phase 2 adapter, not embedded in Phase 0/1"
  owners: ["team-platform"]
  sla_days: 7
  enforcement: "scripts/audit/verify_core_contract_gate.sh"
  verification: >-
    scripts/audit/verify_core_contract_gate.sh --check adapter-boundary;
    evidence/phase0/core_contract_gate_adapter_boundary.json
  notes: >-
    Enforces Rules 2 and 9. Verifies that no Phase 0/1 migration file contains
    a CREATE TABLE whose name encodes a methodology or sector noun. Verifies
    that no Phase 0/1 function body contains a direct reference to a
    methodology-specific payload field by name. Adapters are registered in
    adapter_registrations at Phase 2 and referenced by methodology_version_id.

- id: INV-137
  aliases: ["I-PILOT-VERB-01"]
  status: roadmap
  severity: P0
  title: "Phase 0/1 functions use generic platform verbs only — no sector-encoded function names"
  owners: ["team-db", "team-platform"]
  sla_days: 7
  enforcement: "scripts/audit/verify_core_contract_gate.sh"
  verification: >-
    scripts/audit/verify_core_contract_gate.sh --check function-names;
    evidence/phase0/core_contract_gate_function_names.json
  notes: >-
    Enforces Rule 3. Scans Phase 0/1 migration files for CREATE FUNCTION
    statements whose names encode a sector or methodology. Prohibited patterns:
    record_solar_*, issue_plastic_*, record_collection_*, issue_pwrm_*, and
    equivalents. Allowed: register_project, record_monitoring_record,
    attach_evidence, open_verification_case, run_methodology_calculation,
    issue_asset_batch, retire_asset_batch, record_authority_decision,
    attempt_lifecycle_transition.

- id: INV-138
  aliases: ["I-PILOT-EVID-01"]
  status: roadmap
  severity: P0
  title: "Evidence class taxonomy is universal — RAW_SOURCE through ISSUANCE_ARTIFACT enforced by CHECK constraint"
  owners: ["team-db"]
  sla_days: 7
  enforcement: "scripts/db/verify_evidence_nodes_schema.sh"
  verification: >-
    scripts/db/verify_evidence_nodes_schema.sh;
    evidence/phase0/evidence_nodes_class_constraint.json
  notes: >-
    Enforces Rule 5. Verifies that evidence_nodes.evidence_class has a CHECK
    constraint restricting values to exactly: RAW_SOURCE, ATTESTED_SOURCE,
    NORMALIZED_RECORD, ANALYST_FINDING, VERIFIER_FINDING, REGULATORY_EXPORT,
    ISSUANCE_ARTIFACT. No sector-specific class values are permitted. The
    constraint must exist at the DB layer, not only in application code.

- id: INV-139
  aliases: ["I-PILOT-JX-01"]
  status: roadmap
  severity: P0
  title: "jurisdiction_code is a required non-nullable field on all regulatory tables"
  owners: ["team-db", "team-platform"]
  sla_days: 7
  enforcement: "scripts/db/verify_regulatory_schema_neutrality.sh"
  verification: >-
    scripts/db/verify_regulatory_schema_neutrality.sh;
    evidence/phase0/regulatory_schema_neutrality.json
  notes: >-
    Enforces Rule 6. Verifies that regulatory_authorities, regulatory_checkpoints,
    jurisdiction_profiles, lifecycle_checkpoint_rules, and interpretation_packs
    all have jurisdiction_code as NOT NULL. No regulatory record may exist without
    explicit jurisdiction binding. The engine reads profile data; it does not
    encode country-specific behaviour in function bodies.

- id: INV-140
  aliases: ["I-PILOT-LC-01"]
  status: roadmap
  severity: P0
  title: "Asset lifecycle states are limited to the minimal neutral set — no sector-prefixed states"
  owners: ["team-db"]
  sla_days: 7
  enforcement: "scripts/db/verify_asset_lifecycle_states.sh"
  verification: >-
    scripts/db/verify_asset_lifecycle_states.sh;
    evidence/phase0/asset_lifecycle_states.json
  notes: >-
    Enforces Rule 7. Verifies that asset_batches.status CHECK constraint
    allows exactly and only: DRAFT, ACTIVE, ISSUED, RETIRED, CANCELLED.
    No state containing a sector prefix (SOLAR_*, PLASTIC_*, FORESTRY_*)
    is permitted at the platform layer. Partial retirement is expressed
    through retirement_events.retired_quantity, not through a PARTIALLY_RETIRED
    state. Staged approvals are expressed through checkpoint configuration.

- id: INV-141
  aliases: ["I-PILOT-REPLAY-01"]
  status: roadmap
  severity: P0
  title: "Every decision record references an interpretation_version_id for replayability"
  owners: ["team-db", "team-platform"]
  sla_days: 7
  enforcement: "scripts/db/verify_interpretation_versioning.sh"
  verification: >-
    scripts/db/verify_interpretation_versioning.sh;
    evidence/phase0/interpretation_versioning.json
  notes: >-
    Enforces Check 4 (Replayability). Verifies that authority_decision_records,
    lifecycle_checkpoint_evaluations, and any table recording a regulatory
    or workflow decision has interpretation_version_id as NOT NULL FK to
    interpretation_packs. Append-only trigger must block UPDATE/DELETE.
    Without this, decisions cannot be replayed under a later interpretation
    version, destroying audit traceability.

- id: INV-142
  aliases: ["I-PILOT-PAYLOAD-01"]
  status: roadmap
  severity: P0
  title: "Core functions do not interpret sector-specific payload field names"
  owners: ["team-db", "team-platform"]
  sla_days: 7
  enforcement: "scripts/audit/verify_core_contract_gate.sh"
  verification: >-
    scripts/audit/verify_core_contract_gate.sh --check payload-neutrality;
    evidence/phase0/core_contract_gate_payload_neutrality.json
  notes: >-
    Enforces Rule 10. Scans Phase 0/1 migration files and Phase 1 service
    source for references to sector-specific field names extracted from JSON
    payloads by name (e.g. ->>'capacity_kw', ->>'contamination_rate_pct',
    ->>'panel_serial'). Core may only validate that record_payload_json is
    a JSON object and that it matches a registered schema_reference_id.
    All field interpretation belongs to the adapter layer.

- id: INV-143
  aliases: ["I-PILOT-INTERP-01"]
  status: roadmap
  severity: P0
  title: "Interpretation packs have a single active record per domain per jurisdiction per authority level"
  owners: ["team-platform"]
  sla_days: 7
  enforcement: "scripts/db/verify_interpretation_pack_uniqueness.sh"
  verification: >-
    scripts/db/verify_interpretation_pack_uniqueness.sh;
    evidence/phase0/interpretation_pack_uniqueness.json
  notes: >-
    Enforces the interpretation hierarchy resolution rule. A partial unique index
    must exist on interpretation_packs (domain, jurisdiction_code, authority_level)
    WHERE effective_to IS NULL. Resolution order when multiple authority levels
    exist for the same domain and jurisdiction: SOVEREIGN > REGULATORY > INTERNAL
    > DEFAULT. Without this constraint, replayability is ambiguous because two
    packs from the same period could yield different results with no canonical
    ordering.

- id: INV-144
  aliases: ["I-PILOT-SCOPE-01"]
  status: roadmap
  severity: P0
  title: "Every pilot has a merged SCOPE.md before any pilot task is created"
  owners: ["team-platform"]
  sla_days: 7
  enforcement: "scripts/audit/verify_pilot_scope_declarations.sh"
  verification: >-
    scripts/audit/verify_pilot_scope_declarations.sh;
    evidence/phase0/pilot_scope_declarations.json
  notes: >-
    Enforces the Pilot Scope Declaration requirement from
    AGENTIC_SDLC_PILOT_POLICY.md section 7. Verifies that for every directory
    matching docs/pilots/PILOT_*/,  a SCOPE.md file exists and contains all
    required fields: methodology_adapter, neutral_host_tables, phase2_dependencies,
    no_new_neutral_tables_confirmed, no_neutral_tables_altered_confirmed,
    jurisdiction_profile, interpretation_pack_version, second_pilot_test_answer.
    The second_pilot_test_answer field must name exactly two unrelated sectors.
    Missing or incomplete SCOPE.md blocks all tasks in that pilot directory.

- id: INV-145
  aliases: ["I-GF-REG26-01"]
  status: roadmap
  severity: P0
  title: "Regulation 26 separation of duties: validator cannot verify the same project — DB-enforced"
  owners: ["team-db", "team-platform", "team-security"]
  sla_days: 7
  enforcement: "scripts/db/verify_gf_sch_008.sh"
  verification: >-
    scripts/db/verify_gf_sch_008.sh;
    evidence/phase0/gf_sch_008.json
  notes: >-
    Enforces S.I. No. 5 of 2026 Regulation 26 at the DB layer.
    check_reg26_separation(p_verifier_id, p_project_id, p_requested_role)
    raises SQLSTATE GF001 if a verifier who validated a project attempts
    to verify the same project. This function is called by
    issue_verifier_read_token before any token is issued.
    Application-layer enforcement alone is not acceptable — this constraint
    must exist in the DB function and be proven by negative test
    GF-W1-SCH-008-N1.
