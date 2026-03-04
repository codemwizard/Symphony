# docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md
# Symphony Hardening — Canonical Task Packs (Waves 1–6) — MERGED v1
# All 64 tasks across Waves 1–6. All four review findings resolved.
#
# Post-merge patches applied (over Wave-1 v6 + Waves-2-6 v1 base):
#   PATCH-A (Wave 2 exit gate): Expanded freeze-flag required_deliverables from
#            1 ambiguous path to 5 explicitly named artifact paths
#            (freeze_flag_participant_suspended/account_frozen/aml_hold/
#            regulator_stop/program_hold); updated acceptance_assertions to
#            count 9 artifacts (4 + 5 freeze-flag); added field requirement
#            that verifier checks each by name, no glob enumeration.
#            Shared schema: wave2_exit/freeze_flag_execution_blocked.schema.json
#   PATCH-B (Wave 1 exit gate): Added DECISION NOTE in acceptance_assertions
#            documenting that depends_on covers 012–013B only; 000–011A are
#            transitively covered; decision recorded in DECISION_LOG.md.
#   PATCH-C (Wave 6 exit gate): Added explicit requirement that verifier script
#            checks all 5 prior wave exit gate artifacts + tsk_hard_102.json
#            directly (not just transitively); added tsk_hard_102_confirmed:true
#            field to gate evidence artifact; added FAIL_CLOSED for tsk_hard_102
#            absent or pass=false.
#   PATCH-D (Metadata governance): All 6 tasks that were governance-implicit in
#            the condensed context doc (025, 031, 032, 081, 094, 100) have full
#            [METADATA GOVERNANCE] blocks in the source canonical files — confirmed
#            present; no additional changes needed.
#
# Original Wave-1 v6 patch notes follow:
#
# Fixes applied in v5:
#   FIX-1: Option A — original Wave-1 IDs restored; adjustment scaffolding removed from Wave-1
#   FIX-2: Circuit breaker is its own task TSK-HARD-017; TSK-HARD-016 is malformed quarantine only
#   FIX-3: Evidence event classes moved from docs/architecture/evidence_schema.json
#           into evidence/schemas/hardening/event_classes/ (the set validate_evidence_schema.sh reads);
#           docs mirror is informational, not gating
#   FIX-4: Wave-1 exit gate now has 7 explicit required artifact paths + 7 explicit schema paths
#   FIX-5: Rail inquiry engine state machine has its own dedicated task (TSK-HARD-012);
#           TSK-HARD-013 is effect sealing enforcement (original meaning restored);
#           inquiry state machine includes SCHEDULED, SENT, ACKNOWLEDGED, EXHAUSTED
#   FIX-6: All "must not close before X" prose constraints converted to explicit depends_on edges
#   FIX-7: Standard metadata governance assertion applied to every metadata-driven task
#
# Micro-fixes applied in v6:
#   MICRO-FIX-1: TSK-HARD-000 verifier now checks WAVE_PLAN.md lists Wave-1 IDs matching
#                canonical order block; TRACEABILITY_MATRIX contains TSK-HARD-013B as a
#                distinct row; no downstream dependency references orphan/replay under 013
#   MICRO-FIX-2: Metadata governance signing caveat added — Wave-1 tasks produce evidence
#                artifacts that are signed when signing service is available; if signing
#                service is not yet available (pre-Wave-4), artifact is marked
#                unsigned_reason=DEPENDENCY_NOT_READY and re-signed with linkage once
#                Wave-4 HSM/KMS path (TSK-HARD-051) is complete; assurance tier
#                declared per TSK-HARD-096 standard
#   MICRO-FIX-3: Header FIX-5 line updated to name all four inquiry states including
#                ACKNOWLEDGED; TSK-HARD-012 title updated to reflect full state set
#   MICRO-FIX-4: TSK-HARD-016 acceptance assertion reworded — quarantine capture occurs
#                regardless of upstream HTTP status; caller response does not gate capture
#   MICRO-FIX-5: TSK-OPS-WAVE1-EXIT-GATE acceptance assertion explicitly requires
#                verify_program_wave1_exit_gate.sh to validate each artifact against its
#                schema before emitting pass (not existence + pass=true only)
#   MICRO-FIX-6: TSK-HARD-000 acceptance assertion added — TRACEABILITY_MATRIX contains
#                TSK-HARD-013B as distinct row; no downstream task references orphan/replay
#                under ID 013
#
# Wave-1 canonical task order (IDs restored to original meaning):
#   TSK-HARD-000  Hardening charter and invariant baseline
#   TSK-HARD-001  Trust invariants documentation freeze
#   TSK-HARD-002  Evidence event class schema registration
#   TSK-HARD-010  Rail uncertainty model and inquiry policy framework
#   TSK-HARD-011  Metadata-driven per-rail inquiry policy
#   TSK-HARD-011A Policy snapshot and decision evidence baseline
#   TSK-HARD-012  Rail inquiry engine (SCHEDULED → SENT → EXHAUSTED state machine)
#   TSK-HARD-013  Effect sealing enforcement
#   TSK-HARD-014  Late callback reconciliation (orphaned attestation landing zone)
#   TSK-HARD-015  Conflicting truth containment (FINALITY_CONFLICT state machine)
#   TSK-HARD-016  Malformed response quarantine and evidence capture
#   TSK-HARD-017  Schema drift anomaly circuit breaker
#   TSK-HARD-094  Offline Safe Mode execution gate
#   TSK-HARD-101  Zambia MMO reality controls
#   TSK-HARD-013B Orphan and replay containment  [see note below]
#
# NOTE on TSK-HARD-013B: effect sealing (013) and orphan/replay containment were
# merged under 013 in prior versions. They are separated here. Orphan/replay
# containment is TSK-HARD-013B to avoid renumbering downstream tasks. If the
# program decides to renumber, record the decision in DECISION_LOG.md and update
# TRACEABILITY_MATRIX before execution begins.
#
# Metadata governance standard assertion (FIX-7, updated in MICRO-FIX-2):
# Applied to tasks: 011, 011A, 016, 017, 094, 101
# Text: "Policy/config referenced by this task is versioned; each version has a
#        unique version_id; activation of a new version produces an evidence artifact
#        of type policy_activation_event; this artifact is signed when the signing
#        service (TSK-HARD-051, Wave-4) is available; if the signing service is not
#        yet available at the time of activation, the artifact is emitted with field
#        unsigned_reason=DEPENDENCY_NOT_READY and is re-signed with back-linkage
#        (re_sign_timestamp, re_sign_key_id, original_activation_event_id) once
#        TSK-HARD-051 is complete; assurance tier is declared per TSK-HARD-096
#        standard once that task is complete; runtime operations reference
#        policy_version_id at execution time; in-place edits to an active policy
#        version are blocked at the DB/store layer."
#
# Standard acceptance assertions (apply to ALL tasks, not repeated per task):
#   - evidence file exists and is valid JSON
#   - task_id in evidence matches task pack
#   - pass=true in evidence for successful closeout
#   - declared depends_on all confirmed complete before close
#   - verifier exits 0
#   - RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh exits 0
#   - Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md present in EXEC_LOG.md
#   - at least one negative-path test present and passing
#
# Standard failure modes (apply to ALL tasks, not repeated per task):
#   - missing contract / docs / verifier => FAIL_CLOSED
#   - invalid or missing evidence => FAIL
#   - dependency incomplete => BLOCKED
#   - undeclared path mutations => FAIL_REVIEW
#   - negative-path test absent => FAIL

---

## Wave 1 Task Packs

---

### TSK-HARD-000

- task_id: TSK-HARD-000
- title: Hardening program charter and invariant baseline
- phase: Hardening
- wave: 1
- depends_on: none
- goal: Establish the hardening charter, program governance documents, and baseline
  invariant map that all downstream tasks reference. This task produces no runtime
  code. Its output is the governance layer that makes all other tasks auditable.
- required_deliverables:
  - docs/programs/symphony-hardening/CHARTER.md
  - docs/programs/symphony-hardening/SCOPE.md
  - docs/programs/symphony-hardening/DECISION_LOG.md
  - docs/programs/symphony-hardening/MASTER_PLAN.md
  - docs/programs/symphony-hardening/WAVE_PLAN.md
  - docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md
  - tasks/TSK-HARD-000/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_000.json
- verifier_command: bash scripts/audit/verify_tsk_hard_000.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_000.json
- schema_path: evidence/schemas/hardening/tsk_hard_000.schema.json
- acceptance_assertions:
  - CHARTER.md exists, is non-empty, and names the program owner and approval authority
  - SCOPE.md exists and defines in-scope and explicitly out-of-scope items
  - DECISION_LOG.md exists with at least one entry (program inception decision)
  - MASTER_PLAN.md exists and references all six waves by name
  - WAVE_PLAN.md exists and lists all Wave-1 task IDs in canonical order
  - TRACEABILITY_MATRIX.md exists with one row per hardening task ID; each row has
    columns: task_id, wave, title, depends_on, evidence_path, status
  - baseline invariant map in CHARTER.md or linked doc references all 12 hard
    invariants by ID
  - EXEC_LOG.md contains Canonical-Reference line
  - [MICRO-FIX-1] WAVE_PLAN.md lists Wave-1 task IDs in exactly this order:
    TSK-HARD-000, TSK-HARD-001, TSK-HARD-002, TSK-HARD-010, TSK-HARD-011,
    TSK-HARD-011A, TSK-HARD-012, TSK-HARD-013, TSK-HARD-014, TSK-HARD-015,
    TSK-HARD-016, TSK-HARD-017, TSK-HARD-094, TSK-HARD-101, TSK-HARD-013B,
    TSK-OPS-A1-STABILITY-GATE, TSK-OPS-WAVE1-EXIT-GATE; verifier script confirms
    this list by diffing WAVE_PLAN.md against the canonical order block in
    HARDENING_TASK_PACKS.md programmatically — not by visual inspection
  - [MICRO-FIX-6] TRACEABILITY_MATRIX.md contains TSK-HARD-013B as a distinct row
    with its own task_id, title, depends_on, and evidence_path; no row in
    TRACEABILITY_MATRIX or depends_on field in any task pack uses ID 013 to
    reference orphan/replay containment work; verifier script confirms absence of
    orphan/replay references under bare ID 013
- failure_modes:
  - any governance document missing => FAIL_CLOSED
  - TRACEABILITY_MATRIX.md absent => FAIL_CLOSED
  - invariant map references fewer than 12 invariants => FAIL
  - EXEC_LOG.md missing Canonical-Reference => FAIL
  - [MICRO-FIX-1] WAVE_PLAN.md Wave-1 task ID list does not match canonical order
    block in HARDENING_TASK_PACKS.md => FAIL_CLOSED
  - [MICRO-FIX-1] verifier uses visual inspection rather than programmatic diff
    to confirm WAVE_PLAN.md order => FAIL_REVIEW
  - [MICRO-FIX-6] TRACEABILITY_MATRIX.md missing TSK-HARD-013B row => FAIL_CLOSED
  - [MICRO-FIX-6] any task pack depends_on field references orphan/replay work
    under bare ID 013 => FAIL_CLOSED

---

### TSK-HARD-001

- task_id: TSK-HARD-001
- title: Trust invariants documentation freeze
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-000]
- goal: Produce TRUST_INVARIANTS.md — the human-readable, institutionally legible
  specification of all 12 hard invariants. This document is the primary artifact
  shown to institutional buyers, regulators, and auditors before any runtime
  demonstration. It must be complete, frozen, and independently verifiable against
  the codebase without running any test.
- required_deliverables:
  - docs/programs/symphony-hardening/TRUST_INVARIANTS.md
  - tasks/TSK-HARD-001/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_001.json
- verifier_command: bash scripts/audit/verify_tsk_hard_001.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_001.json
- schema_path: evidence/schemas/hardening/tsk_hard_001.schema.json
- acceptance_assertions:
  - TRUST_INVARIANTS.md exists and contains exactly 12 invariant entries
  - each invariant entry contains all of: invariant_id, plain_language_statement,
    enforcement_layer (one or more of: DB / API / CI / runtime),
    violation_impact_description, test_mapping (reference to specific verifier
    script or CI check that enforces this invariant)
  - no invariant entry has an empty or placeholder value in any field
  - TRUST_INVARIANTS.md is referenced from TRACEABILITY_MATRIX.md
  - verifier script confirms invariant count >= 12 and all required fields present
    by parsing TRUST_INVARIANTS.md programmatically (not by visual inspection)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - TRUST_INVARIANTS.md missing => FAIL_CLOSED
  - fewer than 12 invariants documented => FAIL
  - any invariant entry missing a required field => FAIL
  - verifier relies on visual inspection only (no programmatic parse) => FAIL_REVIEW

---

### TSK-HARD-002

- task_id: TSK-HARD-002
- title: Evidence event class schema registration
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-001]
- goal: Register all hardening event class schemas into the schema set that
  validate_evidence_schema.sh actually reads and enforces. This is the contract
  that governs what a valid evidence artifact looks like for every new event type
  introduced by the hardening program. The docs/architecture/ mirror is
  informational only and carries no gate weight.
- required_deliverables:
  - evidence/schemas/hardening/event_classes/inquiry_event.schema.json
  - evidence/schemas/hardening/event_classes/malformed_quarantine_event.schema.json
  - evidence/schemas/hardening/event_classes/orphaned_attestation_event.schema.json
  - evidence/schemas/hardening/event_classes/finality_conflict_record.schema.json
  - evidence/schemas/hardening/event_classes/adjustment_approval_event.schema.json
  - evidence/schemas/hardening/event_classes/policy_activation_event.schema.json
  - evidence/schemas/hardening/event_classes/pka_snapshot_event.schema.json
  - evidence/schemas/hardening/event_classes/canonicalization_archive_event.schema.json
  - evidence/schemas/hardening/event_classes/dr_ceremony_event.schema.json
  - evidence/schemas/hardening/event_classes/verification_continuity_event.schema.json
  - docs/architecture/EVIDENCE_EVENT_CLASSES.md  [informational mirror — not gating]
  - tasks/TSK-HARD-002/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_002.json
- verifier_command: bash scripts/audit/verify_tsk_hard_002.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_002.json
- schema_path: evidence/schemas/hardening/tsk_hard_002.schema.json
- acceptance_assertions:
  - all 10 event class schema files listed above exist under
    evidence/schemas/hardening/event_classes/
  - each schema file is valid JSON Schema (draft-07 or later)
  - each schema enforces additionalProperties: false at top level
  - scripts/audit/validate_evidence_schema.sh discovers and loads all 10 schemas
    automatically (no manual registration step required per schema)
  - validate_evidence_schema.sh run against a minimal valid sample for each event
    class returns exit 0
  - validate_evidence_schema.sh run against a sample with a missing required field
    for each event class returns exit non-zero
  - docs/architecture/EVIDENCE_EVENT_CLASSES.md exists as human-readable mirror
    but is NOT referenced in any verifier or gate script as a gating input
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the 10 schema files missing => FAIL_CLOSED
  - validate_evidence_schema.sh does not load schemas automatically => FAIL
  - schema permits additionalProperties at top level => FAIL
  - docs mirror referenced as a gate input in any script => FAIL_REVIEW
    (violates FIX-3: docs must not be the enforcement surface)

---

### TSK-HARD-010

- task_id: TSK-HARD-010
- title: Rail uncertainty model and inquiry policy framework
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-002]
- goal: Define the complete model for how the system behaves when a rail returns
  silence, contradiction, or garbage. This task produces the policy framework
  document and the rail scenario matrix that all downstream inquiry and containment
  tasks implement against. No runtime code is required; the output is a specification
  that is testable and frozen.
- required_deliverables:
  - docs/programs/symphony-hardening/INQUIRY_POLICY_FRAMEWORK.md
  - docs/programs/symphony-hardening/RAIL_SCENARIO_MATRIX.md
  - tasks/TSK-HARD-010/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_010.json
- verifier_command: bash scripts/audit/verify_tsk_hard_010.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_010.json
- schema_path: evidence/schemas/hardening/tsk_hard_010.schema.json
- acceptance_assertions:
  - INQUIRY_POLICY_FRAMEWORK.md exists and defines the following fields for each
    policy entry: rail_id (wildcard permitted), cadence_seconds, retry_window_seconds,
    max_attempts, timeout_threshold_seconds, orphan_threshold_seconds,
    circuit_breaker_threshold_rate, circuit_breaker_window_seconds
  - RAIL_SCENARIO_MATRIX.md exists and contains one row per scenario type; minimum
    required scenario types: SILENT_RAIL, CONFLICTING_FINALITY, LATE_CALLBACK,
    MALFORMED_RESPONSE, PARTIAL_RESPONSE, TIMEOUT_EXCEEDED
  - each scenario row defines: scenario_type, description, expected_system_response,
    evidence_artifact_type, implementing_task_id
  - implementing_task_id in each row references a real task ID in TRACEABILITY_MATRIX
  - no scenario row has a missing or placeholder implementing_task_id
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - INQUIRY_POLICY_FRAMEWORK.md missing => FAIL_CLOSED
  - RAIL_SCENARIO_MATRIX.md missing => FAIL_CLOSED
  - fewer than 6 scenario types defined => FAIL
  - any scenario row missing implementing_task_id => FAIL
  - implementing_task_id references non-existent task => FAIL

---

### TSK-HARD-011

- task_id: TSK-HARD-011
- title: Metadata-driven per-rail inquiry policy
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-010]
- goal: Implement the runtime policy loader that resolves per-rail inquiry behavior
  from versioned metadata. Remove all hardcoded timeout/retry/cadence constants
  from adapter and inquiry code. Policy is versioned; the active version_id is
  recorded in every inquiry evidence artifact.
- required_deliverables:
  - runtime policy loader implementation
  - per-rail policy config schema at
    evidence/schemas/hardening/rail_inquiry_policy.schema.json
  - policy store migration (if DB-backed) or config file under version control
    (if file-backed) — must be explicitly stated in EXEC_LOG.md
  - tasks/TSK-HARD-011/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_011.json
- verifier_command: bash scripts/audit/verify_tsk_hard_011.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_011.json
- schema_path: evidence/schemas/hardening/tsk_hard_011.schema.json
- acceptance_assertions:
  - grep for hardcoded timeout/retry/cadence constants in adapter and inquiry code
    returns zero results (verifier runs this grep and fails if any found)
  - policy loader resolves policy by rail_id at runtime from store, not from
    compiled-in constants
  - inquiry evidence artifact contains policy_version_id field populated at
    execution time — not null, not empty
  - per-rail policy config schema validates against
    evidence/schemas/hardening/rail_inquiry_policy.schema.json
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] policy config is versioned: each
    version has a unique version_id; activation of a new version produces an evidence
    artifact of type policy_activation_event (registered in TSK-HARD-002); this
    artifact is signed when the signing service (TSK-HARD-051) is available; if the
    signing service is not yet available, the artifact is emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to an active policy version are blocked
    at the store layer; runtime operations reference policy_version_id at execution time
  - negative-path test: deploying a policy update without a version_id is rejected
  - EXEC_LOG.md states whether policy store is DB-backed or file-backed and
    contains Canonical-Reference line
- failure_modes:
  - any hardcoded constant found by grep => FAIL_CLOSED
  - policy_version_id absent from inquiry evidence => FAIL
  - in-place edit of active policy version permitted => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - activation of new policy version produces no evidence artifact => FAIL
    [METADATA GOVERNANCE violation]
  - activation evidence artifact is unsigned AND unsigned_reason field is absent
    => FAIL [signing caveat requires explicit field when unsigned]

---

### TSK-HARD-011A

- task_id: TSK-HARD-011A
- title: Policy snapshot and decision evidence baseline
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-011]
- goal: Ensure that every automated decision records a snapshot of the policy version
  that governed it, producing a decision evidence artifact that is independently
  verifiable without access to the current active policy.
- required_deliverables:
  - decision event log wiring (policy_version_id recorded per decision)
  - policy snapshot capture at decision time (not resolved at query time)
  - tasks/TSK-HARD-011A/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_011a.json
- verifier_command: bash scripts/audit/verify_tsk_hard_011a.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_011a.json
- schema_path: evidence/schemas/hardening/tsk_hard_011a.schema.json
- acceptance_assertions:
  - every automated inquiry/dispatch decision record contains policy_version_id
    populated at the time of the decision — not resolved lazily at query time
  - decision evidence artifact is of event class inquiry_event (TSK-HARD-002
    schema) and is schema-valid
  - test: deactivating a policy version after a decision was made does not alter
    the policy_version_id recorded on that decision record
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] same caveat as TSK-HARD-011:
    activation of a new policy version produces an evidence artifact; signed when
    signing service is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active version are blocked;
    runtime references policy_version_id at execution time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - policy_version_id resolved at query time rather than decision time => FAIL_CLOSED
  - decision record not schema-valid against inquiry_event schema => FAIL
  - deactivating policy version mutates historical decision records => FAIL_CLOSED

