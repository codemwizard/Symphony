# Pilot Scope Declaration
#
# Location: docs/pilots/PILOT_<n>/SCOPE.md
# Required: must be merged before any task in this pilot directory is created.
# Enforced by: scripts/audit/verify_pilot_scope_declarations.sh (INV-144)
# Policy: docs/operations/AGENTIC_SDLC_PILOT_POLICY.md section 7
#
# Instructions:
#   Replace every <PLACEHOLDER> with a real value.
#   Do not leave placeholders. The gate script checks for them.
#   The second_pilot_test_answer MUST name two different sectors, not variations
#   of the same sector.

---
pilot_id: PILOT_<n>
pilot_name: "<Human readable name>"
created_date: "<YYYY-MM-DD>"
owner: "<team or person>"
status: "DRAFT | ACTIVE | CLOSED"

## Methodology adapter

methodology_adapter: "<e.g. PWRM0001 | VM0044 | IRMA_MINING | SOLAR_CBI>"
adapter_phase: "2"
adapter_registration_task: "<TSK-P2-ADAPT-xxx>"

## Neutral host tables this pilot will populate

# List only tables from the canonical neutral host schema.
# If a table is not on this list, the pilot does not touch it.
# If you need a table not on this list, see Architecture Exception Process.
neutral_host_tables:
  - projects
  - methodology_versions
  - monitoring_records
  # Add others as needed from the approved neutral host schema only.
  # Do NOT add sector-specific tables here. They do not exist at Phase 0/1.

## Phase 2 adapter dependencies

# List the adapter components this pilot requires.
# These are all Phase 2 artifacts, not Phase 0/1.
phase2_dependencies:
  - adapter_registrations row for <methodology_adapter>
  - policy_bundle_versions rows for <methodology_adapter>
  - verification_checklist_templates rows for <methodology_adapter>
  - "<other adapter artifacts>"

## Neutrality confirmations

# Both must be true. If either is false, this pilot cannot proceed.
# Raise a Core Design Gap issue instead.
no_new_neutral_tables_confirmed: true   # This pilot adds no new Phase 0/1 tables
no_neutral_tables_altered_confirmed: true  # This pilot modifies no Phase 0/1 tables

## Jurisdiction

jurisdiction_profile: "<e.g. ZM_CARBON_MARKET | ZW_CARBON_MARKET | MZ_CARBON_MARKET>"
jurisdiction_profile_task: "<TSK-P2-JX-xxx>"

## Interpretation packs

# Specify the interpretation pack version active at pilot launch.
# This is recorded for replayability. If the law changes during the pilot,
# a new interpretation pack is published and this field is updated via PR.
interpretation_pack_version: "<interpretation_pack_id>"
interpretation_pack_domain: "<e.g. CARBON_MARKET | TAXONOMY | CLAIMS_SUBSTANTIATION>"
interpretation_confidence: "<CONFIRMED | PRACTICE_ASSUMED | PENDING_CLARIFICATION>"

## Second Pilot Test

# This answer is required. It must explicitly name TWO sectors that are
# completely unrelated to this pilot's sector. It must explain how the
# neutral host tables and Phase 1 functions listed above would work
# identically for those sectors without modification.
#
# A weak answer (e.g. "yes it would work") blocks the pilot.
# A missing answer blocks the pilot.
# Naming two variations of the same sector (e.g. plastic collection and
# plastic recycling) blocks the pilot — they must be genuinely different.
second_pilot_test_answer: >-
  Sector 1: <name a completely different sector from this pilot's sector>
  This pilot uses <list tables>. For a <Sector 1> pilot, the same tables
  would be populated with record_type = '<SECTOR_1_RECORD_TYPE>' and
  methodology_version_id pointing to a <Sector 1 methodology> entry.
  No Phase 0/1 schema change is required.

  Sector 2: <name a second completely different sector>
  Similarly, a <Sector 2> pilot would use the same tables with different
  methodology_version_id and record_type values registered in the adapter.
  The neutral host tables are agnostic to the sector. Only the adapter
  and policy bundle differ.

## Architecture exception record (if applicable)

# If this pilot required a Core Design Gap issue and formal exception approval,
# record it here. Leave blank if no exception was needed.
architecture_exception_id: ""
exception_expiry_date: ""
exception_rollback_plan: ""
