# TSK-P2-PREAUTH-003-REM-04B PLAN — Register INV-EXEC-TRUTH-001 in docs/security/**

Task: TSK-P2-PREAUTH-003-REM-04B
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-PREAUTH-003-REM-04
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.SECURITY_DOCS_UNREGISTERED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Register INV-EXEC-TRUTH-001 on the two `docs/security/**` surfaces that Security Guardian owns per AGENTS.md path authority: `docs/security/THREAT_MODEL.md` (threat entry for execution-record tamper) and `docs/security/COMPLIANCE_MAP.md` (audit-control mapping row). Both additions cross-reference the enforcement path (`scripts/db/verify_execution_truth_anchor.sh`) produced by REM-05 and the invariant block landed by REM-04.

This task exists because the original REM-04 mixed docs/invariants/** (INVARIANTS_CURATOR) with docs/security/** (SECURITY_GUARDIAN). Devin Review comment `BUG_pr-review-job-c4fc938f95fc4692ac528a10081cda97_0002` flagged that as a path-authority violation; splitting REM-04 into REM-04 (invariants-only) and REM-04B (security-only) keeps each task under a single owner role.

---

## Architectural Context

Invariant registration has three surfaces in Symphony:

1. `docs/invariants/INVARIANTS_MANIFEST.yml` + `INVARIANTS_IMPLEMENTED.md` — machine-readable registry, owned by INVARIANTS_CURATOR. This is REM-04.
2. `docs/security/THREAT_MODEL.md` — human-readable threat catalogue used by security review, owned by SECURITY_GUARDIAN. This is REM-04B.
3. `docs/security/COMPLIANCE_MAP.md` — audit-control-to-invariant mapping used by compliance review, owned by SECURITY_GUARDIAN. This is REM-04B.

The three surfaces must agree on the enforcement/verification pointers; divergence is itself an audit finding. This task does not re-prove the DB-level invariant (that's REM-03/REM-05) and does not register the YAML block (that's REM-04) — it only makes the security-review surface reflect the same facts.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-REM-04` is `status=completed`; the INV-EXEC-TRUTH-001 block exists in `docs/invariants/INVARIANTS_MANIFEST.yml`.
- [ ] `scripts/db/verify_execution_truth_anchor.sh` exists on disk (REM-05 landed).
- [ ] `docs/security/THREAT_MODEL.md` and `docs/security/COMPLIANCE_MAP.md` exist (pre-existing governance files).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/security/THREAT_MODEL.md` | MODIFY | Append `execution-record tamper` threat entry referencing INV-EXEC-TRUTH-001 |
| `docs/security/COMPLIANCE_MAP.md` | MODIFY | Append audit-control row referencing INV-EXEC-TRUTH-001 |
| `scripts/audit/verify_invariant_exec_truth_001_security_docs.sh` | CREATE | Grep-based verifier emitting evidence JSON |
| `evidence/phase2/tsk_p2_preauth_003_rem_04b.json` | CREATE | Emitted by the security-docs verifier |
| `tasks/TSK-P2-PREAUTH-003-REM-04B/meta.yml` | CREATE | Task meta |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-04B/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-04B/EXEC_LOG.md` | CREATE | Append-only record |

`out_of_scope`:
- `docs/invariants/**` (INVARIANTS_CURATOR only, covered by REM-04).
- `scripts/db/**` (DB_FOUNDATION only).
- `scripts/dev/pre_ci.sh` and `scripts/audit/run_invariants_fast_checks.sh` (CI wiring is REM-05B).

---

## Stop Conditions

- `docs/invariants/INVARIANTS_MANIFEST.yml` lacks the INV-EXEC-TRUTH-001 block — STOP, REM-04 has not landed.
- `scripts/db/verify_execution_truth_anchor.sh` is missing — STOP, REM-05 has not landed.
- Edit lands in `docs/invariants/**` or `scripts/db/**` — STOP (path-authority violation).
- Threat entry references a lifecycle / retry / state-machine threat — STOP, that is the lifecycle REM's surface, not Wave 3.

---

## Implementation Steps

### Step 1: Append the threat entry

**What:** `[ID tsk_p2_preauth_003_rem_04b_work_item_01]` Append a threat entry to `docs/security/THREAT_MODEL.md` following the document's existing entry format. The entry must include:

- Title: `execution-record tamper`
- Assets: `execution_records.*` (all columns of the immutable ledger)
- Attack vectors: (a) UPDATE or DELETE after INSERT; (b) retroactive rebinding of `interpretation_version_id` to a pack that was not active at `execution_timestamp`; (c) insertion of rows with NULL determinism columns bypassing UNIQUE detection.
- Mitigation: `INV-EXEC-TRUTH-001` — NOT NULL + UNIQUE determinism + append-only trigger `execution_records_append_only` (GF056) + temporal-binding trigger `execution_records_temporal_binding` (GF058).
- Verifier: `scripts/db/verify_execution_truth_anchor.sh`.
- Evidence pointer: `evidence/phase2/tsk_p2_preauth_003_rem_05.json`.

**Acceptance:** `grep -q 'execution-record tamper' docs/security/THREAT_MODEL.md` and `grep -q 'INV-EXEC-TRUTH-001' docs/security/THREAT_MODEL.md` both return 0.

### Step 2: Append the compliance-map row

**What:** `[ID tsk_p2_preauth_003_rem_04b_work_item_02]` Append a row to `docs/security/COMPLIANCE_MAP.md` mapping an external audit control (SOC2 CC7.2 or local regulator equivalent already present in the file) to INV-EXEC-TRUTH-001 with enforcement pointer `scripts/db/verify_execution_truth_anchor.sh`.

**Acceptance:** `grep -q 'INV-EXEC-TRUTH-001' docs/security/COMPLIANCE_MAP.md` returns 0.

### Step 3: Author the security-docs verifier

**What:** `[ID tsk_p2_preauth_003_rem_04b_work_item_03]` Create `scripts/audit/verify_invariant_exec_truth_001_security_docs.sh`:

1. `#!/usr/bin/env bash` + `set -Eeuo pipefail`.
2. Assert both files exist.
3. Grep for `execution-record tamper` and `INV-EXEC-TRUTH-001` in THREAT_MODEL.md.
4. Grep for `INV-EXEC-TRUTH-001` in COMPLIANCE_MAP.md.
5. Emit `evidence/phase2/tsk_p2_preauth_003_rem_04b.json` with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes` (SHA-256 of each surface), `command_outputs` (grep results), `execution_trace`, `threat_model_present` (bool), `compliance_map_present` (bool).
6. Exit 0 iff both booleans are true.

**Acceptance:** `PRE_CI_CONTEXT=1 bash scripts/audit/verify_invariant_exec_truth_001_security_docs.sh` exits 0 and the evidence JSON parses with `jq -e '.status == "PASS"'`.

---

## Negative Tests (required before status leaves `planned`)

- **N1:** remove the `INV-EXEC-TRUTH-001` reference from `THREAT_MODEL.md`; re-run the verifier; must exit non-zero with `threat_model_present=false`.
- **N2:** remove the `INV-EXEC-TRUTH-001` row from `COMPLIANCE_MAP.md`; re-run; must exit non-zero with `compliance_map_present=false`.

---

## Proof Guarantees

- `THREAT_MODEL.md` carries an `execution-record tamper` entry whose mitigation is INV-EXEC-TRUTH-001.
- `COMPLIANCE_MAP.md` carries a row mapping an external audit control to INV-EXEC-TRUTH-001.
- Security-docs verifier emits PASS evidence with both presence booleans true.

## Proof Limitations

- This task is documentation only; enforcement lives at the DB layer (REM-03) and verifier layer (REM-05). A passing evidence JSON here proves registration, not that the underlying controls are active.
- Compliance control mapping is asserted by grep, not audit-validated; external auditor sign-off is out of scope.
- THREAT_MODEL.md is a human-review artefact and does not have a machine schema; the verifier only greps for required anchors.

## Out of Scope

- `docs/invariants/**` (REM-04).
- Verifier authorship (REM-05).
- CI wiring (REM-05B).
- Lifecycle / retry / execution_state (REM-2026-04-20_execution-lifecycle).

---

## Evidence

- `evidence/phase2/tsk_p2_preauth_003_rem_04b.json` — required fields listed under Step 3.

---

## DRD / Remediation markers

- `failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.SECURITY_DOCS_UNREGISTERED`
- `origin_task_id: TSK-P2-PREAUTH-003-REM-04`
- `repro_command: bash scripts/audit/verify_invariant_exec_truth_001_security_docs.sh`
- `first_observed_utc: 2026-04-20T00:00:00Z`
- `remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md`
- Two-strike rule applies: if the grep verifier fails on a second attempt, open a remediation branch rather than patching in place.
