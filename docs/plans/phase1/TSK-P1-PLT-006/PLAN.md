# TSK-P1-PLT-006 PLAN — Token Issuance & Sequence

Task: TSK-P1-PLT-006
Owner: ARCHITECT
Depends on: TSK-P1-PLT-001
failure_signature: 1.PLT.006.TOKEN_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Synchronize the token issuance flow by updating the frontend payload and enhancing the backend response. This task enables verifiable collection tracking in the pilot by returning the `sequence` number for each issued token.

## Architectural Context

The `EvidenceLinkIssueHandler` manages the insertion of collection proofs into the ledger outbox. The pilot UI requires the `sequence` number of these records to display a "Seq #NN" badge in the session log.

---

## Pre-conditions

- [x] TSK-P1-PLT-001 is scaffolded.
- [x] `token-issuance.html` (Line 259) audited for payload structure.
- [x] `Program.cs` (Line 563) audited for expected request record.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Update handler to return `sequence`. |
| `src/symphony-pilot/token-issuance.html` | MODIFY | Align payload fields and display sequence. |
| `tasks/TSK-P1-PLT-006/meta.yml` | MODIFY | Update status. |

---

## Stop Conditions

- **If the sequence number returned is not consistent with the DB record sequence** -> STOP
- **If the frontend continues to send supplier_id (instead of submitter_msisdn/id structure)** -> STOP

---

## Implementation Steps

### Step 1: Return Sequence Number
**What:** `[ID TSK-P1-PLT-006_work_item_01]` Update the issuance handler in `Program.cs`.
**How:** Extract the `Sequence` property from the `EvidenceLinkSubmissionLog` append result and include it in the anonymous response object.
**Done when:** API returns `{ instruction_id: "...", sequence: 5 }`.

### Step 2: Refactor Frontend Payload
**What:** `[ID TSK-P1-PLT-006_work_item_02]` Update `issueToken` in `token-issuance.html`.
**How:** Map `worker` (msisdn) to `submitter_msisdn` and `proofType` to `artifact_type`.
**Done when:** Issuance requests return 200 OK.

### Step 3: Handle Sequence in UI
**What:** `[ID TSK-P1-PLT-006_work_item_03]` Update the session log logic in `token-issuance.html`.
**How:** Store the `sequence` field in the `sessionTokens` array and display it in the table.
**Done when:** The table shows "Seq #5" (or similar) for new tokens.

---

## Verification

```bash
# [ID TSK-P1-PLT-006_work_item_01]
curl -X POST http://localhost:5242/pilot-demo/api/evidence-links/issue \
  -H 'Content-Type: application/json' \
  -H 'Cookie: symphony_pilot_demo_operator=VALID' \
  -d '{"program_id": "PGM-ZAMBIA-GRN-001", "instruction_id": "INST-001", "submitter_msisdn": "+260971..."}' \
  | grep 'sequence' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_006.json`

Required fields:
- `task_id`: "TSK-P1-PLT-006"
- `status`: "PASS"
- `checks`: array including payload alignment and sequence return validation
