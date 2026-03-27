# GF-W1-GOV-005A PLAN — Fail closed on invalid migration ownership and reference order

Task: GF-W1-GOV-005A
Owner: SECURITY_GUARDIAN
Depends on: GF-W1-GOV-005
failure_signature: PH0.CI.GF_W1_GOV_005A.OWNERSHIP_REFERENCE_GRAPH
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Build a graph verifier that proves governed object ownership, reference order,
sidecar/SQL consistency, and direct dependency completeness for the corrective
Green Finance schema chain. Done means invalid graphs fail before merge and the
evidence file reports exactly which ownership, ordering, dependency, or DDL
constraints failed. The proof artifact is
`evidence/phase0/gf_gov_005a_reference_order.json`.

---

## Architectural Context

The migration sequence guard proves numbering discipline but not semantic graph
integrity. This task closes the gap that allowed downstream patching and forged
sidecars to survive as long as file numbers looked clean. It must exist before
the rebuilt schema tasks can be safely implemented.

---

## Pre-conditions

- [ ] `GF-W1-GOV-005` is completed.
- [ ] Approval metadata exists for regulated-surface changes.
- [ ] The corrective task packs use forward-renumbered migration paths that do not collide with current repo state.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_migration_reference_order.py` | MODIFY | Add semantic graph enforcement |
| `scripts/audit/tests/test_verify_migration_reference_order.py` | MODIFY | Add adversarial regression coverage |
| `evidence/phase0/gf_gov_005a_reference_order.json` | CREATE | Proof artifact |
| `tasks/GF-W1-GOV-005A/meta.yml` | MODIFY | Task contract |

---

## Stop Conditions

- **If the verifier falls back to regex-only extraction** -> STOP
- **If any governed object can be created without appearing in sidecar metadata** -> STOP
- **If ownerless references can pass in pre-rebuild mode** -> STOP
- **If direct dependency completeness cannot be derived from the task graph** -> STOP

---

## Implementation Steps

### Step 1: Parse governed ownership
**What:** `[ID gf_w1_gov_005a_work_item_01]` Parse governed objects from tokenized or parsed SQL.
**How:** Capture tables, named indexes, standalone sequences, and explicitly named constraints.
**Done when:** Duplicate ownership can be detected deterministically.

### Step 2: Parse references and order
**What:** `[ID gf_w1_gov_005a_work_item_02]` Parse references and resolve them against ordered ownership.
**How:** Validate same-file ordering and fail ownerless references explicitly.
**Done when:** Forward and ownerless references fail closed.

### Step 3: Validate metadata truth
**What:** `[ID gf_w1_gov_005a_work_item_03]` Compare sidecars to parsed SQL and verify direct dependency completeness.
**How:** Construct `schema_object -> migration -> task` and compare the full referenced-table owner set to `depends_on`.
**Done when:** Sidecar forgery and missing direct dependencies fail.

### Step 4: Ban implicit execution paths
**What:** `[ID gf_w1_gov_005a_work_item_04]` Reject procedural SQL, dynamic DDL, and destructive DDL.
**How:** Treat those constructs as forbidden for this corrective sequence.
**Done when:** The adversarial tests fail on those constructs.

### Step 5: Emit evidence
**What:** `[ID gf_w1_gov_005a_work_item_05]` Write `evidence/phase0/gf_gov_005a_reference_order.json`.
**How:** Run the verifier and persist bounded proof fields.
**Done when:** The evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_gov_005a_work_item_01] [ID gf_w1_gov_005a_work_item_02] [ID gf_w1_gov_005a_work_item_03]
python3 scripts/audit/verify_migration_reference_order.py || exit 1

# [ID gf_w1_gov_005a_work_item_04]
python3 -m pytest scripts/audit/tests/test_verify_migration_reference_order.py || exit 1

# [ID gf_w1_gov_005a_work_item_05]
test -f evidence/phase0/gf_gov_005a_reference_order.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_gov_005a_reference_order.json`

Required fields:
- `task_id`: `GF-W1-GOV-005A`
- `git_sha`
- `timestamp_utc`
- `status`
- `owners`
- `references`
- `task_ownership_map`
- `task_dependency_failures`
- `duplicate_owner_failures`
- `forward_reference_failures`
- `ambiguous_owner_failures`
- `root_if_not_exists_failures`
- `undeclared_object_failures`
- `sidecar_sql_mismatch_failures`
- `dynamic_ddl_failures`
- `destructive_ddl_failures`
- `normalization_cases`
- `ignored_reference_warnings`
- `checks`

---

## Rollback

If this task must be reverted:
1. Restore the prior verifier only if the corrective schema chain is also backed out.
2. Remove the unmerged evidence/test changes together.
3. Update task status and remediation trace before retrying.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Regex-only verifier behavior | CRITICAL_FAIL | Require tokenized/parsed SQL and test for forbidden shortcuts |
| Sidecar forgery passes | CRITICAL_FAIL | Compare every governed object in SQL to sidecars |
| Anti-pattern: transitive dependency treated as direct | FAIL | Build the full referenced-owner set and compare directly |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`
