# TSK-P2-PREAUTH-003-REM-04 PLAN — Register INV-EXEC-TRUTH-001 in docs/invariants/**

Task: TSK-P2-PREAUTH-003-REM-04
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-PREAUTH-003-REM-05
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.INVARIANT_UNREGISTERED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Register `INV-EXEC-TRUTH-001` in `docs/invariants/INVARIANTS_MANIFEST.yml` with `status=implemented` and add a matching row to `docs/invariants/INVARIANTS_IMPLEMENTED.md`. Registration is fail-closed: it only proceeds when REM-05 evidence is present and fresh; otherwise the registration verifier exits non-zero and this task's status stays `planned`.

Security-review surfaces under `docs/security/**` (THREAT_MODEL.md threat entry and COMPLIANCE_MAP.md control row) are owned by SECURITY_GUARDIAN and registered via the sibling task `TSK-P2-PREAUTH-003-REM-04B` per the AGENTS.md path-authority split. REM-04B blocks the `checkpoint/EXEC-TRUTH-REM` checkpoint.

---

## Architectural Context

Per the operation manual and the invariants curator role (`AGENTS.md` §Invariants Curator Agent), no invariant is "implemented" unless enforcement + verification evidence exists. REM-03 installs the DB-layer enforcement. REM-05 produces the verifier plus the fresh evidence. Only then does this task flip the manifest. That sequencing is what keeps the invariant registry honest. Registering earlier would be an anti-drift violation.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-REM-05` is `status=completed` and `evidence/phase2/tsk_p2_preauth_003_rem_05.json` exists.
- [ ] `scripts/db/verify_execution_truth_anchor.sh` exists and is executable.
- [ ] The upstream evidence JSON's embedded `git_sha` matches or descends from the current HEAD of the working branch (freshness gate).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/invariants/INVARIANTS_MANIFEST.yml` | MODIFY (append) | New INV-EXEC-TRUTH-001 block |
| `docs/invariants/INVARIANTS_IMPLEMENTED.md` | MODIFY (append) | Row for new invariant |
| `scripts/audit/verify_invariant_exec_truth_001_registration.sh` | CREATE | Registration verifier |
| `evidence/phase2/tsk_p2_preauth_003_rem_04.json` | CREATE | Evidence emitted by registration verifier |
| `tasks/TSK-P2-PREAUTH-003-REM-04/meta.yml` | MODIFY | Status progression |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-04/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-04/EXEC_LOG.md` | CREATE | Append-only record |

---

## Stop Conditions

- Upstream REM-05 evidence missing -> STOP.
- Upstream evidence `run_id` older than the working-branch HEAD SHA at the time this task runs -> STOP.
- `enforcement_location` path resolves to nothing -> STOP.
- `INVARIANTS_MANIFEST.yml` fails YAML parse after append -> STOP.
- Any edit lands in `docs/security/**` -> STOP (path-authority violation; that scope belongs to REM-04B).

---

## Implementation Steps

### Step 1: Author the invariant block

**What:** `[ID tsk_p2_preauth_003_rem_04_work_item_01]` Append to `docs/invariants/INVARIANTS_MANIFEST.yml`:

```yaml
- id: INV-EXEC-TRUTH-001
  aliases: ["I-P2-PREAUTH-003-REM", "INV-EXEC-RECORDS-TRUTH-ANCHOR"]
  status: implemented
  severity: P0
  title: "execution_records is a NOT-NULL-bound, append-only, deterministically-keyed, temporally-resolved truth anchor"
  owners: ["team-db", "team-security"]
  sla_days: 7
  enforcement: "scripts/db/verify_execution_truth_anchor.sh"
  verification: >-
    scripts/db/verify_execution_truth_anchor.sh inspects pg_attribute for NOT NULL
    on interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id;
    pg_constraint for execution_records_determinism_unique UNIQUE
    (input_hash, interpretation_version_id, runtime_version) and FK to
    interpretation_packs(interpretation_pack_id); pg_trigger for
    execution_records_append_only_trigger (BEFORE UPDATE OR DELETE) and
    execution_records_temporal_binding_trigger (BEFORE INSERT);
    pg_proc.proconfig for SECURITY DEFINER SET search_path = pg_catalog, public.
    Evidence: evidence/phase2/tsk_p2_preauth_003_rem_05.json.
  notes: >-
    Introduced by remediation casefile REM-2026-04-20_execution-truth-anchor
    after TSK-P2-PREAUTH-003-01/-02 left the table semantically broken. FK target
    column is interpretation_pack_id (real PK of interpretation_packs); the child
    column on execution_records is historically named interpretation_version_id.
    Lifecycle / retry / failure-state semantics are owned by
    REM-2026-04-20_execution-lifecycle and MUST NOT touch this append-only contract.
```

Then append to `docs/invariants/INVARIANTS_IMPLEMENTED.md` a row in the table following the existing schema, referencing `INV-EXEC-TRUTH-001`, `scripts/db/verify_execution_truth_anchor.sh`, and `evidence/phase2/tsk_p2_preauth_003_rem_05.json`.

**Done when:** Both files contain literal substring `INV-EXEC-TRUTH-001` and YAML of the manifest parses without error.

### Step 2: Author the registration verifier

**What:** `[ID tsk_p2_preauth_003_rem_04_work_item_02]` Create `scripts/audit/verify_invariant_exec_truth_001_registration.sh`. The verifier must:

1. Load `docs/invariants/INVARIANTS_MANIFEST.yml` via `python3 -c 'import yaml; …'` and confirm an entry with `id == 'INV-EXEC-TRUTH-001'` and `status == 'implemented'` exists. `|| exit 1`.
2. Read the entry's `enforcement` field; confirm the path exists and is executable (`test -x`).
3. Read the entry's `verification` evidence pointer; confirm `evidence/phase2/tsk_p2_preauth_003_rem_05.json` exists. Parse it, extract `git_sha` and `run_id`, and confirm they are not older than the current `HEAD` SHA of the branch.
4. Confirm `docs/invariants/INVARIANTS_IMPLEMENTED.md` contains the literal substring `INV-EXEC-TRUTH-001`.
5. Compute SHA-256 of the upstream evidence JSON and record it as `upstream_evidence_hash`.
6. Emit `evidence/phase2/tsk_p2_preauth_003_rem_04.json` with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `manifest_present` (bool), `enforcement_path_resolves` (bool), `verification_evidence_fresh` (bool), `upstream_evidence_hash`.
7. `|| exit 1` on any assertion failure.

**Done when:** Verifier exits 0 against the populated governance surface and the three boolean fields are all true.

### Step 3: Emit evidence

Run `PRE_CI_CONTEXT=1 bash scripts/audit/verify_invariant_exec_truth_001_registration.sh` and verify its output JSON lands at the declared path with the required fields.

---

## Verification

```bash
# [ID tsk_p2_preauth_003_rem_04_work_item_02] Run the registration verifier and emit evidence.
test -x scripts/audit/verify_invariant_exec_truth_001_registration.sh && PRE_CI_CONTEXT=1 bash scripts/audit/verify_invariant_exec_truth_001_registration.sh || exit 1

# [ID tsk_p2_preauth_003_rem_04_work_item_01] Confirm manifest contains INV-EXEC-TRUTH-001 block.
test -f docs/invariants/INVARIANTS_MANIFEST.yml && grep -q 'INV-EXEC-TRUTH-001' docs/invariants/INVARIANTS_MANIFEST.yml || exit 1

# [ID tsk_p2_preauth_003_rem_04_work_item_01] Confirm implemented registry lists INV-EXEC-TRUTH-001.
test -f docs/invariants/INVARIANTS_IMPLEMENTED.md && grep -q 'INV-EXEC-TRUTH-001' docs/invariants/INVARIANTS_IMPLEMENTED.md || exit 1

# [ID tsk_p2_preauth_003_rem_04_work_item_02] Confirm evidence file carries the manifest_present proof field.
test -f evidence/phase2/tsk_p2_preauth_003_rem_04.json && grep -q 'manifest_present' evidence/phase2/tsk_p2_preauth_003_rem_04.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_preauth_003_rem_04.json`

Required fields:
- `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`
- `manifest_present`: true
- `enforcement_path_resolves`: true
- `verification_evidence_fresh`: true
- `upstream_evidence_hash`: SHA-256 of `evidence/phase2/tsk_p2_preauth_003_rem_05.json`

---

## Rollback

1. Remove the INV-EXEC-TRUTH-001 block from `INVARIANTS_MANIFEST.yml` (or flip status to `in_progress`).
2. Remove the row from `INVARIANTS_IMPLEMENTED.md`.
3. Security-surface rollback (docs/security/**) is owned by REM-04B.
4. File exception in `docs/security/EXCEPTION_REGISTER.yml`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Registration runs before REM-05 evidence exists | FAIL (false-positive "implemented") | Dependency + freshness gate in verifier |
| Manifest YAML corruption | CRITICAL_FAIL | Verifier YAML-parses manifest before asserting presence |
| Governance docs silently diverge | FAIL | Verifier asserts substring presence in all four files |

---

## Approval (regulated surface)

- [ ] `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-04.json` present
- [ ] Approved by: `<approver_id>`
- [ ] Approval timestamp: `<ISO 8601>`