---

### TSK-HARD-012

- task_id: TSK-HARD-012
- title: Rail inquiry engine — SCHEDULED, SENT, ACKNOWLEDGED, EXHAUSTED state machine
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-011A, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement the rail inquiry engine with an explicit, DB-enforced state machine
  governing inquiry lifecycle. The core invariant: no instruction may be
  auto-finalized while its inquiry is in an uncertain or exhausted state. The
  EXHAUSTED state is a holding state, not a resolution state.
- required_deliverables:
  - inquiry state machine implementation with DB-enforced state enum:
    SCHEDULED, SENT, ACKNOWLEDGED, EXHAUSTED
  - state transition guards (illegal transitions rejected with named SQLSTATE)
  - auto-finalization prohibition: code path that attempts to finalize an
    instruction while inquiry is EXHAUSTED must be blocked and evidenced
  - tasks/TSK-HARD-012/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_012.json
- verifier_command: bash scripts/audit/verify_tsk_hard_012.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_012.json
- schema_path: evidence/schemas/hardening/tsk_hard_012.schema.json
- acceptance_assertions:
  - inquiry state enum exists in DB with values: SCHEDULED, SENT, ACKNOWLEDGED,
    EXHAUSTED — no other values permitted
  - state transitions enforced: SCHEDULED → SENT on dispatch confirmation only;
    SENT → ACKNOWLEDGED on confirmed rail response only; SENT → EXHAUSTED on
    max-attempts-exceeded per policy loaded from TSK-HARD-011 metadata;
    ACKNOWLEDGED → no further inquiry states (terminal for inquiry, not for
    instruction)
  - EXHAUSTED is a holding state: instruction remains in its pre-finalization state
    when inquiry reaches EXHAUSTED — no automatic progression to any outcome state
  - any code path that attempts to auto-finalize an instruction while inquiry state
    is EXHAUSTED is intercepted and fails-closed with named error
    (e.g. P7301 INQUIRY_EXHAUSTED_AUTO_FINALIZE_BLOCKED)
  - auto-finalization intercept produces an evidence artifact of event class
    inquiry_event containing: instruction_id, inquiry_state: EXHAUSTED,
    attempted_action: AUTO_FINALIZE, outcome: BLOCKED
  - negative-path test: simulating max-attempts-exceeded drives inquiry to
    EXHAUSTED; subsequent auto-finalization attempt produces P7301 and evidence
    artifact; instruction state is unchanged
  - max_attempts threshold resolved from policy metadata (TSK-HARD-011) — not
    hardcoded
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - auto-finalization permitted from EXHAUSTED state => FAIL_CLOSED
  - auto-finalization intercept produces no evidence artifact => FAIL
  - max_attempts hardcoded rather than policy-resolved => FAIL_CLOSED
  - illegal state transition silently permitted => FAIL_CLOSED
  - negative-path test absent => FAIL

---
### TSK-HARD-013

- task_id: TSK-HARD-013
- title: Effect sealing enforcement
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-012, TSK-OPS-A1-STABILITY-GATE]
- goal: Compute and store effect_seal_hash at instruction seal time. Enforce that
  outbound dispatch payload hash equals the stored seal. Any mismatch fails-closed
  pre-dispatch and produces an evidence artifact. This prevents silent payload
  mutation between instruction sealing and dispatch.
- required_deliverables:
  - effect_seal_hash computation and storage at seal time
  - pre-dispatch hash equality check (outbound payload hash vs stored seal)
  - mismatch evidence artifact
  - tasks/TSK-HARD-013/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_013.json
- verifier_command: bash scripts/audit/verify_tsk_hard_013.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_013.json
- schema_path: evidence/schemas/hardening/tsk_hard_013.schema.json
- acceptance_assertions:
  - effect_seal_hash computed and stored at instruction seal time using a
    deterministic canonicalization of the instruction payload
  - canonicalization algorithm is identified by canonicalization_version in the
    seal record (references TSK-HARD-052 standard, may be stub at this stage)
  - pre-dispatch check computes hash of outbound payload and compares to stored
    effect_seal_hash; mismatch causes dispatch to be rejected before sending
  - mismatch produces evidence artifact containing: instruction_id,
    stored_seal_hash, computed_dispatch_hash, mismatch_detected: true,
    dispatch_blocked: true, timestamp
  - mismatch evidence is of event class inquiry_event or a dedicated
    seal_mismatch_event class; if dedicated class, schema registered in
    TSK-HARD-002 schema set
  - negative-path test: mutating the outbound payload after sealing produces a
    mismatch evidence artifact and dispatch is blocked; instruction state is
    unchanged
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - mismatch not detected pre-dispatch => FAIL_CLOSED
  - mismatch detected but dispatch proceeds => FAIL_CLOSED
  - mismatch produces no evidence artifact => FAIL
  - hash comparison performed post-dispatch => FAIL_CLOSED
  - negative-path test absent => FAIL

---
### TSK-HARD-014

- task_id: TSK-HARD-014
- title: Late callback reconciliation — orphaned attestation landing zone
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-013, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a persistent, queryable orphaned attestation landing zone that
  receives callbacks arriving after their parent instruction has reached a terminal
  or EXHAUSTED state. Late callbacks must not be discarded, must not mutate
  instruction state, and must produce evidence artifacts for audit retrieval.
- required_deliverables:
  - orphaned attestation landing zone (persistent, queryable store — not a log)
  - late callback routing logic (detects terminal/EXHAUSTED parent state and
    routes to landing zone instead of instruction state machine)
  - late callback evidence artifact
  - tasks/TSK-HARD-014/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_014.json
- verifier_command: bash scripts/audit/verify_tsk_hard_014.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_014.json
- schema_path: evidence/schemas/hardening/tsk_hard_014.schema.json
- acceptance_assertions:
  - orphaned attestation landing zone is a persistent store queryable by
    instruction_id, arrival_timestamp, and classification
  - landing zone is separate from the main instruction state tables (not a
    flag on the instruction row)
  - late callback routing: on callback arrival, system checks parent instruction
    state; if state is terminal or EXHAUSTED the callback is routed to landing
    zone, not applied to instruction
  - each landing zone record contains: callback_payload_hash, arrival_timestamp,
    instruction_id, instruction_state_at_arrival, classification: LATE_CALLBACK
  - late callback evidence artifact is schema-valid against
    orphaned_attestation_event schema (registered in TSK-HARD-002)
  - negative-path test: sending a callback after instruction reaches terminal state
    produces a landing zone record and does not mutate instruction state; verified
    by querying instruction state before and after callback arrival
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - late callback mutates terminal instruction state => FAIL_CLOSED
  - late callback silently discarded (no landing zone record) => FAIL
  - landing zone is a log (append-only text) rather than a queryable store => FAIL
  - landing zone record missing any required field => FAIL
  - negative-path test absent => FAIL

---
### TSK-HARD-015

- task_id: TSK-HARD-015
- title: Conflicting truth containment — FINALITY_CONFLICT state machine
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-014, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement deterministic detection and containment of contradictory finality
  signals from different rails or counterparties. FINALITY_CONFLICT must be a
  named, directly queryable state in the instruction state enum — not a derived
  condition inferred from logs. Containment holds all release; no auto-resolution
  is permitted.
- required_deliverables:
  - FINALITY_CONFLICT state added to instruction state enum in DB
  - conflict detection logic (contradictory signals → FINALITY_CONFLICT transition)
  - conflict containment: release hold while in FINALITY_CONFLICT
  - FINALITY_CONFLICT evidence artifact (structured conflict pack)
  - tasks/TSK-HARD-015/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_015.json
- verifier_command: bash scripts/audit/verify_tsk_hard_015.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_015.json
- schema_path: evidence/schemas/hardening/tsk_hard_015.schema.json
- acceptance_assertions:
  - FINALITY_CONFLICT is a value in the instruction state enum in the DB — its
    presence confirmed by querying the enum type directly (not by log inspection)
  - contradictory finality signals (example: rail_a confirms SUCCESS, rail_b
    confirms FAILED for same instruction) deterministically trigger transition
    to FINALITY_CONFLICT state
  - FINALITY_CONFLICT state holds all release: no funds movement, no
    auto-resolution, no automatic progression to any outcome state permitted
  - transition to FINALITY_CONFLICT is irreversible without an explicit human
    operator action that is itself recorded in evidence
  - FINALITY_CONFLICT evidence artifact is schema-valid against
    finality_conflict_record schema (registered in TSK-HARD-002) and contains:
    instruction_id, contradiction_timestamp, rail_a_id, rail_a_response,
    rail_b_id, rail_b_response, conflict_classification, containment_action:
    HOLD_RELEASE
  - negative-path test: supplying contradictory finality signals produces
    FINALITY_CONFLICT state and evidence artifact; instruction state confirmed
    FINALITY_CONFLICT by direct DB query; no release occurs
  - resolution of FINALITY_CONFLICT requires explicit operator action with
    secondary approval; resolution action produces evidence artifact
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - FINALITY_CONFLICT absent from DB state enum => FAIL_CLOSED
  - FINALITY_CONFLICT only detectable by log inspection => FAIL_CLOSED
    (must be directly queryable as a state value)
  - contradictory signals produce silent resolution to any outcome => FAIL_CLOSED
  - release occurs while instruction is in FINALITY_CONFLICT => FAIL_CLOSED
  - FINALITY_CONFLICT evidence artifact not schema-valid => FAIL
  - negative-path test absent => FAIL

---
### TSK-HARD-016

- task_id: TSK-HARD-016
- title: Malformed response quarantine and evidence capture
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-015, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a dedicated quarantine store for malformed, toxic, or unparseable
  provider payloads. Malformed responses must be captured as classified evidence
  artifacts — not routed to generic error handlers, not silently dropped, not
  stored with unbounded payload size. The quarantine store is the basis for the
  schema drift circuit breaker in TSK-HARD-017.
- required_deliverables:
  - malformed payload quarantine store (persistent, queryable)
  - streaming capture with hard truncation policy (first N KB, N from policy config)
  - payload hash stored alongside truncated capture
  - parser classification logic: TRANSPORT, PROTOCOL, SYNTAX, SEMANTIC
  - retention lifecycle policy per quarantine record
  - OOM-safe capture (test with oversized payload)
  - quarantine evidence artifact
  - tasks/TSK-HARD-016/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_016.json
- verifier_command: bash scripts/audit/verify_tsk_hard_016.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_016.json
- schema_path: evidence/schemas/hardening/tsk_hard_016.schema.json
- acceptance_assertions:
  - quarantine capture occurs regardless of upstream HTTP status code returned to
    caller; caller response must not prevent quarantine creation; a malformed
    payload that causes a 500 response to the caller must still produce a quarantine
    record — absence of quarantine record when any response was returned is the
    failure condition, not the HTTP status code itself
  - hard truncation: captured payload is truncated to first N KB before storage;
    N is loaded from policy metadata (TSK-HARD-011); no unbounded write permitted
  - payload hash (of full pre-truncation payload where possible, or of truncated
    payload with truncation_applied: true flag) stored with each record
  - parser classification applied and stored per record: exactly one of TRANSPORT,
    PROTOCOL, SYNTAX, SEMANTIC
  - retention lifecycle policy defined per classification type: duration and action
    (archive or purge) at expiry; loaded from policy metadata
  - OOM-safe test: sending payload larger than 10× truncation threshold completes
    without OOM; only first N KB captured
  - quarantine evidence artifact is schema-valid against malformed_quarantine_event
    schema (registered in TSK-HARD-002) and contains: quarantine_id,
    adapter_id, rail_id, classification, truncation_applied, payload_hash,
    capture_timestamp, retention_policy_version_id
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] truncation threshold N and
    retention lifecycle are loaded from versioned policy config; activation of a
    new policy version produces an evidence artifact; signed when signing service
    is available; if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY
    and re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits
    to active policy version are blocked; runtime references policy_version_id at
    capture time
  - negative-path test: sending known-malformed payload to adapter produces quarantine
    record with correct classification; absence-of-quarantine is the failure
    condition regardless of HTTP status returned to caller
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - quarantine capture absent when any response (including 500) was returned
    to caller => FAIL_CLOSED [capture must occur regardless of HTTP status]
  - unbounded payload write permitted => FAIL_CLOSED
  - OOM on oversized payload => FAIL_CLOSED
  - parser classification absent from quarantine record => FAIL
  - truncation threshold or retention lifecycle hardcoded => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---
### TSK-HARD-017

- task_id: TSK-HARD-017
- title: Schema drift anomaly circuit breaker
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-016, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a per-adapter, per-rail circuit breaker that monitors the rolling
  malformed response rate using the quarantine data from TSK-HARD-016. When the
  malformed rate exceeds a configured threshold, the adapter is automatically
  suspended. Suspension blocks all further dispatch from that adapter until an
  authorized operator explicitly resumes it. No automatic recovery. Suspension and
  resume both produce evidence artifacts.
- required_deliverables:
  - malformed rate monitor (rolling window per adapter/rail, fed from quarantine
    store)
  - auto-suspend logic (rate threshold breach → adapter suspended)
  - manual operator override required to resume (no automatic recovery path)
  - suspension evidence artifact
  - resume evidence artifact (including operator_id, justification, secondary
    approval if required by TSK-HARD-092 UX controls)
  - tasks/TSK-HARD-017/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_017.json
- verifier_command: bash scripts/audit/verify_tsk_hard_017.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_017.json
- schema_path: evidence/schemas/hardening/tsk_hard_017.schema.json
- acceptance_assertions:
  - malformed rate computed per adapter_id and rail_id on a rolling window;
    window duration loaded from policy metadata (TSK-HARD-011)
  - when observed malformed rate >= circuit_breaker_threshold_rate (from policy),
    adapter state transitions to SUSPENDED automatically
  - SUSPENDED adapter rejects all dispatch attempts with named error
    (e.g. P7401 ADAPTER_SUSPENDED_CIRCUIT_BREAKER)
  - no automatic recovery path exists: adapter remains SUSPENDED until explicit
    operator resume action
  - suspension evidence artifact schema-valid and contains: adapter_id, rail_id,
    trigger_threshold, observed_rate, suspension_timestamp, policy_version_id
  - resume requires explicit operator action with: operator_id,
    justification_text, timestamp; resume action produces a resume evidence
    artifact
  - negative-path test: driving malformed rate above threshold produces suspension;
    subsequent dispatch attempt returns P7401; adapter confirmed SUSPENDED by
    direct state query; adapter does not auto-recover after time passes
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] circuit_breaker_threshold_rate and
    rolling window duration are loaded from versioned policy config (TSK-HARD-011);
    activation of a new policy version produces an evidence artifact; signed when
    signing service is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active policy version are blocked;
    runtime references policy_version_id at evaluation time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - adapter auto-recovers without operator action => FAIL_CLOSED
  - dispatch proceeds while adapter is SUSPENDED => FAIL_CLOSED
  - suspension produces no evidence artifact => FAIL
  - threshold hardcoded rather than policy-resolved => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---
### TSK-HARD-094

- task_id: TSK-HARD-094
- title: Offline Safe Mode execution gate
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-017, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a fail-closed execution gate that blocks instruction dispatch
  while the system is in offline or degraded signing mode. Unsigned evidence
  produced during offline periods must be preserved with gap markers, and a
  re-sign linkage must be established on recovery so the evidence chain is
  continuous.
- required_deliverables:
  - offline/degraded mode detection and dispatch block
  - unsigned evidence chain gap markers during offline period
  - recovery re-sign linkage (offline evidence re-signed and linked to gap markers
    on reconnection)
  - offline block evidence artifact
  - tasks/TSK-HARD-094/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_094.json
- verifier_command: bash scripts/audit/verify_tsk_hard_094.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_094.json
- schema_path: evidence/schemas/hardening/tsk_hard_094.schema.json
- acceptance_assertions:
  - instruction dispatch is blocked while system detects offline/degraded signing
    mode; block produces named error (e.g. P7501 OFFLINE_SAFE_MODE_ACTIVE)
  - gap markers inserted into evidence chain for each offline period: gap_start,
    gap_end (populated on recovery), gap_reason
  - on recovery: unsigned evidence artifacts from offline period are re-signed
    using current active key; re-sign produces evidence artifacts that reference
    original gap marker
  - re-signed artifacts preserve original timestamp (offline period timestamp)
    and add re_sign_timestamp and re_sign_key_id fields
  - offline block evidence artifact schema-valid and contains: block_start,
    block_end (populated on recovery), reason, evidence_gap_marker_ids[]
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] offline detection thresholds and
    safe mode policy loaded from versioned policy config; activation of a new policy
    version produces an evidence artifact; signed when signing service is available;
    if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY and
    re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits to
    active version blocked; runtime references policy_version_id
  - negative-path test: simulating offline mode blocks dispatch and produces
    P7501; dispatch rejected; gap marker created; on simulated recovery, re-sign
    linkage established and gap marker closed
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - dispatch permitted in offline mode => FAIL_CLOSED
  - gap markers not inserted during offline period => FAIL
  - re-sign linkage absent on recovery => FAIL
  - re-signed artifact does not preserve original timestamp => FAIL
  - negative-path test absent => FAIL

---
### TSK-HARD-101

- task_id: TSK-HARD-101
- title: Zambia MMO reality controls
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-094, TSK-OPS-A1-STABILITY-GATE]
- goal: Encode the operational control set for Zambia MMO rail-specific failure
  modes: asynchronous contradiction, delayed settlement confirmation, dual-debit
  risk, and operator-side silent rejection. Controls must be metadata-driven
  (not hardcoded per MMO name) and produce deterministic evidence per scenario.
- required_deliverables:
  - MMO reality control rule set (metadata-driven, not per-MMO-name hardcoding)
  - scenario coverage: ASYNC_CONTRADICTION, DELAYED_SETTLEMENT, DUAL_DEBIT_RISK,
    SILENT_REJECTION
  - fallback posture per scenario (hold / inquiry / escalate / containment)
  - deterministic control evidence artifact per scenario type
  - tasks/TSK-HARD-101/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_101.json
- verifier_command: bash scripts/audit/verify_tsk_hard_101.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_101.json
- schema_path: evidence/schemas/hardening/tsk_hard_101.schema.json
- acceptance_assertions:
  - MMO reality control rule set defines at minimum: ASYNC_CONTRADICTION,
    DELAYED_SETTLEMENT, DUAL_DEBIT_RISK, SILENT_REJECTION
  - each scenario entry in rule set defines: scenario_type, detection_condition,
    fallback_posture (one of: hold / inquiry / escalate / containment),
    evidence_artifact_type, policy_version_id
  - rule set is loaded from versioned policy metadata (not hardcoded per MMO name
    or per MMO identifier); rule matching uses rail_class or behavior_profile, not
    MMO name string
  - fallback posture for each scenario type routes to the appropriate existing
    mechanism: hold routes to FINALITY_CONFLICT containment (TSK-HARD-015),
    inquiry routes to inquiry engine (TSK-HARD-012), containment routes to
    quarantine (TSK-HARD-016/017)
  - each scenario produces a deterministic control evidence artifact schema-valid
    against the appropriate event class from TSK-HARD-002
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] MMO reality control rule set is
    versioned; activation of a new rule set version produces an evidence artifact;
    signed when signing service is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active version blocked; runtime
    references policy_version_id at scenario evaluation time
  - negative-path test: simulating each of the 4 scenario types produces expected
    fallback posture and evidence artifact; verified by querying evidence store
    and instruction/inquiry state
  - EXEC_LOG.md contains Canonical-Reference line and explicitly states that no
    MMO name is hardcoded in the rule matching logic
- failure_modes:
  - rule matching uses hardcoded MMO name string => FAIL_CLOSED
    [portability and governance violation]
  - any of the 4 required scenario types absent from rule set => FAIL
  - fallback posture routes to mechanism not implemented in prior tasks => BLOCKED
  - rule set activation produces no evidence artifact => FAIL
    [METADATA GOVERNANCE violation]
  - rule set activation artifact is unsigned AND unsigned_reason field absent => FAIL
    [signing caveat requires explicit field when unsigned]
  - negative-path test absent or covers fewer than 4 scenarios => FAIL

---
### TSK-HARD-013B

- task_id: TSK-HARD-013B
- title: Orphan and replay containment
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-101, TSK-HARD-014, TSK-OPS-A1-STABILITY-GATE]
- goal: Classify and contain orphan events (events whose parent instruction cannot
  be resolved or is in an incompatible state) and prevent replay-based state
  corruption. Orphan events that are not late callbacks (handled in TSK-HARD-014)
  are classified here. Replay detection must be idempotency-key or
  message-fingerprint based — not state-based.
