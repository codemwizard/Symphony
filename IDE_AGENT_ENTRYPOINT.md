# IDE Agent Entrypoint (Canonical IDE Contract)

This file defines the deterministic, IDE-neutral procedure that **any** connected agent must follow when operating in the Symphony repository.

## Canonical Authority
You MUST treat these as canonical:
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `AGENTS.md`

## Deterministic Boot Procedure (Fail-Closed)
Before doing any implementation work, run:

1) Conformance gate:
```bash
scripts/audit/verify_agent_conformance.sh
```

2) Local parity gate:
```bash
scripts/dev/pre_ci.sh
```

If either step fails, STOP. Do not proceed.

## Deterministic Task Procedure
For a specific task:
```bash
scripts/agent/run_task.sh <TASK_ID>
```

This will:
- Load `tasks/<TASK_ID>/meta.yml` (requires `schema_version: 1`)
- Require referenced `PLAN.md` and `EXEC_LOG.md` exist
- Run conformance + pre-CI gates
- Execute `verification:` commands in-order (stop on first failure; optional per-check retries)
- Require `evidence:` files exist afterward and are fresh for this run (run_id matches)
- If `phase: '0'`, run Phase0 contract evidence gate:
  `scripts/ci/check_evidence_required.sh`

## Manifest
Machine-readable version: `agent_manifest.yml`

## Hard Stop Conditions
Stop immediately if:
- conformance gate fails
- pre-CI fails
- required task artifacts are missing
- any verification command fails
- evidence outputs do not exist or are stale after verification
