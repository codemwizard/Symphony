# PLAN: GF-W1-GOV-005A

[ID GF-W1-GOV-005A]

## Mandatory Pre-Task Reads (AGENT_GUARDRAILS_GREEN_FINANCE compliance)

Files read before implementation:
- docs/operations/AGENTIC_SDLC_PILOT_POLICY.md
- docs/operations/PILOT_REJECTION_PLAYBOOK.md
- docs/operations/AI_AGENT_OPERATION_MANUAL.md
- docs/operations/AGENT_GUARDRAILS_GREEN_FINANCE.md

## Pre-Implementation Neutrality Checklist

- [x] Five mandatory documents read above.
- [x] meta.yml contains second_pilot_test with two unrelated sectors (PWRM0001, VM0044).
- [x] No table created or modified — CI wiring only.
- [x] No function created or modified — CI wiring only.
- [x] No payload field referenced in core validation logic.
- [x] jurisdiction_code constraint: not applicable — no new tables.
- [x] No new lifecycle state introduced.
- [x] verify_core_contract_gate.sh --fixtures to be run before implementation is marked complete.

## Objective

[ID GF-W1-GOV-005A-WI01] [ID GF-W1-GOV-005A-WI02] [ID GF-W1-GOV-005A-WI03] [ID GF-W1-GOV-005A-WI04]

Create a fail-closed static verifier (`scripts/audit/verify_gf_w1_gov_005a.sh`) that
confirms all 9 GF Phase 0 schema migration files are present, contain no forward FK
references, and contain no sector-specific table names before Wave 5 Phase 1 functions
are permitted to begin. No database connection required.

## Migration Files Under Inspection

| Migration | Table(s) | Expected path |
|---|---|---|
| 0080 | adapter_registrations | schema/migrations/0080_gf_adapter_registrations.sql |
| 0097 | projects | schema/migrations/0097_gf_projects.sql |
| 0098 | methodology_versions | schema/migrations/0098_gf_methodology_versions.sql |
| 0099 | monitoring_records | schema/migrations/0099_gf_monitoring_records.sql |
| 0100 | evidence_nodes, evidence_edges | schema/migrations/0100_gf_evidence_lineage.sql |
| 0101 | asset_batches, asset_lifecycle_events, retirement_events | schema/migrations/0101_gf_asset_lifecycle.sql |
| 0102 | regulatory_authorities, regulatory_checkpoints | schema/migrations/0102_gf_regulatory_plane.sql |
| 0103 | jurisdiction_profiles, lifecycle_checkpoint_rules | schema/migrations/0103_gf_jurisdiction_rules.sql |
| 0106 | verifier_registry, verifier_project_assignments | schema/migrations/0106_gf_verifier_registry.sql |

## Execution Details

[ID GF-W1-GOV-005A-WI01] Verify file presence: for each of the 9 migration SQL files
listed above, confirm the file exists at the declared path. Fail on first absence.

[ID GF-W1-GOV-005A-WI02] Check FK reference order: for each GF migration file, extract
lines matching `REFERENCES <table>` and confirm the referenced table is defined (via
`CREATE TABLE`) in the same or an earlier-numbered migration file. Fail on any forward
reference.

[ID GF-W1-GOV-005A-WI03] Check sector-noun absence: grep all 9 migration files for
the patterns: `plastic_`, `solar_`, `pwrm_`, `forest_`, `mining_`, `agriculture_`,
`collection_credit`, `recycling_`. Fail if any match is found.

[ID GF-W1-GOV-005A-WI04] Emit `evidence/phase1/gf_w1_gov_005a.json` containing
task_id, git_sha, timestamp_utc, status (PASS/FAIL), observed_paths, observed_hashes,
command_outputs, execution_trace, migrations_present count, forward_fk_violations list,
sector_noun_violations list.

## Constraints

- No migration SQL produced — CI wiring only.
- Static file analysis only — no DATABASE_URL required.
- Must not modify any existing GF migration files.
- Script must be placed at `scripts/audit/verify_gf_w1_gov_005a.sh` and be executable.

## Verification Commands

```bash
bash scripts/audit/verify_gf_w1_gov_005a.sh
test -f evidence/phase1/gf_w1_gov_005a.json
grep -q '"status": "PASS"' evidence/phase1/gf_w1_gov_005a.json
```

## Negative Test

[ID GF-W1-GOV-005A-N1] Temporarily rename one migration file; verifier must exit 1 naming it.
[ID GF-W1-GOV-005A-N2] Add a test line `REFERENCES plastic_batches` to a temp copy; verifier must exit 1.

## Evidence Path

`evidence/phase1/gf_w1_gov_005a.json`