- required_deliverables:
  - orphan classification logic: LATE_CALLBACK (delegated to TSK-HARD-014),
    DUPLICATE_DISPATCH, UNKNOWN_REFERENCE, REPLAY_ATTEMPT
  - replay detection via idempotency key or message fingerprint
  - orphan evidence artifact per classification type
  - tasks/TSK-HARD-013B/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_013b.json
- verifier_command: bash scripts/audit/verify_tsk_hard_013b.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_013b.json
- schema_path: evidence/schemas/hardening/tsk_hard_013b.schema.json
- acceptance_assertions:
  - orphan events classified into exactly: LATE_CALLBACK (routed to TSK-HARD-014
    landing zone), DUPLICATE_DISPATCH, UNKNOWN_REFERENCE, REPLAY_ATTEMPT
  - classification is deterministic: same event always produces same classification
  - replay detection: each processed event has an idempotency_key or
    message_fingerprint stored; re-presentation of a previously processed event
    is detected by key/fingerprint lookup before state mutation
  - replay attempt produces containment evidence artifact schema-valid against
    orphaned_attestation_event schema and contains: event_fingerprint,
    original_processing_timestamp, replay_detected_timestamp,
    classification: REPLAY_ATTEMPT, action: REJECTED
  - replay attempt is rejected — not applied to instruction state
  - DUPLICATE_DISPATCH and UNKNOWN_REFERENCE are also rejected and produce
    evidence artifacts with respective classification values
  - negative-path test: replaying a previously processed event produces
    REPLAY_ATTEMPT classification and evidence artifact; instruction state
    unchanged; verified by querying state before and after replay attempt
  - negative-path test: submitting event with unknown instruction reference
    produces UNKNOWN_REFERENCE classification and evidence artifact
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - replay attempt applied to instruction state => FAIL_CLOSED
  - replay detection absent (no idempotency key or fingerprint check) => FAIL_CLOSED
  - any classification type absent from implementation => FAIL
  - containment evidence artifact not schema-valid => FAIL
  - negative-path test absent => FAIL

---
### TSK-OPS-A1-STABILITY-GATE

- task_id: TSK-OPS-A1-STABILITY-GATE
- title: Program A1 Stability Gate
- phase: Hardening
- wave: 1
- depends_on: none  [runs in parallel; must pass before any runtime hardening task
  is marked done]
- goal: Enforce program-level A1 stability: k8s manifests valid, sandbox deploy
  dry-run passes. This gate is a precondition for all Wave-1 runtime tasks
  (TSK-HARD-012 through TSK-HARD-013B). It does not depend on those tasks; rather,
  those tasks depend on it.
- required_deliverables:
  - scripts/audit/verify_program_a1_stability_gate.sh
  - evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
  - evidence/phase1/program_a1_stability_gate.json
  - evidence/phase1/sandbox_deploy_dry_run.json
- verifier_command: bash scripts/audit/verify_program_a1_stability_gate.sh
- evidence_path: evidence/phase1/program_a1_stability_gate.json
- schema_path: evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
- acceptance_assertions:
  - evidence/phase1/k8s_manifests_validation.json exists and pass=true
  - evidence/phase1/sandbox_deploy_dry_run.json exists and contains all required
    fields: task_id, git_sha, namespace, images, migration_job_ran,
    services_ready, timestamp_utc, pass
  - sandbox_deploy_dry_run.json validates against
    evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
  - verify_program_a1_stability_gate.sh exits non-zero if either input is missing
    or pass=false
- failure_modes:
  - k8s_manifests_validation.json missing or pass=false => FAIL_CLOSED
  - sandbox_deploy_dry_run.json missing required fields => FAIL
  - schema not registered => FAIL

---

### TSK-OPS-WAVE1-EXIT-GATE

- task_id: TSK-OPS-WAVE1-EXIT-GATE
- title: Wave-1 Exit Gate
- phase: Hardening
- wave: 1
- depends_on:
    [TSK-HARD-012, TSK-HARD-013, TSK-HARD-014, TSK-HARD-015,
     TSK-HARD-016, TSK-HARD-017, TSK-HARD-094, TSK-HARD-101, TSK-HARD-013B]
- goal: Deterministic Wave-1 pass/fail gate. All seven negative-path evidence
  artifacts must be present and schema-valid. Gate script exits non-zero if any
  artifact is missing, invalid, or pass=false. No manual override.
- required_deliverables:
  - scripts/audit/verify_program_wave1_exit_gate.sh
  - evidence/phase1/program_wave1_exit_gate.json
  - evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json
  - evidence/phase1/wave1_exit/malformed_response_capture.json
  - evidence/phase1/wave1_exit/conflicting_truth_containment.json
  - evidence/phase1/wave1_exit/offline_safe_mode_block.json
  - evidence/phase1/wave1_exit/inquiry_exhausted_no_autofinalize.json
  - evidence/phase1/wave1_exit/finality_conflict_enum_confirmed.json
  - evidence/phase1/wave1_exit/circuit_breaker_suspension.json
- verifier_command: bash scripts/audit/verify_program_wave1_exit_gate.sh
- evidence_path: evidence/phase1/program_wave1_exit_gate.json
- schema_path: evidence/schemas/hardening/wave1_exit/wave1_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave1_exit/effect_seal_mismatch.schema.json
  - evidence/schemas/hardening/wave1_exit/malformed_response_capture.schema.json
  - evidence/schemas/hardening/wave1_exit/conflicting_truth_containment.schema.json
  - evidence/schemas/hardening/wave1_exit/offline_safe_mode_block.schema.json
  - evidence/schemas/hardening/wave1_exit/inquiry_exhausted_no_autofinalize.schema.json
  - evidence/schemas/hardening/wave1_exit/finality_conflict_enum_confirmed.schema.json
  - evidence/schemas/hardening/wave1_exit/circuit_breaker_suspension.schema.json
- acceptance_assertions:
  - all 7 artifact paths listed in required_deliverables exist
  - each artifact validates against its corresponding schema in schema_set
  - each artifact contains pass=true
  - gate script is deterministic: identical inputs produce identical exit code
  - [MICRO-FIX-5] verify_program_wave1_exit_gate.sh must validate each of the 7
    artifacts against its corresponding schema in schema_set before emitting pass;
    it must either call scripts/audit/validate_evidence_schema.sh internally for
    each artifact or implement equivalent schema validation inline; checking only
    file existence and pass=true field without schema validation is insufficient
    and constitutes a defective gate script (FAIL_CLOSED)
  - gate script exits non-zero if any single artifact is missing, invalid JSON,
    fails schema validation, or contains pass=false
  - specific assertions per artifact:
    - effect_seal_mismatch_fail_closed.json: contains fields instruction_id,
      stored_seal_hash, computed_dispatch_hash, mismatch_detected: true,
      dispatch_blocked: true
    - malformed_response_capture.json: contains fields quarantine_id, adapter_id,
      classification (one of TRANSPORT/PROTOCOL/SYNTAX/SEMANTIC),
      truncation_applied, payload_hash
    - conflicting_truth_containment.json: contains fields instruction_id,
      rail_a_response, rail_b_response, conflict_classification,
      containment_action: HOLD_RELEASE
    - offline_safe_mode_block.json: contains fields block_start, reason,
      evidence_gap_marker_ids[]
    - inquiry_exhausted_no_autofinalize.json: contains fields instruction_id,
      inquiry_state: EXHAUSTED, attempted_action: AUTO_FINALIZE,
      outcome: BLOCKED
    - finality_conflict_enum_confirmed.json: contains fields confirmation_method:
      DB_ENUM_QUERY (not LOG_INSPECTION), enum_value_confirmed:
      FINALITY_CONFLICT, query_timestamp
    - circuit_breaker_suspension.json: contains fields adapter_id, rail_id,
      trigger_threshold, observed_rate, suspension_timestamp,
      policy_version_id, auto_recovery_possible: false
  - Wave-2 tasks are BLOCKED until this gate passes
  - DECISION NOTE: depends_on covers tasks 012–013B; tasks 000–011A are
    transitively required (012 depends_on 011A which chains back to 000).
    Excluding 000–011A from the direct depends_on list is intentional — transitive
    coverage is sufficient. Decision recorded in DECISION_LOG.md.
- failure_modes:
  - any of the 7 artifacts missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - any artifact contains pass=false => FAIL_CLOSED
  - gate script exits zero when any artifact is missing => FAIL_CLOSED
    (gate script itself is defective)
  - [MICRO-FIX-5] gate script checks existence and pass=true but skips schema
    validation => FAIL_CLOSED (gate script itself is defective)
  - manual override of gate result => FAIL_CLOSED (not permitted)

# docs/programs/symphony-hardening/HARDENING_TASK_PACKS_WAVES_2_TO_6.md
# CANONICAL — v1
# Produced at the same standard as WAVE1_TASK_PACKS_FINAL.md (v6)
#
# All fixes from Wave-1 v6 applied uniformly:
#   - Full acceptance_assertions on every task (no blank tasks)
#   - Full required_deliverables on every task
#   - Metadata governance signing caveat (MICRO-FIX-2) on all metadata-driven tasks:
#     "activation produces an evidence artifact; signed when signing service is
#      available; if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY
#      and re-signed with back-linkage once TSK-HARD-051 is complete"
#   - All depends_on edges explicit — no prose sequencing constraints
#   - Negative-path test required on every task
#   - Standard acceptance assertions and failure modes apply to all tasks
#     (stated once below, not repeated per task)
#
# Wave-2 canonical task order:
#   TSK-HARD-020  Adjustment instruction schema and lifecycle
#   TSK-HARD-021  Approval stage model and quorum baseline
#   TSK-HARD-022  Execution attempt model, idempotency, and value ceiling
#   TSK-HARD-023  Recipient inheritance enforcement
#   TSK-HARD-025  Cooling-off and legal hold transitions
#   TSK-HARD-026  Approval attribution and role attestation
#   TSK-HARD-024  Terminal immutability enforcement (P7101) on adjustment tables
#   TSK-OPS-WAVE2-EXIT-GATE
#
# Wave-3 canonical task order:
#   TSK-HARD-030  Lineage reference strategy DSL
#   TSK-HARD-031  Dispatch reference allocation and registry
#   TSK-HARD-032  Length-aware canonicalization and alias collision
#   TSK-HARD-033  Reference registry linkage enforcement
#   TSK-OPS-WAVE3-EXIT-GATE
#
# Wave-4 canonical task order:
#   TSK-HARD-050  Key class separation model
#   TSK-HARD-051  HSM/KMS signing path enforcement
#   TSK-HARD-052  Signature metadata completeness standard
#   TSK-HARD-053  Key rotation drill evidence
#   TSK-HARD-054  Historical verification continuity (archive-only)
#   TSK-HARD-011B Signed policy bundle activation
#   TSK-HARD-096  Assurance tier disclosure evidence
#   TSK-OPS-WAVE4-EXIT-GATE
#
# Wave-5 canonical task order:
#   TSK-HARD-060  Canonicalization version registry
#   TSK-HARD-061  Historical verifier loader (no fallback to latest)
#   TSK-HARD-062  Archive integrity continuity (signed snapshots)
#   TSK-HARD-070  Trust-anchor archival controls (PKA)
#   TSK-HARD-071  Trust anchor archive and revocation material store
#   TSK-HARD-072  Offline verification package (DR recovery bundle)
#   TSK-HARD-073  Multi-party recovery ceremony controls
#   TSK-HARD-074  Regulator access audit envelope
#   TSK-HARD-097  Recovery continuity proof (end-to-end)
#   TSK-HARD-099  Long-horizon audit replay continuity (5-year)
#   TSK-HARD-102  Wave-5 regulator continuity gate
#   TSK-OPS-WAVE5-EXIT-GATE
#
# Wave-6 canonical task order:
#   TSK-HARD-080  Signing scale path (batch/Merkle + HSM throughput)
#   TSK-HARD-081  Rail Command Center v1
#   TSK-HARD-082  BoZ/Auditor demonstration pack (6 scripted scenarios)
#   TSK-HARD-090  QA matrix hardening completeness
#   TSK-HARD-091  Feature-flag rollout evidence controls
#   TSK-HARD-092  Operator safety UX controls
#   TSK-HARD-093  Reporting continuity and activation controls
#   TSK-HARD-095  BoZ submission audit trail primitives
#   TSK-HARD-098  Penalty defense pack generation
#   TSK-HARD-040  Privacy-preserving audit tokenization
#   TSK-HARD-041  Erasure workflow and key shredding controls
#   TSK-HARD-042  Privacy-preserving audit query continuity
#   TSK-HARD-100  Anti-abuse controls and retraction safety
#   TSK-OPS-WAVE6-EXIT-GATE
#
# Standard acceptance assertions (apply to ALL tasks — not repeated per task):
#   - evidence file exists and is valid JSON
#   - task_id in evidence matches task pack
#   - pass=true in evidence for successful closeout
#   - declared depends_on all confirmed complete before close
#   - verifier exits 0
#   - RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh exits 0
#   - Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md present in EXEC_LOG.md
#   - at least one negative-path test present and passing
#
# Standard failure modes (apply to ALL tasks — not repeated per task):
#   - missing contract / docs / verifier => FAIL_CLOSED
#   - invalid or missing evidence => FAIL
#   - dependency incomplete => BLOCKED
#   - undeclared path mutations => FAIL_REVIEW
#   - negative-path test absent => FAIL

---

## Wave 2 Task Packs

Wave-2 entry gate: TSK-OPS-WAVE1-EXIT-GATE must be pass=true before any Wave-2
task may be marked done.

---

### TSK-HARD-020

- task_id: TSK-HARD-020
- title: Adjustment instruction schema and lifecycle
- phase: Hardening
- wave: 2
- depends_on: [TSK-OPS-WAVE1-EXIT-GATE]
- goal: Define and migrate the adjustment instruction table with its full lifecycle
  state machine. An adjustment is an additive correction to a terminal parent
  instruction — it never mutates the parent. This task establishes the schema
  foundation that all Wave-2 governance tasks build on.
- required_deliverables:
  - adjustment instruction table schema and DB migration (expand/contract compliant)
  - state enum with all required values
  - parent_instruction_id FK constraint
  - append-only enforcement (no UPDATE/DELETE on parent instruction from adjustment path)
  - tasks/TSK-HARD-020/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_020.json
- verifier_command: bash scripts/audit/verify_tsk_hard_020.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_020.json
- schema_path: evidence/schemas/hardening/tsk_hard_020.schema.json
- acceptance_assertions:
  - adjustment instruction table exists with state enum containing exactly:
    requested, pending_approval, cooling_off, eligible_execute, executed,
    denied, blocked_legal_hold — no other values permitted
  - parent_instruction_id is a non-nullable FK to the instruction table;
    an adjustment row cannot be inserted without a valid parent
  - no DB path exists that mutates a column on the parent instruction row
    via the adjustment code path; verified by static analysis of migration
    and triggers
  - schema migration is expand/contract compliant and reversible; verifier
    confirms the down-migration restores prior state cleanly
  - migration does not acquire DDL locks on the instruction table during
    apply; lock-risk lint passes
  - evidence artifact schema-valid and contains: task_id, migration_id,
    state_enum_values[], parent_fk_confirmed: true, pass
  - negative-path test: attempting to insert an adjustment row with a
    null parent_instruction_id fails with FK constraint error
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - parent instruction mutated via adjustment code path => FAIL_CLOSED
  - state enum missing any required value => FAIL
  - migration not reversible => FAIL
  - migration acquires DDL lock => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-021

- task_id: TSK-HARD-021
- title: Approval stage model and quorum baseline
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-020]
- goal: Implement the approval stage model that governs how an adjustment transitions
  from requested to pending_approval. Quorum rules are metadata-driven per
  adjustment type. Role heterogeneity is enforced at the DB layer — same-department
  duplicate approvals cannot satisfy quorum.
- required_deliverables:
  - approval stage table schema and migration
  - quorum policy schema at evidence/schemas/hardening/adjustment_quorum_policy.schema.json
  - quorum evaluation logic with role heterogeneity enforcement
  - policy store entry for default quorum policy (N departments, threshold T)
  - tasks/TSK-HARD-021/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_021.json
- verifier_command: bash scripts/audit/verify_tsk_hard_021.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_021.json
- schema_path: evidence/schemas/hardening/tsk_hard_021.schema.json
- acceptance_assertions:
  - approval stage table exists with fields: stage_id, adjustment_id,
    required_approver_count, quorum_threshold, stage_status, quorum_policy_version_id
  - each approval record contains: approver_id, role_at_approval_time,
    department_at_approval_time, approval_timestamp
  - quorum policy is loaded from versioned policy metadata per adjustment type —
    not hardcoded; policy_version_id referenced in approval stage record
  - cross-departmental quorum enforced: minimum N distinct departments required
    (N from policy); N >= 2 for all adjustment types
  - role heterogeneity enforced at evaluation time: two approvals from the same
    department do not increment the distinct-department count even if roles differ
  - negative-path test: submitting two approvals from the same department does
    not satisfy quorum; stage remains pending_approval
  - negative-path test: submitting approvals from N-1 distinct departments does
    not satisfy quorum
  - [METADATA GOVERNANCE] quorum policy config is versioned; activation of a new
    version produces an evidence artifact; signed when signing service is available;
    if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY and
    re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits to
    active policy version are blocked; runtime references policy_version_id at
    quorum evaluation time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - quorum hardcoded per adjustment type => FAIL_CLOSED
  - same-department duplicate approvals satisfy quorum => FAIL_CLOSED
  - role heterogeneity not enforced at evaluation time => FAIL_CLOSED
  - policy_version_id absent from approval stage record => FAIL
  - in-place edit of active quorum policy permitted => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path tests absent => FAIL

---

### TSK-HARD-022

- task_id: TSK-HARD-022
- title: Execution attempt model, idempotency, and value ceiling
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-021]
- goal: Implement the execution attempt model with idempotency enforcement and
  cumulative value ceiling. The ceiling is enforced at the DB layer — not only
  at the application layer. A series of partial adjustments against the same
  parent instruction must not collectively exceed the original instruction value.
  Ceiling breach fails-closed with a named error and produces evidence.
- required_deliverables:
  - execution attempt table schema and migration
  - idempotency key per execution attempt
  - DB-layer cumulative ceiling enforcement (check constraint or trigger)
  - named error P7201 ADJUSTMENT_CEILING_BREACH
  - ceiling breach evidence artifact
  - tasks/TSK-HARD-022/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_022.json
- verifier_command: bash scripts/audit/verify_tsk_hard_022.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_022.json
- schema_path: evidence/schemas/hardening/tsk_hard_022.schema.json
- acceptance_assertions:
  - execution attempt table exists with fields: attempt_id, adjustment_id,
    idempotency_key, adjustment_value, attempt_timestamp, dispatch_reference,
    outcome
  - idempotency_key is unique per adjustment_id; duplicate key on same
    adjustment_id is rejected with named error, not applied twice
  - adjustment_value field is non-nullable; zero-value adjustments require
    explicit justification field
  - cumulative ceiling enforced at DB layer: sum of adjustment_value across all
    executed attempts against the same parent_instruction_id must not exceed
    the original instruction value; this is a DB check constraint or trigger —
    not solely an application-layer check
  - ceiling breach attempt fails with P7201 ADJUSTMENT_CEILING_BREACH before
    any state change occurs
  - ceiling breach produces evidence artifact schema-valid against
    adjustment_approval_event class (TSK-HARD-002) and contains: adjustment_id,
    parent_instruction_id, breach_amount, ceiling_value, cumulative_executed,
    outcome: CEILING_BREACH
  - negative-path test: submitting a sequence of adjustments whose cumulative
    value exceeds parent instruction value — last adjustment fails with P7201
    and produces breach evidence artifact; parent instruction state unchanged
  - negative-path test: replaying an execution attempt with same idempotency_key
    is rejected; not applied twice
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - duplicate execution attempt applied => FAIL_CLOSED
  - cumulative ceiling absent or enforced only at application layer => FAIL_CLOSED
  - ceiling breach produces no evidence artifact => FAIL
  - ceiling breach does not fail before state change => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

### TSK-HARD-023

- task_id: TSK-HARD-023
- title: Recipient inheritance enforcement
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-022]
- goal: Enforce that the recipient of an adjustment is inherited exclusively from
  the parent instruction. The issue_adjustment() interface does not accept a
  recipient parameter. Any attempt to supply a recipient — directly or via an
  alternate field name — is rejected. This closes the redirect exploit where
  a corrective adjustment could be directed to a different recipient than the
  original instruction.
- required_deliverables:
  - issue_adjustment() interface with recipient parameter removed
  - recipient resolution logic (from parent instruction at execution time)
  - redirect exploit negative-path test
  - tasks/TSK-HARD-023/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_023.json
