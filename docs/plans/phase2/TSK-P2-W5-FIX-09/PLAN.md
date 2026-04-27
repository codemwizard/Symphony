# TSK-P2-W5-FIX-09 PLAN — Set signature placeholder posture in generate_transition_hash()

Task: TSK-P2-W5-FIX-09
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-08
failure_signature: P2.W5-FIX.SIGNATURE-POSTURE.AMBIGUOUS_HASH
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Migration 0141 created `enforce_transition_signature()` which uses a placeholder
`verify_ed25519_signature()` that always returns true. The `transition_hash` is generated
by the client or trigger but has no distinguishing marker. After this task, the hash
output is prefixed with `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` so it is impossible to
mistake for real cryptographic output.

Note: The hash is currently generated in migration 0137's table definition
(`transition_hash TEXT NOT NULL`). The client is expected to provide it. We need to
determine if there's a trigger that auto-generates the hash. If not, this task adds a
BEFORE INSERT trigger that sets `transition_hash` with the placeholder prefix when the
provided hash doesn't already have it.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-08 status=completed. MIGRATION_HEAD = 0152.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0153_set_signature_placeholder_posture.sql` | CREATE | CREATE OR REPLACE function to prefix hash |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0153 |
| `scripts/db/verify_tsk_p2_w5_fix_09.sh` | CREATE | Verify placeholder prefix |
| `evidence/phase2/tsk_p2_w5_fix_09.json` | CREATE | Evidence |
| Governance files | MODIFY | Steps 9-13 |

---

## Implementation Steps

### Step 1: Audit Current Hash Behavior
**What:** `[ID w5_fix_09_work_01]` Determine how transition_hash is currently generated.

### Step 2: Write Migration
**What:** `[ID w5_fix_09_work_02]` CREATE OR REPLACE a function that ensures transition_hash starts with `PLACEHOLDER_PENDING_SIGNING_CONTRACT:`.

### Step 3-7: Standard governance sequence.

---

## Verification

```bash
bash scripts/db/verify_tsk_p2_w5_fix_09.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_09.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_09.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, placeholder_prefix_verified

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Placeholder looks like real signature | False authority chain | Prefix is clearly labeled |
| Hash function doesn't exist | No-op migration | Audit current state first |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
