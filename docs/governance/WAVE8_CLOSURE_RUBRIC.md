# Wave 8 Closure Rubric

**Status:** Authoritative
**Date:** 2026-04-29
**Related Tasks:** TSK-P2-W8-GOV-001

## Purpose

This rubric defines the authoritative closure criteria for Wave 8 tasks. All Wave 8 completion claims must satisfy this rubric.

## Authoritative Boundary

**Table:** `asset_batches`

Wave 8 completion is measured **only** at the `asset_batches` boundary. No other table or surface may claim Wave 8 completion authority.

## Closure Requirements

### 1. Deliverable Completeness

A task is incomplete unless:

- All deliverables specified in the task's PLAN.md exist.
- All deliverables are in the correct location with the correct filename.
- All deliverables contain the required content as specified in acceptance criteria.

### 2. Verification Pass

A task is incomplete unless:

- The task-specific verifier script exists and is executable.
- The verifier script passes without errors.
- The verifier produces evidence with all required fields.

### 3. Evidence Completeness

A task is incomplete unless the evidence file contains:

- `task_id`: The task identifier
- `git_sha`: The Git commit SHA of the implementation
- `timestamp_utc`: UTC timestamp of verification
- `status`: Pass/fail status
- `checks`: List of verification checks performed
- `observed_paths`: List of file paths observed during verification
- `observed_hashes`: Hashes of observed files
- `command_outputs`: Output of verification commands
- `execution_trace`: Trace of verification execution

### 4. Regulated Surface Compliance

For tasks touching regulated surfaces:

- Stage A approval metadata exists before any regulated-surface edit.
- Approval metadata conforms to approval_metadata.schema.json.
- Conformance check passes with `--mode=stage-a --branch=<branch-name>`.
- EXEC_LOG.md is append-only and carries remediation trace markers.

### 5. Remediation Trace Compliance

For tasks requiring remediation trace:

- EXEC_LOG.md contains required markers: failure_signature, origin_task_id, repro_command, verification_commands_run, final_status.
- Markers are appended-only (no deletion or modification of existing markers).
- Markers are present at the time of regulated-surface edits.

### 6. Contract Conformance

For tasks implementing contract-defined behavior:

- Implementation conforms to the relevant contract document (CANONICAL_ATTESTATION_PAYLOAD_v1.md, TRANSITION_HASH_CONTRACT.md, ED25519_SIGNING_CONTRACT.md).
- SQL runtime behavior matches contract-defined semantics.
- No implementation drift from contract requirements.

### 7. Single Enforcement Domain

A task is incomplete unless:

- The task is constrained to one primary enforcement domain.
- The task does not span multiple enforcement domains.
- If implementation reveals a second enforcement domain, the task is split into separate packs.

### 8. Boundary Enforcement

For database tasks:

- The migration executes at the `asset_batches` boundary.
- The verifier proves PostgreSQL accepts or rejects writes at `asset_batches`.
- No detached or helper-only verification is accepted.

### 9. Evidence Admissibility

A task is incomplete unless:

- Evidence satisfies the Wave 8 Evidence Admissibility Policy.
- No inadmissible proof patterns are used (see WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md).
- Reflection-only proof, toy-crypto proof, and wrapper-only branch markers are rejected.

## Closure Claim Process

To claim Wave 8 completion for a task:

1. Complete all deliverables as specified in PLAN.md.
2. Run the task-specific verifier and ensure it passes.
3. Generate complete evidence with all required fields.
4. Satisfy regulated surface compliance (if applicable).
5. Satisfy remediation trace compliance (if applicable).
6. Verify contract conformance (if applicable).
7. Verify single enforcement domain compliance.
8. Verify boundary enforcement (if database task).
9. Verify evidence admissibility.
10. Update task status in WAVE8_TASK_STATUS_MATRIX.md to "True-Complete".

## Closure Revocation

A closure claim is revoked if:

- Any closure requirement is later found to be unsatisfied.
- Evidence is found to be falsified or incomplete.
- Regulated surface edits are made without required approval.
- Implementation drifts from contract requirements.
- Inadmissible proof patterns are discovered.

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_TASK_STATUS_MATRIX.md
- WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md
- WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md
- WAVE8_MIGRATION_HEAD_TRUTH_TABLE.md