- verifier_command: bash scripts/audit/verify_tsk_hard_023.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_023.json
- schema_path: evidence/schemas/hardening/tsk_hard_023.schema.json
- acceptance_assertions:
  - issue_adjustment() function/API signature does not contain a recipient,
    payee, beneficiary, or equivalent parameter; verifier confirms this by
    static analysis of the interface definition
  - recipient is resolved at execution time by reading parent instruction's
    recipient field directly — not passed through by the caller
  - any HTTP request body or function call containing a recipient field when
    calling the adjustment endpoint is rejected with a named error
    (e.g. P7601 ADJUSTMENT_RECIPIENT_NOT_PERMITTED)
  - recipient on the produced adjustment record matches parent instruction
    recipient exactly; verified by comparing fields post-execution
  - negative-path test: calling issue_adjustment() with an explicit recipient
    field value different from the parent instruction recipient is rejected
    with P7601; no adjustment record created
  - negative-path test: calling issue_adjustment() with an explicit recipient
    field matching the parent instruction recipient is also rejected with P7601
    (the parameter is not permitted regardless of value)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - recipient accepted as an input parameter => FAIL_CLOSED
  - redirect exploit not blocked (mismatched recipient applied) => FAIL_CLOSED
  - recipient resolved from caller input rather than parent instruction => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

### TSK-HARD-025

- task_id: TSK-HARD-025
- title: Cooling-off and legal hold transitions
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-023]
- goal: Implement the cooling_off sealed state and all global freeze flags that
  can block adjustment execution. Cooling-off period is policy-driven. Each freeze
  flag type (participant_suspended, account_frozen, aml_hold, regulator_stop,
  program_hold) blocks execution independently. Legal hold transitions produce
  evidence artifacts with authority references.
- required_deliverables:
  - cooling_off state transition in adjustment lifecycle
  - cooling-off period loaded from policy metadata (not hardcoded)
  - global freeze flag check at execution gate
  - five freeze flag types implemented and individually testable
  - legal hold evidence artifact
  - tasks/TSK-HARD-025/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_025.json
- verifier_command: bash scripts/audit/verify_tsk_hard_025.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_025.json
- schema_path: evidence/schemas/hardening/tsk_hard_025.schema.json
- acceptance_assertions:
  - cooling_off state present in adjustment state enum (extends TSK-HARD-020
    enum); transition to cooling_off from pending_approval is defined and
    enforced
  - cooling-off period duration loaded from policy metadata; verifier confirms
    no hardcoded duration constant in execution gate code
  - execution attempt blocked while adjustment is in cooling_off state; blocked
    with named error (e.g. P7701 ADJUSTMENT_COOLING_OFF_ACTIVE)
  - global freeze flags checked at execution gate in this order:
    participant_suspended, account_frozen, aml_hold, regulator_stop, program_hold
  - any single active freeze flag blocks execution with named error that
    includes the flag type (e.g. P7702 ADJUSTMENT_FREEZE_AML_HOLD)
  - all five freeze flag types are independently checkable and independently
    testable
  - legal hold transition (any flag activation) produces an evidence artifact
    schema-valid against adjustment_approval_event class and contains:
    adjustment_id, hold_type, hold_timestamp, authority_reference, operator_id
  - negative-path test: executing adjustment in cooling_off state fails with
    P7701 and produces no execution attempt record
  - negative-path test: executing adjustment with each of the five freeze flags
    active individually fails with the correct named error
  - [METADATA GOVERNANCE] cooling-off duration policy is versioned; activation
    of a new version produces an evidence artifact; signed when signing service
    is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active version are blocked;
    runtime references policy_version_id at execution gate evaluation time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - execution permitted during cooling_off => FAIL_CLOSED
  - any freeze flag check absent from execution gate => FAIL_CLOSED
  - any of the five freeze flag types not implemented => FAIL
  - cooling-off period hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - legal hold produces no evidence artifact => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-026

- task_id: TSK-HARD-026
- title: Approval attribution and role attestation
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-025]
- goal: Record cryptographic role-attestation at the moment of each approval
  signing. Role and department must be captured at signing time — not resolved
  from current user state at query time. Attestation is linked to the specific
  approval stage. This closes the role-spoofing attack where a role change after
  approval could retroactively alter the attestation record.
- required_deliverables:
  - role and department capture at signing time (snapshot, not live lookup)
  - attestation schema extension to approval record
  - signature or signature reference per attestation
  - signing-time capture test
  - tasks/TSK-HARD-026/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_026.json
- verifier_command: bash scripts/audit/verify_tsk_hard_026.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_026.json
- schema_path: evidence/schemas/hardening/tsk_hard_026.schema.json
- acceptance_assertions:
  - each approval record contains: approver_id, role_at_time_of_signing,
    department_at_time_of_signing, attestation_timestamp, signature_ref
  - role_at_time_of_signing and department_at_time_of_signing are populated
    at the moment the approval action is submitted — not resolved lazily
    from a user directory at query time
  - signature_ref links to an evidence artifact signed with key class AAK
    (adjustment attestation key, defined in TSK-HARD-050); if TSK-HARD-050
    is not yet complete, signature_ref is populated with
    unsigned_reason=DEPENDENCY_NOT_READY and updated once TSK-HARD-050 is done
  - attestation record is linked to a specific approval stage_id — not to the
    adjustment_id alone
  - test: changing the approver's role in the user directory after approval
    does not alter role_at_time_of_signing on the historical approval record;
    verified by querying the record before and after the role change
  - negative-path test: approval record without role_at_time_of_signing or
    department_at_time_of_signing fields fails schema validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - role resolved at query time rather than signing time => FAIL_CLOSED
  - role-change-after-approval mutates historical attestation record => FAIL_CLOSED
  - attestation not linked to specific approval stage_id => FAIL
  - signature_ref absent and unsigned_reason not populated => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-024

- task_id: TSK-HARD-024
- title: Terminal immutability enforcement (P7101) on adjustment tables
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-026]
- goal: Deploy the P7101 terminal immutability trigger on the adjustment
  instruction table. Any direct UPDATE on a row whose state is terminal
  (executed, denied, blocked_legal_hold) must raise SQLSTATE P7101.
  This mirrors the existing P7101 enforcement on the parent instruction
  table and closes the gap where adjustment records could be silently
  edited after reaching a terminal state.
- required_deliverables:
  - P7101 trigger deployed on adjustment instruction table
  - terminal states covered: executed, denied, blocked_legal_hold
  - negative-path test for each terminal state
  - tasks/TSK-HARD-024/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_024.json
- verifier_command: bash scripts/audit/verify_tsk_hard_024.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_024.json
- schema_path: evidence/schemas/hardening/tsk_hard_024.schema.json
- acceptance_assertions:
  - P7101 trigger exists on adjustment instruction table; verifier confirms
    trigger presence by querying DB information_schema or equivalent
  - trigger fires on any UPDATE to a row where current state is in
    (executed, denied, blocked_legal_hold)
  - trigger raises SQLSTATE P7101; UPDATE is not applied
  - trigger covers all three terminal states individually; not only one
  - negative-path test for each terminal state: direct UPDATE attempt raises
    P7101; row state is unchanged after attempt; verified by querying row
    before and after UPDATE attempt
  - P7101 trigger does not interfere with legitimate state transitions
    (e.g. transition to executed from eligible_execute is not blocked)
  - evidence artifact contains: task_id, trigger_name, terminal_states_covered[],
    negative_path_outcomes[], pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - P7101 trigger absent from adjustment table => FAIL_CLOSED
  - direct UPDATE on any terminal state row permitted => FAIL_CLOSED
  - trigger covers fewer than three terminal states => FAIL
  - legitimate state transitions blocked by trigger => FAIL
  - negative-path test absent for any terminal state => FAIL

---

### TSK-OPS-WAVE2-EXIT-GATE

- task_id: TSK-OPS-WAVE2-EXIT-GATE
- title: Wave-2 Exit Gate
- phase: Hardening
- wave: 2
- depends_on:
    [TSK-HARD-020, TSK-HARD-021, TSK-HARD-022, TSK-HARD-023,
     TSK-HARD-025, TSK-HARD-026, TSK-HARD-024]
- goal: Deterministic Wave-2 pass/fail gate. All five negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Gate script exits
  non-zero if any artifact is missing, invalid, or failing. Wave-3 tasks are
  BLOCKED until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave2_exit_gate.sh
  - evidence/phase1/program_wave2_exit_gate.json
  - evidence/phase1/wave2_exit/adjustment_ceiling_breach.json
  - evidence/phase1/wave2_exit/recipient_redirect_blocked.json
  - evidence/phase1/wave2_exit/cooling_off_execution_blocked.json
  - evidence/phase1/wave2_exit/p7101_terminal_update_blocked.json
  # Freeze-flag artifacts (one per flag type; shared schema)
  - evidence/phase1/wave2_exit/freeze_flag_participant_suspended.json
  - evidence/phase1/wave2_exit/freeze_flag_account_frozen.json
  - evidence/phase1/wave2_exit/freeze_flag_aml_hold.json
  - evidence/phase1/wave2_exit/freeze_flag_regulator_stop.json
  - evidence/phase1/wave2_exit/freeze_flag_program_hold.json
- verifier_command: bash scripts/audit/verify_program_wave2_exit_gate.sh
- evidence_path: evidence/phase1/program_wave2_exit_gate.json
- schema_path: evidence/schemas/hardening/wave2_exit/wave2_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave2_exit/adjustment_ceiling_breach.schema.json
  - evidence/schemas/hardening/wave2_exit/recipient_redirect_blocked.schema.json
  - evidence/schemas/hardening/wave2_exit/cooling_off_execution_blocked.schema.json
  - evidence/schemas/hardening/wave2_exit/freeze_flag_execution_blocked.schema.json
  - evidence/schemas/hardening/wave2_exit/p7101_terminal_update_blocked.schema.json
- acceptance_assertions:
  - all required_deliverables evidence artifacts exist
  - gate script validates each artifact against its schema in schema_set before
    emitting pass; checking existence and pass=true alone is insufficient
  - each artifact contains pass=true
  - gate script exits non-zero if any artifact is missing, fails schema
    validation, or contains pass=false
  - gate script is deterministic: identical inputs produce identical exit code
  - specific field requirements per artifact:
    - adjustment_ceiling_breach.json: contains adjustment_id,
      parent_instruction_id, breach_amount, ceiling_value,
      outcome: CEILING_BREACH
    - recipient_redirect_blocked.json: contains adjustment_id,
      attempted_recipient, error_code: P7601, outcome: REJECTED
    - cooling_off_execution_blocked.json: contains adjustment_id,
      state_at_attempt: cooling_off, error_code: P7701, outcome: BLOCKED
    - freeze_flag_*.json: contains adjustment_id, flag_type, error_code: P7702,
      outcome: BLOCKED (exactly one artifact per flag type listed above)
    - p7101_terminal_update_blocked.json: contains adjustment_id,
      terminal_state_at_attempt, sqlstate: P7101, outcome: BLOCKED
  - Wave-3 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - any artifact contains pass=false => FAIL_CLOSED
  - gate validates only existence and pass=true without schema validation
    => FAIL_CLOSED (gate script itself is defective)
  - manual override of gate result => FAIL_CLOSED (not permitted)

---

## Wave 3 Task Packs

Wave-3 entry gate: TSK-OPS-WAVE2-EXIT-GATE must be pass=true before any Wave-3
task may be marked done.

---

### TSK-HARD-030

- task_id: TSK-HARD-030
- title: Lineage reference strategy DSL
- phase: Hardening
- wave: 3
- depends_on: [TSK-OPS-WAVE2-EXIT-GATE]
- goal: Define the reference strategy DSL that governs how adjustment dispatch
  references are derived from parent instruction references. Strategy selection
  is per-rail and loaded from policy metadata. The DSL is schema-validated and
  frozen once activated. This provides the policy contract that TSK-HARD-031
  implements at runtime.
- required_deliverables:
  - reference strategy DSL schema at
    evidence/schemas/hardening/reference_strategy_dsl.schema.json
  - policy store entry for each supported strategy type
  - docs/programs/symphony-hardening/REFERENCE_STRATEGY_DSL.md
  - tasks/TSK-HARD-030/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_030.json
- verifier_command: bash scripts/audit/verify_tsk_hard_030.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_030.json
- schema_path: evidence/schemas/hardening/tsk_hard_030.schema.json
- acceptance_assertions:
  - DSL schema defines and validates all four supported strategy types:
    SUFFIX, DETERMINISTIC_ALIAS, RE_ENCODED_HASH_TOKEN, RAIL_NATIVE_ALT_FIELD
  - each strategy entry in the DSL specifies: strategy_type, rail_id (wildcard
    permitted), max_length, nonce_retry_limit, collision_action
  - strategy selection is per-rail: DSL is looked up by rail_id at dispatch time,
    not hardcoded in adapter code
  - DSL document (REFERENCE_STRATEGY_DSL.md) is informational and the schema
    in evidence/schemas/hardening/ is the enforcement surface
  - DSL schema validates successfully against JSON Schema draft-07 or later
  - [METADATA GOVERNANCE] reference strategy config is versioned; activation of
    a new version produces an evidence artifact; signed when signing service is
    available; if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY
    and re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits
    to active version are blocked; runtime references policy_version_id at
    strategy selection time
  - negative-path test: rail with no matching DSL entry produces a named error
    rather than falling back to a default strategy silently
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the four strategy types absent from DSL schema => FAIL
  - strategy selection hardcoded in adapter code => FAIL_CLOSED
  - docs mirror used as enforcement surface => FAIL_REVIEW
  - in-place edit of active DSL version permitted => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---

### TSK-HARD-031

- task_id: TSK-HARD-031
- title: Dispatch reference allocation and registry
- phase: Hardening
- wave: 3
- depends_on: [TSK-HARD-030]
- goal: Implement the dispatch reference registry and the runtime allocation engine
  that applies the strategy DSL from TSK-HARD-030. The registry is a persistent,
  queryable store. Alias generation includes nonce retry on collision up to the
  configured limit. Every collision event — whether resolved by retry or not —
  produces an evidence artifact. The registry entry is created before dispatch,
  not after.
- required_deliverables:
  - dispatch reference registry (persistent, queryable store)
  - allocation engine implementing all four DSL strategy types
  - nonce retry logic with configurable max_retry limit
  - collision evidence artifact
  - pre-dispatch registry registration enforcement
  - tasks/TSK-HARD-031/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_031.json
- verifier_command: bash scripts/audit/verify_tsk_hard_031.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_031.json
- schema_path: evidence/schemas/hardening/tsk_hard_031.schema.json
- acceptance_assertions:
  - dispatch reference registry is a persistent store queryable by: reference,
    instruction_id, adjustment_id, allocation_timestamp, strategy_used
  - allocation engine implements all four strategy types defined in TSK-HARD-030
    DSL; strategy resolved from per-rail policy at allocation time
  - registry entry is created and committed before dispatch is attempted;
    dispatch without a registry entry is blocked (see TSK-HARD-033)
  - each registry entry contains: registry_id, instruction_id, adjustment_id
    (nullable), allocated_reference, strategy_used, policy_version_id,
    allocation_timestamp, collision_retry_count
  - on collision: nonce incremented and retry attempted up to max_retry_limit
    (from DSL policy); each retry logged on the registry entry
  - if max_retry_limit is reached without resolving collision: allocation fails
    with named error (e.g. P7801 REFERENCE_ALLOCATION_RETRY_EXHAUSTED) and
    produces a collision exhaustion evidence artifact
  - collision evidence artifact contains: reference_attempted, collision_count,
    strategy_used, outcome: EXHAUSTED or RESOLVED
  - [METADATA GOVERNANCE] max_retry_limit and strategy selection are loaded from
    versioned DSL policy config (TSK-HARD-030); activation produces evidence
    artifact; signed when available; unsigned_reason=DEPENDENCY_NOT_READY if not;
    in-place edits to active version blocked; runtime references policy_version_id
  - negative-path test: forcing collision exhaustion (all nonce variations
    collide) produces P7801 and exhaustion evidence artifact; no registry entry
    committed with unresolved reference
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - dispatch proceeds without registry entry => FAIL_CLOSED
  - collision silently retried without logging retry count => FAIL
  - collision exhaustion produces no evidence artifact => FAIL
  - allocation engine does not implement all four strategy types => FAIL
  - max_retry_limit hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---

### TSK-HARD-032

- task_id: TSK-HARD-032
- title: Length-aware canonicalization and alias collision detection
- phase: Hardening
- wave: 3
- depends_on: [TSK-HARD-031]
- goal: Implement length-aware pre-dispatch canonicalization of outbound
  references to per-rail field length limits. Adapter-level outbound validation
  rejects references that exceed rail limits before they reach the wire.
  Truncation collision detection identifies cases where two distinct allocated
  references truncate to the same wire-level value, producing a collision
  evidence artifact rather than silently dispatching a duplicate.
- required_deliverables:
  - per-rail max length config (loaded from policy metadata)
  - pre-dispatch canonicalization to per-rail max length
  - adapter-level outbound field validation
  - truncation collision detection
  - collision evidence artifact on truncation collision
  - tasks/TSK-HARD-032/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_032.json
- verifier_command: bash scripts/audit/verify_tsk_hard_032.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_032.json
- schema_path: evidence/schemas/hardening/tsk_hard_032.schema.json
- acceptance_assertions:
  - per-rail max reference field length is loaded from policy metadata (not
    hardcoded per rail name); policy_version_id referenced at canonicalization time
  - outbound reference is canonicalized to per-rail max length before dispatch;
    canonicalization is deterministic given the same input and policy version
  - adapter-level validation rejects any outbound reference that exceeds the
    rail's max field length after canonicalization; rejection produces a named
    error (e.g. P7901 REFERENCE_LENGTH_EXCEEDED)
  - truncation collision detection: before dispatching a canonicalized reference,
    the registry is checked for any existing entry with the same
    post-canonicalization value but a different pre-canonicalization value;
    if found, this is a truncation collision
  - truncation collision produces an evidence artifact and blocks dispatch;
    the artifact contains: original_reference, truncated_reference,
    colliding_registry_entry_id, outcome: TRUNCATION_COLLISION_BLOCKED
  - duplicate detection test: two distinct full-length references that truncate
    to the same value are detected as a truncation collision before the second
    is dispatched
  - [METADATA GOVERNANCE] per-rail max length config is versioned; activation
    produces evidence artifact; signed when available; unsigned_reason field
    if not; in-place edits blocked; runtime references policy_version_id
  - negative-path test: dispatching a reference that exceeds rail max length
    is rejected with P7901; wire is not touched
  - negative-path test: dispatching a reference whose truncated form collides
    with an existing registry entry produces truncation collision evidence
    and dispatch is blocked
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - reference dispatched without length canonicalization => FAIL
  - reference exceeding rail max length dispatched to wire => FAIL_CLOSED
  - truncation collision not detected => FAIL_CLOSED
  - truncation collision produces no evidence artifact => FAIL
  - per-rail max length hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - negative-path tests absent => FAIL

---

### TSK-HARD-033

- task_id: TSK-HARD-033
- title: Reference registry linkage enforcement
- phase: Hardening
- wave: 3
- depends_on: [TSK-HARD-032]
- goal: Enforce that every outbound dispatch references a registered entry in the
  registry from TSK-HARD-031. Dispatch without a registry entry is blocked.
  Adjusted references (from adjustment dispatches) are accepted when a registry
  entry exists for the adjustment_id. Rail-rejected duplicates produce evidence
  artifacts that reference the original dispatch registry entry.
- required_deliverables:
  - pre-dispatch registry linkage check
  - rejection evidence for unregistered references
  - adjusted reference acceptance logic
  - duplicate rejection evidence artifact
  - tasks/TSK-HARD-033/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_033.json
- verifier_command: bash scripts/audit/verify_tsk_hard_033.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_033.json
- schema_path: evidence/schemas/hardening/tsk_hard_033.schema.json
- acceptance_assertions:
  - pre-dispatch check confirms reference exists in registry before any outbound
    call is made; absence blocks dispatch with named error
    (e.g. P8001 REFERENCE_NOT_REGISTERED)
  - unregistered reference rejection produces evidence artifact containing:
    reference_attempted, instruction_id, outcome: UNREGISTERED_BLOCKED
  - adjusted references (dispatched for an adjustment_id) are accepted when
    the registry contains an entry with matching adjustment_id and
    allocated_reference; no special bypass is required
  - when a rail rejects a dispatch as a duplicate (rail-level duplicate
    rejection): the system records a duplicate rejection evidence artifact
    that references the original dispatch registry entry by registry_id
  - duplicate rejection evidence artifact contains: reference, rail_rejection_code,
    original_registry_entry_id, rejection_timestamp
  - negative-path test: dispatching with an unregistered reference fails with
    P8001 and produces rejection evidence; wire is not touched
  - negative-path test: dispatch with a registry entry for adjustment_id
    succeeds (adjusted reference accepted)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - unregistered reference dispatched to wire => FAIL_CLOSED
  - unregistered reference rejection produces no evidence => FAIL
  - rail-rejected duplicate produces no evidence artifact => FAIL
  - adjusted reference rejected when valid registry entry exists => FAIL
  - negative-path tests absent => FAIL

