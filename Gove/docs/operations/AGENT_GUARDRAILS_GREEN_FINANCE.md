# Agent Guardrails — Green Finance Domain
# Addendum to AGENTS.md and AI_AGENT_OPERATION_MANUAL.md
#
# Location: docs/operations/AGENT_GUARDRAILS_GREEN_FINANCE.md
# Status: Canonical
# Owner: Architecture / Platform
# Apex authority: docs/operations/AI_AGENT_OPERATION_MANUAL.md
#
# This document defines additional hard constraints for any AI agent
# operating on tasks tagged: phase: green, pilot: true, or
# domain: green_finance in their meta.yml.
#
# These constraints are ADDITIVE to AGENTS.md. They do not replace it.
# Both apply simultaneously. When they conflict, the stricter rule wins.

---

## Why this document exists

Symphony's existing agent guardrails are designed for the payment domain.
They are strong on DB security, migration discipline, and evidence integrity.
They do not cover the specific failure modes that arise when AI agents
work on a platform designed to be domain-neutral while pilots create
constant pressure toward domain specialisation.

AI agents are particularly susceptible to the pilot contamination pattern
because: they optimise for task completion; they will find the shortest
path to a passing test; and that shortest path almost always involves
adding a column, table, or validation rule that encodes sector logic
in the platform layer. This document exists to block that path before
the agent takes it.

---

## 1) Mandatory pre-task reads

Before accepting any green finance task, an agent MUST read these files
in order. Reading means loading the full content, not skimming headers.

1. docs/operations/AGENTIC_SDLC_PILOT_POLICY.md  (the ten rules)
2. docs/operations/PILOT_REJECTION_PLAYBOOK.md    (violation patterns)
3. docs/operations/AI_AGENT_OPERATION_MANUAL.md   (apex authority)
4. docs/invariants/INVARIANTS_MANIFEST.yml         (INV-135 through INV-144)
5. The pilot's SCOPE.md at docs/pilots/PILOT_<n>/SCOPE.md if it exists

An agent that has not read these files is not authorised to begin
implementation. The task PLAN.md must record that these files were read,
with the git SHA of each file at time of reading.

---

## 2) The pre-implementation neutrality checklist

Before writing a single line of implementation (migration SQL, function
body, schema change, or service code), the agent must complete this
checklist and record it in the task PLAN.md.

[ ] I have read the five mandatory documents above.
[ ] The task meta.yml contains second_pilot_test with a non-empty answer
    naming two unrelated sectors.
[ ] No table I am creating or modifying contains a sector noun.
    (I checked: solar_, plastic_, forestry_, agriculture_, mining_, pwrm_,
    collection_, recycling_, and equivalents are absent from all new names.)
[ ] No function I am creating contains a sector or methodology noun.
    (I checked: record_solar_*, issue_plastic_*, record_collection_*,
    issue_pwrm_*, and equivalents are absent from all new function names.)
[ ] No payload field is referenced by name in any core validation logic.
    (I checked: capacity_kw, contamination_rate_pct, panel_serial,
    net_weight_kg, biomass_baseline, and equivalents do not appear
    in any -> or ->> extraction in core functions.)
[ ] jurisdiction_code is NOT NULL on every regulatory table I am creating.
[ ] Every decision record I am creating has interpretation_version_id
    as a NOT NULL FK.
[ ] No new lifecycle state contains a sector prefix.
[ ] I have run: scripts/audit/verify_core_contract_gate.sh --fixtures
    and it passed before I began implementation.

If any checkbox cannot be checked, the agent must STOP and raise a
Core Design Gap issue before proceeding. The agent does not proceed
with a partial implementation pending resolution.

---

## 3) Hard stop conditions (green finance specific)

An agent MUST stop immediately and escalate to a human supervisor
when any of the following occur. These are in addition to the stop
conditions in AI_AGENT_OPERATION_MANUAL.md.

### 3.1 Schema stop conditions

STOP if the agent is about to write a CREATE TABLE whose name contains
any of: solar_, plastic_, forestry_, agriculture_, mining_, pwrm_,
collection_, recycling_, energy_project, forest_carbon, mine_site,
water_efficiency, tourism_, fleet_registry, recycling_facility,
virgin_polymer, or any other term that identifies a sector or methodology.

STOP if the agent is about to write an ALTER TABLE ADD COLUMN on any
Phase 0/1 neutral host table where the column name identifies a sector
measurement (capacity, weight, contamination, biomass, serial, emission,
catch, fleet, or similar domain-specific nouns).

