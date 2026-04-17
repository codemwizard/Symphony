# TSK-P2-PREAUTH-000 PLAN — Author and merge ADR for Spatial Capability Model

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification command MUST be explicitly mapped using tracking IDs (e.g., `[ID <task_id>_work_item_01]`).
-->

Task: TSK-P2-PREAUTH-000
Owner: ARCHITECT
Depends on: None
failure_signature: PRE-PHASE2.PREAUTH.ADR-SPATIAL.MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
Create the Architecture Decision Record (ADR) for the Spatial Capability Model before any PostGIS implementation begins. The ADR will document the spatial capability model requirements including PostGIS extension usage, geometry types (POLYGON, 4326), EU Taxonomy K13 taxonomy alignment requirements, DNSH spatial checks, and trade-offs between spatial approaches. This task eliminates the risk of architectural drift and inconsistent implementation across regulatory extensions.

---

## Architectural Context
This task exists at the ground zero of Wave 1 because it has no dependencies and provides the canonical design reference for all PostGIS spatial work in Wave 8 (TSK-P2-REG-003). Without this ADR, the spatial feature lacks architectural documentation, creating risk of inconsistent implementation. This plan guards against the anti-pattern of writing the ADR after implementation has already started.

---

## Pre-conditions
- [ ] No dependencies (this is a ground-zero task)
- [ ] docs/operations/AI_AGENT_OPERATION_MANUAL.md has been read
- [ ] docs/operations/TASK_CREATION_PROCESS.md has been read
- [ ] docs/plans/phase2/ATOMIC_TASK_BREAKDOWN_PLAN.md has been read
- [ ] This PLAN.md has been reviewed and approved

---

## Files to Change
| File | Action | Reason |
|------|--------|--------|
| `docs/decisions/adr-spatial-capability-model.md` | CREATE | ADR for Spatial Capability Model |
| `tasks/TSK-P2-PREAUTH-000/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions
- **If the ADR lacks explicit trade-off analysis between spatial approaches** -> STOP
- **If the ADR does not reference the specific EU Taxonomy K13 and DNSH requirements** -> STOP
- **If the ADR lacks clear boundary definitions for protected areas vs project boundaries** -> STOP
- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP

---

## Implementation Steps

### Step 1: Create ADR file
**What:** `[ID tsk_p2_preauth_000_work_item_01]` Create ADR file at docs/decisions/adr-spatial-capability-model.md with context, decision, and consequences sections following ADR template.
**How:** Create the file with standard ADR structure including context, decision, consequences sections.
**Done when:** File exists at docs/decisions/adr-spatial-capability-model.md and is readable.

```bash
# ADR template structure
cat > docs/decisions/adr-spatial-capability-model.md << 'ADR'
# ADR: Spatial Capability Model

## Context
[Describe the problem or requirement]

## Decision
[Describe the chosen approach]

## Consequences
[Describe positive and negative consequences]
ADR
```

### Step 2: Document spatial capability model requirements
**What:** `[ID tsk_p2_preauth_000_work_item_02]` Document spatial capability model requirements including PostGIS extension usage, geometry types (POLYGON, 4326), and protected area overlap detection.
**How:** Add specific technical details to the ADR decision section.
**Done when:** ADR contains explicit PostGIS extension reference and geometry type specifications (POLYGON, 4326).

### Step 3: Document EU Taxonomy K13 and DNSH requirements
**What:** `[ID tsk_p2_preauth_000_work_item_03]` Document EU Taxonomy K13 taxonomy alignment requirements and DNSH (Do No Significant Harm) spatial checks in the ADR.
**How:** Add regulatory requirements section to ADR.
**Done when:** ADR contains EU Taxonomy K13 and DNSH requirements documented with clear spatial check definitions.

### Step 4: Document trade-offs
**What:** `[ID tsk_p2_preauth_000_work_item_04]` Document trade-offs between different spatial approaches (e.g., PostGIS vs custom geometry handling) with justification for selected approach.
**How:** Add trade-off analysis section to ADR.
**Done when:** ADR contains trade-off analysis section with justification for selected spatial approach.

### Step 5: Emit evidence
**What:** `[ID tsk_p2_preauth_000_work_item_05]` Run verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p2_preauth_000.sh > evidence/phase2/tsk_p2_preauth_000.json || exit 1
```
**Done when:** Verification executes and the explicit JSON schema is written to disk.

---

## Verification

```bash
# [ID tsk_p2_preauth_000_work_item_01]
test -f docs/decisions/adr-spatial-capability-model.md || exit 1

# [ID tsk_p2_preauth_000_work_item_02]
grep -q "PostGIS" docs/decisions/adr-spatial-capability-model.md || exit 1
grep -q "POLYGON" docs/decisions/adr-spatial-capability-model.md || exit 1
grep -q "4326" docs/decisions/adr-spatial-capability-model.md || exit 1

# [ID tsk_p2_preauth_000_work_item_03]
grep -q "K13" docs/decisions/adr-spatial-capability-model.md || exit 1
grep -q "DNSH" docs/decisions/adr-spatial-capability-model.md || exit 1

# [ID tsk_p2_preauth_000_work_item_04]
grep -q "trade-off" docs/decisions/adr-spatial-capability-model.md || exit 1

# [ID tsk_p2_preauth_000_work_item_05]
bash scripts/audit/verify_tsk_p2_preauth_000.sh || exit 1
```

---

## Evidence Contract
File: `evidence/phase2/tsk_p2_preauth_000.json`

Required fields:
- `task_id`: "TSK-P2-PREAUTH-000"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `adr_path`: "docs/decisions/adr-spatial-capability-model.md"
- `postgis_specified`: true
- `geometry_types`: ["POLYGON"]
- `srid": 4326
- `k13_documented`: true
- `dnsh_documented`: true
- `trade_off_analysis_present`: true

---

## Rollback
Not applicable for DOCS_ONLY tasks. If this task must be reverted:
1. Delete docs/decisions/adr-spatial-capability-model.md
2. Update status back to 'planned' in meta.yml
3. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| ADR file missing after task completion | CRITICAL_FAIL | Verification checks file existence |
| ADR lacks PostGIS or geometry specifications | FAIL | Verification checks for specific keywords |
| ADR lacks K13 or DNSH requirements | FAIL | Verification checks for regulatory keywords |
| ADR lacks trade-off analysis | FAIL_REVIEW | Verification checks for trade-off section |
| Anti-pattern: Declaring the ADR complete without human review | FAIL_REVIEW | This plan requires explicit human signoff before marking complete |
| Anti-pattern: Writing the ADR after implementation has already started | FAIL_REVIEW | This task is at ground zero with no dependencies, forcing ADR before any spatial work |

---

## Approval (for regulated surfaces)
Not required for DOCS_ONLY tasks.