---

### TSK-OPS-WAVE3-EXIT-GATE

- task_id: TSK-OPS-WAVE3-EXIT-GATE
- title: Wave-3 Exit Gate
- phase: Hardening
- wave: 3
- depends_on:
    [TSK-HARD-030, TSK-HARD-031, TSK-HARD-032, TSK-HARD-033]
- goal: Deterministic Wave-3 pass/fail gate. All four negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Wave-4 tasks are
  BLOCKED until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave3_exit_gate.sh
  - evidence/phase1/program_wave3_exit_gate.json
  - evidence/phase1/wave3_exit/reference_allocation_retry_exhausted.json
  - evidence/phase1/wave3_exit/reference_length_exceeded.json
  - evidence/phase1/wave3_exit/truncation_collision_blocked.json
  - evidence/phase1/wave3_exit/unregistered_reference_blocked.json
- verifier_command: bash scripts/audit/verify_program_wave3_exit_gate.sh
- evidence_path: evidence/phase1/program_wave3_exit_gate.json
- schema_path: evidence/schemas/hardening/wave3_exit/wave3_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave3_exit/reference_allocation_retry_exhausted.schema.json
  - evidence/schemas/hardening/wave3_exit/reference_length_exceeded.schema.json
  - evidence/schemas/hardening/wave3_exit/truncation_collision_blocked.schema.json
  - evidence/schemas/hardening/wave3_exit/unregistered_reference_blocked.schema.json
- acceptance_assertions:
  - all 4 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - gate script exits non-zero if any artifact is missing, fails schema
    validation, or contains pass=false
  - specific field requirements per artifact:
    - reference_allocation_retry_exhausted.json: contains reference_attempted,
      collision_count, strategy_used, outcome: EXHAUSTED
    - reference_length_exceeded.json: contains reference_attempted, rail_max_length,
      reference_length, error_code: P7901, outcome: REJECTED
    - truncation_collision_blocked.json: contains original_reference,
      truncated_reference, colliding_registry_entry_id,
      outcome: TRUNCATION_COLLISION_BLOCKED
    - unregistered_reference_blocked.json: contains reference_attempted,
      instruction_id, error_code: P8001, outcome: UNREGISTERED_BLOCKED
  - Wave-4 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - gate validates only existence without schema validation => FAIL_CLOSED
  - manual override => FAIL_CLOSED (not permitted)

---

## Wave 4 Task Packs

Wave-4 entry gate: TSK-OPS-WAVE3-EXIT-GATE must be pass=true before any Wave-4
task may be marked done.

Note: TSK-HARD-051 completion is the point at which all Wave-1 through Wave-3
unsigned_reason=DEPENDENCY_NOT_READY evidence artifacts must be retroactively
re-signed with back-linkage. The EXEC_LOG.md for TSK-HARD-051 must include a
re-sign sweep record confirming all prior DEPENDENCY_NOT_READY artifacts have
been re-signed and their re_sign_timestamp and re_sign_key_id fields populated.

---

### TSK-HARD-050

- task_id: TSK-HARD-050
- title: Key class separation model
- phase: Hardening
- wave: 4
- depends_on: [TSK-OPS-WAVE3-EXIT-GATE]
- goal: Formally define the key class taxonomy and authorization matrix for all
  signing operations. Four key classes are defined: EASK, PCSK, AAK, and
  transport identities. The authorization matrix defines which caller types may
  invoke sign operations per key class. The matrix is enforced at the signing
  service layer — unauthorized cross-class signing is rejected with a named error.
- required_deliverables:
  - key class taxonomy document at docs/architecture/KEY_CLASS_TAXONOMY.md
  - authorization matrix schema at
    evidence/schemas/hardening/key_auth_matrix.schema.json
  - runtime authorization enforcement in signing service
  - negative-path test per key class
  - tasks/TSK-HARD-050/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_050.json
- verifier_command: bash scripts/audit/verify_tsk_hard_050.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_050.json
- schema_path: evidence/schemas/hardening/tsk_hard_050.schema.json
- acceptance_assertions:
  - key class taxonomy defines exactly four classes: EASK (evidence artifact
    signing key), PCSK (policy and config signing key), AAK (adjustment
    attestation key), TRANSPORT_IDENTITY
  - each key class entry in taxonomy specifies: class_id, permitted_callers[],
    permitted_artifact_types[], key_backend (HSM/KMS/software), exportable: false
  - authorization matrix is loaded at signing service startup and enforced per
    request; matrix is not hardcoded in application code
  - unauthorized caller attempting sign with wrong key class is rejected with
    named error (e.g. P8101 KEY_CLASS_UNAUTHORIZED)
  - cross-class signing attempts produce evidence artifacts containing:
    caller_id, requested_key_class, permitted_key_classes[], outcome: REJECTED
  - negative-path test: caller authorized for AAK attempts to sign with EASK
    key class — rejected with P8101 and produces rejection evidence
  - negative-path test: caller authorized for EASK attempts to sign with PCSK
    key class — rejected with P8101
  - taxonomy document is informational; enforcement surface is the authorization
    matrix schema and runtime enforcement; docs mirror not gating
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - key classes undocumented or fewer than four defined => FAIL
  - authorization matrix not enforced at runtime => FAIL_CLOSED
  - cross-class signing permitted silently => FAIL_CLOSED
  - cross-class rejection produces no evidence artifact => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-051

- task_id: TSK-HARD-051
- title: HSM/KMS signing path enforcement
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-050]
- goal: Enforce that all evidence artifact signing operations route through the
  HSM/KMS backend (OpenBao or equivalent). Private keys are non-exportable. The
  signing service supports digest signing (caller supplies hash; HSM signs hash —
  raw payload not transmitted to HSM). Rate limits and caller-level authorization
  are enforced. Every sign operation produces an audit log entry. Completion of
  this task triggers the DEPENDENCY_NOT_READY re-sign sweep for all prior waves.
- required_deliverables:
  - signing service with HSM/KMS backend fully operational
  - digest signing endpoint
  - per-key-class rate limits configured
  - sign audit log
  - DEPENDENCY_NOT_READY re-sign sweep record in EXEC_LOG.md
  - tasks/TSK-HARD-051/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_051.json
- verifier_command: bash scripts/audit/verify_tsk_hard_051.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_051.json
- schema_path: evidence/schemas/hardening/tsk_hard_051.schema.json
- acceptance_assertions:
  - all evidence artifact sign operations route through HSM/KMS backend;
    verifier confirms by audit log inspection — no sign operations appear
    that lack an HSM/KMS audit log entry
  - private keys are non-exportable: no sign operation response contains
    raw key material; verified by inspecting signing service response schema
  - digest signing supported: signing endpoint accepts pre-computed hash and
    returns signature; raw payload path does not transmit full payload to HSM
  - rate limits configured per key class: verifier confirms rate limit config
    exists for each of the four key classes defined in TSK-HARD-050
  - caller-level authorization enforced: signing request authenticated by
    caller identity before key class authorization is checked
  - every sign operation produces an audit log entry containing: caller_id,
    key_id, key_class, artifact_type, digest_hash, timestamp, outcome
  - sign audit log is append-only and independently queryable
  - EXEC_LOG.md includes a re-sign sweep record confirming: (1) all evidence
    artifacts from Waves 1–3 with unsigned_reason=DEPENDENCY_NOT_READY have
    been re-signed, (2) each re-signed artifact has re_sign_timestamp and
    re_sign_key_id populated, (3) original_activation_event_id back-reference
    is present on each re-signed artifact, (4) sweep_completed_timestamp
  - negative-path test: sign operation bypassing HSM (e.g. direct software
    signing call) is blocked and produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any sign operation bypasses HSM/KMS => FAIL_CLOSED
  - raw key material returned by signing service => FAIL_CLOSED
  - sign audit log absent or not append-only => FAIL
  - DEPENDENCY_NOT_READY re-sign sweep not completed => FAIL
    (all prior unsigned artifacts must be re-signed before this task closes)
  - re-signed artifact missing back-reference to original event => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-052

- task_id: TSK-HARD-052
- title: Signature metadata completeness standard
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-051]
- goal: Establish and enforce the signature metadata standard for all evidence
  artifacts. Every signed artifact must carry a complete set of provenance fields.
  Missing any required field causes deterministic verification failure — not silent
  acceptance. The standard document is the normative reference; the schema in the
  evidence schema set is the enforcement surface.
- required_deliverables:
  - signature metadata standard document at
    docs/architecture/SIGNATURE_METADATA_STANDARD.md
  - enforcement in signing path: all required fields populated before artifact
    is returned
  - validation test: missing any required field causes schema validation failure
  - tasks/TSK-HARD-052/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_052.json
- verifier_command: bash scripts/audit/verify_tsk_hard_052.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_052.json
- schema_path: evidence/schemas/hardening/tsk_hard_052.schema.json
- acceptance_assertions:
  - every signed evidence artifact contains all required fields: key_id,
    key_version, algorithm, canonicalization_version, signature_timestamp,
    signing_service_id, trust_chain_ref, assurance_tier
  - when artifact is part of a Merkle batch (TSK-HARD-080), additional fields
    required: merkle_root, leaf_index, merkle_proof
  - missing any required field causes deterministic schema validation failure
    (validate_evidence_schema.sh exits non-zero); not silent acceptance
  - signing path populates all required fields before returning artifact to
    caller; caller cannot omit any field
  - SIGNATURE_METADATA_STANDARD.md is informational; schema in
    evidence/schemas/hardening/ is the enforcement surface
  - negative-path test: artifact with canonicalization_version field absent
    fails schema validation; artifact with signing_service_id absent fails
    schema validation; verified per field individually
  - negative-path test: batch artifact missing merkle_proof field fails
    schema validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - missing required metadata field silently accepted => FAIL_CLOSED
  - canonicalization_version absent from any signed artifact => FAIL_CLOSED
  - assurance_tier absent (added retroactively once TSK-HARD-096 is complete;
    if TSK-HARD-096 not yet done, field must be present with value
    PENDING_TIER_ASSIGNMENT — not absent) => FAIL
  - Merkle metadata absent from any batch artifact => FAIL
  - docs standard used as enforcement surface => FAIL_REVIEW
  - negative-path tests absent => FAIL

---

### TSK-HARD-053

- task_id: TSK-HARD-053
- title: Key rotation drill evidence
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-052]
- goal: Implement and evidence the key rotation SOP for both scheduled and
  emergency scenarios. Historical verification compatibility must be confirmed
  after rotation: artifacts signed with the deactivated key must remain verifiable
  using archived key material only. Rotation evidence artifacts are themselves
  meta-signed by a key class that is not being rotated.
- required_deliverables:
  - docs/operations/KEY_ROTATION_SOP.md
  - scheduled rotation drill evidence artifact
  - emergency rotation drill evidence artifact
  - post-rotation historical verification evidence
  - tasks/TSK-HARD-053/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_053.json
- verifier_command: bash scripts/audit/verify_tsk_hard_053.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_053.json
- schema_path: evidence/schemas/hardening/tsk_hard_053.schema.json
- acceptance_assertions:
  - KEY_ROTATION_SOP.md exists and covers: scheduled rotation flow with
    pre-rotation checklist, emergency rotation flow with trigger criteria,
    activation procedure, deactivation procedure with archival step,
    rollback procedure, historical verification compatibility check step
  - scheduled rotation drill produces evidence artifact containing: old_key_id,
    new_key_id, rotation_type: SCHEDULED, activation_timestamp,
    deactivation_timestamp, archival_confirmed: true, drill_outcome: PASS
  - emergency rotation drill produces evidence artifact containing:
    rotation_type: EMERGENCY, trigger_reason, old_key_deactivation_timestamp,
    new_key_activation_timestamp, order_confirmed: deactivation_before_activation,
    drill_outcome: PASS
  - deactivation_before_activation order enforced: new key must not be activated
    before old key is deactivated and archived in emergency scenario
  - post-rotation historical verification: at least one artifact signed with
    the deactivated key is verified successfully using archived key material only
    (operational key store excluded from verification environment during this test)
  - post-rotation verification evidence contains: verified_artifact_id,
    key_used: ARCHIVED_KEY, operational_store_excluded: true, outcome: PASS
  - rotation evidence artifacts are meta-signed: signed with a key class that
    is not the key class being rotated; meta-signing key class identified in
    drill evidence
  - negative-path test: attempting to verify a post-rotation artifact using
    the current operational key store (instead of archived key) produces
    UNVERIFIABLE_MISSING_KEY or equivalent named error — not a false pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - KEY_ROTATION_SOP.md absent => FAIL
  - emergency rotation not drilled => FAIL
  - new key activated before old key deactivated in emergency scenario => FAIL_CLOSED
  - historical verification broken after rotation => FAIL_CLOSED
  - post-rotation verification uses operational key store => FAIL_CLOSED
  - rotation evidence not meta-signed => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-054

- task_id: TSK-HARD-054
- title: Historical verification continuity (archive-only)
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-053]
- goal: Confirm that artifacts signed under each historical key version remain
  verifiable using archived key material only, with the operational key store
  completely excluded. Verification failure for a missing version produces a
  named error — not a silent pass. This task establishes the baseline that the
  Wave-5 five-year horizon simulation (TSK-HARD-099) extends.
- required_deliverables:
  - archive-only verification environment setup (operational store excluded)
  - historical verification test across all key versions in rotation history
  - named error modes for missing material
  - tasks/TSK-HARD-054/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_054.json
- verifier_command: bash scripts/audit/verify_tsk_hard_054.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_054.json
- schema_path: evidence/schemas/hardening/tsk_hard_054.schema.json
- acceptance_assertions:
  - test environment configured with operational key store explicitly excluded;
    EXEC_LOG.md confirms exclusion method (environment variable, network block,
    or equivalent)
  - at least one artifact signed under each historical key version in the
    rotation history is successfully verified using archived key material only
  - verification result for each historical key version recorded in evidence
    artifact: key_version, artifact_verified, archived_material_used,
    operational_store_excluded: true, outcome
  - missing key version in archive produces UNVERIFIABLE_MISSING_KEY named error
    — not a silent pass or a fallback to operational store
  - missing canonicalization version in archive produces
    UNVERIFIABLE_MISSING_CANONICALIZER named error — not a silent pass
  - neither UNVERIFIABLE_MISSING_KEY nor UNVERIFIABLE_MISSING_CANONICALIZER
    is treated as a passing state in any test or CI check; verifier script
    confirms absence of these error codes in passing test output
  - negative-path test: requesting verification of an artifact whose key
    version has been deliberately removed from the archive produces
    UNVERIFIABLE_MISSING_KEY; outcome is FAIL, not PASS
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - verification falls back to operational key store => FAIL_CLOSED
  - missing key version produces silent pass => FAIL_CLOSED
  - missing canonicalization version produces silent pass => FAIL_CLOSED
  - UNVERIFIABLE error treated as passing in any test => FAIL_CLOSED
  - historical key versions not all covered by test => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-011B

- task_id: TSK-HARD-011B
- title: Signed policy bundle activation
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-054]
- goal: Enforce that policy bundles follow a signed lifecycle: draft → approved →
  active. The approved-to-active transition requires a valid signature verified at
  activation time. Unsigned or invalidly signed bundles cannot be activated.
  Runtime enforcement re-verifies the policy signature before applying the policy
  to any decision. High-risk policies require re-verification on every execution.
- required_deliverables:
  - policy bundle lifecycle: draft → approved → active state machine
  - signature verification at activation time
  - runtime re-verification at decision time
  - high-risk policy re-verification on every execution
  - activation rejection evidence artifact
  - tasks/TSK-HARD-011B/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_011b.json
- verifier_command: bash scripts/audit/verify_tsk_hard_011b.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_011b.json
- schema_path: evidence/schemas/hardening/tsk_hard_011b.schema.json
- acceptance_assertions:
  - policy bundle state enum: draft, approved, active — no other values
  - transition from approved to active blocked if bundle signature is invalid
    or absent; blocked with named error (e.g. P8201 POLICY_BUNDLE_UNSIGNED)
  - signature verified at activation time using signing service
    (TSK-HARD-051); verification result recorded in policy activation event
  - runtime enforcement: policy bundle signature re-verified at decision time
    before policy is applied; verification failure blocks decision with
    named error (e.g. P8202 POLICY_BUNDLE_VERIFICATION_FAILED)
  - high-risk policies (flag defined in policy metadata) require signature
    re-verification on every execution, not only at activation; verifier
    confirms high-risk flag is checked before applying policy
  - policy activation produces evidence artifact schema-valid against
    policy_activation_event class (TSK-HARD-002) and contains: policy_id,
    policy_version, signer_key_id, activation_timestamp, verification_outcome,
    assurance_tier
  - negative-path test: attempting to activate an unsigned policy bundle
    produces P8201 and rejection evidence artifact; bundle state remains approved
  - negative-path test: runtime decision with an invalidly signed policy
    bundle produces P8202; decision is blocked
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - unsigned policy bundle activated => FAIL_CLOSED
  - runtime verification absent at decision time => FAIL_CLOSED
  - high-risk policy applied without per-execution re-verification => FAIL_CLOSED
  - activation evidence artifact absent => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-096

- task_id: TSK-HARD-096
- title: Assurance tier disclosure evidence
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-011B]
- goal: Establish the assurance tier taxonomy and enforce that every signed evidence
  artifact carries an assurance_tier field populated by the signing service.
  The tier field discloses whether signing was HSM-backed, software-backed, or
  involved a DEPENDENCY_NOT_READY interim state. Retroactively update all
  re-signed artifacts from prior waves with the correct tier value.
- required_deliverables:
  - assurance tier taxonomy document at docs/architecture/ASSURANCE_TIER_TAXONOMY.md
  - assurance_tier field enforced in signing service output
  - tier value validation in evidence schema
  - retroactive tier assignment for re-signed artifacts from prior waves
  - tasks/TSK-HARD-096/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_096.json
- verifier_command: bash scripts/audit/verify_tsk_hard_096.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_096.json
- schema_path: evidence/schemas/hardening/tsk_hard_096.schema.json
- acceptance_assertions:
  - assurance tier taxonomy defines at minimum three tiers: HSM_BACKED,
    SOFTWARE_BACKED, DEPENDENCY_NOT_READY; taxonomy document identifies
    which tier applies to which signing path
  - every signed evidence artifact produced from this task forward contains
    assurance_tier field with one of the defined tier values
  - assurance_tier field is populated by the signing service — not self-reported
    by the caller; signing service determines tier from key backend type
  - disclosure test: artifact produced via HSM path carries assurance_tier:
    HSM_BACKED; artifact produced via software path carries
    assurance_tier: SOFTWARE_BACKED
  - EXEC_LOG.md includes a retroactive tier assignment record: all re-signed
    artifacts from Waves 1–3 (which were previously marked
    unsigned_reason=DEPENDENCY_NOT_READY) must now have assurance_tier field
    populated with the correct tier value; sweep_completed_timestamp recorded
  - artifacts from prior waves with assurance_tier: PENDING_TIER_ASSIGNMENT
    (stub from TSK-HARD-052) are updated to their correct tier value
  - taxonomy document is informational; schema in evidence/schemas/hardening/
    is the enforcement surface; docs mirror not gating
  - negative-path test: artifact from HSM path that claims
    assurance_tier: SOFTWARE_BACKED fails signing service internal validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - assurance_tier absent from any signed artifact produced after this task => FAIL
  - tier self-reported by caller rather than set by signing service => FAIL_CLOSED
  - taxonomy not documented => FAIL
  - retroactive sweep not completed for prior-wave artifacts => FAIL
  - PENDING_TIER_ASSIGNMENT stubs remaining after this task closes => FAIL
  - negative-path test absent => FAIL

---

### TSK-OPS-WAVE4-EXIT-GATE

- task_id: TSK-OPS-WAVE4-EXIT-GATE
- title: Wave-4 Exit Gate
- phase: Hardening
- wave: 4
- depends_on:
    [TSK-HARD-050, TSK-HARD-051, TSK-HARD-052, TSK-HARD-053,
     TSK-HARD-054, TSK-HARD-011B, TSK-HARD-096]
- goal: Deterministic Wave-4 pass/fail gate. All five negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Wave-5 tasks are
  BLOCKED until this gate passes. Additionally confirms the DEPENDENCY_NOT_READY
  re-sign sweep and assurance tier sweep are complete.