STOP if the agent is about to write a CREATE INDEX on a neutral host
table where the index is designed to serve a single pilot's query pattern.

### 3.2 Function stop conditions

STOP if the agent is about to write a CREATE FUNCTION whose name begins
with: record_solar, issue_plastic, record_collection, issue_collection,
issue_pwrm, record_forestry, issue_forestry, record_mining, record_recycling,
issue_recycling, record_agriculture, issue_agriculture, record_water,
issue_water, or any equivalent sector-encoded prefix.

STOP if the agent is about to write logic inside a Phase 1 core function
that reads a payload field by name using -> or ->>.

STOP if the agent is about to write an IF or CASE branch inside a Phase 1
core function that tests jurisdiction_code against a hardcoded country value.

### 3.3 Lifecycle stop conditions

STOP if the agent is about to add a CHECK constraint that includes any
value matching: *_VERIFIED, *_PENDING, *_ISSUED, *_APPROVED, *_FAILED
where the prefix identifies a sector.

STOP if the agent is about to add a lifecycle state that is not in the
approved minimal set: DRAFT, ACTIVE, ISSUED, RETIRED, CANCELLED.

### 3.4 Pilot scope stop conditions

STOP if a task in a pilot directory (docs/pilots/PILOT_<n>/) references
a table that does not exist in the canonical Phase 0 neutral host schema.

STOP if docs/pilots/PILOT_<n>/SCOPE.md does not exist before any task
in that pilot directory begins implementation.

STOP if the SCOPE.md second_pilot_test_answer field is empty, less than
100 characters, or names only one sector.

---

## 4) What agents must NOT infer or assume

AI agents have a strong tendency to be "helpful" by inferring unstated
requirements and adding what seems obviously needed. In the green finance
domain, this is dangerous. The following are explicit prohibitions on
agent inference.

**Do not infer that a pilot needs a dedicated table.**
Even if a pilot's domain clearly involves collection events, solar
installations, or forestry plots, the agent must not infer that a
dedicated table is required. The neutral host tables handle all sectors.
The adapter handles the specialisation.

**Do not infer that a slow query needs a new index.**
If a query is slow during development, the agent must not automatically
add an index. The agent must raise this as a performance observation
in the EXEC_LOG.md and escalate for architecture review.

**Do not infer that a methodology-specific check belongs in core.**
If a methodology document says "contamination rate must be below 15%",
the agent must not add that check to a core DB function. It goes in
the adapter's JSON schema for payload validation.

**Do not infer jurisdiction-specific rules from regulatory documents.**
If the agent reads S.I. No. 5 of 2026 and concludes that a Letter of
No Objection is required before issuance in Zambia, the agent must not
hardcode that rule in a Phase 1 function. It goes in a jurisdiction
profile data row and a lifecycle_checkpoint_rules row.

**Do not infer that a missing SCOPE.md means the pilot has not started.**
A missing SCOPE.md means the pilot CANNOT start. The agent must stop
and flag the missing document, not proceed on the assumption that the
scope is obvious.

---

## 5) Evidence requirements (green finance specific)

Every green finance task produces evidence in addition to the standard
Symphony evidence requirements.

The task's evidence output at `evidence/phase0/<task_id>.json` or
`evidence/phase1/<task_id>.json` MUST include a `neutrality_verification`
block:

```json
{
  "check_id": "<task_id>_neutrality",
  "timestamp_utc": "...",
  "git_sha": "...",
  "status": "PASS",
  "neutrality_verification": {
    "core_contract_gate_run": true,
    "core_contract_gate_result": "PASS",
    "core_contract_gate_evidence": "evidence/phase0/core_contract_gate.json",
    "second_pilot_test_present": true,
    "second_pilot_test_sectors_named": ["<sector 1>", "<sector 2>"],
    "no_sector_nouns_in_schema": true,
    "no_payload_fields_in_core": true,
    "no_jurisdiction_code_in_function_body": true,
    "interpretation_version_id_present_on_decisions": true
  }
}
```

A task without this block in its evidence is treated as incomplete
regardless of whether the core work appears correct.

---

## 6) Task meta.yml additional required fields

Any task tagged `phase: green` or containing a `pilot` key in meta.yml
MUST include these additional fields beyond the standard schema:

