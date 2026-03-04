# Phase-1 Remaining Tasks Implementation Plan

## Scope
This document defines the execution checklist for the remaining DAG tasks on Phase-1:

1. `TSK-P1-203`
2. `TSK-P1-204`
3. `TSK-P1-205`
4. `TSK-P1-060`

It aligns to:

- `docs/tasks/phase1_dag.yml`
- `docs/tasks/phase1_prompts.md`
- `Ruthless-Review.txt`

The objective is mechanical completion with verifier-backed evidence and fail-closed behavior.

## Non-negotiable controls
The following controls must be present in the implementation outputs and verifier coverage:

1. `effect_seal_hash` enforcement: approved effect must match executed effect.
2. `P7101` terminal immutability with explicit post-terminal mutation policy.
3. Concurrency safety: `FOR UPDATE`, idempotency keys, duplicate attempt prevention.
4. Offline safe mode: approvals allowed by policy, execution blocked fail-closed.
5. Decision-event evidence, not only terminal-event evidence.
6. Reference allocation and registry linkage at execution attempt creation.

## Global execution checklist
Run for each task in order:

1. Create branch `task/<TASK_ID>`.
2. Confirm dependency task state is `completed` on `main`.
3. Implement only paths allowed by prompt metadata.
4. Run task verifier and evidence validator.
5. Run `scripts/dev/pre_ci.sh`.
6. Confirm evidence JSON includes `task_id` and `status` in `{PASS,DONE,OK}` and `pass: true` when required.
7. Set `tasks/<TASK_ID>/meta.yml` to `status: "completed"`.
8. Commit with message `<TASK_ID>: <short title>`.

## Task plan: TSK-P1-203
Task intent: sandbox deploy manifests restore + posture verifier, including migration job/init ordering.

### Required implementation
1. Ensure sandbox manifests include:
- `ledger-api`
- `executor-worker`
- migration job or init container that runs before service start
- secrets/bootstrap mechanism
2. Add `scripts/audit/verify_tsk_p1_203.sh` to verify required resources and ordering.
3. Emit evidence:
- `evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json`

### Required command contract
Run:

```bash
bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_203.sh || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_203.sh; exit 1; }; scripts/audit/verify_tsk_p1_203.sh --evidence evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json; python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json\"); assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert d.get(\"task_id\") == \"TSK-P1-203\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"), str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
```

### Hardening coverage
1. Verify offline safe mode config presence on deploy surface.
2. Verify migration job cannot be bypassed by deployment ordering.

## Task plan: TSK-P1-204
Task intent: exception case-pack generator script/tool, not a new service.

### Required implementation
1. Add `scripts/tools/generate_exception_case_pack.sh` or `.py`.
2. Input must accept `correlation_id` or `instruction_id`.
3. Output pack must include:
- ingress attestation
- outbox attempts
- exception chain
- relevant evidence artifacts
4. Output must exclude raw PII.
5. Add `scripts/audit/verify_tsk_p1_204.sh` to generate sample pack in CI.
6. Emit evidence:
- `evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json`

### Required command contract
Run:

```bash
bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_204.sh || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_204.sh; exit 1; }; scripts/audit/verify_tsk_p1_204.sh --evidence evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json; python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json\"); assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert d.get(\"task_id\") == \"TSK-P1-204\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"), str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
```

### Hardening coverage
1. Include effect seal metadata in pack when present.
2. Include reference allocation metadata in pack.
3. Include legal-hold and offline-gate decision records in pack evidence.

## Task plan: TSK-P1-205
Task intent: KPI evidence artifact including settlement window compliance.

### Required implementation
1. Produce KPI evidence artifact and verifier.
2. Include minimum KPIs from prompt:
- `ingress_success_rate`
- `p95_ingress_latency_ms`
- `retry_ceiling_respected_pct`
- `evidence_pack_generation_success_pct`
- `tenant_isolation_selftest_passed` (boolean and count)
- `settlement_window_compliance_pct` with reference to PERF-005 artifact path or ID
3. Define computation method and measurement truth for each KPI.
4. Emit evidence:
- `evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json`

### Required command contract
Run:

```bash
bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_205.sh || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_205.sh; exit 1; }; scripts/audit/verify_tsk_p1_205.sh --evidence evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json; python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json\"); assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert d.get(\"task_id\") == \"TSK-P1-205\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"), str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
```

### Hardening coverage
Add operational control metrics:

1. seal mismatch blocks
2. offline execution blocks
3. legal hold blocks
4. approval quorum latency

## Task plan: TSK-P1-060
Task intent: Phase-2 followthrough program definition only after Phase-1 closeout checkpoint.

### Dependency gate
Must not execute until:

1. `checkpoint/PHASE-1-CLOSEOUT` is complete
2. `evidence/phase1/phase1_closeout.json` exists and validates

### Required implementation
1. Add verifier:
- `scripts/audit/verify_p1_060_phase2_followthrough_gate.sh`
2. Emit gate evidence:
- `evidence/phase1/p1_060_phase2_followthrough_gate.json`
3. Create or update:
- `docs/phases/PHASE2_PROGRAM.md`
4. Document Phase-2 scope and mandatory stub activations:
- levy status enforcement
- `kyc_hold` routing
- provider signature verification
- remittance period status enforcement
- performance regression classification
- live rail adapter activation

### Required command contract
Run:

```bash
bash scripts/audit/verify_p1_060_phase2_followthrough_gate.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-060 --evidence evidence/phase1/p1_060_phase2_followthrough_gate.json
```

## Evidence event model (decision-level)
For tasks in this sequence, evidence must cover decision points:

1. submission created
2. approval or rejection recorded
3. quorum satisfied
4. effect seal computed
5. cooling requirement derived and completion
6. legal-hold gate check result
7. offline safe mode gate result
8. execution attempt created with reference metadata
9. terminal execution outcome

## SQL and workflow hardening checklist
Use this for reviewer signoff when implementing DB workflow controls:

1. `effect_seal_hash` computed from canonical fields at approval finalization.
2. execution request payload hash compared to seal before dispatch.
3. post-terminal update policy explicit and minimal.
4. all state-changing paths lock parent row with `FOR UPDATE`.
5. approval duplicates blocked by unique keys.
6. execution duplicates and concurrent actives blocked by unique keys and status checks.
7. policy snapshot only, no mutable policy lookups for in-flight adjustments.
8. offline safe mode blocks execution creation fail-closed.
9. dispatch reference allocated and linked before outbound call.

## Completion definition for this plan
This plan is complete only when:

1. All four tasks are `completed` in their `tasks/<TASK_ID>/meta.yml`.
2. All task-specific verifier commands pass.
3. `scripts/dev/pre_ci.sh` passes for each task branch.
4. All task evidence artifacts exist and validate.
5. `scripts/audit/verify_phase1_closeout.sh` passes with required contract evidence.