- required_deliverables:
  - scripts/audit/verify_program_wave4_exit_gate.sh
  - evidence/phase1/program_wave4_exit_gate.json
  - evidence/phase1/wave4_exit/key_class_unauthorized_rejected.json
  - evidence/phase1/wave4_exit/hsm_bypass_blocked.json
  - evidence/phase1/wave4_exit/unsigned_policy_bundle_rejected.json
  - evidence/phase1/wave4_exit/historical_verification_archive_only.json
  - evidence/phase1/wave4_exit/dependency_not_ready_resign_sweep.json
- verifier_command: bash scripts/audit/verify_program_wave4_exit_gate.sh
- evidence_path: evidence/phase1/program_wave4_exit_gate.json
- schema_path: evidence/schemas/hardening/wave4_exit/wave4_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave4_exit/key_class_unauthorized_rejected.schema.json
  - evidence/schemas/hardening/wave4_exit/hsm_bypass_blocked.schema.json
  - evidence/schemas/hardening/wave4_exit/unsigned_policy_bundle_rejected.schema.json
  - evidence/schemas/hardening/wave4_exit/historical_verification_archive_only.schema.json
  - evidence/schemas/hardening/wave4_exit/dependency_not_ready_resign_sweep.schema.json
- acceptance_assertions:
  - all 5 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - specific field requirements per artifact:
    - key_class_unauthorized_rejected.json: contains caller_id,
      requested_key_class, error_code: P8101, outcome: REJECTED
    - hsm_bypass_blocked.json: contains attempted_signing_path: SOFTWARE_BYPASS,
      outcome: BLOCKED
    - unsigned_policy_bundle_rejected.json: contains policy_id, error_code: P8201,
      outcome: ACTIVATION_REJECTED
    - historical_verification_archive_only.json: contains key_versions_tested[],
      operational_store_excluded: true, all_outcomes: PASS
    - dependency_not_ready_resign_sweep.json: contains sweep_completed_timestamp,
      artifacts_resigned_count, artifacts_with_pending_tier_assignment_cleared: true
  - Wave-5 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - dependency_not_ready_resign_sweep artifact absent or incomplete => FAIL_CLOSED
  - manual override => FAIL_CLOSED (not permitted)

---

## Wave 5 Task Packs

Wave-5 entry gate: TSK-OPS-WAVE4-EXIT-GATE must be pass=true before any Wave-5
task may be marked done.

---

### TSK-HARD-060

- task_id: TSK-HARD-060
- title: Canonicalization version registry
- phase: Hardening
- wave: 5
- depends_on: [TSK-OPS-WAVE4-EXIT-GATE]
- goal: Implement the frozen canonicalization spec registry. Each version entry
  is immutable once activated. Test vectors are executable. The registry is
  independently queryable without operational runtime dependency. This is the
  foundation that TSK-HARD-061 (historical verifier loader) and TSK-HARD-062
  (archive snapshots) build on.
- required_deliverables:
  - canonicalization version registry store (append-only, independently queryable)
  - one frozen entry per active canonicalization version
  - executable test vectors per version
  - activation and deprecation metadata
  - tasks/TSK-HARD-060/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_060.json
- verifier_command: bash scripts/audit/verify_tsk_hard_060.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_060.json
- schema_path: evidence/schemas/hardening/tsk_hard_060.schema.json
- acceptance_assertions:
  - registry exists and is independently queryable without operational runtime
    dependency (e.g. can be queried from a read-only replica or exported snapshot)
  - each registry entry contains: version_id, spec_document_hash,
    implementation_package_ref, test_vectors_ref, activation_date,
    deprecation_date (nullable), entry_timestamp
  - spec documents are immutable once activated: UPDATE to spec_document_hash
    on an activated entry is blocked; verifier confirms via negative-path test
  - test vectors are stored alongside the spec and are executable — not
    documentation-only; verifier runs test vectors for each version and confirms
    they pass against the corresponding implementation package
  - registry is append-only: no DELETE on existing entries; verifier confirms
    via negative-path test
  - negative-path test: attempting to update spec_document_hash on an activated
    entry is rejected with a named error
  - negative-path test: attempting to delete an entry from the registry is
    rejected with a named error
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - spec document mutable after activation => FAIL_CLOSED
  - test vectors not executable => FAIL
  - registry entries deletable => FAIL_CLOSED
  - registry requires operational runtime to query => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-061

- task_id: TSK-HARD-061
- title: Historical verifier loader — no fallback to latest
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-060]
- goal: Implement the historical verifier that resolves the exact canonicalization
  version used at signing time from the registry. No fallback to current or latest
  version is permitted. If the exact version is absent from the registry, the
  verifier produces UNVERIFIABLE_MISSING_CANONICALIZER — not a silent pass, not a
  retry with a different version.
- required_deliverables:
  - historical verifier loader implementation
  - version resolution logic (reads canonicalization_version from artifact
    signature metadata, loads exact version from registry)
  - UNVERIFIABLE_MISSING_CANONICALIZER error mode
  - tasks/TSK-HARD-061/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_061.json
- verifier_command: bash scripts/audit/verify_tsk_hard_061.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_061.json
- schema_path: evidence/schemas/hardening/tsk_hard_061.schema.json
- acceptance_assertions:
  - historical verifier reads canonicalization_version from the artifact's
    signature metadata (field defined in TSK-HARD-052 standard)
  - verifier loads exact spec version from registry by version_id — no fallback
    to current/latest permitted; verifier confirms by static analysis that no
    fallback code path exists
  - if exact version_id is absent from registry: verification fails with
    named error UNVERIFIABLE_MISSING_CANONICALIZER; outcome is FAIL not PASS
  - UNVERIFIABLE_MISSING_CANONICALIZER is not caught and swallowed anywhere
    in the codebase; verifier confirms by grep for catch blocks around this
    error code
  - verification result contains: artifact_id, canonicalization_version_requested,
    canonicalization_version_found (or null if absent), outcome
  - negative-path test: artifact with canonicalization_version set to a value
    absent from registry produces UNVERIFIABLE_MISSING_CANONICALIZER;
    outcome is FAIL; no silent fallback occurs
  - negative-path test: artifact with canonicalization_version present in
    registry is verified successfully
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - fallback to latest canonicalization version occurs => FAIL_CLOSED
  - missing version produces silent pass => FAIL_CLOSED
  - UNVERIFIABLE_MISSING_CANONICALIZER swallowed by catch block => FAIL_CLOSED
  - verification result missing canonicalization_version_requested field => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-062

- task_id: TSK-HARD-062
- title: Archive integrity continuity — signed canonicalization snapshots
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-061]
- goal: Produce canonicalization archive snapshots that are cryptographically
  signed with key class PCSK. Each snapshot packages all active canonicalization
  versions, their spec hashes, and their test vectors. Offsite replication is
  confirmed with a linkage record. This produces the portable archive that
  TSK-HARD-072 (DR recovery bundle) packages.
- required_deliverables:
  - canonicalization archive snapshot generator
  - signed snapshot manifest (PCSK-signed)
  - offsite replication linkage record
  - tasks/TSK-HARD-062/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_062.json
- verifier_command: bash scripts/audit/verify_tsk_hard_062.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_062.json
- schema_path: evidence/schemas/hardening/tsk_hard_062.schema.json
- acceptance_assertions:
  - archive snapshot packages: all active and deprecated canonicalization
    versions with spec_document_hash, implementation_package_ref,
    test_vectors_ref, and activation_date for each
  - snapshot manifest is signed with key class PCSK (from TSK-HARD-050);
    signature verified at snapshot creation time
  - manifest contains: snapshot_timestamp, canonicalization_versions_included[],
    manifest_hash, signing_key_id, assurance_tier
  - offsite replication linkage record produced after snapshot and confirms:
    snapshot_id, offsite_location_ref, replication_timestamp,
    integrity_check_outcome: PASS
  - offsite replication linkage record is schema-valid against
    canonicalization_archive_event class (TSK-HARD-002)
  - snapshot can be used to independently verify historical artifacts without
    operational runtime dependency; confirmed by isolated verification test
  - negative-path test: snapshot with missing spec_document_hash for any
    included version fails snapshot manifest validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - snapshot manifest unsigned => FAIL_CLOSED
  - snapshot signed with wrong key class (not PCSK) => FAIL
  - offsite replication not confirmed => FAIL
  - snapshot missing any active canonicalization version => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-070

- task_id: TSK-HARD-070
- title: Trust-anchor archival controls — Public Key Archive
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-062]
- goal: Implement the Public Key Archive (PKA) as an append-only store that is
  physically or logically separate from the operational database. The PKA contains
  one entry per key version for each key class. No UPDATE or DELETE is permitted
  on existing PKA entries. The PKA can be restored independently from a snapshot
  without access to the operational DB.
- required_deliverables:
  - PKA store (separate from operational DB)
  - append-only enforcement on PKA entries
  - independent restore test
  - PKA snapshot mechanism
  - tasks/TSK-HARD-070/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_070.json
- verifier_command: bash scripts/audit/verify_tsk_hard_070.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_070.json
- schema_path: evidence/schemas/hardening/tsk_hard_070.schema.json
- acceptance_assertions:
  - PKA is a persistent store that is separate from the operational database;
    EXEC_LOG.md explicitly states whether the separation is physical (different
    DB instance), logical (different schema with separate credentials), or other;
    chosen approach confirmed in DECISION_LOG.md
  - PKA entries are append-only: UPDATE and DELETE operations on existing PKA
    entries are blocked at the DB layer (trigger or RLS policy); verifier
    confirms via negative-path test
  - each PKA entry contains: key_id, key_version, key_class, public_key_material,
    trust_anchor_ref, activation_date, deactivation_date (nullable), entry_timestamp
  - PKA can be snapshotted and restored to an isolated environment without
    access to the operational DB; isolated restore test confirms PKA entries
    are intact and queryable after restore
  - isolated restore test: PKA snapshot restored to isolated environment;
    historical verification performed using PKA only; verification succeeds
    for at least one artifact per key class
  - PKA snapshot evidence artifact is schema-valid against pka_snapshot_event
    class (TSK-HARD-002) and contains: snapshot_id, snapshot_timestamp,
    key_versions_included[], restore_test_outcome: PASS
  - negative-path test: attempting UPDATE on an existing PKA entry is rejected
    with a named error
  - negative-path test: attempting DELETE on an existing PKA entry is rejected
    with a named error
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - PKA shares storage with operational DB and cannot be independently restored
    => FAIL_CLOSED
  - UPDATE permitted on PKA entries => FAIL_CLOSED
  - DELETE permitted on PKA entries => FAIL_CLOSED
  - isolated restore test fails => FAIL_CLOSED
  - separation approach not documented in DECISION_LOG.md => FAIL_REVIEW
  - negative-path tests absent => FAIL

---

### TSK-HARD-071

- task_id: TSK-HARD-071
- title: Trust anchor archive and revocation material store
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-070]
- goal: Produce versioned trust anchor snapshots, archive revocation material for
  all deactivated keys, and archive all verification policy versions. All archived
  materials must be independently restorable. This provides the trust context
  that DR recovery and long-horizon verification (TSK-HARD-099) depend on.
- required_deliverables:
  - trust anchor snapshot store (versioned)
  - revocation material store (revoked key IDs, timestamps, reasons)
  - verification policy version archive
  - independent restore test for each store
  - tasks/TSK-HARD-071/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_071.json
- verifier_command: bash scripts/audit/verify_tsk_hard_071.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_071.json
- schema_path: evidence/schemas/hardening/tsk_hard_071.schema.json
- acceptance_assertions:
  - trust anchor snapshots exist and are versioned with: snapshot_id,
    snapshot_timestamp, signing_key_id, trust_anchor_entries[]
  - each trust anchor snapshot is signed with key class PCSK at creation time
  - revocation material archived for all deactivated keys: revoked_key_id,
    revocation_timestamp, revocation_reason, revoking_operator_id
  - revocation material is append-only: no UPDATE or DELETE on revocation records
  - verification policy versions archived: each version with activation_date,
    policy_document_hash, signing_key_id, deprecation_date (nullable)
  - all three archived stores (trust anchor, revocation, verification policy)
    are independently restorable; isolated restore test performed for each
  - evidence artifact contains: task_id, stores_archived[], restore_tests_passed[],
    pass
  - negative-path test: verification of an artifact from a revoked key produces
    a named error referencing revocation material (not a silent pass)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - revocation material not archived => FAIL_CLOSED
  - revocation records mutable => FAIL_CLOSED
  - verification policy versions not versioned => FAIL
  - any archived store not independently restorable => FAIL_CLOSED
  - negative-path test absent => FAIL

---

### TSK-HARD-072

- task_id: TSK-HARD-072
- title: Offline verification package — DR recovery bundle
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-071]
- goal: Generate the encrypted offline DR recovery bundle containing all materials
  required for independent historical verification. The bundle is encrypted at
  rest with a key accessible only via the quorum ceremony in TSK-HARD-073.
  A signed chain-of-custody manifest covers all bundle contents. The bundle
  must be usable in an isolated environment with no operational runtime dependency.
- required_deliverables:
  - DR recovery bundle generator script
  - encrypted bundle (PKA export + canonicalization archive + trust anchor
    archive + revocation material + verification policy archive + verifier
    tooling package)
  - signed chain-of-custody manifest (PCSK-signed)
  - isolated environment verification test
  - tasks/TSK-HARD-072/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_072.json
- verifier_command: bash scripts/audit/verify_tsk_hard_072.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_072.json
- schema_path: evidence/schemas/hardening/tsk_hard_072.schema.json
- acceptance_assertions:
  - DR recovery bundle contains exactly: PKA export, canonicalization archive
    snapshot (TSK-HARD-062), trust anchor archive (TSK-HARD-071), revocation
    material (TSK-HARD-071), verification policy archive (TSK-HARD-071),
    verifier tooling package (self-contained, no network dependency)
  - bundle is encrypted at rest; encryption key is accessible only via quorum
    ceremony defined in TSK-HARD-073; EXEC_LOG.md documents encryption scheme
  - chain-of-custody manifest signed with key class PCSK and contains:
    bundle_timestamp, contents_hash[], signing_key_id, chain_of_custody_refs[],
    assurance_tier
  - isolated environment verification test: using only the bundle contents
    (no operational runtime, no network), verify at least two historical
    artifacts of distinct types; both verifications must succeed
  - isolated test evidence contains: test_timestamp, artifacts_verified[],
    operational_runtime_used: false, network_used: false, outcomes[]
  - evidence artifact is schema-valid against dr_ceremony_event class
    (TSK-HARD-002)
  - negative-path test: bundle with any required component missing fails
    manifest integrity check before isolation test is attempted
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - bundle missing any required component => FAIL_CLOSED
  - bundle not encrypted at rest => FAIL_CLOSED
  - encryption key accessible without quorum ceremony => FAIL_CLOSED
  - chain-of-custody manifest unsigned => FAIL_CLOSED
  - isolated verification test fails or uses operational runtime => FAIL_CLOSED
  - negative-path test absent => FAIL

---

### TSK-HARD-073

- task_id: TSK-HARD-073
- title: Multi-party recovery ceremony controls
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-072]
- goal: Implement the quorum access policy and ceremony procedure for DR bundle
  access. Quorum must span heterogeneous roles from at least three distinct
  authority categories. Every bundle access event produces a ceremony evidence
  artifact that is itself signed and archived. A drill ceremony must be performed
  and evidenced before this task closes.
- required_deliverables:
  - quorum access policy (minimum threshold defined and enforced)
  - docs/operations/DR_RECOVERY_CEREMONY.md
  - ceremony evidence artifact schema
  - drill ceremony performed and drill evidence artifact
  - tasks/TSK-HARD-073/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_073.json
- verifier_command: bash scripts/audit/verify_tsk_hard_073.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_073.json
- schema_path: evidence/schemas/hardening/tsk_hard_073.schema.json
- acceptance_assertions:
  - quorum access policy defines: minimum participant count (e.g. 2-of-3 or
    3-of-5) and required authority categories; threshold and categories
    documented in DR_RECOVERY_CEREMONY.md and enforced at access gate
  - required authority categories: at minimum one Board-level authority, one
    Security function authority, one Audit/Witness authority
  - DR_RECOVERY_CEREMONY.md exists and covers: pre-ceremony checklist,
    participant verification procedure, access evidence recording steps,
    post-ceremony integrity check, emergency ceremony variant
  - every bundle access event produces a ceremony evidence artifact containing:
    ceremony_id, ceremony_type (DRILL or LIVE), participants[], roles[],
    authority_categories[], quorum_threshold, quorum_met: true/false,
    access_timestamp, purpose, outcome
  - ceremony evidence artifact is schema-valid against dr_ceremony_event class
    (TSK-HARD-002) and is itself signed with key class PCSK
  - signed ceremony evidence artifact is archived in a store that is independent
    of the DR bundle itself
  - drill ceremony performed: drill evidence artifact exists with
    ceremony_type: DRILL and outcome: PASS
  - negative-path test: bundle access attempted with fewer than required
    authority categories present is rejected; rejection evidence produced
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - bundle accessed without quorum => FAIL_CLOSED
  - role heterogeneity not enforced (same authority category satisfies multiple
    quorum slots) => FAIL_CLOSED
  - ceremony produces no evidence artifact => FAIL_CLOSED
  - ceremony evidence artifact not signed => FAIL_CLOSED
  - drill not performed before task closes => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-074

- task_id: TSK-HARD-074
- title: Regulator access audit envelope
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-073]
- goal: Implement the regulator-accessible audit envelope that packages signed
  evidence artifacts for regulatory inspection. The regulator role is read-only —
  it cannot mutate any record. Every regulator access event is logged in an
  append-only, signed access log. This is the delivery mechanism for BoZ and
  equivalent regulatory access.
- required_deliverables:
  - regulator audit envelope schema
  - read-only regulator role enforcement
  - access log (append-only, signed)
  - envelope packaging tool
  - tasks/TSK-HARD-074/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_074.json
- verifier_command: bash scripts/audit/verify_tsk_hard_074.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_074.json
- schema_path: evidence/schemas/hardening/tsk_hard_074.schema.json
- acceptance_assertions:
  - regulator audit envelope contains: signed evidence artifacts, access log
    excerpt, package manifest with package_timestamp and signing_key_id
  - regulator role enforced at DB/API layer: any write operation (INSERT,
    UPDATE, DELETE) attempted by a regulator-role session is rejected with
    a named error (e.g. P8301 REGULATOR_WRITE_DENIED)
  - every regulator access event is logged: accessor_id, role, access_timestamp,
    session_id, artifacts_accessed[]
  - access log is append-only: no UPDATE or DELETE on access log entries;
    verified by negative-path test
  - access log is signed at each append: each log entry carries a signature
    or the log is periodically signed as a batch with Merkle proof
  - envelope packaging tool accepts: instruction_id or adjustment_id or date
    range, and produces a single signed package
  - negative-path test: regulator-role session attempting INSERT on any evidence
    table is rejected with P8301
  - negative-path test: UPDATE on access log entry is rejected
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - regulator role can mutate any record => FAIL_CLOSED
  - access log not append-only => FAIL_CLOSED
  - access log entries unsigned or unbatched for > 24h => FAIL
  - envelope produced without signing => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

### TSK-HARD-097

- task_id: TSK-HARD-097
- title: Recovery continuity proof — end-to-end DR path
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-074]
- goal: Produce evidence that the full recovery path from DR bundle retrieval
  through quorum ceremony through isolated verification is functional end-to-end.
  No step may require access to the operational runtime. At least three historical
  artifacts of distinct types must be verified. This task is the end-to-end
  integration test of the entire Wave-5 trust continuity stack.
- required_deliverables:
  - end-to-end recovery continuity test script
  - continuity evidence artifact
  - tasks/TSK-HARD-097/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_097.json
- verifier_command: bash scripts/audit/verify_tsk_hard_097.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_097.json
- schema_path: evidence/schemas/hardening/tsk_hard_097.schema.json
- acceptance_assertions:
  - end-to-end test performs these steps in order: (1) retrieve DR bundle via
    quorum ceremony (produces ceremony evidence artifact), (2) decrypt bundle
    using quorum-derived key, (3) restore PKA and canonicalization archive to
    an isolated environment, (4) verify at least three historical artifacts of
    distinct types using restored archives only, (5) confirm each verification
    produces a signed verification result
  - each of the five steps is individually evidenced and referenced in the
    continuity evidence artifact
  - continuity evidence artifact contains: test_timestamp, ceremony_evidence_ref,
    bundle_decrypted: true, artifacts_verified[], artifact_types_covered[],
    operational_runtime_used: false, verification_outcomes[], pass
  - artifact_types_covered must contain at least three distinct values
    (e.g. inquiry_event, finality_conflict_record, adjustment_approval_event)
  - evidence artifact is schema-valid against verification_continuity_event
    class (TSK-HARD-002)
  - test fails with explicit error if any step requires operational runtime
    access; the isolation constraint is machine-enforced, not relying on
    operator discipline
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any step accesses operational runtime => FAIL_CLOSED
  - fewer than three distinct artifact types verified => FAIL
  - any step not individually evidenced => FAIL
  - continuity evidence artifact not schema-valid => FAIL
  - test passes without performing quorum ceremony => FAIL_CLOSED