```yaml
# Standard fields (already required by verify_task_meta_schema.sh)
schema_version: 1
phase: '0'   # or '1', '2', etc.
task_id: TSK-P0-GF-<n>
...

# Additional required fields for green finance tasks
green_finance: true
second_pilot_test: >-
  Sector 1: <name sector>.
  Sector 2: <name different sector>.
  Both would use the same Phase 0/1 tables and functions because
  <specific explanation of neutrality>.
pilot_scope_declaration: docs/pilots/PILOT_<n>/SCOPE.md
core_contract_gate_required: true
touches_neutral_host: true | false
touches_adapter_layer: true | false
touches_jurisdiction_profile: true | false
touches_interpretation_packs: true | false
```

The `verify_task_meta_schema.sh` script must be extended to enforce
these fields for tasks where `green_finance: true`.

If `touches_neutral_host: true` and `phase` is `0` or `1`:
- `core_contract_gate_required` must be `true`
- `second_pilot_test` must be present and non-trivial
- `pilot_scope_declaration` must point to a file that exists

---

## 7) Allowed agent paths (green finance extension)

These paths are added to agent path authority for green finance tasks.
They are IN ADDITION to the paths in AGENTS.md, not replacements.

### DB Foundation Agent (green finance extension)
Additional allowed paths:
- `schema/migrations/0[0-9][0-9][0-9]_gf_*.sql`  (green finance migrations)
- `scripts/db/verify_*_neutral_host*.sh`
- `scripts/db/verify_*_green*.sh`

Additional NEVER rules:
- Never create a migration whose table names contain sector nouns.
- Never add a column to a neutral host table for a single methodology.
- Never create a Phase 1 function that reads payload fields by name.

### Invariants Curator Agent (green finance extension)
Additional allowed paths:
- `docs/invariants/NEUTRAL_HOST_INVARIANT_ENTRIES.md`
- `docs/pilots/**`

Additional NEVER rules:
- Never mark a green finance invariant as `implemented` without
  a passing `verify_core_contract_gate.sh` run in the evidence.

### New: Pilot Scope Agent
Allowed paths:
- `docs/pilots/**`
- `tasks/TSK-P*-GF-*/**`
- `docs/operations/AGENTIC_SDLC_PILOT_POLICY.md` (read only)

Must run: `scripts/audit/verify_pilot_scope_declarations.sh`

Never:
- Create or modify Phase 0/1 migration files.
- Register adapter content in neutral host tables.
- Approve its own scope declarations (human review required).

---

## 8) The agent self-check (run before every commit)

Before committing any change on a green finance task, the agent
runs this sequence. All must pass. If any fails, do not commit.

```bash
# 1. Core Contract Gate — neutrality, adapter boundary, function names,
#    payload neutrality, pilot scope declarations
scripts/audit/verify_core_contract_gate.sh

# 2. Task meta schema — includes green finance additional fields
scripts/audit/verify_task_meta_schema.sh --mode strict --scope changed

# 3. Pilot scope declarations (if a pilot directory was touched)
scripts/audit/verify_pilot_scope_declarations.sh

# 4. Standard invariants fast checks (always required)
scripts/audit/run_invariants_fast_checks.sh

# 5. Standard security fast checks (always required)
scripts/audit/run_security_fast_checks.sh
```

Evidence from step 1 must be included in the task evidence output.
Evidence from steps 2–5 must appear in the EXEC_LOG.md.

---

## 9) What makes a green finance task DONE

A green finance task is not done until ALL of the following are true.
This is stricter than the standard Symphony definition of done.

Standard Symphony done criteria (from AI_AGENT_OPERATION_MANUAL.md):
- Task meta declares invariants, verifiers, evidence paths, ownership.
- PLAN.md exists and is referenced.
- EXEC_LOG.md records commands executed.
- Declared verifiers pass.
- Required evidence exists and is schema-valid.
- CI/pre-CI parity gates pass.

Additional green finance done criteria:
- `verify_core_contract_gate.sh` passed and evidence is present.
- `second_pilot_test` in task meta.yml names two concrete unrelated sectors.
- No sector nouns appear in any new table, column, function, or enum name.
- No payload field is referenced by name in any Phase 0/1 function body.
- No jurisdiction-specific logic appears in any Phase 0/1 function body.
- Every new decision record table has `interpretation_version_id NOT NULL`.
- The pilot SCOPE.md exists and passes `verify_pilot_scope_declarations.sh`.
- The `neutrality_verification` block is present in task evidence JSON.
- A human reviewer (not the implementing agent) has confirmed the
  Second Pilot Test answer is genuine, not perfunctory.

The last point is non-negotiable: an AI agent cannot be the sole judge
of whether its own Second Pilot Test answer is adequate. A human must
confirm it before the task is marked `completed`.
