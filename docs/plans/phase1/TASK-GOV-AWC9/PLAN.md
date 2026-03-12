# PLAN — TASK-GOV-AWC9

## Mission

Repair the immediate evidence freshness mismatch that blocks `TASK-GOV-AWC2`
by normalizing `TASK-INVPROC-06`'s JSON evidence to the deterministic runner
`run_id` contract.

## Scope

This task is limited to:
- `scripts/audit/verify_invproc_06_ci_wiring_closeout.sh`
- `scripts/audit/verify_human_governance_review_signoff.sh`
- `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`
- regulated approval metadata for this branch batch
- its own task pack files

## Non-Goals

- Do not weaken `scripts/agent/run_task.sh` freshness semantics.
- Do not perform the broader verifier migration in this task.
- Do not alter unrelated task evidence writers here.

## Exact Changes

1. Add `run_id` emission to:
   - `scripts/audit/verify_invproc_06_ci_wiring_closeout.sh`
   - `scripts/audit/verify_human_governance_review_signoff.sh`
2. Use this rule:
   - if `SYMPHONY_RUN_ID` is present, emit that value
   - otherwise emit `standalone-<timestamp_utc>`
3. Add the runner-targeted JSON evidence contract note to
   `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`.
4. Regenerate both `TASK-INVPROC-06` evidence files under the new contract.

## Verification Commands

```bash
bash scripts/audit/verify_invproc_06_ci_wiring_closeout.sh
bash scripts/audit/verify_human_governance_review_signoff.sh
python3 -c "import json; paths=['evidence/phase1/invproc_06_ci_wiring_closeout.json','evidence/phase1/human_governance_review_signoff.json']; [(__import__('sys').exit(1) if not json.load(open(p)).get('run_id') else None) for p in paths]; print('PASS')"
bash scripts/agent/run_task.sh TASK-INVPROC-06
```

## Evidence

- `evidence/phase1/task_gov_awc9_invproc06_run_id_contract.json`

## Remediation Markers

```text
failure_signature: GOV.AWC9.INVPROC06.RUN_ID_CONTRACT
origin_task_id: TASK-GOV-AWC9
repro_command: bash scripts/agent/run_task.sh TASK-INVPROC-06
verification_commands_run: pending
final_status: PENDING
```