---

### TSK-HARD-099

- task_id: TSK-HARD-099
- title: Long-horizon audit replay continuity — five-year simulation
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-097]
- goal: Confirm that artifacts produced today remain verifiable at a five-year
  horizon using only archived materials. The simulation must identify any
  component with a shelf life shorter than five years and define the
  archive/refresh policy for that component. No dependency on any operational
  runtime component that requires active maintenance to remain valid.
- required_deliverables:
  - five-year horizon simulation test
  - shelf life risk register
  - archive/refresh policy per component with shelf life risk
  - replay continuity evidence artifact
  - tasks/TSK-HARD-099/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_099.json
- verifier_command: bash scripts/audit/verify_tsk_hard_099.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_099.json
- schema_path: evidence/schemas/hardening/tsk_hard_099.schema.json
- acceptance_assertions:
  - simulation test verifies artifacts using only: archived PKA (TSK-HARD-070),
    archived canonicalization specs (TSK-HARD-062), archived trust anchors
    (TSK-HARD-071), archived revocation material (TSK-HARD-071), archived
    verification policy (TSK-HARD-071) — no dependency on any component that
    requires active operational maintenance to remain current
  - shelf life risk register documents every archived component and its expected
    shelf life; components with shelf life < 5 years are explicitly flagged
  - for each flagged component: an archive/refresh policy is defined that
    ensures the component remains verifiable at the five-year horizon
    (e.g. annual refresh of OCSP staples, quarterly test vector re-execution)
  - replay continuity evidence contains: simulation_timestamp,
    artifacts_verified[], archived_materials_used[], shelf_life_risks_documented[],
    refresh_policies_defined[], operational_runtime_used: false, pass
  - evidence artifact is schema-valid against verification_continuity_event class
  - negative-path test: simulating the absence of one archived component causes
    the simulation to fail with a named error — not a silent pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - simulation depends on any operational runtime component => FAIL_CLOSED
  - any archived component shelf life risk not documented => FAIL
  - any flagged component lacks a defined refresh policy => FAIL
  - five-year simulation not performed => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-102

- task_id: TSK-HARD-102
- title: Wave-5 regulator continuity gate
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-099]
- goal: Produce the final Wave-5 programmatic gate confirming all trust continuity
  controls are complete, all evidence is valid, and the DR recovery path is
  proven end-to-end. This gate is a precondition for all Wave-6 productization tasks.
- required_deliverables:
  - scripts/audit/verify_tsk_hard_102.sh
  - evidence/phase1/hardening/tsk_hard_102.json
- verifier_command: bash scripts/audit/verify_tsk_hard_102.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_102.json
- schema_path: evidence/schemas/hardening/tsk_hard_102.schema.json
- acceptance_assertions:
  - gate verifier script confirms all Wave-5 task evidence files exist and
    pass=true: tsk_hard_060 through tsk_hard_074, tsk_hard_097, tsk_hard_099
  - gate evidence artifact lists all confirmed task_ids with their pass status
    and evidence_path
  - gate is deterministic: re-running with unchanged evidence produces
    identical exit code and output
  - gate script validates each Wave-5 evidence artifact against its schema
    before emitting pass — not existence + pass=true check alone
  - gate evidence artifact contains: task_id: TSK-HARD-102,
    wave5_tasks_confirmed[], all_pass: true, gate_timestamp, pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any Wave-5 evidence file missing => FAIL_CLOSED
  - any Wave-5 evidence file contains pass=false => FAIL_CLOSED
  - gate validates only existence without schema validation => FAIL_CLOSED
  - gate non-deterministic => FAIL

---

### TSK-OPS-WAVE5-EXIT-GATE

- task_id: TSK-OPS-WAVE5-EXIT-GATE
- title: Wave-5 Exit Gate
- phase: Hardening
- wave: 5
- depends_on:
    [TSK-HARD-060, TSK-HARD-061, TSK-HARD-062, TSK-HARD-070, TSK-HARD-071,
     TSK-HARD-072, TSK-HARD-073, TSK-HARD-074, TSK-HARD-097, TSK-HARD-099,
     TSK-HARD-102]
- goal: Deterministic Wave-5 pass/fail gate. All five negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Wave-6 tasks are
  BLOCKED until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave5_exit_gate.sh
  - evidence/phase1/program_wave5_exit_gate.json
  - evidence/phase1/wave5_exit/unverifiable_missing_canonicalizer.json
  - evidence/phase1/wave5_exit/pka_entry_update_blocked.json
  - evidence/phase1/wave5_exit/bundle_access_quorum_rejected.json
  - evidence/phase1/wave5_exit/regulator_write_denied.json
  - evidence/phase1/wave5_exit/dr_recovery_end_to_end_pass.json
- verifier_command: bash scripts/audit/verify_program_wave5_exit_gate.sh
- evidence_path: evidence/phase1/program_wave5_exit_gate.json
- schema_path: evidence/schemas/hardening/wave5_exit/wave5_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave5_exit/unverifiable_missing_canonicalizer.schema.json
  - evidence/schemas/hardening/wave5_exit/pka_entry_update_blocked.schema.json
  - evidence/schemas/hardening/wave5_exit/bundle_access_quorum_rejected.schema.json
  - evidence/schemas/hardening/wave5_exit/regulator_write_denied.schema.json
  - evidence/schemas/hardening/wave5_exit/dr_recovery_end_to_end_pass.schema.json
- acceptance_assertions:
  - all 5 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - specific field requirements per artifact:
    - unverifiable_missing_canonicalizer.json: contains artifact_id,
      canonicalization_version_requested, error: UNVERIFIABLE_MISSING_CANONICALIZER,
      outcome: FAIL
    - pka_entry_update_blocked.json: contains entry_id, attempted_operation: UPDATE,
      outcome: BLOCKED
    - bundle_access_quorum_rejected.json: contains ceremony_id,
      authority_categories_present[], quorum_met: false, outcome: REJECTED
    - regulator_write_denied.json: contains accessor_id, attempted_operation,
      error_code: P8301, outcome: DENIED
    - dr_recovery_end_to_end_pass.json: contains ceremony_evidence_ref,
      artifacts_verified[], operational_runtime_used: false,
      artifact_types_covered[] (minimum 3 distinct types), all_outcomes: PASS
  - Wave-6 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - dr_recovery evidence shows operational_runtime_used: true => FAIL_CLOSED
  - manual override => FAIL_CLOSED (not permitted)

---

## Wave 6 Task Packs

Wave-6 entry gate: TSK-OPS-WAVE5-EXIT-GATE must be pass=true before any Wave-6
task may be marked done.

---

### TSK-HARD-080

- task_id: TSK-HARD-080
- title: Signing scale path — batch/Merkle and HSM throughput
- phase: Hardening
- wave: 6
- depends_on: [TSK-OPS-WAVE5-EXIT-GATE]
- goal: Implement the Merkle batch signing engine for high-volume evidence artifact
  production. Define the artifact class taxonomy distinguishing individual from
  batch signing. Conduct HSM/KMS throughput load tests and degradation tests.
  Confirm that HSM or KMS region outage causes fail-closed behavior — no fallback
  to software signing.
- required_deliverables:
  - artifact class taxonomy document at docs/architecture/ARTIFACT_CLASS_TAXONOMY.md
  - Merkle batch signing engine implementation
  - HSM throughput load test with evidence artifact
  - HSM/KMS outage fail-closed tests with evidence artifacts
  - tasks/TSK-HARD-080/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_080.json
- verifier_command: bash scripts/audit/verify_tsk_hard_080.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_080.json
- schema_path: evidence/schemas/hardening/tsk_hard_080.schema.json
- acceptance_assertions:
  - artifact class taxonomy defines at minimum two classes: INDIVIDUAL_SIGNED,
    BATCH_MERKLE_SIGNED; taxonomy document is informational, schema is
    enforcement surface
  - Merkle batch signing engine: accepts a batch of artifact hashes, produces
    a Merkle root and per-leaf proof for each artifact in the batch
  - each batch artifact carries Merkle metadata per TSK-HARD-052 standard:
    merkle_root, leaf_index, merkle_proof
  - individual artifact verification using Merkle proof is confirmed correct:
    given leaf_index, merkle_proof, and merkle_root, the artifact hash is
    verified as a member of the batch
  - HSM throughput load test: load test exercises signing service at peak
    expected TPS (target TPS defined in test config); evidence artifact records:
    test_timestamp, target_tps, achieved_tps, error_rate, outcome
  - degradation test: load exceeding target TPS causes signing service to queue
    requests — not drop or corrupt them; confirmed by verifying all queued
    requests eventually produce correct signatures
  - HSM outage simulation: when HSM is unavailable, signing service fails-closed
    with named error — does not fall back to software signing; outage evidence
    artifact contains: simulated_outage_duration, fallback_attempted: false,
    outcome: FAIL_CLOSED
  - KMS region outage simulation: when KMS region is unavailable, signing
    service fails-closed — does not fall back to alternate region or software;
    region outage evidence artifact contains equivalent fields
  - negative-path test: Merkle proof for wrong leaf index fails verification
    deterministically — not a false pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - Merkle batch produces incorrect proof for any leaf => FAIL_CLOSED
  - leaf verification using proof produces false pass => FAIL_CLOSED
  - HSM outage causes fallback to software signing => FAIL_CLOSED
  - KMS region outage causes fallback => FAIL_CLOSED
  - throughput test not performed => FAIL
  - degradation test shows dropped or corrupted requests under load => FAIL_CLOSED
  - negative-path test absent => FAIL

---

### TSK-HARD-081

- task_id: TSK-HARD-081
- title: Rail Command Center v1
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-080]
- goal: Implement the Rail Command Center v1 operational dashboard with exactly
  six specified metrics/dashboards. All six are required for acceptance. Each
  dashboard has a configurable alert threshold. Threshold breach produces a
  signed alert evidence artifact. This is the primary operational interface for
  managing the Wave-1 hardening controls in production.
- required_deliverables:
  - command center UI or API with all six dashboards
  - configurable alert thresholds per dashboard
  - alert evidence artifact per threshold breach
  - tasks/TSK-HARD-081/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_081.json
- verifier_command: bash scripts/audit/verify_tsk_hard_081.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_081.json
- schema_path: evidence/schemas/hardening/tsk_hard_081.schema.json
- acceptance_assertions:
  - all six dashboards present and individually verifiable; no dashboard may
    be deferred or merged with another:
    (1) MALFORMED_RESPONSE_RATE: rolling malformed rate per rail/adapter;
        configurable window duration; visual threshold marker; fed from
        quarantine store (TSK-HARD-016)
    (2) SCHEMA_DRIFT_ALERTS: current malformed rate vs circuit-breaker threshold
        per adapter; visual indicator when rate approaches or breaches threshold;
        shows current circuit breaker state (ACTIVE or SUSPENDED)
    (3) INQUIRY_EXHAUSTION: count of instructions currently in EXHAUSTED inquiry
        state; drill-down to instruction detail; age of each EXHAUSTED state
    (4) FINALITY_CONFLICTS: count and list of instructions in FINALITY_CONFLICT
        state; age of each conflict; responsible rail_id; time in conflict
    (5) LATE_CALLBACKS: count of orphaned attestation landing zone entries grouped
        by age bucket: 0–1h, 1–24h, 24h+; drill-down per entry
    (6) MEAN_TIME_TO_CONTAINMENT: median and 95th percentile time from
        malformed/conflict event creation to operator-acknowledged containment
        action; rolling window configurable
  - each dashboard has a configurable alert threshold loaded from policy metadata
  - threshold breach produces an alert evidence artifact schema-valid against
    an appropriate hardening event class and containing: dashboard_id,
    threshold_breached, observed_value, breach_timestamp, policy_version_id
  - all six alert thresholds independently configurable; changing one threshold
    does not affect others
  - [METADATA GOVERNANCE] dashboard thresholds and window durations are loaded
    from versioned policy config; activation of new version produces evidence
    artifact; signed when signing service available; unsigned_reason if not;
    in-place edits to active version blocked; runtime references policy_version_id
  - negative-path test: driving malformed rate above dashboard-1 threshold
    produces alert evidence artifact within one rolling window interval
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the six dashboards absent => FAIL
  - any dashboard threshold not configurable => FAIL
  - threshold breach produces no alert evidence artifact => FAIL
  - alert evidence artifact not schema-valid => FAIL
  - threshold loaded from hardcoded constant => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---

### TSK-HARD-082

- task_id: TSK-HARD-082
- title: BoZ/Auditor demonstration pack — six scripted scenarios
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-081]
- goal: Implement the BoZ/Auditor demonstration pack with exactly six scripted,
  deterministic scenarios. Each scenario produces a signed evidence artifact as
  output. Each scenario script exits non-zero if expected evidence is not produced.
  The pack is the primary institutional sales and regulatory demonstration
  instrument.
- required_deliverables:
  - docs/programs/symphony-hardening/BOZ_DEMO_PACK.md
  - six scenario scripts at scripts/demo/scenario_{01..06}.sh or equivalent
  - reproducible signed evidence artifact per scenario
  - tasks/TSK-HARD-082/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_082.json
- verifier_command: bash scripts/audit/verify_tsk_hard_082.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_082.json
- schema_path: evidence/schemas/hardening/tsk_hard_082.schema.json
- acceptance_assertions:
  - BOZ_DEMO_PACK.md exists and describes all six scenarios with: scenario_id,
    title, narrative, seed_inputs, expected_evidence_artifact, script_path
  - exactly six scenario scripts implemented; none may be deferred:
    SCENARIO-01 SILENT_RAIL_CONTAINMENT: rail returns no response; system
      enters inquiry SCHEDULED→SENT→EXHAUSTED; auto-finalization blocked with
      P7301; evidence artifact produced confirming inquiry_state: EXHAUSTED
      and outcome: BLOCKED
    SCENARIO-02 MALFORMED_RESPONSE_CAPTURE: adapter receives known-malformed
      payload; quarantine record created with parser classification and
      truncation applied; evidence artifact produced; confirmed by querying
      quarantine store
    SCENARIO-03 LATE_CALLBACK_HANDLING: callback arrives after instruction
      reaches terminal state; orphaned attestation landing zone record created
      with classification: LATE_CALLBACK; instruction state unchanged; evidence
      artifact produced
    SCENARIO-04 ADJUSTMENT_WITH_LEGAL_HOLD: adjustment instruction submitted;
      AML hold flag active; execution blocked at blocked_legal_hold or
      cooling_off state; evidence artifact produced containing hold_type: AML_HOLD
      and authority_reference
    SCENARIO-05 HISTORICAL_VERIFICATION_ARCHIVE_ONLY: artifact signed under
      previous key version; verified using archived PKA and canonicalization
      archive only; no operational runtime access; signed verification result
      produced containing operational_runtime_used: false
    SCENARIO-06 DR_RECOVERY_CEREMONY: quorum of required authority categories
      accesses offline bundle; ceremony evidence artifact produced with
      participants[], roles[], authority_categories[], access_timestamp;
      isolated environment verification performed and passed
  - each scenario script: (a) accepts seed inputs as parameters for
    determinism, (b) produces a signed evidence artifact as its primary output,
    (c) exits non-zero if the expected evidence artifact is not produced,
    (d) is idempotent: running twice with same seed inputs produces equivalent
    evidence artifacts (same logical outcome, different timestamps permitted)
  - each scenario evidence artifact is schema-valid against the relevant event
    class from TSK-HARD-002 schema set
  - verifier runs all six scenarios and confirms each exits zero and produces
    schema-valid evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - fewer than six scenarios implemented => FAIL
  - any scenario script exits zero when expected evidence not produced => FAIL_CLOSED
  - any scenario evidence artifact not schema-valid => FAIL_CLOSED
  - any scenario not deterministic given same seed inputs => FAIL
  - BOZ_DEMO_PACK.md absent => FAIL

---

### TSK-HARD-090

- task_id: TSK-HARD-090
- title: QA matrix hardening completeness
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-082]
- goal: Extend the QA matrix to cover all hardening negative-path scenarios.
  The matrix is the authoritative record of what is tested. Each entry must
  reference a specific executable test. Ten scenarios are required; none may
  be deferred or combined.
- required_deliverables:
  - extended QA matrix document at docs/programs/symphony-hardening/QA_MATRIX.md
  - executable test script or test case reference per scenario
  - test coverage evidence artifact
  - tasks/TSK-HARD-090/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_090.json
- verifier_command: bash scripts/audit/verify_tsk_hard_090.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_090.json
- schema_path: evidence/schemas/hardening/tsk_hard_090.schema.json
- acceptance_assertions:
  - QA matrix exists and each entry contains: scenario_id, description,
    expected_outcome, test_script_ref (path to executable test),
    evidence_artifact_path, pass_fail_status
  - exactly ten required scenarios present; none may be absent:
    QA-01 TOXIC_PAYLOAD_INJECTION: one test per parser classification
      (TRANSPORT, PROTOCOL, SYNTAX, SEMANTIC) — four tests required
    QA-02 TRUNCATION_COLLISION: two distinct references truncating to same
      value detected as collision; collision evidence artifact produced
    QA-03 ROLE_TAMPERING_ATTEMPT: approver submits approval with manipulated
      role claim; attestation captures original role; tampered claim rejected
    QA-04 COOLING_OFF_PLUS_AML_HOLD: both active simultaneously; execution
      blocked; combined hold evidence artifact produced
    QA-05 ALIAS_COLLISION_NONCE_EXHAUSTION: nonce retry limit exhausted;
      P7801 produced; exhaustion evidence artifact produced
    QA-06 MISSING_CANONICALIZER_VERSION:
      UNVERIFIABLE_MISSING_CANONICALIZER produced; no silent pass
    QA-07 HSM_OUTAGE: signing service fails-closed; no software fallback;
      outage evidence artifact produced
    QA-08 KMS_REGION_OUTAGE: signing service fails-closed; no fallback
      to alternate region; region outage evidence artifact produced
    QA-09 DR_ARCHIVE_ACCESS_WITHOUT_QUORUM: bundle access blocked;
      rejection evidence artifact produced
    QA-10 BATCH_MERKLE_PROOF_MISSING_LEAF: verification fails
      deterministically for leaf not in batch; not a silent pass
  - each QA entry's test_script_ref points to a file that exists and is
    executable; verifier confirms existence of all referenced scripts
  - all ten scenarios pass when verifier runs the test suite
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the ten required scenarios absent from QA matrix => FAIL
  - any scenario_id entry lacks a test_script_ref => FAIL
  - any referenced test script does not exist or is not executable => FAIL
  - any QA scenario test fails => FAIL
  - QA-01 covers fewer than all four parser classification types => FAIL

---

### TSK-HARD-091

- task_id: TSK-HARD-091
- title: Feature-flag rollout evidence controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-090]
- goal: Implement the feature flag registry for all hardening components with
  phased rollout controls. Flag state changes produce evidence artifacts. The
  rollout plan covers phased enablement per hardening wave. No hardening
  component may be enabled in production without a registered flag and a
  documented rollout stage.
- required_deliverables:
  - feature flag registry (persistent, queryable)
  - rollout plan document at docs/programs/symphony-hardening/ROLLOUT_PLAN.md
  - flag state change evidence artifacts
  - tasks/TSK-HARD-091/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_091.json
- verifier_command: bash scripts/audit/verify_tsk_hard_091.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_091.json
- schema_path: evidence/schemas/hardening/tsk_hard_091.schema.json
- acceptance_assertions:
  - feature flag registry documents all hardening component flags with: flag_id,
    component, wave, default_state, current_state, rollout_stage, owner
  - every hardening component introduced in Waves 1–6 has a corresponding
    flag entry; verifier confirms by cross-referencing flag registry against
    TRACEABILITY_MATRIX
  - flag state changes produce evidence artifacts containing: flag_id,
    previous_state, new_state, changed_by, change_timestamp, justification
  - flag state change evidence artifacts are append-only and independently
    queryable
  - ROLLOUT_PLAN.md exists and defines rollout stages per wave with go/no-go
    criteria for each stage
  - no hardening component is enabled in production without its flag being in
    a registered ENABLED rollout stage per ROLLOUT_PLAN.md
  - negative-path test: enabling a component without a registered flag entry
    is blocked and produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any hardening component lacks a flag entry => FAIL
  - flag state change produces no evidence artifact => FAIL
  - flag enabled without registered rollout stage => FAIL_CLOSED
  - ROLLOUT_PLAN.md absent => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-092

- task_id: TSK-HARD-092
- title: Operator safety UX controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-091]
- goal: Implement operator-facing safety controls for all hardening-related
  high-risk actions. High-risk actions require secondary approval from a distinct
  operator role. All operator safety actions produce evidence artifacts. This
  is the UX enforcement complement to the technical controls in Waves 1–5.
- required_deliverables:
  - operator safety controls document at
    docs/programs/symphony-hardening/OPERATOR_SAFETY_CONTROLS.md
  - secondary approval enforcement for high-risk actions
  - confirmation step with evidence artifact for all controlled actions
  - tasks/TSK-HARD-092/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_092.json
- verifier_command: bash scripts/audit/verify_tsk_hard_092.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_092.json
- schema_path: evidence/schemas/hardening/tsk_hard_092.schema.json
- acceptance_assertions:
  - OPERATOR_SAFETY_CONTROLS.md exists and lists all controlled operator actions
    with: action_id, description, risk_level (HIGH/MEDIUM), confirmation_required,
    secondary_approval_required, evidence_artifact_produced
  - high-risk actions that require secondary approval from a distinct operator
    role at minimum: circuit breaker adapter resume, FINALITY_CONFLICT manual
    resolution, legal hold removal, DR bundle access (ceremony), policy bundle
    activation
  - secondary approval enforced: the approving operator must have a different
    operator_id and a different role from the initiating operator; same-role
    approval does not satisfy the requirement
  - every controlled operator action (regardless of risk level) produces a
    confirmation evidence artifact containing: action_type, initiator_id,
    initiator_role, approver_id (if applicable), approver_role (if applicable),
    confirmation_timestamp, justification_text, outcome
  - negative-path test: high-risk action attempted without secondary approval
    is blocked and produces rejection evidence containing action_type and
    outcome: SECONDARY_APPROVAL_REQUIRED
  - negative-path test: secondary approval from same-role operator is rejected
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any high-risk action permits execution without secondary approval => FAIL_CLOSED
  - secondary approval from same-role operator accepted => FAIL_CLOSED
  - any controlled action produces no evidence artifact => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-093

- task_id: TSK-HARD-093
- title: Reporting continuity and activation controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-092]
- goal: Ensure all hardening-related regulatory report outputs are signed,
  activation-controlled via signed policy bundles, and continuous. A gap in
  the report sequence produces an alert — not a silent skip. This closes the
  regulatory reporting surface of the hardening program.
- required_deliverables:
  - signed report output enforcement in reporting pipeline
  - policy bundle activation control for each report type
  - report sequence gap detection and alerting
  - tasks/TSK-HARD-093/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_093.json
- verifier_command: bash scripts/audit/verify_tsk_hard_093.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_093.json
- schema_path: evidence/schemas/hardening/tsk_hard_093.schema.json
- acceptance_assertions:
  - every hardening-related regulatory report output is signed per TSK-HARD-052
    metadata standard before delivery
  - report activation is controlled via a signed policy bundle (TSK-HARD-011B);
    report generation blocked if governing policy bundle is unsigned or inactive
  - report sequence gap detection: each report type has a sequence number or
    scheduled interval; a missing report or out-of-sequence report produces
    an alert evidence artifact — not a silent skip
  - report gap alert evidence artifact contains: report_type, expected_sequence,
    detected_gap, alert_timestamp, alert_delivered: true/false
  - report gaps are recoverable: gap alert is resolved by either producing the
    missing report (with backdated_report: true flag) or recording an explicit
    gap acknowledgement with operator justification
  - negative-path test: deliberately skipping one report in a sequence produces
    a gap alert evidence artifact within one scheduled interval
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - report output unsigned => FAIL
  - report gap produces silent skip => FAIL_CLOSED
  - report activation not controlled by signed policy bundle => FAIL
  - gap alert evidence artifact not produced => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-095

- task_id: TSK-HARD-095
- title: BoZ submission audit trail primitives
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-093]
- goal: Implement the audit trail primitives for all BoZ regulatory submissions.
  Every submission produces an evidence artifact. Submission evidence is
  append-only. Every read of submission evidence is access-logged.
- required_deliverables:
  - BoZ submission evidence schema at
    evidence/schemas/hardening/boz_submission_event.schema.json
  - submission evidence artifact per submission
  - append-only enforcement on submission evidence store
  - access log for submission evidence reads
  - tasks/TSK-HARD-095/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_095.json
- verifier_command: bash scripts/audit/verify_tsk_hard_095.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_095.json
- schema_path: evidence/schemas/hardening/tsk_hard_095.schema.json
- acceptance_assertions:
  - every BoZ regulatory submission produces an evidence artifact schema-valid
    against boz_submission_event schema and containing: submission_id,
    report_type, submission_timestamp, signing_key_id, submission_hash,
    outcome, assurance_tier
  - submission evidence is stored in an append-only store; UPDATE and DELETE
    on submission evidence records are blocked at DB layer
  - access log records every read of submission evidence: accessor_id,
    role, access_timestamp, session_id, submission_ids_accessed[]
  - access log is itself append-only and signed
  - submission evidence and its access log are independently queryable
  - negative-path test: attempting UPDATE on a submission evidence record
    is rejected and produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - submission produces no evidence artifact => FAIL_CLOSED
  - submission evidence store not append-only => FAIL_CLOSED
  - access log absent or not append-only => FAIL_CLOSED
  - access log unsigned => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-098

- task_id: TSK-HARD-098
- title: Penalty defense pack generation
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-095]
- goal: Implement the penalty defense pack generator for regulatory dispute
  scenarios. Given an instruction_id, adjustment_id, or submission_id, the
  generator produces a single signed JSON pack containing the complete evidence
  chain for that entity. The pack contains no raw PII. This is the primary
  artifact used in regulatory penalty proceedings and commercial disputes.
- required_deliverables:
  - defense pack generator script at scripts/tools/generate_penalty_defense_pack.sh
    or equivalent
  - defense pack schema at evidence/schemas/hardening/penalty_defense_pack.schema.json
  - sample defense pack evidence artifact
  - tasks/TSK-HARD-098/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_098.json
- verifier_command: bash scripts/audit/verify_tsk_hard_098.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_098.json
- schema_path: evidence/schemas/hardening/tsk_hard_098.schema.json
- acceptance_assertions:
  - generator accepts as input: instruction_id OR adjustment_id OR submission_id
    (exactly one required; multiple inputs rejected)
  - output is a single signed JSON pack schema-valid against
    penalty_defense_pack.schema.json and containing: pack_id, generated_at,
    signing_key_id, assurance_tier, entity_type, entity_id,
    evidence_artifacts[], instruction_lifecycle_timeline,
    approval_trail (if adjustment), submission_record (if submission),
    verification_results[]
  - pack contains no raw PII: all subject references are pseudonymous tokens
    (from TSK-HARD-040); verifier confirms by scanning pack for any field
    matching known PII patterns
  - pack is signed with key class EASK (TSK-HARD-050) at generation time
  - generator exits non-zero if it cannot produce a complete and schema-valid
    pack; partial packs not permitted
  - verification_results[] in pack contains at least one verification result
    confirming the primary evidence artifact is valid
  - negative-path test: calling generator with unknown entity_id produces
    named error and exits non-zero; no partial pack produced
  - negative-path test: generated pack fails schema validation if pack is
    manually edited (confirming schema enforcement is not bypassed)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - pack contains raw PII => FAIL_CLOSED
  - pack not signed => FAIL_CLOSED
  - generator produces partial pack on incomplete evidence => FAIL_CLOSED
  - pack fails schema validation => FAIL
  - generator exits zero on unknown entity_id => FAIL
  - negative-path tests absent => FAIL

---

### TSK-HARD-040

- task_id: TSK-HARD-040
- title: Privacy-preserving audit tokenization
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-098]
- goal: Complete PII vault decoupling. Implement the tokenization scheme that
  maps PII subjects to stable pseudonymous tokens. All evidence artifacts and
  audit tables must contain tokens, not raw PII. Audit query responses return
  tokenized references. The token is stable per subject per audit period.
- required_deliverables:
  - tokenization scheme implementation
  - vault decoupling completion (no raw PII in evidence or audit tables)
  - audit query interface returning tokenized references
  - tasks/TSK-HARD-040/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_040.json
- verifier_command: bash scripts/audit/verify_tsk_hard_040.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_040.json
- schema_path: evidence/schemas/hardening/tsk_hard_040.schema.json
- acceptance_assertions:
  - PII vault decoupling complete: verifier scans all evidence artifact schemas
    and audit table schemas for known PII field names (name, id_number,
    phone, email, account_number equivalents); none present in non-vault tables
  - tokenization scheme: PII subject → pseudonymous token mapping is:
    (a) deterministic: same subject always maps to same token within an
    audit period, (b) one-way: token cannot be reversed without vault access,
    (c) stable per audit period: token does not change within a period even if
    subject details change
  - audit query interface: querying by token returns all evidence artifacts
    for that token; no raw PII returned in query response
  - audit query response includes: token, subject_status (LIVE or PURGED),
    evidence_artifacts[] — the boolean status is returned without revealing identity
  - negative-path test: scanning evidence artifact tables directly (without
    vault) returns no resolvable PII
  - negative-path test: audit query for an unknown token returns empty result
    or NOT_FOUND — not an error that reveals vault internals
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - raw PII present in any evidence artifact or audit table => FAIL_CLOSED
  - token not stable within audit period => FAIL
  - audit query returns raw PII in response => FAIL_CLOSED
  - tokenization reversible without vault access => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

### TSK-HARD-041

- task_id: TSK-HARD-041
- title: Erasure workflow and key shredding controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-040]
- goal: Implement per-user, per-period salt management and cryptographic
  shredding on erasure request. Erasure renders subject tokens unresolvable
  by deleting the salt from the vault. Evidence artifacts are preserved —
  they receive a purge_marker that links to the erasure evidence artifact.
  The evidence chain remains intact and auditable after erasure.
- required_deliverables:
  - per-user per-period salt management in vault
  - erasure request workflow with cryptographic shredding
  - purge_marker implementation in evidence artifacts
  - erasure evidence artifact
  - tasks/TSK-HARD-041/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_041.json
- verifier_command: bash scripts/audit/verify_tsk_hard_041.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_041.json
- schema_path: evidence/schemas/hardening/tsk_hard_041.schema.json
- acceptance_assertions:
  - per-user, per-period salt exists in vault; salt rotation supported within
    an audit period without invalidating existing tokens for that period
  - erasure request triggers: (1) salt deleted from vault (cryptographic
    shred), (2) all evidence artifacts for that subject token receive a
    purge_marker field replacing the token reference
  - erasure does not delete evidence artifacts; artifacts remain intact
    with purge_marker containing: erasure_id, erasure_timestamp,
    subject_token_hash (not the token itself), method: CRYPTOGRAPHIC_SHRED
  - purge_marker links to the erasure evidence artifact by erasure_id;
    erasure evidence artifact is independently queryable by erasure_id
  - erasure evidence artifact contains: erasure_id, erasure_timestamp,
    requesting_operator_id, subject_token_hash, method: CRYPTOGRAPHIC_SHRED,
    artifacts_purge_marked_count, outcome
  - post-erasure: subject token is unresolvable; vault lookup for the
    erased subject returns NOT_FOUND
  - post-erasure: audit query for the erased subject token returns the
    purge_marker, not resolved subject data
  - negative-path test: after erasure, vault lookup for erased subject
    returns NOT_FOUND; audit query returns purge_marker; no raw subject
    data accessible
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - erasure deletes evidence artifacts => FAIL_CLOSED
  - token resolvable after salt shredding => FAIL_CLOSED
  - purge_marker absent from any evidence artifact after erasure => FAIL
  - erasure evidence artifact not independently queryable => FAIL
  - negative-path test absent => FAIL

---

### TSK-HARD-042

- task_id: TSK-HARD-042
- title: Privacy-preserving audit query continuity
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-041]
- goal: Confirm that audit query responses remain coherent, structured, and
  evidenced after erasure events. A query for an erased subject must return
  a structured PURGED placeholder — not a 404, not an error, not an empty
  result. The purge evidence linkage must be queryable. The evidence chain
  continuity is documented, not a silent hole.
- required_deliverables:
  - structured PURGED placeholder response for erased subjects
  - purge evidence linkage (queryable by purge_evidence_ref)
  - evidence chain continuity documentation
  - post-erasure query test
  - tasks/TSK-HARD-042/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_042.json
- verifier_command: bash scripts/audit/verify_tsk_hard_042.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_042.json
- schema_path: evidence/schemas/hardening/tsk_hard_042.schema.json
- acceptance_assertions:
  - audit query for an erased subject token returns a structured placeholder:
    {token_hash, status: PURGED, purge_evidence_ref, erasure_timestamp}
  - structured placeholder is schema-valid and consistently returned for all
    erased subjects — no variation in response structure
  - purge evidence linkage: given purge_evidence_ref from the placeholder,
    the erasure evidence artifact from TSK-HARD-041 is retrievable; linkage
    confirmed by querying by erasure_id
  - evidence chain continuity confirmed: the gap left by erasure is documented
    in the evidence chain with a purge_marker and linkage; it is not a silent
    hole visible to auditors
  - negative-path test: querying an erased subject does not return HTTP 404 or
    any unstructured error; returns structured PURGED placeholder
  - negative-path test: querying a non-existent (never-registered) subject
    token returns NOT_FOUND (distinct from PURGED) — to confirm the two states
    are distinguishable
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - erased subject query returns 404 or unstructured error => FAIL
  - PURGED and NOT_FOUND responses are indistinguishable => FAIL
  - structured placeholder absent or non-schema-valid => FAIL
  - purge evidence linkage not queryable => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

### TSK-HARD-100

- task_id: TSK-HARD-100
- title: Anti-abuse controls and retraction safety
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-042]
- goal: Implement rate limiting on all high-risk operator and automated actions.
  Implement safe retraction paths for reversible hardening actions. Rate limit
  breaches produce evidence artifacts and block further attempts. Retraction
  actions require secondary approval and produce immutable evidence artifacts.
  Scope must be confirmed in EXEC_LOG.md before implementation begins.
- required_deliverables:
  - anti-abuse control taxonomy document at
    docs/programs/symphony-hardening/ANTI_ABUSE_CONTROLS.md
  - rate limiting per controlled action type
  - rate limit breach evidence artifacts
  - retraction workflow with secondary approval
  - retraction evidence artifacts (immutable)
  - tasks/TSK-HARD-100/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_100.json
- verifier_command: bash scripts/audit/verify_tsk_hard_100.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_100.json
- schema_path: evidence/schemas/hardening/tsk_hard_100.schema.json
- acceptance_assertions:
  - EXEC_LOG.md confirms scope of controlled action types before implementation
    begins; any scope change requires a DECISION_LOG.md entry
  - ANTI_ABUSE_CONTROLS.md exists and documents: controlled_action_types[],
    rate_limit_per_action (requests per window), window_duration,
    breach_action (block and evidence), retraction_eligible_actions[]
  - rate limiting applied to at minimum: adjustment submission, adjustment
    approval, circuit breaker override, erasure request, legal hold activation,
    DR bundle access request
  - rate limit configuration loaded from policy metadata (not hardcoded)
  - rate limit breach: further attempts blocked for remainder of window;
    breach evidence artifact produced containing: action_type, actor_id,
    breach_timestamp, limit_threshold, observed_count, window_duration,
    outcome: RATE_LIMITED
  - retraction of a hardening action (e.g. legal hold removal, circuit breaker
    resume, flag disable) requires: secondary approval from distinct operator
    role, justification text, produces retraction evidence artifact
  - retraction evidence artifact is immutable once created: P7101-equivalent
    trigger blocks UPDATE/DELETE on retraction records
  - [METADATA GOVERNANCE] rate limits and window durations loaded from versioned
    policy config; activation produces evidence artifact; signed when available;
    unsigned_reason if not; in-place edits to active version blocked; runtime
    references policy_version_id
  - negative-path test: exceeding rate limit on any controlled action blocks
    further attempts and produces breach evidence artifact
  - negative-path test: retraction without secondary approval is blocked and
    produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - rate limiting absent from any controlled action type => FAIL_CLOSED
  - rate limit hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - retraction requires no secondary approval => FAIL_CLOSED
  - retraction evidence artifact mutable => FAIL_CLOSED
  - rate limit breach produces no evidence artifact => FAIL
  - scope not confirmed in EXEC_LOG.md before implementation => FAIL_REVIEW
  - negative-path tests absent => FAIL

---

### TSK-OPS-WAVE6-EXIT-GATE

- task_id: TSK-OPS-WAVE6-EXIT-GATE
- title: Wave-6 Exit Gate — Hardening Program Complete
- phase: Hardening
- wave: 6
- depends_on:
    [TSK-HARD-080, TSK-HARD-081, TSK-HARD-082, TSK-HARD-090, TSK-HARD-091,
     TSK-HARD-092, TSK-HARD-093, TSK-HARD-095, TSK-HARD-098, TSK-HARD-040,
     TSK-HARD-041, TSK-HARD-042, TSK-HARD-100]
- goal: Deterministic hardening program completion gate. All six negative-path
  evidence artifacts must be present, schema-valid, and pass=true. Passing this
  gate constitutes completion of the hardening program. The program may not claim
  "evidence-grade" institutional status until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave6_exit_gate.sh
  - evidence/phase1/program_wave6_exit_gate.json
  - evidence/phase1/wave6_exit/hsm_outage_fail_closed.json
  - evidence/phase1/wave6_exit/boz_scenario_all_six_pass.json
  - evidence/phase1/wave6_exit/pii_absent_from_evidence_tables.json
  - evidence/phase1/wave6_exit/erased_subject_purge_placeholder.json
  - evidence/phase1/wave6_exit/rate_limit_breach_blocked.json
  - evidence/phase1/wave6_exit/retraction_secondary_approval_enforced.json
- verifier_command: bash scripts/audit/verify_program_wave6_exit_gate.sh
- evidence_path: evidence/phase1/program_wave6_exit_gate.json
- schema_path: evidence/schemas/hardening/wave6_exit/wave6_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave6_exit/hsm_outage_fail_closed.schema.json
  - evidence/schemas/hardening/wave6_exit/boz_scenario_all_six_pass.schema.json
  - evidence/schemas/hardening/wave6_exit/pii_absent_from_evidence_tables.schema.json
  - evidence/schemas/hardening/wave6_exit/erased_subject_purge_placeholder.schema.json
  - evidence/schemas/hardening/wave6_exit/rate_limit_breach_blocked.schema.json
  - evidence/schemas/hardening/wave6_exit/retraction_secondary_approval_enforced.schema.json
- acceptance_assertions:
  - all 6 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - gate script exits non-zero if any artifact is missing, fails schema
    validation, or contains pass=false
  - gate script explicitly checks all prior wave exit gate evidence artifacts
    (program_wave1 through program_wave5) and confirms each has pass=true;
    transitive depends_on coverage is not sufficient — script must verify
    each by reading the artifacts directly
  - gate script explicitly checks evidence/phase1/hardening/tsk_hard_102.json
    exists and contains pass=true; TSK-HARD-102 is the Wave-5 regulator
    continuity gate and is a separate check from program_wave5_exit_gate.json;
    a gate script that checks only the wave exit gate artifact and omits
    tsk_hard_102.json check is defective (FAIL_CLOSED)
  - specific field requirements per artifact:
    - hsm_outage_fail_closed.json: contains simulated_outage_duration,
      fallback_attempted: false, outcome: FAIL_CLOSED
    - boz_scenario_all_six_pass.json: contains scenario_ids[] (all six),
      all_exits_zero: true, all_evidence_schema_valid: true
    - pii_absent_from_evidence_tables.json: contains tables_scanned[],
      pii_fields_found: 0, scan_timestamp
    - erased_subject_purge_placeholder.json: contains token_hash,
      status: PURGED, purge_evidence_ref, query_returned_404: false
    - rate_limit_breach_blocked.json: contains action_type, actor_id,
      outcome: RATE_LIMITED, breach_evidence_produced: true
    - retraction_secondary_approval_enforced.json: contains action_type,
      initiator_id, approval_attempted_without_secondary: true,
      outcome: SECONDARY_APPROVAL_REQUIRED
  - gate evidence artifact contains: hardening_program_complete: true,
    all_waves_confirmed: [1,2,3,4,5,6], tsk_hard_102_confirmed: true,
    gate_timestamp
  - hardening program is not considered complete until this gate passes;
    no claim of "evidence-grade" institutional status may be made until
    this artifact exists with pass=true and hardening_program_complete: true
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - any artifact contains pass=false => FAIL_CLOSED
  - tsk_hard_102.json absent or pass=false => FAIL_CLOSED
  - any prior wave exit gate artifact absent or pass=false => FAIL_CLOSED
  - gate emits hardening_program_complete: true before all wave exit gates
    and tsk_hard_102 have been confirmed => FAIL_CLOSED (gate script is defective)
  - manual override => FAIL_CLOSED (not permitted)
