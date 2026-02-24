# Phase-1 Task Prompts Pack (Patched for Execution-Metadata Completeness)

> This patch version preserves the task prompt content and adds a per-task **Execution Metadata Patch Block**
> so an orchestrator can execute under hard rules without inventing verifier/evidence/file semantics.
>
> Added for every DAG task node:
> - `verifier_command`
> - `evidence_path`
> - `files_to_change`
> - `acceptance_assertions`
> - `failure_modes`
>
> If a task prompt section was missing in the source pack, this file inserts a stub section and marks it clearly.

## checkpoint/CS-0 — Checkpoint CS-0 (clean slate complete)

### Goal
Checkpoint node: confirm the clean-slate stage is mechanically complete before Phase-0 closeout tasks run.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/CS-0
depends_on:
- TSK-P1-059
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/CS-0 --evidence evidence/phase1/checkpoint__CS-0.json
evidence_path: evidence/phase1/checkpoint__CS-0.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/CS-0 have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__CS-0.json and validate_evidence.py passes for task_id checkpoint/CS-0.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/P0-DONE — Checkpoint P0-DONE (Phase-0 closeout complete)

### Goal
Checkpoint node: confirm Phase-0 closeout gate chain has completed before Phase-1 tasks begin.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/P0-DONE
depends_on:
- TSK-P0-210
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/P0-DONE --evidence evidence/phase1/checkpoint__P0-DONE.json
evidence_path: evidence/phase1/checkpoint__P0-DONE.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/P0-DONE have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__P0-DONE.json and validate_evidence.py passes for task_id checkpoint/P0-DONE.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/PERF-ENG — Checkpoint PERF-ENG (perf engineering complete)

### Goal
Checkpoint node: confirm perf engineering stage completion before regulatory perf checks run.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/PERF-ENG
depends_on:
- PERF-003
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/PERF-ENG --evidence evidence/phase1/checkpoint__PERF-ENG.json
evidence_path: evidence/phase1/checkpoint__PERF-ENG.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/PERF-ENG have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__PERF-ENG.json and validate_evidence.py passes for task_id checkpoint/PERF-ENG.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/PERF-REG — Checkpoint PERF-REG (perf regulatory complete)

### Goal
Checkpoint node: confirm perf regulatory stage completion before escrow tasks run.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/PERF-REG
depends_on:
- PERF-006
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/PERF-REG --evidence evidence/phase1/checkpoint__PERF-REG.json
evidence_path: evidence/phase1/checkpoint__PERF-REG.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/PERF-REG have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__PERF-REG.json and validate_evidence.py passes for task_id checkpoint/PERF-REG.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/ESC — Checkpoint ESC (escrow stage complete)

### Goal
Checkpoint node: confirm escrow stage completion before hierarchy tasks run.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/ESC
depends_on:
- TSK-P1-ESC-002
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/ESC --evidence evidence/phase1/checkpoint__ESC.json
evidence_path: evidence/phase1/checkpoint__ESC.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/ESC have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__ESC.json and validate_evidence.py passes for task_id checkpoint/ESC.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/HIER — Checkpoint HIER (hierarchy stage complete)

### Goal
Checkpoint node: confirm hierarchy stage completion before infrastructure/base-ops tasks run.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/HIER
depends_on:
- TSK-P1-HIER-011
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/HIER --evidence evidence/phase1/checkpoint__HIER.json
evidence_path: evidence/phase1/checkpoint__HIER.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/HIER have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__HIER.json and validate_evidence.py passes for task_id checkpoint/HIER.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/BASE-OPS — Checkpoint BASE-OPS (base operations stage complete)

### Goal
Checkpoint node: confirm base operations stage completion before Phase-1 closeout tasks run.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/BASE-OPS
depends_on:
- TSK-P1-REG-003
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/BASE-OPS --evidence evidence/phase1/checkpoint__BASE-OPS.json
evidence_path: evidence/phase1/checkpoint__BASE-OPS.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/BASE-OPS have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__BASE-OPS.json and validate_evidence.py passes for task_id checkpoint/BASE-OPS.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## checkpoint/PHASE-1-CLOSEOUT — Checkpoint PHASE-1-CLOSEOUT (Phase-1 closeout complete)

### Goal
Checkpoint node: confirm Phase-1 closeout stage completion before Phase-2 followthrough tasks can execute.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: checkpoint/PHASE-1-CLOSEOUT
depends_on:
- TSK-P1-205
verifier_command: bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/PHASE-1-CLOSEOUT --evidence evidence/phase1/checkpoint__PHASE-1-CLOSEOUT.json
evidence_path: evidence/phase1/checkpoint__PHASE-1-CLOSEOUT.json
files_to_change:
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_checkpoint.sh
acceptance_assertions:
- All dependencies listed in docs/tasks/phase1_dag.yml for checkpoint/PHASE-1-CLOSEOUT have PASS evidence (per prompt-pack evidence_path mapping).
- Evidence file exists at evidence/phase1/checkpoint__PHASE-1-CLOSEOUT.json and validate_evidence.py passes for task_id checkpoint/PHASE-1-CLOSEOUT.
failure_modes:
- Missing dependency evidence or dependency evidence not PASS => BLOCKED.
- Missing prompt execution metadata mapping for a dependency (task_id/evidence_path not found) => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
```

## TSK-CLEAN-001 — Task metadata truth pass

### Goal
Audit every task folder in the repository and establish a single source of truth for task
metadata. Every task that exists in the DAG must have a corresponding `tasks/<TASK_ID>/meta.yml`
file with fields: `task_id`, `title`, `status` (one of: roadmap | in-progress | complete | blocked),
`phase`, `evidence_path`, `verifier_path`, `depends_on`. Tasks that exist in `meta.yml` files but
not in the DAG must be flagged as orphaned. Any task whose `status == complete` must have a
resolvable `evidence_path` on disk.

### Scope
- In-scope: creating or updating `tasks/<ID>/meta.yml` for all DAG task IDs; emitting a
  machine-readable audit report; wiring the audit into `scripts/audit/verify_task_evidence_contract.sh`
  so CI fails on any orphan, missing file, or mismatched status.
- Out-of-scope: changing any task's implementation; changing the DAG structure; any schema migrations.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-CLEAN-001
depends_on: []
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_clean_001.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_clean_001.sh; exit 1; }; scripts/audit/verify_tsk_clean_001.sh
  --evidence evidence/phase0/tsk_clean_001__task_metadata_truth_pass.json; python3
  -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_clean_001__task_metadata_truth_pass.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-CLEAN-001\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_clean_001__task_metadata_truth_pass.json
files_to_change:
- tasks/TSK-CLEAN-001/meta.yml
- docs/tasks/phase1_prompts.md
- tasks/**/meta.yml
- scripts/audit/verify_task_evidence_contract.sh
- scripts/dev/pre_ci.sh
- scripts/audit/verify_tsk_clean_001.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_clean_001__task_metadata_truth_pass.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-CLEAN-001' and pass == true.
- tasks/TSK-CLEAN-001/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-CLEAN-002 — Kill informational-only perf posture everywhere

### Goal
Find and eliminate every location in the codebase where a performance check, gate, or
verifier runs but is configured as informational-only (i.e., exits 0 regardless of result,
logs a warning, or has a hard-coded `|| true`). Every perf check must be fail-closed after
this task: if the check cannot run, or if the measurement fails its threshold, the CI job
must exit non-zero. Document each location changed and the before/after behavior in the
evidence artifact.

### Scope
- In-scope: scripts in `scripts/audit/`, `scripts/perf/`, `.github/workflows/`, and
  `scripts/dev/pre_ci.sh` that contain informational-only perf posture. Changing exit codes,
  removing `|| true`, removing `|| echo WARNING` patterns. Emitting evidence of every change.
- Out-of-scope: adding new perf checks (that is PERF-001/002); changing threshold values;
  any schema changes; any application code.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-CLEAN-002
depends_on:
- TSK-CLEAN-001
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_clean_002.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_clean_002.sh; exit 1; }; scripts/audit/verify_tsk_clean_002.sh
  --evidence evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-CLEAN-002\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json
files_to_change:
- tasks/TSK-CLEAN-002/meta.yml
- docs/tasks/phase1_prompts.md
- tasks/**/meta.yml
- scripts/audit/verify_task_evidence_contract.sh
- scripts/dev/pre_ci.sh
- scripts/audit/verify_tsk_clean_002.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-CLEAN-002' and pass == true.
- tasks/TSK-CLEAN-002/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-059 — Gate script modularization (no behavior changes)

### Goal
Refactor the existing gate/check scripts in `scripts/audit/` and `scripts/dev/` so that
each discrete check lives in its own file and is invoked by a single orchestrator entry
point (`scripts/dev/ordered_checks.sh` or its equivalent). No behavior change is permitted:
every check that passed before must pass after, every check that failed before must still
fail. The only change is structural — monolithic scripts are split into individual,
addressable, named check files with stable IDs. This is a prerequisite for PERF-001/002
which must be able to insert new checks without modifying the orchestrator script.

### Scope
- In-scope: splitting multi-check scripts into per-check files; updating the orchestrator
  to call each file in the same order as before; confirming that `pre_ci.sh` and CI still
  invoke the orchestrator identically; emitting evidence that all pre-existing checks still
  produce the same pass/fail results.
- Out-of-scope: adding new checks; changing thresholds; changing any check's logic;
  any schema or application changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-059
depends_on:
- TSK-CLEAN-002
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_059.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_059.sh; exit 1; }; scripts/audit/verify_tsk_p1_059.sh
  --evidence evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-059\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json
files_to_change:
- tasks/TSK-P1-059/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- docs/PHASE1/**
- infra/**
- evidence/phase1/**
- scripts/audit/verify_tsk_p1_059.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-059' and pass == true.
- tasks/TSK-P1-059/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P0-101 — Ordered checks runner + phase gating

### Agent prompt (copy/paste)
```text
task_id: TSK-P0-101
title: Ordered checks runner + phase gating
owner_signoff: CTO
depends_on:
- checkpoint/CS-0
evidence:
  - evidence/phase0/ordered_checks_manifest.json

Goal
- Implement the canonical DAG task intent for TSK-P0-101: Ordered checks runner + phase gating.
- Make phase gating fail-closed: missing required scripts/evidence must fail.

Requirements
1) Implement scripts/dev/ordered_checks.sh (or equivalent canonical path already used by repo).
   - Must run sub-checks in a fixed order.
   - Must output a machine-readable manifest of what ran and results as evidence/phase0/ordered_checks_manifest.json.

2) Provide stable check IDs and categories (SEC-*, INT-*, GOV-*).
   - Include timestamps, git SHA, and tool versions in the manifest.

3) Integrate with pre-CI and CI so the same ordered checks run in both (parity).
   - If the repo already has pre_ci.sh, wire it to call ordered_checks.sh.

Acceptance
- Running ordered checks twice on the same clean DB snapshot produces identical evidence (except timestamp).
- Missing a required check script causes a hard failure with a clear error message.
- Evidence JSON validates against the repo’s evidence schema validator.

Deliverables
- Ordered checks script + README section describing how to run.
- Evidence manifest emitted deterministically.
- Unit smoke test or CI job that confirms the runner is invoked.

Do not
- Add new phase concepts or policy language; implement execution only.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-101
depends_on:
- checkpoint/CS-0
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_101.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_101.sh; exit 1; }; scripts/audit/verify_tsk_p0_101.sh
  --evidence evidence/phase0/tsk_p0_101__ordered_checks_runner_gating.json; python3
  -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_p0_101__ordered_checks_runner_gating.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-101\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_p0_101__ordered_checks_runner_gating.json
files_to_change:
- tasks/TSK-P0-101/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/audit/verify_tsk_p0_101.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_p0_101__ordered_checks_runner_gating.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-101' and pass == true.
- tasks/TSK-P0-101/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P0-102 — Enforce file evidence dev-only (fail-closed)

### Goal
Ensure that file-based evidence emission (writing JSON files to `evidence/`) is gated
fail-closed in non-dev environments. In production and staging, any verifier that attempts
to write evidence to disk must fail explicitly rather than silently succeed with no evidence
written. Implement an environment detection guard in the evidence-writing path: if
`SYMPHONY_ENV` is not `development` or `ci`, writing evidence to a local path must raise
an explicit error. In CI, evidence writing is permitted. In production, it is forbidden
and must be fail-closed (exit 1 with a clear message: `EVIDENCE_WRITE_FORBIDDEN_IN_ENV:<env>`).

### Scope
- In-scope: adding the environment guard to `scripts/audit/validate_evidence_json.sh` and
  the shared evidence-writing helper (wherever evidence JSON is emitted); confirming CI
  still writes evidence; emitting `evidence/phase0/TSK-P0-102.json` proving the guard is
  in place and tested.
- Out-of-scope: changing what is written to evidence files; any schema migrations;
  any application code changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-102
depends_on:
- TSK-P0-101
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_102.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_102.sh; exit 1; }; scripts/audit/verify_tsk_p0_102.sh
  --evidence evidence/phase0/tsk_p0_102__enforce_file_evidence_dev_only_fail.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_p0_102__enforce_file_evidence_dev_only_fail.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-102\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_p0_102__enforce_file_evidence_dev_only_fail.json
files_to_change:
- tasks/TSK-P0-102/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/audit/verify_tsk_p0_102.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_p0_102__enforce_file_evidence_dev_only_fail.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-102' and pass == true.
- tasks/TSK-P0-102/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P0-103 — Single payload materialization

### Agent prompt (copy/paste)
```text
task_id: TSK-P0-103
title: Single payload materialization
owner_signoff: CTO
depends_on:
- TSK-P0-102
evidence:
  - evidence/phase0/evidence_schema_validation.json

Goal
- Implement the canonical DAG task intent for TSK-P0-103: Single payload materialization.

Requirements
1) Define/extend the canonical evidence schema(s) in a single location.
   - Must include: git_sha, produced_at_utc, check_id, status, inputs, outputs, measurement_truth (when applicable).
2) Implement/extend scripts/audit/validate_evidence_json.sh:
   - Must scan evidence/phase0 and evidence/phase1 directories.
   - Must fail on invalid JSON, schema mismatch, missing required fields, or unknown extra fields (strict mode).
3) Emit evidence/phase0/evidence_schema_validation.json reporting:
   - count_valid, count_invalid, invalid_files list, schema_version.

Acceptance
- Introducing a malformed evidence JSON makes CI fail.
- Evidence schema validation itself is run from ordered checks.

Deliverables
- Updated schema file(s)
- Updated validator script
- Ordered checks wiring
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-103
depends_on:
- TSK-P0-102
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_103.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_103.sh; exit 1; }; scripts/audit/verify_tsk_p0_103.sh
  --evidence evidence/phase0/tsk_p0_103__single_payload_materialization.json; python3
  -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_p0_103__single_payload_materialization.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-103\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_p0_103__single_payload_materialization.json
files_to_change:
- tasks/TSK-P0-103/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/audit/verify_tsk_p0_103.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_p0_103__single_payload_materialization.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-103' and pass == true.
- tasks/TSK-P0-103/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```
## TSK-P0-104 — perf smoke scaffold only, forward-compatible with PERF-001/002

### Agent prompt (copy/paste)
```text
task_id: TSK-P0-104
title: perf smoke scaffold only, forward-compatible with PERF-001/002
owner_signoff: CTO
depends_on:
- TSK-P0-103
evidence:
  - evidence/phase1/perf_smoke_baseline.json

Goal
Create a perf smoke entrypoint that is deterministic, CI runnable, and baseline-gated —
without duplicating work reserved for PERF-001 (engine metrics) and PERF-002 (regression
classification). This task produces Perf Smoke Schema v1 only.

Critical deconflict rule (must follow)
This task produces Perf Smoke Schema v1 and must be forward-compatible.
Include placeholders/nullable fields for future additions:
  engine_metrics: null
  regression_classification: null
PERF-001/002 will extend the same artifact later; do not bake in assumptions that block
schema evolution.

Deliverables
1) Script: scripts/audit/run_perf_smoke.sh
   - Runs a deterministic workload (fixed seed, fixed request count — document both explicitly).
   - Outputs JSON to evidence/phase1/perf_smoke_baseline.json.
   - Defines and documents the jitter tolerance rule explicitly (e.g., ±5% on p95).
2) Baseline file mechanism:
   - perf_baseline.json checked in (or generated then locked in CI).
   - CI gate fails if p95 latency or throughput_rps regresses beyond declared threshold vs baseline.
   - Gate checks ONLY p95_ms and throughput_rps. No other metrics in Phase-0.
3) JSON schema versioning:
   - schema_version field set to "1.0".
   - All fields documented in a comment or README section.

Acceptance
- Script outputs deterministic JSON on repeated runs (within the jitter tolerance rule
  defined and documented in the script header).
- CI gate fails on regression vs baseline beyond threshold for p95_ms or throughput_rps.
- Evidence emitted at evidence/phase1/perf_smoke_baseline.json with all required fields.
- Running the script twice on identical input produces identical output (modulo timestamps).

Evidence artifact: evidence/phase1/perf_smoke_baseline.json
Required fields:
  schema_version: "1.0"
  task_id: "TSK-P0-104"
  pass: true/false
  p50_ms: <number>
  p95_ms: <number>
  throughput_rps: <number>
  baseline_ref: <sha256 hash of perf_baseline.json>
  jitter_tolerance_pct: <number — the explicitly declared tolerance>
  regression_detected: false
  engine_metrics: null        (forward-compat placeholder — PERF-001 fills this)
  regression_classification: null  (forward-compat placeholder — PERF-002 fills this)
  git_sha: <current git SHA>
  produced_at_utc: <ISO 8601>

Do not
- Add engine metrics or classification logic. That belongs to PERF-001/002.
- Create a new perf framework. Use or extend scripts/audit/ only.
- Hardcode thresholds without documenting them; document all thresholds in the script header.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-104
depends_on:
- TSK-P0-103
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_104.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_104.sh; exit 1; }; scripts/audit/verify_tsk_p0_104.sh
  --evidence evidence/phase1/tsk_p0_104__perf_smoke_scaffold_only_forward_compatible.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p0_104__perf_smoke_scaffold_only_forward_compatible.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-104\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p0_104__perf_smoke_scaffold_only_forward_compatible.json
files_to_change:
- tasks/TSK-P0-104/meta.yml
- scripts/audit/run_perf_smoke.sh
- perf_baseline.json
- docs/PHASE0/phase0_contract.yml
- evidence/phase1/perf_smoke_baseline.json
- scripts/audit/verify_tsk_p0_104.sh
acceptance_assertions:
- Script scripts/audit/run_perf_smoke.sh exists and is executable.
- Evidence file exists at evidence/phase1/tsk_p0_104__perf_smoke_scaffold_only_forward_compatible.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-104' and pass == true.
- Evidence JSON contains schema_version == '1.0'.
- Evidence JSON contains engine_metrics == null (forward-compat placeholder, not yet
  populated).
- Evidence JSON contains regression_classification == null (forward-compat placeholder,
  not yet populated).
- Evidence JSON contains regression_detected == false.
- perf_baseline.json is checked in and its SHA256 matches baseline_ref in evidence.
- CI gate fails if p95_ms or throughput_rps regresses beyond declared jitter_tolerance_pct
  vs baseline.
- Jitter tolerance rule is documented explicitly in the script header (not implicit).
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- engine_metrics not null => FAIL (PHASE_VIOLATION: PERF-001 scope crept into TSK-P0-104).
- regression_classification not null => FAIL (PHASE_VIOLATION: PERF-002 scope crept
    into TSK-P0-104).
- regression_detected == true => FAIL.
- baseline_ref hash does not match perf_baseline.json content => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```

## TSK-P0-105 — INV-077 approval metadata evidence (make it real, not placeholder)

### Agent prompt (copy/paste)
```text
task_id: TSK-P0-105
title: INV-077 approval metadata evidence (make it real, not placeholder)
owner_signoff: CTO
depends_on:
- TSK-P0-104
evidence:
  - evidence/phase0/migration_governance.json

Goal
- Implement the canonical DAG task intent for TSK-P0-105: INV-077 approval metadata evidence (make it real, not placeholder).

Requirements
1) Implement scripts/db/verify_migration_governance.sh that checks:
   - No applied migration file changed (checksum ledger / baseline file).
   - No top-level BEGIN/COMMIT in migration files.
   - Concurrency-safe index rule: “no-tx marker” present for CONCURRENTLY operations.
2) Emit evidence/phase0/migration_governance.json with:
   - baseline_hash, changed_files[], violations[], status.
3) Wire into ordered checks.

Acceptance
- Modifying an already-applied migration makes CI fail.
- A migration with CONCURRENTLY inside a transaction makes CI fail.

Deliverables
- Governance verifier + documentation snippet.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-105
depends_on:
- TSK-P0-104
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_105.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_105.sh; exit 1; }; scripts/audit/verify_tsk_p0_105.sh
  --evidence evidence/phase0/tsk_p0_105__inv_approval_metadata_evidence_make_it.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_p0_105__inv_approval_metadata_evidence_make_it.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-105\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_p0_105__inv_approval_metadata_evidence_make_it.json
files_to_change:
- tasks/TSK-P0-105/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/audit/verify_tsk_p0_105.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_p0_105__inv_approval_metadata_evidence_make_it.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-105' and pass == true.
- tasks/TSK-P0-105/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```

## Stage 1-B — MMO Levy Schema Hooks (insert before final Phase-0 tasks)

## TSK-P0-LEVY-001 — levy_rates table (versioned statutory rate registry

**Goal**
- Create the `levy_rates` table as a Phase-0 structural hook: a versioned registry
  of statutory MMO levy rates. No calculation logic. No enforcement. Structural
  readiness only, with a verifier proving the table and its constraints exist exactly
  as specified.

**Phase classification rationale**
- This is Phase-0 by Q1 of the classification decision tree: purely structural,
  no runtime business outcome semantics. The levy rate registry is a governance
  primitive analogous to `risk_formula_versions` — it holds statutory facts that
  Phase-2 calculation logic will read. Creating it now prevents a Phase-2 engineer
  from hardcoding the rate (a governance defect) or scrambling to add a registry
  into a live system.

**Scope**
- In-scope: migration creating `levy_rates` table, column constraints, index,
  verifier, deterministic evidence artifact, contract wiring.
- Out-of-scope: any function that reads this table to compute a levy. Any
  application code that references levy_rates at runtime. Any ZRA submission logic.
  Any NOT NULL constraint on columns that runtime does not yet write.

**Inputs / discovery (must do first)**
- Locate current task metadata and status in `tasks/TSK-P0-LEVY-001/meta.yml`
  (create if it does not exist; status = roadmap → in-progress on start).
- Grep for any existing migration referencing `levy_rates` to confirm this is
  a new table and not a rename.
- Confirm no existing contract entry for this task (or add it if somehow present).
- Confirm the next available migration sequence number in `schema/migrations/`.

**Schema specification (implement exactly as described)**

```sql
-- Migration: 00XX_levy_rates_hook.sql
-- Phase-0 structural hook. No runtime reads permitted until Phase-2.

CREATE TABLE levy_rates (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Jurisdiction this rate applies to. Initially 'ZM' only.
    jurisdiction_code   CHAR(2)     NOT NULL,
    -- Finance Act or statutory instrument that introduced this rate.
    -- Nullable in Phase-0: Phase-2 will enforce NOT NULL once ingestion exists.
    statutory_reference TEXT,
    -- Rate expressed in basis points (bps). 20 bps = 0.20%.
    -- Zambia Mobile Money Transaction Levy 2023: 20 bps, capped per transaction.
    rate_bps            INTEGER     NOT NULL CHECK (rate_bps >= 0 AND rate_bps <= 10000),
    -- Per-transaction cap in the smallest currency unit (ngwee for ZMW).
    -- NULL means no cap applies. Zambia 2023: cap exists, value to be confirmed
    -- with Compliance before Phase-2 population.
    cap_amount_minor    BIGINT      CHECK (cap_amount_minor IS NULL OR cap_amount_minor > 0),
    -- Currency this cap is denominated in.
    cap_currency_code   CHAR(3),
    -- Inclusive start of validity window (Finance Act effective date).
    effective_from      DATE        NOT NULL,
    -- Inclusive end of validity window. NULL = currently in force.
    effective_to        DATE        CHECK (effective_to IS NULL OR effective_to >= effective_from),
    -- Audit fields.
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by          TEXT        NOT NULL DEFAULT current_user,
    -- Constraint: only one rate may be in force per jurisdiction at any time.
    -- Enforced by partial unique index below.
    CONSTRAINT levy_rates_cap_currency_required
        CHECK (cap_amount_minor IS NULL OR cap_currency_code IS NOT NULL)
);

-- Only one currently-in-force rate per jurisdiction (effective_to IS NULL).
CREATE UNIQUE INDEX levy_rates_one_active_per_jurisdiction
    ON levy_rates (jurisdiction_code)
    WHERE effective_to IS NULL;

-- Standard lookup index.
CREATE INDEX levy_rates_jurisdiction_date_idx
    ON levy_rates (jurisdiction_code, effective_from DESC);

COMMENT ON TABLE levy_rates IS
    'Phase-0 structural hook. Versioned registry of statutory MMO levy rates by '
    'jurisdiction. Populated in Phase-2 once Compliance confirms exact statutory '
    'values. DO NOT read this table in application runtime until Phase-2.';

COMMENT ON COLUMN levy_rates.rate_bps IS
    'Rate in basis points. 20 = 0.20%. Zambia MMO Levy 2023 = 20 bps.';

COMMENT ON COLUMN levy_rates.cap_amount_minor IS
    'Per-transaction cap in smallest currency unit (e.g. ngwee). '
    'NULL = no cap. Confirm exact ZMW cap with Compliance Counsel before Phase-2 population.';
```

**Deliverables**
- Migration file `schema/migrations/00XX_levy_rates_hook.sql` exactly as specified.
- `tasks/TSK-P0-LEVY-001/meta.yml` created/updated: status = complete, phase = 0,
  migration reference, verifier path, evidence path.
- Verifier script `scripts/db/verify_levy_rates_hook.sh` (see acceptance criteria).
- Deterministic evidence artifact at `evidence/phase0/TSK-P0-LEVY-001.json`.
- Contract entry added to `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

The verifier must confirm ALL of the following and exit 0 only if every check passes:

1. Table `levy_rates` exists in the target schema.
2. Columns present with correct types: `id` (uuid), `jurisdiction_code` (char(2)),
   `statutory_reference` (text, nullable), `rate_bps` (integer, not null),
   `cap_amount_minor` (bigint, nullable), `cap_currency_code` (char(3), nullable),
   `effective_from` (date, not null), `effective_to` (date, nullable),
   `created_at` (timestamptz, not null), `created_by` (text, not null).
3. CHECK constraint on `rate_bps` range (0–10000) is present.
4. CHECK constraint `levy_rates_cap_currency_required` is present.
5. Partial unique index `levy_rates_one_active_per_jurisdiction` exists and is
   a partial index on `(jurisdiction_code) WHERE effective_to IS NULL`.
6. Standard lookup index `levy_rates_jurisdiction_date_idx` exists.
7. Table comment contains the string `Phase-0 structural hook`.
8. No application code (`.cs`, `.ts`, `.js` files outside `scripts/` and `schema/`)
   references `levy_rates` — confirm by grep. If any references found, exit 1 with
   the file paths listed.
9. Migration file checksum matches the registered checksum in the migration registry.

**Evidence + CI gate**
- Add an ordered check in `pre_ci.sh` and CI so this gate runs in Stage 1-B,
  after TSK-P0-210 and before TSK-P0-LEVY-002.
- Evidence path: `evidence/phase0/TSK-P0-LEVY-001.json`.
- Required evidence fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `table_exists`, `column_count_verified`, `constraints_verified`,
  `indexes_verified`, `no_runtime_references`, `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_structural_hook_only"`).

**Failure modes (must be explicit)**
- Table already exists with different column spec → exit 1, list column
  discrepancies, do not silently alter.
- Any runtime code reference found → exit 1, list file paths.
- Migration checksum mismatch → exit 1 with both checksums shown.
- Missing prereq (migration framework not initialised) → exit 1 with message
  `PREREQ MISSING: migration framework not initialised`.
- Evidence file not emitted for any reason → CI exits 1.

**Notes**

Phase-0 hard boundaries for this task:
- DO NOT insert any rows into `levy_rates`. The table is a hook. Seeding with
  statutory values is a Phase-2 task requiring Compliance sign-off on the exact
  rate and cap figures.
- DO NOT create any function, stored procedure, or trigger that reads `levy_rates`.
- DO NOT add `levy_rates` to any application dependency injection or repository
  class. It must remain invisible to application runtime until Phase-2.
- The `cap_amount_minor` value for Zambia 2023 is believed to be in the range of
  ZMW 2.00–5.00 per transaction (200–500 ngwee) but this has NOT been confirmed
  against the current Finance Act. Leave NULL until Compliance confirms.
- `statutory_reference` is nullable intentionally. Phase-2 will enforce NOT NULL
  once the ingestion workflow exists that populates it from gazette references.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-LEVY-001
title: levy_rates table (versioned statutory rate registry
depends_on:
- TSK-P0-105
files_to_change:
  - db/migrations/*levy_rates*.sql
  - db/schema.sql
  - scripts/verify/verify_levy_rates_table.sh
verifier_command: bash scripts/verify/verify_levy_rates_table.sh
evidence_path: evidence/phase0/levy_rates_table_verification.json
acceptance_assertions:
  - levy_rates table exists as versioned statutory rate registry with effective dating/version constraints required by prompt
  - Verifier validates deterministic schema contract and non-placeholder evidence payload
failure_modes:
  - Table lacks version/effective-date semantics implied by DAG title
  - Verifier/evidence wrapper remains generic and does not inspect levy_rates table
```

## TSK-P0-LEVY-002 — TSK-P0-LEVY-002 — levy_applicable column on ingress_attestations (expand-first hook)

**Goal**
- Add a nullable `levy_applicable` boolean column to `ingress_attestations` as a
  Phase-0 expand-first hook. This is the field that Phase-2 calculation logic will
  use to flag which instructions attract the levy. In Phase-0 it is nullable, always
  NULL at runtime, and has no enforcement. The verifier proves the column exists with
  the correct type and nullability, and that no runtime code attempts to set it.

**Phase classification rationale**
- Phase-0 by Q1 and the expand-first migration safety rule. The alternative —
  adding this column in Phase-2 — requires a migration against a table that by then
  holds production-adjacent data. Nullable additions are safe and reversible; adding
  them now costs nothing and avoids a risky live migration later. The enforcement
  (NOT NULL DEFAULT false, application logic setting the value) belongs in Phase-2.

**Scope**
- In-scope: migration adding the column, verifier, evidence, contract wiring.
- Out-of-scope: any application code that reads or writes `levy_applicable`. Any
  NOT NULL constraint. Any DEFAULT value that implies runtime sets this. Any CHECK
  constraint against other columns. Any index on this column (add in Phase-2 when
  cardinality is known).

**Inputs / discovery (must do first)**
- Confirm `ingress_attestations` exists (it is a Phase-0 primitive — it must exist).
  If it does not exist, stop and raise an explicit error: `PREREQ MISSING:
  ingress_attestations table not found`.
- Grep for any existing `levy_applicable` column reference to confirm this is new.
- Locate task metadata at `tasks/TSK-P0-LEVY-002/meta.yml`.
- Confirm next available migration sequence number.

**Schema specification**

```sql
-- Migration: 00XY_ingress_attestations_levy_applicable_hook.sql
-- Phase-0 expand-first hook. Column is nullable and always NULL until Phase-2
-- classification logic is implemented.

ALTER TABLE ingress_attestations
    ADD COLUMN IF NOT EXISTS levy_applicable BOOLEAN DEFAULT NULL;

COMMENT ON COLUMN ingress_attestations.levy_applicable IS
    'Phase-0 structural hook. NULL until Phase-2 MMO Levy classification logic '
    'sets this field. TRUE = instruction is subject to MMO levy under the applicable '
    'jurisdiction statutory rate. FALSE = exempt. NULL = not yet classified. '
    'DO NOT read or write this column in application runtime until Phase-2.';
```

**Deliverables**
- Migration file `schema/migrations/00XY_ingress_attestations_levy_applicable_hook.sql`.
- `tasks/TSK-P0-LEVY-002/meta.yml` created/updated.
- Verifier script `scripts/db/verify_levy_applicable_hook.sh`.
- Evidence artifact `evidence/phase0/TSK-P0-LEVY-002.json`.
- Contract entry added to `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

Verifier confirms ALL of the following:

1. Column `levy_applicable` exists on `ingress_attestations`.
2. Column type is `boolean`.
3. Column is nullable (no NOT NULL constraint).
4. Column has no DEFAULT other than NULL (or an explicit `DEFAULT NULL`).
5. Column comment contains the string `Phase-0 structural hook`.
6. No application runtime code (`.cs`, `.ts`, `.js` outside `scripts/` and
   `schema/`) references `levy_applicable` — grep check, exit 1 with paths if found.
7. No index exists on `levy_applicable` alone or as the leading column — an index
   here in Phase-0 is premature and signals scope creep.
8. Migration checksum valid.
9. `ingress_attestations` row count before and after migration is identical
   (column add must not touch existing rows — confirm via count comparison in test
   environment).

**Evidence + CI gate**
- Gate runs after TSK-P0-LEVY-001 passes.
- Evidence path: `evidence/phase0/TSK-P0-LEVY-002.json`.
- Required fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `column_exists`, `type_correct`, `nullable_confirmed`, `no_default_value`,
  `no_runtime_references`, `no_premature_index`, `row_count_unchanged`,
  `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_expand_first_hook_only"`).

**Failure modes (must be explicit)**
- `ingress_attestations` not found → exit 1 with `PREREQ MISSING` message.
- Column already exists with wrong type → exit 1, show actual type.
- NOT NULL constraint present → exit 1.
- Any runtime reference found → exit 1, list paths.
- Any index found on `levy_applicable` → exit 1.
- Row count changed → exit 1.

**Notes**

Phase-0 hard boundaries:
- DO NOT add `levy_applicable` to any DTO, request model, or response model.
  It must be invisible to application layer until Phase-2.
- DO NOT add a CHECK constraint linking `levy_applicable` to `rail_type` or
  any other column. That business logic belongs in Phase-2.
- The reason this is a nullable boolean rather than an enum is deliberate:
  NULL = unclassified (not yet processed by Phase-2 logic). FALSE = explicitly
  exempt. TRUE = levy applicable. A three-state semantic captured in one column
  without an enum migration cost.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-LEVY-002
title: TSK-P0-LEVY-002 — levy_applicable column on ingress_attestations (expand-first hook)
depends_on:
- TSK-P0-LEVY-001
files_to_change:
  - db/migrations/*ingress_attestations*levy_applicable*.sql
  - db/schema.sql
  - scripts/verify/verify_ingress_attestations_levy_applicable_column.sh
verifier_command: bash scripts/verify/verify_ingress_attestations_levy_applicable_column.sh
evidence_path: evidence/phase0/ingress_attestations_levy_applicable_column_verification.json
acceptance_assertions:
  - ingress_attestations contains levy_applicable expand-first hook column with compatible default/backfill behavior
  - Verifier proves column presence/type/default on actual database schema metadata
failure_modes:
  - Column hook implemented on wrong table/column name or with breaking migration semantics
  - Evidence omits schema metadata for levy_applicable column
```

## TSK-P0-LEVY-003 — levy_calculation_records table (Phase-2 write target stub)

**Goal**
- Create the `levy_calculation_records` table as a Phase-0 structural stub. This is
  the table Phase-2 calculation logic will write computed levy obligations into — one
  row per instruction that attracts the levy. In Phase-0 it is empty, has all columns
  nullable where runtime does not yet exist, and has no triggers or functions. The
  verifier proves structural presence only.

**Phase classification rationale**
- Phase-0 hook by Q1. Creating this now defines the evidence schema for levy
  obligations before Phase-2 engineers are under delivery pressure. It also allows
  Phase-1 engineers to reference the table shape when designing the adapter interface
  (TSK-P1-ADP-001) without having to invent the schema on the fly. The structural
  decision made here — particularly the FK to `ingress_attestations` — is a
  governance decision that should be made deliberately, not under time pressure.

**Scope**
- In-scope: migration, verifier, evidence, contract.
- Out-of-scope: any function that inserts into this table. Any trigger. Any
  application code. Any NOT NULL constraints on columns that Phase-2 runtime
  will populate. Any foreign key that references a table that does not yet exist.

**Inputs / discovery (must do first)**
- Confirm `ingress_attestations` exists (FK dependency).
- Confirm `levy_rates` exists (FK dependency — TSK-P0-LEVY-001 must be complete).
- Grep for any existing `levy_calculation_records` reference.
- Locate task metadata. Confirm migration sequence number.

**Schema specification**

```sql
-- Migration: 00XZ_levy_calculation_records_hook.sql
-- Phase-0 structural hook. Phase-2 calculation logic writes to this table.
-- All columns nullable in Phase-0 except id and instruction_id.

CREATE TABLE levy_calculation_records (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- FK to the instruction that attracted the levy.
    -- NOT NULL: if this record exists, it must be linked to an instruction.
    instruction_id          UUID        NOT NULL
                                REFERENCES ingress_attestations(id)
                                ON DELETE RESTRICT,

    -- FK to the rate that was applied. Nullable in Phase-0: rate registry
    -- will be populated in Phase-2.
    levy_rate_id            UUID        REFERENCES levy_rates(id)
                                ON DELETE RESTRICT,

    -- Jurisdiction the levy was calculated under.
    jurisdiction_code       CHAR(2),

    -- Taxable transaction amount in smallest currency unit (ngwee).
    -- Nullable: Phase-2 derives this from the instruction payload.
    taxable_amount_minor    BIGINT      CHECK (taxable_amount_minor IS NULL
                                            OR taxable_amount_minor >= 0),

    -- Calculated levy amount in smallest currency unit, before cap.
    levy_amount_pre_cap     BIGINT      CHECK (levy_amount_pre_cap IS NULL
                                            OR levy_amount_pre_cap >= 0),

    -- Cap applied (from levy_rates.cap_amount_minor). NULL = no cap applied.
    cap_applied_minor       BIGINT      CHECK (cap_applied_minor IS NULL
                                            OR cap_applied_minor >= 0),

    -- Final levy amount after cap. This is the amount remitted to ZRA.
    levy_amount_final       BIGINT      CHECK (levy_amount_final IS NULL
                                            OR levy_amount_final >= 0),

    -- Currency of all monetary fields above.
    currency_code           CHAR(3),

    -- ZRA reporting period this record falls into (YYYY-MM of transaction).
    -- Nullable: Phase-2 derives from instruction timestamp.
    reporting_period        CHAR(7)     CHECK (reporting_period IS NULL
                                            OR reporting_period ~ '^\d{4}-\d{2}$'),

    -- Status of this levy record in the ZRA remittance lifecycle.
    -- Phase-0: column exists, no enforcement of valid values yet.
    -- Phase-2 will add: CHECK (levy_status IN ('CALCULATED','BATCHED','REMITTED','DISPUTED'))
    levy_status             TEXT,

    -- Timestamp when Phase-2 calculation logic wrote this record.
    calculated_at           TIMESTAMPTZ,
    calculated_by_version   TEXT,       -- Software version that ran the calculation.

    -- Audit fields.
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Unique: one levy record per instruction (an instruction cannot attract
    -- the levy twice).
    CONSTRAINT levy_calculation_one_per_instruction
        UNIQUE (instruction_id)
);

-- Lookup by reporting period for ZRA batch generation.
CREATE INDEX levy_calc_reporting_period_idx
    ON levy_calculation_records (reporting_period, jurisdiction_code)
    WHERE reporting_period IS NOT NULL;

-- Lookup by status for remittance workflow.
CREATE INDEX levy_calc_status_idx
    ON levy_calculation_records (levy_status)
    WHERE levy_status IS NOT NULL;

COMMENT ON TABLE levy_calculation_records IS
    'Phase-0 structural hook. Phase-2 MMO Levy calculation engine writes one row '
    'per levy-applicable instruction. Empty in Phase-0 and Phase-1. '
    'DO NOT write to this table until Phase-2 calculation logic is gated.';

COMMENT ON COLUMN levy_calculation_records.levy_status IS
    'Phase-0 hook: TEXT with no constraint. Phase-2 will add CHECK constraint '
    'enforcing valid lifecycle values: CALCULATED, BATCHED, REMITTED, DISPUTED.';
```

**Deliverables**
- Migration file `schema/migrations/00XZ_levy_calculation_records_hook.sql`.
- `tasks/TSK-P0-LEVY-003/meta.yml` created/updated.
- Verifier `scripts/db/verify_levy_calculation_records_hook.sh`.
- Evidence `evidence/phase0/TSK-P0-LEVY-003.json`.
- Contract entry in `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

Verifier confirms ALL of the following:

1. Table `levy_calculation_records` exists.
2. Primary key on `id` (uuid).
3. `instruction_id` is NOT NULL with FK to `ingress_attestations(id)`.
4. `levy_rate_id` is nullable with FK to `levy_rates(id)`.
5. UNIQUE constraint `levy_calculation_one_per_instruction` on `instruction_id`.
6. All monetary amount columns are nullable BIGINT with non-negative CHECK constraints.
7. `reporting_period` pattern CHECK constraint present (`^\d{4}-\d{2}$`).
8. `levy_status` is plain TEXT with no CHECK constraint (Phase-2 will add it).
9. Both indexes exist: `levy_calc_reporting_period_idx` (partial) and
   `levy_calc_status_idx` (partial).
10. Table is empty (zero rows).
11. No application runtime code references `levy_calculation_records` — grep check.
12. No trigger or function writes to this table — confirm via `pg_proc` and
    `pg_trigger` queries.
13. Table comment contains `Phase-0 structural hook`.
14. Migration checksum valid.

**Evidence + CI gate**
- Gate runs after TSK-P0-LEVY-002 passes.
- Evidence path: `evidence/phase0/TSK-P0-LEVY-003.json`.
- Required fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `table_exists`, `pk_verified`, `fk_ingress_verified`, `fk_levy_rate_verified`,
  `unique_constraint_verified`, `amount_columns_nullable`, `status_column_unconstrained`,
  `indexes_verified`, `table_is_empty`, `no_runtime_references`,
  `no_triggers_or_functions`, `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_structural_hook_only"`).

**Failure modes (must be explicit)**
- `ingress_attestations` not found → exit 1, `PREREQ MISSING`.
- `levy_rates` not found (TSK-P0-LEVY-001 not complete) → exit 1,
  `PREREQ MISSING: TSK-P0-LEVY-001 must complete before TSK-P0-LEVY-003`.
- Any trigger found on this table → exit 1, list trigger names.
- Any application runtime reference found → exit 1, list paths.
- Table not empty → exit 1 (someone seeded data — this is a Phase-0 violation).
- `levy_status` has a CHECK constraint → exit 1 (Phase-2 work crept into Phase-0).

**Notes**

Phase-0 hard boundaries:
- The `levy_status` column intentionally has NO CHECK constraint in Phase-0.
  If the agent adds a CHECK constraint with values like CALCULATED/BATCHED/REMITTED,
  it has crossed into Phase-1/Phase-2 scope. Stop and revert.
- The UNIQUE constraint on `instruction_id` is intentional and correct for Phase-0:
  it is a structural governance rule (one levy per instruction), not a runtime
  enforcement of calculation logic. This is the same pattern as terminal uniqueness
  on outbox attempt states.
- Do not add a `tenant_id` column in Phase-0. Tenant denormalisation on this table
  happens in Phase-2 when RLS is applied. The FK chain through
  `ingress_attestations` provides implicit tenant linkage until then.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-LEVY-003
title: levy_calculation_records table (Phase-2 write target stub)
depends_on:
- TSK-P0-LEVY-002
files_to_change:
  - db/migrations/*levy_calculation_records*.sql
  - db/schema.sql
  - scripts/verify/verify_levy_calculation_records_table.sh
verifier_command: bash scripts/verify/verify_levy_calculation_records_table.sh
evidence_path: evidence/phase0/levy_calculation_records_table_verification.json
acceptance_assertions:
  - levy_calculation_records table exists as Phase-2 write target stub with contract-safe schema scaffold fields
  - Verifier checks table structure specifically for levy_calculation_records and records canonical evidence
failure_modes:
  - Phase-2 write target stub represented only in docs without actual table schema anchor
  - Verifier wrapper is generic and does not target levy_calculation_records
```

## TSK-P0-LEVY-004 — levy_remittance_periods table (ZRA reporting cycle anchor)

**Goal**
- Create the `levy_remittance_periods` table as a Phase-0 structural hook. This
  table defines the ZRA reporting cycles — monthly periods for which a levy return
  must be filed. In Phase-0 it is empty and has no runtime logic. It exists to
  anchor Phase-2 batch generation and ZRA submission workflows to a governed
  period structure rather than ad-hoc date arithmetic.

**Phase classification rationale**
- Phase-0 hook by Q1. The ZRA Monthly MMO Levy Return is filed by calendar month.
  This table is the period registry — a governance primitive that defines what
  "a complete month" means in the ZRA submission context. Defining the period
  structure now prevents Phase-2 engineers from encoding month-boundary logic
  directly into application code, which is untestable and produces evidence that
  cannot be reconstructed deterministically.

**Scope**
- In-scope: migration, verifier, evidence, contract.
- Out-of-scope: any logic that creates period rows automatically. Any trigger
  that fires on month-end. Any application code. Any FK from
  `levy_calculation_records` to this table (that FK is Phase-2 — it requires
  the period to exist before the FK can be enforced, which implies runtime that
  does not exist yet).

**Inputs / discovery (must do first)**
- Grep for any existing `levy_remittance_periods` reference.
- Locate task metadata. Confirm migration sequence number.
- This task has no schema prerequisite beyond the migration framework.

**Schema specification**

```sql
-- Migration: 00XW_levy_remittance_periods_hook.sql
-- Phase-0 structural hook. ZRA monthly levy return period registry.
-- Phase-2 populates rows and links levy_calculation_records to periods.

CREATE TABLE levy_remittance_periods (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Human-readable period identifier. Format: YYYY-MM.
    -- Matches the reporting_period column on levy_calculation_records.
    period_code             CHAR(7)     NOT NULL
                                CHECK (period_code ~ '^\d{4}-\d{2}$'),

    -- Jurisdiction this period applies to.
    jurisdiction_code       CHAR(2)     NOT NULL,

    -- Inclusive start and end of the period (calendar month boundaries).
    period_start            DATE        NOT NULL,
    period_end              DATE        NOT NULL
                                CHECK (period_end >= period_start),

    -- ZRA statutory filing deadline for this period.
    -- Nullable in Phase-0: deadline rule confirmed with Compliance in Phase-2.
    -- Expected: last working day of the month following the period.
    filing_deadline         DATE        CHECK (filing_deadline IS NULL
                                            OR filing_deadline >= period_end),

    -- Lifecycle status of this period in the ZRA submission workflow.
    -- Phase-0: TEXT, no constraint. Phase-2 adds:
    -- CHECK (period_status IN ('OPEN','CALCULATING','FILED','ACCEPTED','DISPUTED'))
    period_status           TEXT,

    -- Timestamp when the ZRA return for this period was submitted.
    -- NULL until Phase-2 submission workflow exists.
    filed_at                TIMESTAMPTZ,

    -- ZRA acknowledgement reference returned on successful submission.
    -- NULL until Phase-2 live integration.
    zra_reference           TEXT,

    -- Audit.
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- One period per jurisdiction per calendar month.
    CONSTRAINT levy_periods_unique_period_jurisdiction
        UNIQUE (period_code, jurisdiction_code)
);

-- Lookup by jurisdiction for batch processing.
CREATE INDEX levy_periods_jurisdiction_idx
    ON levy_remittance_periods (jurisdiction_code, period_start DESC);

-- Lookup of open/unfiled periods.
CREATE INDEX levy_periods_status_idx
    ON levy_remittance_periods (period_status)
    WHERE period_status IS NOT NULL;

COMMENT ON TABLE levy_remittance_periods IS
    'Phase-0 structural hook. ZRA monthly MMO levy return period registry. '
    'Empty in Phase-0 and Phase-1. Phase-2 populates rows and links '
    'levy_calculation_records to periods via reporting_period = period_code. '
    'DO NOT create period rows or file returns until Phase-2 ZRA integration is gated.';

COMMENT ON COLUMN levy_remittance_periods.filing_deadline IS
    'Phase-0 hook: nullable. ZRA statutory deadline for monthly levy returns is '
    'expected to be the last working day of the following month. '
    'Confirm exact rule with Compliance Counsel before Phase-2 population.';

COMMENT ON COLUMN levy_remittance_periods.period_status IS
    'Phase-0 hook: TEXT with no constraint. Phase-2 will add CHECK enforcing '
    'lifecycle values: OPEN, CALCULATING, FILED, ACCEPTED, DISPUTED.';
```

**Deliverables**
- Migration file `schema/migrations/00XW_levy_remittance_periods_hook.sql`.
- `tasks/TSK-P0-LEVY-004/meta.yml` created/updated.
- Verifier `scripts/db/verify_levy_remittance_periods_hook.sh`.
- Evidence `evidence/phase0/TSK-P0-LEVY-004.json`.
- Contract entry in `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

Verifier confirms ALL of the following:

1. Table `levy_remittance_periods` exists.
2. Primary key on `id` (uuid).
3. UNIQUE constraint `levy_periods_unique_period_jurisdiction` on
   `(period_code, jurisdiction_code)`.
4. `period_code` CHECK constraint enforces `^\d{4}-\d{2}$` pattern.
5. `period_end >= period_start` CHECK constraint present.
6. `filing_deadline` is nullable with CHECK `filing_deadline >= period_end`.
7. `period_status` is plain TEXT with no CHECK constraint.
8. `filed_at` and `zra_reference` are both nullable.
9. Both indexes exist: `levy_periods_jurisdiction_idx` and `levy_periods_status_idx`.
10. Table is empty (zero rows).
11. No application runtime code references `levy_remittance_periods` — grep check.
12. No trigger or function creates rows automatically — confirm via `pg_proc`
    and `pg_trigger`.
13. No FK exists from `levy_calculation_records` to this table (that FK is Phase-2).
    Confirm by querying `pg_constraint`.
14. Table comment contains `Phase-0 structural hook`.
15. Migration checksum valid.

**Evidence + CI gate**
- Gate runs after TSK-P0-LEVY-003 passes.
- Evidence path: `evidence/phase0/TSK-P0-LEVY-004.json`.
- Required fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `table_exists`, `pk_verified`, `unique_constraint_verified`,
  `period_code_check_verified`, `date_range_check_verified`,
  `status_column_unconstrained`, `nullable_columns_verified`,
  `indexes_verified`, `table_is_empty`, `no_runtime_references`,
  `no_auto_triggers`, `no_premature_fk`, `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_structural_hook_only"`).

**Failure modes (must be explicit)**
- Any trigger found → exit 1, list trigger names.
- Any runtime reference found → exit 1, list paths.
- FK from `levy_calculation_records` to this table found → exit 1 with message
  `PHASE VIOLATION: FK levy_calculation_records → levy_remittance_periods belongs
  in Phase-2. Remove from this migration.`
- `period_status` has a CHECK constraint → exit 1.
- Table not empty → exit 1.
- `period_code` pattern CHECK missing or wrong → exit 1.

**Notes**

Phase-0 hard boundaries:
- DO NOT create a cron job, scheduled task, or any automation that generates
  period rows month-by-month. That is Phase-2 operational logic.
- DO NOT add a FK from `levy_calculation_records.reporting_period` (CHAR(7)) to
  `levy_remittance_periods.period_code` in Phase-0. The FK relationship between
  these two tables is deliberately deferred to Phase-2 because: (a) it requires
  period rows to exist before instructions can be processed, implying runtime that
  does not exist yet; (b) the join between them will be by `period_code` string
  match, not by UUID FK — confirm this design with the lead engineer before Phase-2.
- `zra_reference` is nullable and unconstrained. ZRA's sandbox API acknowledgement
  format is unknown until Phase-2 integration work begins. Do not invent a format
  constraint here.
- The filing deadline rule ("last working day of the following month") is the
  expected interpretation of the ZRA levy regulations, but this has not been
  confirmed with Compliance Counsel. Leave `filing_deadline` nullable and add
  a Phase-2 roadmap note in `meta.yml` to confirm this before population.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-LEVY-004
title: levy_remittance_periods table (ZRA reporting cycle anchor)
depends_on:
- TSK-P0-LEVY-003
files_to_change:
  - db/migrations/*levy_remittance_periods*.sql
  - db/schema.sql
  - scripts/verify/verify_levy_remittance_periods_table.sh
verifier_command: bash scripts/verify/verify_levy_remittance_periods_table.sh
evidence_path: evidence/phase0/levy_remittance_periods_table_verification.json
acceptance_assertions:
  - levy_remittance_periods table exists with remittance cycle anchor fields needed for ZRA reporting periods
  - Verifier validates schema contract and evidence is generated from actual introspection
failure_modes:
  - Remittance-period anchor omitted or modeled with non-deterministic placeholder schema
  - Evidence path/file name remains generic and not levy_remittance_periods-specific
```

## TSK-P0-KYC-001 — kyc_provider_registry table (trusted external provider registry)

**Goal**
- Create the `kyc_provider_registry` table as a Phase-0 structural hook: a governed
  registry of licensed KYC providers whose verification hashes Symphony will accept.
  No provider API calls. No verification logic. A registry of trusted signers only,
  analogous to `levy_rates` for levy governance — a table that Phase-2 application
  logic will read to validate that an incoming KYC hash was signed by a known,
  active provider.

**Phase classification rationale**
- Phase-0 by Q1 of the classification decision tree: purely structural, no runtime
  business outcome semantics. The provider registry is a governance primitive that
  prevents Phase-2 engineers from hardcoding provider public keys in application
  code (a security defect) or accepting KYC hashes from unregistered providers
  (a regulatory defect). Creating it now also allows the regulatory affairs hire
  to confirm which providers are BoZ-recognised during Phase-1, before Phase-2
  engineering begins.

**Scope**
- In-scope: migration creating `kyc_provider_registry`, column constraints, indexes,
  verifier, deterministic evidence artifact, contract wiring.
- Out-of-scope: any function that reads this table to validate a hash. Any
  application code referencing this table at runtime. Any insertion of provider
  rows (Phase-2 task requiring Compliance sign-off on which providers are
  BoZ-recognised). Any NOT NULL constraint on columns that runtime does not yet write.

**Inputs / discovery (must do first)**
- Locate current task metadata and status in `tasks/TSK-P0-KYC-001/meta.yml`
  (create if it does not exist; status = roadmap → in-progress on start).
- Grep for any existing migration referencing `kyc_provider_registry` to confirm
  this is a new table and not a rename.
- Confirm no existing contract entry for this task (or add it if somehow present).
- Confirm the next available migration sequence number in `schema/migrations/`.

**Schema specification (implement exactly as described)**

```sql
-- Migration: 00XA_kyc_provider_registry_hook.sql
-- Phase-0 structural hook. No runtime reads permitted until Phase-2.
-- Symphony never calls providers directly. It only trusts hashes signed by
-- providers registered here.

CREATE TABLE kyc_provider_registry (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Short, unique code for this provider used as a foreign key target.
    -- e.g. 'PELEZA-ZM', 'SMILEID-ZM', 'INTERNAL-TEST'
    provider_code           TEXT        NOT NULL,

    -- Human-readable name.
    provider_name           TEXT        NOT NULL,

    -- Country this provider is licensed to operate in (ISO 3166-1 alpha-2).
    jurisdiction_code       CHAR(2)     NOT NULL,

    -- The provider's current public key for verifying their hash signatures.
    -- PEM-encoded Ed25519 or ECDSA P-256 public key. Nullable in Phase-0:
    -- specific provider keys confirmed with Compliance in Phase-2.
    -- Phase-2 will enforce NOT NULL.
    public_key_pem          TEXT,

    -- Algorithm used by this provider to sign verification hashes.
    -- Nullable in Phase-0. Phase-2 will add CHECK constraint.
    -- Expected values: 'Ed25519', 'ECDSA-P256', 'HMAC-SHA256'
    signing_algorithm       TEXT,

    -- BoZ reference or licence number for this provider, if applicable.
    -- Nullable: to be confirmed with Compliance during Phase-1.
    boz_licence_reference   TEXT,

    -- Whether this provider is currently active and accepting new verifications.
    -- NULL in Phase-0 (unclassified). Phase-2 sets to TRUE on first activation.
    is_active               BOOLEAN     DEFAULT NULL,

    -- Inclusive start of this provider's registration validity.
    -- Nullable: Phase-2 sets when provider is onboarded.
    active_from             DATE,

    -- End of validity. NULL = currently active.
    active_to               DATE        CHECK (active_to IS NULL OR active_from IS NULL
                                            OR active_to >= active_from),

    -- Audit fields.
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by              TEXT        NOT NULL DEFAULT current_user,
    updated_at              TIMESTAMPTZ,

    -- One registration per provider code (codes are unique system-wide).
    CONSTRAINT kyc_provider_unique_code
        UNIQUE (provider_code),

    -- One active key per provider per jurisdiction at any time.
    -- Partial unique index below enforces this.
    CONSTRAINT kyc_provider_unique_active_per_jurisdiction
        UNIQUE (jurisdiction_code, provider_code)
);

-- Only one active provider registration per jurisdiction per code.
CREATE UNIQUE INDEX kyc_provider_active_idx
    ON kyc_provider_registry (jurisdiction_code, provider_code)
    WHERE active_to IS NULL AND is_active IS NOT FALSE;

-- Lookup by jurisdiction for Phase-2 validation logic.
CREATE INDEX kyc_provider_jurisdiction_idx
    ON kyc_provider_registry (jurisdiction_code, active_from DESC);

COMMENT ON TABLE kyc_provider_registry IS
    'Phase-0 structural hook. Registry of licensed external KYC providers whose '
    'verification hashes Symphony accepts. Symphony never calls providers directly. '
    'Phase-2 populates rows once Compliance confirms which providers are '
    'BoZ-recognised. DO NOT read this table in application runtime until Phase-2.';

COMMENT ON COLUMN kyc_provider_registry.public_key_pem IS
    'Phase-0 hook: nullable. Provider public key for verifying hash signatures. '
    'Phase-2 will enforce NOT NULL and validate key format on insert. '
    'Confirm exact key format (Ed25519 vs ECDSA) with provider before Phase-2 population.';

COMMENT ON COLUMN kyc_provider_registry.signing_algorithm IS
    'Phase-0 hook: TEXT, no constraint. Phase-2 will add CHECK enforcing '
    'accepted values: Ed25519, ECDSA-P256, HMAC-SHA256.';
```

**Deliverables**
- Migration file `schema/migrations/00XA_kyc_provider_registry_hook.sql` exactly as specified.
- `tasks/TSK-P0-KYC-001/meta.yml` created/updated: status = complete, phase = 0,
  migration reference, verifier path, evidence path.
- Verifier script `scripts/db/verify_kyc_provider_registry_hook.sh` (see acceptance criteria).
- Deterministic evidence artifact at `evidence/phase0/TSK-P0-KYC-001.json`.
- Contract entry added to `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

The verifier must confirm ALL of the following and exit 0 only if every check passes:

1. Table `kyc_provider_registry` exists in the target schema.
2. Columns present with correct types: `id` (uuid), `provider_code` (text, not null),
   `provider_name` (text, not null), `jurisdiction_code` (char(2), not null),
   `public_key_pem` (text, nullable), `signing_algorithm` (text, nullable),
   `boz_licence_reference` (text, nullable), `is_active` (boolean, nullable, default null),
   `active_from` (date, nullable), `active_to` (date, nullable),
   `created_at` (timestamptz, not null), `created_by` (text, not null),
   `updated_at` (timestamptz, nullable).
3. UNIQUE constraint `kyc_provider_unique_code` on `provider_code` present.
4. UNIQUE constraint `kyc_provider_unique_active_per_jurisdiction` present.
5. Partial unique index `kyc_provider_active_idx` exists on
   `(jurisdiction_code, provider_code) WHERE active_to IS NULL AND is_active IS NOT FALSE`.
6. Lookup index `kyc_provider_jurisdiction_idx` exists.
7. `active_to` CHECK constraint present.
8. Table comment contains the string `Phase-0 structural hook`.
9. No application code (`.cs`, `.ts`, `.js` files outside `scripts/` and `schema/`)
   references `kyc_provider_registry` — confirm by grep. If any references found,
   exit 1 with the file paths listed.
10. Table is empty (zero rows — providers are Phase-2 data requiring Compliance sign-off).
11. Migration file checksum matches the registered checksum in the migration registry.

**Evidence + CI gate**
- Add an ordered check in `pre_ci.sh` and CI so this gate runs in Stage 1-C,
  after TSK-P0-LEVY-004 and before TSK-P0-KYC-002.
- Evidence path: `evidence/phase0/TSK-P0-KYC-001.json`.
- Required evidence fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `table_exists`, `column_count_verified`, `constraints_verified`,
  `indexes_verified`, `table_is_empty`, `no_runtime_references`,
  `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_structural_hook_only"`).

**Failure modes (must be explicit)**
- Table already exists with different column spec → exit 1, list column
  discrepancies, do not silently alter.
- Table is not empty → exit 1 with message: `PHASE VIOLATION: kyc_provider_registry
  contains rows. Provider registration requires Compliance sign-off and belongs in Phase-2.`
- Any runtime code reference found → exit 1, list file paths.
- `signing_algorithm` has a CHECK constraint → exit 1 (Phase-2 scope crept in).
- Migration checksum mismatch → exit 1 with both checksums shown.
- Missing prereq (migration framework not initialised) → exit 1 with message
  `PREREQ MISSING: migration framework not initialised`.
- Evidence file not emitted for any reason → CI exits 1.

**Notes**

Phase-0 hard boundaries for this task:
- DO NOT insert any rows into `kyc_provider_registry`. Provider registration
  requires Compliance to confirm BoZ recognition status and legal due diligence
  that does not exist yet.
- DO NOT create any function, stored procedure, or trigger that reads this table.
- DO NOT add `kyc_provider_registry` to any application dependency injection or
  repository class.
- The list of Zambian KYC providers expected in Phase-2 is: Peleza (Kenya-origin,
  Zambian data coverage via NRCA), SmileSID (pan-African facial biometric
  verification). Neither has been formally evaluated for BoZ recognition status.
  The regulatory affairs hire must confirm this during Phase-1.
- `signing_algorithm` is intentionally unconstrained in Phase-0. The provider's
  signing scheme must be confirmed technically before enforcing an enum. Peleza
  and SmileSID may differ.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-KYC-001
title: kyc_provider_registry table (trusted external provider registry)
depends_on:
- TSK-P0-LEVY-004
files_to_change:
  - db/migrations/*kyc_provider_registry*.sql
  - db/schema.sql
  - scripts/verify/verify_kyc_provider_registry_table.sh
verifier_command: bash scripts/verify/verify_kyc_provider_registry_table.sh
evidence_path: evidence/phase0/kyc_provider_registry_table_verification.json
acceptance_assertions:
  - kyc_provider_registry table exists with provider identifier, trust/active flags, and versioning/audit columns required by the task prompt
  - verification script asserts schema shape against canonical database metadata and exits non-zero on drift
failure_modes:
  - Table created without trusted external provider registry semantics (missing trust/approval metadata)
  - Evidence generated from static stub JSON instead of live schema verification
```

## TSK-P0-KYC-002 — kyc_verification_records table (hash anchor for external verifications)

**Goal**
- Create the `kyc_verification_records` table as a Phase-0 structural hook. This
  is the table that Phase-2's KYC hash bridge endpoint will write into — one row
  per KYC verification performed by an external provider on a Symphony member.
  Symphony never sees the identity document. It stores only a provider-signed hash
  of the verification outcome, the outcome code, and the signing metadata needed
  to verify the provider's signature independently.

  This table is the answer to the FIC Act AML/Customer-ID 10-year retention
  obligation. The retention class is FIC_AML_CUSTOMER_ID (10 years), not
  DATA_PROTECTION_PII (1 year), because Symphony is retaining evidence of
  verification, not the identity document itself.

**Phase classification rationale**
- Phase-0 hook by Q1 and the expand-first migration safety rule. This table will
  be referenced by the IPDR pack assembly (F-002 in the PRD) as Section 8
  (KYC Evidence). If the table does not exist when IPDR assembly is implemented
  in Phase-1, the assembly code will need to handle its absence as an edge case,
  which is a code smell. Creating the schema now — empty, with no write path —
  costs one day and produces a clean IPDR seam.

**Scope**
- In-scope: migration creating `kyc_verification_records`, column constraints,
  indexes, verifier, evidence, contract wiring.
- Out-of-scope: any endpoint that writes to this table. Any function that
  validates a provider signature. Any PII column of any kind. Any NOT NULL
  constraint on columns that Phase-2 runtime does not yet write. Any application
  code referencing this table.

**Inputs / discovery (must do first)**
- Confirm `kyc_provider_registry` exists (FK dependency — TSK-P0-KYC-001 must
  be complete).
- Confirm `tenant_members` table exists (FK dependency — it is a Phase-0 primitive).
  If absent, stop: `PREREQ MISSING: tenant_members table not found`.
- Grep for any existing `kyc_verification_records` reference.
- Locate task metadata. Confirm migration sequence number.

**Schema specification**

```sql
-- Migration: 00XB_kyc_verification_records_hook.sql
-- Phase-0 structural hook. Phase-2 KYC hash bridge endpoint writes to this table.
-- Symphony stores ONLY the hash and signature, NEVER the raw identity document.
-- Retention class: FIC_AML_CUSTOMER_ID (10 years). See PHASE0_retention_policy.md.

CREATE TABLE kyc_verification_records (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- FK to the Symphony member whose identity was verified.
    -- NOT NULL: a KYC record without a member is meaningless.
    member_id               UUID        NOT NULL
                                REFERENCES public.tenant_members(member_id)
                                ON DELETE RESTRICT,

    -- FK to the provider who performed the verification.
    -- Nullable in Phase-0: provider registry not yet populated.
    -- Phase-2 will enforce NOT NULL.
    provider_id             UUID        REFERENCES kyc_provider_registry(id)
                                ON DELETE RESTRICT,

    -- Short code of the provider (denormalised for log/evidence readability).
    -- Nullable in Phase-0. Phase-2 derives from provider_id join.
    provider_code           TEXT,

    -- The verification outcome as returned by the provider.
    -- Phase-0: TEXT, no constraint.
    -- Phase-2 will add: CHECK (outcome IN ('VERIFIED','FAILED','PARTIAL','EXPIRED'))
    outcome                 TEXT,

    -- The method of verification performed by the provider.
    -- Phase-0: TEXT, no constraint.
    -- Phase-2 will add: CHECK (verification_method IN (
    --   'NRC_LOOKUP',         -- National Registration Card lookup via NRCA
    --   'FACIAL_BIOMETRIC',   -- Live facial biometric match
    --   'DOCUMENT_SCAN',      -- Document OCR + liveness
    --   'MANUAL_REVIEW'       -- Human review by provider agent
    -- ))
    verification_method     TEXT,

    -- The provider's signed hash of the verification outcome.
    -- This is what Symphony can present to BoZ as evidence. The hash is
    -- computed by the provider over a canonical representation of the outcome
    -- (member reference + outcome code + timestamp + provider nonce).
    -- Nullable in Phase-0: no write path exists yet.
    verification_hash       TEXT,

    -- Algorithm used to produce verification_hash. Must match provider's
    -- registered signing_algorithm in kyc_provider_registry.
    -- Nullable in Phase-0.
    hash_algorithm          TEXT,

    -- Provider's digital signature over verification_hash using their private key.
    -- Base64-encoded. Verified using kyc_provider_registry.public_key_pem.
    -- Nullable in Phase-0: no signing pipeline exists yet.
    provider_signature      TEXT,

    -- Key version from provider at the time of signing.
    -- Required for historical signature verification if provider rotates keys.
    -- Nullable in Phase-0.
    provider_key_version    TEXT,

    -- The provider's own reference ID for this verification event.
    -- Stored for cross-reference during dispute resolution.
    -- Nullable in Phase-0.
    provider_reference      TEXT,

    -- Jurisdiction this verification was performed under (NRCA = ZM).
    jurisdiction_code       CHAR(2),

    -- Document type verified (if applicable).
    -- Phase-0: TEXT, no constraint.
    -- Phase-2 will add: CHECK (document_type IN ('NRC','PASSPORT','DRIVERS_LICENCE'))
    document_type           TEXT,

    -- Timestamp when the verification was performed at the provider.
    -- Nullable in Phase-0.
    verified_at_provider    TIMESTAMPTZ,

    -- Timestamp when Symphony received and anchored this hash.
    anchored_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Retention classification. MUST be FIC_AML_CUSTOMER_ID (10 years).
    -- This is the only column with a Phase-0 constraint on its value,
    -- because the wrong retention class is a regulatory defect from day one.
    retention_class         TEXT        NOT NULL
                                DEFAULT 'FIC_AML_CUSTOMER_ID'
                                CHECK (retention_class = 'FIC_AML_CUSTOMER_ID'),

    -- Audit fields.
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by              TEXT        NOT NULL DEFAULT current_user
);

-- Lookup: all KYC records for a given member (for IPDR assembly).
CREATE INDEX kyc_verification_member_idx
    ON kyc_verification_records (member_id, anchored_at DESC);

-- Lookup: all records for a given provider (for provider audit).
CREATE INDEX kyc_verification_provider_idx
    ON kyc_verification_records (provider_id)
    WHERE provider_id IS NOT NULL;

-- Lookup: by jurisdiction and outcome for BoZ examiner access.
CREATE INDEX kyc_verification_jurisdiction_outcome_idx
    ON kyc_verification_records (jurisdiction_code, outcome)
    WHERE outcome IS NOT NULL;

COMMENT ON TABLE kyc_verification_records IS
    'Phase-0 structural hook. Anchors cryptographic evidence that an external '
    'KYC provider verified a Symphony member identity. Symphony never holds raw '
    'identity documents. Retention class: FIC_AML_CUSTOMER_ID (10 years per '
    'FIC Act AML/Customer-ID record obligation). Phase-2 KYC hash bridge endpoint '
    'writes to this table. DO NOT write to this table until Phase-2 is gated.';

COMMENT ON COLUMN kyc_verification_records.verification_hash IS
    'Provider-signed hash of the verification outcome. This is Symphony''s '
    'evidence of KYC — not the document. The hash can be presented to BoZ as '
    'non-repudiable proof that a licensed provider verified this member.';

COMMENT ON COLUMN kyc_verification_records.retention_class IS
    'Retention class enforced at schema level. Must be FIC_AML_CUSTOMER_ID. '
    'FIC Act requires 10-year retention of AML/Customer-ID records. '
    'This column may not be overridden to a shorter class under any circumstance.';

COMMENT ON COLUMN kyc_verification_records.outcome IS
    'Phase-0 hook: TEXT with no constraint. Phase-2 will add CHECK enforcing '
    'valid lifecycle values: VERIFIED, FAILED, PARTIAL, EXPIRED.';

COMMENT ON COLUMN kyc_verification_records.verification_method IS
    'Phase-0 hook: TEXT with no constraint. Phase-2 will add CHECK enforcing '
    'valid method values: NRC_LOOKUP, FACIAL_BIOMETRIC, DOCUMENT_SCAN, MANUAL_REVIEW.';
```

**Deliverables**
- Migration file `schema/migrations/00XB_kyc_verification_records_hook.sql`.
- `tasks/TSK-P0-KYC-002/meta.yml` created/updated.
- Verifier script `scripts/db/verify_kyc_verification_records_hook.sh`.
- Evidence artifact `evidence/phase0/TSK-P0-KYC-002.json`.
- Contract entry added to `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

Verifier confirms ALL of the following:

1. Table `kyc_verification_records` exists.
2. Primary key on `id` (uuid).
3. `member_id` is NOT NULL with FK to `tenant_members(member_id) ON DELETE RESTRICT`.
4. `provider_id` is nullable with FK to `kyc_provider_registry(id) ON DELETE RESTRICT`.
5. `retention_class` is NOT NULL with DEFAULT 'FIC_AML_CUSTOMER_ID' and a CHECK
   constraint that enforces only this value. This is intentionally strict in Phase-0.
6. `outcome`, `verification_method`, `document_type` are all plain TEXT with
   no CHECK constraints (Phase-2 will add them).
7. All hash/signature columns are nullable: `verification_hash`, `hash_algorithm`,
   `provider_signature`, `provider_key_version`, `provider_reference`.
8. `anchored_at` is NOT NULL with DEFAULT now(). `created_at` is NOT NULL.
9. `verified_at_provider` is nullable.
10. All three indexes exist: `kyc_verification_member_idx`,
    `kyc_verification_provider_idx` (partial), `kyc_verification_jurisdiction_outcome_idx`
    (partial).
11. Table is empty (zero rows).
12. No application runtime code references `kyc_verification_records` — grep check,
    exit 1 with paths if found.
13. No trigger or function writes to this table — confirm via `pg_proc` and `pg_trigger`.
14. Table comment contains `Phase-0 structural hook`.
15. Migration checksum valid.

**Evidence + CI gate**
- Gate runs after TSK-P0-KYC-001 passes.
- Evidence path: `evidence/phase0/TSK-P0-KYC-002.json`.
- Required fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `table_exists`, `pk_verified`, `fk_members_verified`, `fk_provider_verified`,
  `retention_class_constraint_verified`, `hash_columns_nullable`,
  `outcome_columns_unconstrained`, `indexes_verified`, `table_is_empty`,
  `no_runtime_references`, `no_triggers_or_functions`, `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_structural_hook_only"`).

**Failure modes (must be explicit)**
- `tenant_members` table not found → exit 1 with `PREREQ MISSING: tenant_members table not found`.
- `kyc_provider_registry` not found (TSK-P0-KYC-001 not complete) → exit 1 with
  `PREREQ MISSING: TSK-P0-KYC-001 must complete before TSK-P0-KYC-002`.
- `retention_class` column missing, nullable, or CHECK constraint absent → exit 1.
  This is non-negotiable: the retention class must be enforced at the schema level.
- Any PII column detected (e.g., `nrc_number`, `full_name`, `date_of_birth`,
  `photo_url`) → exit 1 with message: `ARCHITECTURE VIOLATION: PII columns must
  not appear in kyc_verification_records. Symphony stores hashes, not identity data.`
- `outcome` or `verification_method` has a CHECK constraint → exit 1 (Phase-2 scope).
- Any trigger found → exit 1, list trigger names.
- Any runtime reference found → exit 1, list paths.
- Table not empty → exit 1.

**Notes**

Phase-0 hard boundaries:
- DO NOT add any column that contains or implies PII: no `nrc_number`, `passport_number`,
  `full_name`, `date_of_birth`, `photo_url`, `address`, `phone_number`. If a PII
  column appears in the schema, it is an architectural violation not a phase violation.
  Symphony's non-custodial posture for identity means PII never enters this table.
- DO NOT add `kyc_verification_records` to any DTO or API response model. The
  hash bridge endpoint (Phase-2, TSK-P1-LED-004 extension) is the only write path.
- The `retention_class` CHECK constraint is intentionally enforced in Phase-0
  because classifying these records as anything shorter than 10 years (e.g.,
  defaulting to DATA_PROTECTION_PII at 1 year) would be a regulatory defect
  from the day the table is created.
- Phase-2 will need to confirm with Compliance whether the BoZ examiner needs
  access to individual verification hashes or only to aggregate KYC completion
  rates. This affects the BoZ observability view (TSK-P1-REG-001 extension).

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-KYC-002
title: kyc_verification_records table (hash anchor for external verifications)
depends_on:
- TSK-P0-KYC-001
files_to_change:
  - schema/migrations/*kyc_verification_records*_hook.sql
  - scripts/db/verify_kyc_verification_records_hook.sh
  - docs/PHASE0/phase0_contract.yml
  - tasks/TSK-P0-KYC-002/meta.yml
  - evidence/phase0/TSK-P0-KYC-002.json
verifier_command: bash scripts/db/verify_kyc_verification_records_hook.sh
evidence_path: evidence/phase0/TSK-P0-KYC-002.json
acceptance_assertions:
  - kyc_verification_records table exists with external verification reference fields and hash anchor materialization columns
  - Verifier proves foreign-key linkage to public.tenant_members(member_id) and provider registry integration
  - Evidence exists exactly at evidence/phase0/TSK-P0-KYC-002.json and is schema-valid
failure_modes:
  - Hash anchor or provider linkage columns missing or nullable contrary to task requirements
  - Verifier checks file presence only and does not validate live table schema
```

## TSK-P0-KYC-003 — kyc_hold column on payment_outbox_pending (instruction-level KYC gate hook)

**Goal**
- Add a nullable `kyc_hold` boolean column to `payment_outbox_pending` as a Phase-0
  expand-first hook. This is the flag that Phase-2 instruction routing logic will
  use to hold an instruction pending KYC verification of the beneficiary. In Phase-0
  it is nullable, always NULL at runtime, and has no enforcement. No instruction is
  held. No check is performed. The column exists so that Phase-2 can add routing
  logic without a migration against a table that by then may be under production load.

  This is the structural prerequisite for the `KYC_HOLD` exception type described
  in the roadmap. The exception state machine (Phase-1, F-001) references the
  outbox state; this column is the state the exception engine will read.

**Phase classification rationale**
- Phase-0 by Q1 and the expand-first migration safety rule, identical reasoning
  to `levy_applicable` on `ingress_attestations`. Adding a nullable column to a
  high-write table in production is a safe no-op; adding it after load begins
  is a risk with no upside.

**Scope**
- In-scope: migration adding the column, verifier, evidence, contract wiring.
- Out-of-scope: any application code that reads or writes `kyc_hold`. Any
  NOT NULL constraint. Any DEFAULT value other than NULL. Any CHECK constraint
  linking `kyc_hold` to any other column. Any routing logic that gates on this
  column.

**Inputs / discovery (must do first)**
- Confirm `payment_outbox_pending` exists (it is a Phase-0 primitive). If absent:
  `PREREQ MISSING: payment_outbox_pending table not found`.
- Grep for any existing `kyc_hold` column reference to confirm this is new.
- Locate task metadata. Confirm migration sequence number.

**Schema specification**

```sql
-- Migration: 00XC_payment_outbox_pending_kyc_hold_hook.sql
-- Phase-0 expand-first hook. Column is nullable and always NULL until Phase-2
-- KYC-gated routing logic is implemented.

ALTER TABLE payment_outbox_pending
    ADD COLUMN IF NOT EXISTS kyc_hold BOOLEAN DEFAULT NULL;

COMMENT ON COLUMN payment_outbox_pending.kyc_hold IS
    'Phase-0 structural hook. NULL until Phase-2 KYC-gated routing logic '
    'sets this field. TRUE = instruction is held pending beneficiary KYC '
    'verification. FALSE = KYC gate passed, instruction may proceed. '
    'NULL = KYC gate not yet evaluated (pre-Phase-2 state for all rows). '
    'DO NOT read or write this column in application runtime until Phase-2. '
    'When TRUE, Phase-2 exception engine opens a KYC_HOLD exception record.';
```

**Deliverables**
- Migration file `schema/migrations/00XC_payment_outbox_pending_kyc_hold_hook.sql`.
- `tasks/TSK-P0-KYC-003/meta.yml` created/updated.
- Verifier script `scripts/db/verify_kyc_hold_hook.sh`.
- Evidence artifact `evidence/phase0/TSK-P0-KYC-003.json`.
- Contract entry added to `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

Verifier confirms ALL of the following:

1. Column `kyc_hold` exists on `payment_outbox_pending`.
2. Column type is `boolean`.
3. Column is nullable (no NOT NULL constraint).
4. Column has no DEFAULT other than NULL (or an explicit `DEFAULT NULL`).
5. Column comment contains the string `Phase-0 structural hook`.
6. No application runtime code (`.cs`, `.ts`, `.js` outside `scripts/` and
   `schema/`) references `kyc_hold` — grep check, exit 1 with paths if found.
7. No index exists on `kyc_hold` alone or as the leading column — premature
   in Phase-0, signals scope creep.
8. Migration checksum valid.
9. `payment_outbox_pending` row count before and after migration is identical.

**Evidence + CI gate**
- Gate runs after TSK-P0-KYC-002 passes.
- Evidence path: `evidence/phase0/TSK-P0-KYC-003.json`.
- Required fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `column_exists`, `type_correct`, `nullable_confirmed`, `no_default_value`,
  `no_runtime_references`, `no_premature_index`, `row_count_unchanged`,
  `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_expand_first_hook_only"`).

**Failure modes (must be explicit)**
- `payment_outbox_pending` not found → exit 1 with `PREREQ MISSING` message.
- Column already exists with wrong type → exit 1, show actual type.
- NOT NULL constraint present → exit 1.
- Any runtime reference found → exit 1, list paths.
- Any index found on `kyc_hold` → exit 1.
- Row count changed → exit 1.

**Notes**

Phase-0 hard boundaries:
- DO NOT add `kyc_hold` to any DTO, request model, or response model.
- DO NOT add a CHECK constraint linking `kyc_hold` to `kyc_verification_records`
  or any other table. That business logic belongs in Phase-2.
- Three-state semantic is intentional: NULL = not yet evaluated by Phase-2 logic,
  FALSE = KYC gate passed, TRUE = on hold. All existing rows in Phase-0 and
  Phase-1 will have NULL, which is correct — the gate does not apply until Phase-2
  activates it.
- The `KYC_HOLD` exception type referenced in the PRD roadmap depends on this
  column being non-null (TRUE) to trigger the exception opening. Phase-2 will
  add the routing check and the exception engine hook simultaneously. They are
  a single Phase-2 task, not separable.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-KYC-003
title: kyc_hold column on payment_outbox_pending (instruction-level KYC gate hook)
depends_on:
- TSK-P0-KYC-002
files_to_change:
  - schema/migrations/*payment_outbox_pending*kyc_hold*_hook.sql
  - scripts/db/verify_kyc_hold_hook.sh
  - docs/PHASE0/phase0_contract.yml
  - tasks/TSK-P0-KYC-003/meta.yml
  - evidence/phase0/TSK-P0-KYC-003.json
verifier_command: bash scripts/db/verify_kyc_hold_hook.sh
evidence_path: evidence/phase0/TSK-P0-KYC-003.json
acceptance_assertions:
  - payment_outbox_pending contains kyc_hold column with expand-first compatible defaults/backfill posture
  - Verifier proves existing writes remain valid while KYC gate hook is present
  - Evidence exists exactly at evidence/phase0/TSK-P0-KYC-003.json and is schema-valid
failure_modes:
  - Column added with destructive migration or incompatible nullability/default behavior
  - Verifier checks file presence only and does not validate live schema/index/runtime-reference constraints
```

## TSK-P0-KYC-004 — kyc_retention_policy_declaration (governance document anchor)

**Goal**
- Create a `kyc_retention_policy` table as a Phase-0 structural and governance
  hook: a single-row declaration table that records the retention policy parameters
  for KYC evidence in Symphony. This is not a configuration table — it is an
  immutable governance record. It exists to create a machine-readable, BoZ-auditable
  anchor for the claim "Symphony retains KYC evidence for 10 years under the FIC
  Act AML/Customer-ID class."

  This table has exactly one row in Phase-0 (the Zambia FIC Act declaration) and
  is the only table in this pack that is seeded in Phase-0, because the retention
  obligation is a legal fact that is known now, not a configuration that requires
  Compliance discovery. The regulatory affairs hire has no decision to make here
  — the 10-year obligation is in the FIC Act.

**Phase classification rationale**
- Phase-0 by Q1 for the structural component. The Phase-0 seeding exception
  (one row) is justified because this is a governance declaration, not operational
  data. The pattern is the same as `risk_formula_versions` in HIER-007 — a
  structural registry whose first row is a known-good system default, not a
  user/operator choice. The difference from the levy tables is that here the
  statutory fact (10 years, FIC Act) is fully confirmed and does not require
  Compliance discovery.

**Scope**
- In-scope: migration creating the table, seeding the one Zambia FIC Act row,
  verifier, evidence, contract wiring.
- Out-of-scope: any additional rows. Any application code that writes to this table.
  Any function that reads this table to govern other tables (that is Phase-2 work
  in the retention classification engine).

**Inputs / discovery (must do first)**
- Grep for any existing `kyc_retention_policy` reference to confirm this is new.
- Locate task metadata. Confirm migration sequence number.
- No schema prerequisites beyond the migration framework.

**Schema specification**

```sql
-- Migration: 00XD_kyc_retention_policy_hook.sql
-- Phase-0 structural hook and governance declaration.
-- This table has exactly one row per jurisdiction per retention class.
-- The Zambia row is seeded here because the FIC Act 10-year obligation is a
-- confirmed statutory fact, not a Compliance discovery item.

CREATE TABLE kyc_retention_policy (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Jurisdiction this policy applies to.
    jurisdiction_code       CHAR(2)     NOT NULL,

    -- Retention class this row governs. Must match values used in
    -- kyc_verification_records.retention_class.
    retention_class         TEXT        NOT NULL,

    -- Statutory instrument or Act that mandates this retention period.
    statutory_reference     TEXT        NOT NULL,

    -- Retention period in years.
    retention_years         INTEGER     NOT NULL CHECK (retention_years > 0),

    -- Plain-language description of what this class covers.
    description             TEXT        NOT NULL,

    -- Whether this policy is currently active and governs new records.
    is_active               BOOLEAN     NOT NULL DEFAULT TRUE,

    -- Audit fields. This table is append-only; updates are forbidden.
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by              TEXT        NOT NULL DEFAULT current_user,

    -- One active policy per jurisdiction per class.
    CONSTRAINT kyc_retention_unique_active_class
        UNIQUE (jurisdiction_code, retention_class)
);

-- Append-only enforcement: prevent UPDATE and DELETE.
-- Phase-0 creates the rule; Phase-2 may wrap in a more formal immutability trigger.
CREATE RULE kyc_retention_policy_no_update AS
    ON UPDATE TO kyc_retention_policy DO INSTEAD NOTHING;

CREATE RULE kyc_retention_policy_no_delete AS
    ON DELETE TO kyc_retention_policy DO INSTEAD NOTHING;

COMMENT ON TABLE kyc_retention_policy IS
    'Phase-0 governance declaration. Immutable registry of KYC evidence retention '
    'policies by jurisdiction and retention class. Append-only: UPDATE and DELETE '
    'are rejected by rules. The Zambia FIC Act row is seeded in Phase-0 because '
    'the 10-year obligation is a confirmed statutory fact.';

COMMENT ON RULE kyc_retention_policy_no_update ON kyc_retention_policy IS
    'Immutability enforcement. KYC retention policies are statutory facts. '
    'To supersede a policy, add a new row with updated parameters.';

-- Seed the confirmed Zambia FIC Act policy.
-- This is the ONLY row permitted in Phase-0.
INSERT INTO kyc_retention_policy (
    jurisdiction_code,
    retention_class,
    statutory_reference,
    retention_years,
    description
) VALUES (
    'ZM',
    'FIC_AML_CUSTOMER_ID',
    'Financial Intelligence Centre Act, Chapter 87 of the Laws of Zambia, Section 21 — Customer Identification Records',
    10,
    'KYC verification evidence for Zambian members under FIC Act AML obligations. '
    'Includes verification hash, outcome code, provider reference, and signing '
    'metadata. Does not include raw identity documents (held by licensed provider). '
    'Retention period: 10 years from date of verification.'
);
```

**Deliverables**
- Migration file `schema/migrations/00XD_kyc_retention_policy_hook.sql`.
- `tasks/TSK-P0-KYC-004/meta.yml` created/updated.
- Verifier script `scripts/db/verify_kyc_retention_policy_hook.sh`.
- Evidence artifact `evidence/phase0/TSK-P0-KYC-004.json`.
- Contract entry added to `docs/PHASE0/phase0_contract.yml`.

**Acceptance criteria**

Verifier confirms ALL of the following:

1. Table `kyc_retention_policy` exists.
2. Primary key on `id` (uuid).
3. UNIQUE constraint `kyc_retention_unique_active_class` on
   `(jurisdiction_code, retention_class)`.
4. `retention_years` CHECK constraint present (`retention_years > 0`).
5. `is_active` is NOT NULL with DEFAULT TRUE.
6. `statutory_reference` is NOT NULL.
7. Append-only rules exist: `kyc_retention_policy_no_update` and
   `kyc_retention_policy_no_delete` on this table — confirm via `pg_rules`.
8. Table contains exactly one row.
9. The one row has: `jurisdiction_code = 'ZM'`,
   `retention_class = 'FIC_AML_CUSTOMER_ID'`, `retention_years = 10`,
   `statutory_reference` contains the string `Financial Intelligence Centre Act`.
10. No application runtime code references `kyc_retention_policy` — grep check.
    (Exception: retention classification scripts in `scripts/` are permitted.)
11. Table comment contains `Phase-0 governance declaration`.
12. Migration checksum valid.

**Evidence + CI gate**
- Gate runs after TSK-P0-KYC-003 passes.
- Evidence path: `evidence/phase0/TSK-P0-KYC-004.json`.
- Required fields: `task_id`, `git_sha`, `timestamp_utc`, `pass`,
  `table_exists`, `pk_verified`, `unique_constraint_verified`,
  `retention_years_check_verified`, `append_only_rules_verified`,
  `row_count_is_one`, `zm_fic_act_row_verified`, `statutory_reference_contains_fic_act`,
  `no_runtime_references`, `migration_checksum_valid`,
  `measurement_truth` (value: `"phase0_governance_declaration_single_row"`).

**Failure modes (must be explicit)**
- Append-only rules missing → exit 1 with message: `GOVERNANCE DEFECT: kyc_retention_policy
  has no append-only rules. This table must be immutable.`
- Table has zero rows → exit 1: `SEEDING FAILURE: Zambia FIC Act row not found.
  Check migration for INSERT statement.`
- Table has more than one row → exit 1: `PHASE VIOLATION: kyc_retention_policy
  contains more than one row. Only the ZM FIC Act seed row is permitted in Phase-0.`
- `retention_years` value for ZM row is not 10 → exit 1: `STATUTORY ERROR:
  retention_years must be 10 for FIC_AML_CUSTOMER_ID. Check statutory reference.`
- `retention_class` for ZM row is not 'FIC_AML_CUSTOMER_ID' → exit 1.
- Any runtime reference that is not in `scripts/` → exit 1, list paths.
- Missing CHECK on `retention_years` → exit 1.

**Notes**

Phase-0 boundaries and rationale for the seeding exception:
- This is the ONLY table in this pack where Phase-0 seeding is permitted. The
  reason is that the 10-year FIC Act obligation is a confirmed statutory fact —
  the regulatory affairs hire does not need to discover it, and Compliance does
  not need to sign off on the number. The FIC Act is publicly available law.
- DO NOT add a second row for any other jurisdiction in Phase-0. Additional
  jurisdictions require Compliance research and are Phase-2 scope.
- DO NOT add a second row for any other retention class in Phase-0. The
  DATA_PROTECTION_PII class (1 year) is deliberately absent from this table
  in Phase-0 because KYC verification hashes are classified as FIC_AML records,
  not PII records. If someone adds a 1-year PII class to this table, it creates
  an ambiguity that the retention classification engine in Phase-2 must resolve
  incorrectly. Prevent that ambiguity at the schema level.
- The append-only rules are PostgreSQL RULE objects. They silently swallow
  UPDATE and DELETE statements rather than raising errors, which is standard
  PostgreSQL immutability pattern. Phase-2 may replace with a trigger that
  raises an explicit error for better observability. The verifier must confirm
  the rules exist regardless of whether the Phase-2 upgrade has occurred.
- The `statutory_reference` value includes the specific FIC Act section (21)
  because the 10-year obligation is not from the Act's general record-keeping
  provisions but from the specific customer identification obligations. This
  matters in a BoZ examination.

---

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P0-KYC-004
title: kyc_retention_policy_declaration (governance document anchor)
depends_on:
- TSK-P0-KYC-003
files_to_change:
  - schema/migrations/*kyc_retention_policy*_hook.sql
  - scripts/db/verify_kyc_retention_policy_hook.sh
  - docs/PHASE0/phase0_contract.yml
  - tasks/TSK-P0-KYC-004/meta.yml
  - evidence/phase0/TSK-P0-KYC-004.json
verifier_command: bash scripts/db/verify_kyc_retention_policy_hook.sh
evidence_path: evidence/phase0/TSK-P0-KYC-004.json
acceptance_assertions:
  - kyc_retention_policy governance declaration table exists with append-only rules and statutory seed row
  - Verifier checks schema + seeded row + immutability posture, not file presence only
  - Evidence exists exactly at evidence/phase0/TSK-P0-KYC-004.json and is schema-valid
failure_modes:
  - append-only rules missing or statutory seed row invalid
  - verifier does not validate live schema/row constraints and runtime-reference boundary
```

## TSK-P0-208 — Gate↔Invariant linkage audit

### Goal
Produce a machine-readable audit confirming that every Phase-0 invariant declared in
`docs/PHASE0/phase0_contract.yml` has at least one gate check that references it, and that
every gate check that references an invariant ID resolves to a real declared invariant.
Orphaned gate checks (referencing undeclared invariants) and orphaned invariants (declared
but never checked by any gate) are both failures. The audit must emit a structured JSON
report listing: all invariants found, all gate↔invariant links found, any orphaned
invariants, any orphaned gate references, and a final pass/fail.

### Scope
- In-scope: scanning `docs/PHASE0/phase0_contract.yml` for declared invariants; scanning
  `scripts/audit/` and `scripts/dev/` for gate checks that reference invariant IDs; producing
  `evidence/phase0/TSK-P0-208.json` with the structured report.
- Out-of-scope: adding new invariants; adding new gate checks; any schema or application changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-208
depends_on:
- TSK-P0-KYC-004
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_208.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_208.sh; exit 1; }; scripts/audit/verify_tsk_p0_208.sh
  --evidence evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json; python3
  -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-208\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json
files_to_change:
- tasks/TSK-P0-208/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/audit/verify_tsk_p0_208.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-208' and pass == true.
- tasks/TSK-P0-208/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P0-210 — BoZ observability role proof (include SET ROLE denial)

### Agent prompt (copy/paste)
```text
task_id: TSK-P0-210
title: BoZ observability role proof (include SET ROLE denial)
owner_signoff: CTO
depends_on:
- TSK-P0-208
evidence:
  - evidence/phase0/phase_boundaries_drift.json

Goal
- Implement the canonical DAG task intent for TSK-P0-210: BoZ observability role proof (include SET ROLE denial).

Requirements
1) Canonical doc path: docs/phases/PHASE_BOUNDARIES.md (or the repo’s chosen canonical path).
2) Implement scripts/audit/verify_phase_boundaries_integrity.sh:
   - Fails if the canonical doc is missing.
   - Fails if phase gate scripts reference an unknown phase name or unknown gate IDs.
   - Fails if Phase-1 closeout script lists required evidence not present in Phase-1 contract (see TSK-P1-202).
3) Emit evidence/phase0/phase_boundaries_drift.json.

Acceptance
- Removing or renaming PHASE_BOUNDARIES.md breaks CI.
- Phase gating scripts must reference the doc path in their output (provenance).

Deliverables
- Drift verifier + ordered checks wiring + evidence.
```

---

# Phase‑1 buildout tasks

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P0-210
depends_on:
- TSK-P0-208
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE0/phase0_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE0/phase0_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p0_210.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p0_210.sh; exit 1; }; scripts/audit/verify_tsk_p0_210.sh
  --evidence evidence/phase0/tsk_p0_210__boz_observability_role_proof_include_set.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase0/tsk_p0_210__boz_observability_role_proof_include_set.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P0-210\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase0/tsk_p0_210__boz_observability_role_proof_include_set.json
files_to_change:
- tasks/TSK-P0-210/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/audit/verify_tsk_p0_210.sh
acceptance_assertions:
- Evidence file exists at evidence/phase0/tsk_p0_210__boz_observability_role_proof_include_set.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P0-210' and pass == true.
- tasks/TSK-P0-210/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-057-FINAL — Replace placeholder runtime batching proof + enforce perf promotion

### Goal
The existing TSK-P1-057 runtime batching proof is a placeholder: it either contains
hard-coded pass values, omits the actual batch measurement, or lacks a fail-closed CI gate.
This task replaces it with a real proof:

1. Run an actual batching scenario (configurable batch size, fixed seed) and measure
   throughput against the declared minimum threshold.
2. The verifier must fail if the measured throughput falls below the threshold — no informational
   mode, no `|| true`.
3. Enforce perf promotion: no task that follows in the perf governance stage (PERF-001, PERF-002)
   may start unless this task's evidence exists and `pass == true`.

The "perf promotion" enforcement is implemented by making this task's evidence a required
dependency in `phase1_contract.yml` under the perf governance stage.
Contract mapping for this task is anchored under `INV-120` with required evidence
`evidence/phase1/p1_057_final_perf_promotion.json`.

### Scope
- In-scope: replacing the placeholder verifier and evidence in the existing TSK-P1-057 path;
  adding the threshold check; wiring evidence into `phase1_contract.yml` as a required artifact
  for the perf governance checkpoint.
- Out-of-scope: adding engine metrics (PERF-001); adding regression classification (PERF-002);
  any schema or application changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-057-FINAL
depends_on:
- checkpoint/P0-DONE
verifier_command: bash scripts/audit/verify_p1_057_final_perf_promotion.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-057-FINAL --evidence evidence/phase1/p1_057_final_perf_promotion.json
evidence_path: evidence/phase1/p1_057_final_perf_promotion.json
files_to_change:
- tasks/TSK-P1-057-FINAL/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_p1_057_final_perf_promotion.sh
- docs/PHASE1/phase1_contract.yml
- docs/perf/**
- evidence/phase1/p1_057_final_perf_promotion.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_p1_057_final_perf_promotion.sh and exits 0.
- Evidence file exists at evidence/phase1/p1_057_final_perf_promotion.json and is valid JSON.
- Evidence proves placeholder runtime batching proof is replaced and perf promotion gate is enforced.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## PERF-001 — Non-invasive engine metrics capture (no trace/debug logging)

### Goal
Add structured engine-level metrics capture to the perf smoke runner without enabling
trace or debug logging in the process under test. The metrics must be collected externally
(e.g., via process-level counters, OS-level metrics, or a dedicated metrics endpoint) —
never by injecting logging into the request path. Captured metrics are written into the
`engine_metrics` field of `evidence/phase1/perf_smoke_baseline.json` (the field that was
`null` in TSK-P0-104). This task extends the schema from schema_version "1.0" to "1.1"
(or adds a sub-schema under `engine_metrics`) without breaking existing fields.

Required engine metrics (minimum): `cpu_user_ms`, `cpu_sys_ms`, `gc_collections` (if
applicable), `db_query_count`, `db_query_p95_ms`.
Contract mapping for this task is anchored under `INV-121` with required evidence
`evidence/phase1/perf_001_engine_metrics_capture.json`.

The updated evidence artifact must be backwards-compatible: all fields from schema_version
"1.0" must remain present and valid.

### Scope
- In-scope: extending `scripts/audit/run_perf_smoke.sh` to collect engine metrics;
  updating the evidence schema and emitting `engine_metrics` with required sub-fields;
  confirming trace/debug logging is not enabled during measurement (grep check).
- Out-of-scope: regression classification (PERF-002); rebaseline workflow (PERF-003);
  any schema migrations; any application code changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-001
depends_on:
- TSK-P1-057-FINAL
verifier_command: bash scripts/audit/verify_perf_001_engine_metrics_capture.sh && python3 scripts/audit/validate_evidence.py --task PERF-001 --evidence evidence/phase1/perf_001_engine_metrics_capture.json
evidence_path: evidence/phase1/perf_001_engine_metrics_capture.json
files_to_change:
- tasks/PERF-001/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_perf_001_engine_metrics_capture.sh
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/perf_001_engine_metrics_capture.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_perf_001_engine_metrics_capture.sh and exits 0.
- Evidence file exists at evidence/phase1/perf_001_engine_metrics_capture.json and is valid JSON.
- Evidence records non-invasive engine metrics capture and confirms trace/debug logging is not required.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## PERF-002 — Smart regression detection + mandatory warmup

### Goal
Extend the perf smoke runner with two capabilities:

1. **Mandatory warmup**: before any measurement run, execute a configurable warmup pass
   (default: 10% of total request count, minimum 50 requests). The warmup results are
   discarded. Measurement begins only after warmup completes. If warmup fails, the run
   aborts (fail-closed). Document the warmup parameters in the evidence.

2. **Smart regression detection**: replace the simple threshold gate from TSK-P0-104 with
   a classification scheme that distinguishes: PASS (no regression), SOFT_REGRESSION (within
   a secondary tolerance band — CI warns but does not fail), HARD_REGRESSION (exceeds
   hard threshold — CI fails). The classification thresholds must be declared explicitly in
   `perf_baseline.json` (not hardcoded). The `regression_classification` field in the
   evidence artifact (which was `null` in PERF-001) is populated with the classification
   result and its inputs.

### Scope
- In-scope: extending `scripts/audit/run_perf_smoke.sh` with warmup and smart classification;
  updating `perf_baseline.json` schema to include threshold declarations; populating
  `regression_classification` in the evidence.
- Out-of-scope: rebaseline workflow (PERF-003); any schema or application code changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-002
depends_on:
- PERF-001
verifier_command: bash scripts/audit/verify_perf_002_regression_detection_warmup.sh && python3 scripts/audit/validate_evidence.py --task PERF-002 --evidence evidence/phase1/perf_002_regression_detection_warmup.json
evidence_path: evidence/phase1/perf_002_regression_detection_warmup.json
files_to_change:
- tasks/PERF-002/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_perf_002_regression_detection_warmup.sh
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/perf_002_regression_detection_warmup.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_perf_002_regression_detection_warmup.sh and exits 0.
- Evidence file exists at evidence/phase1/perf_002_regression_detection_warmup.json and is valid JSON.
- Evidence proves smart regression detection thresholds and mandatory warmup execution were applied.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## PERF-003 — Rebaseline workflow with SHA-locked approvals

### Goal
Implement a governed rebaseline workflow: when the current perf run produces a SOFT_REGRESSION
or when a known architectural change warrants a new baseline, an engineer may submit a rebaseline
request. The workflow must:

1. Generate a new candidate `perf_baseline.json` with the updated measurements.
2. Require a SHA-locked approval: the approver records the SHA256 of the candidate baseline
   in a separate approval file (`perf_baseline_approval.yml`) with fields: `approved_by`,
   `approved_at_utc`, `candidate_baseline_sha256`, `reason`.
3. The CI gate validates that `perf_baseline.json` SHA256 matches `candidate_baseline_sha256`
   in the approval file before accepting the new baseline as valid. If they mismatch, CI fails.
4. The approval file is committed to the repo alongside the new baseline.

The workflow must be documented in `docs/perf/REBASELINE.md`.

### Scope
- In-scope: the rebaseline script (`scripts/perf/rebaseline.sh`); the approval file schema;
  the CI gate update to validate SHA-locked approval; documentation.
- Out-of-scope: automated rebaseline triggering; any schema or application changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-003
depends_on:
- PERF-002
verifier_command: bash scripts/audit/verify_perf_003_rebaseline_sha_lock.sh && python3 scripts/audit/validate_evidence.py --task PERF-003 --evidence evidence/phase1/perf_003_rebaseline_sha_lock.json
evidence_path: evidence/phase1/perf_003_rebaseline_sha_lock.json
files_to_change:
- tasks/PERF-003/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_perf_003_rebaseline_sha_lock.sh
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/perf_003_rebaseline_sha_lock.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_perf_003_rebaseline_sha_lock.sh and exits 0.
- Evidence file exists at evidence/phase1/perf_003_rebaseline_sha_lock.json and is valid JSON.
- Evidence proves rebaseline workflow requires SHA-locked approvals.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## PERF-005 — Regulatory timing compliance gate

### Agent prompt (copy/paste)
```text
task_id: PERF-005
title: Regulatory timing compliance gate
owner_signoff: CTO
depends_on:
- checkpoint/PERF-ENG
evidence:
  - evidence/phase1/settlement_window_compliance.json

Goal
- Implement the canonical DAG task intent for PERF-005: Regulatory timing compliance gate.

Requirements
1) Define settlement window policy per rail profile (e.g., ZM-NFS, ZM-MMO).
2) Compute compliance_pct over the Phase‑1 scenario suite runs.
3) Emit measurement_truth clarifying simulated vs live adapter sources.

Evidence
- evidence/phase1/settlement_window_compliance.json
```

---

# Phase‑1 closeout and operational evidence

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-005
depends_on:
- checkpoint/PERF-ENG
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/perf/verify_perf_005.sh
  || { echo MISSING_VERIFIER:scripts/perf/verify_perf_005.sh; exit 1; }; scripts/perf/verify_perf_005.sh
  --evidence evidence/phase1/perf_005__regulatory_timing_compliance_gate.json; python3
  -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/perf_005__regulatory_timing_compliance_gate.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"PERF-005\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/perf_005__regulatory_timing_compliance_gate.json
files_to_change:
- tasks/PERF-005/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/**
- scripts/perf/verify_perf_005.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/perf_005__regulatory_timing_compliance_gate.json
  and is valid JSON.
- Evidence JSON contains task_id == 'PERF-005' and pass == true.
- tasks/PERF-005/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## PERF-005A — Rail-confirmed finality seam stub

### Goal
Add a seam in the perf/compliance measurement pipeline for "rail-confirmed finality": a
named interface point where, in Phase-2, a live rail adapter's finality callback will be
wired. In Phase-1, the seam is a stub that: (a) accepts a finality event in a declared
schema, (b) logs it with a `measurement_truth: "simulated_finality_stub"` field, and
(c) does NOT claim real finality timing.

The seam must be wired into the settlement window compliance computation from PERF-005:
the compliance calculation must call the finality seam rather than hardcoding the simulated
finality timestamp. This ensures Phase-2 can swap in a real rail callback by implementing
the seam interface without modifying the compliance computation logic.

The evidence must explicitly state: `finality_source: "simulated_stub"` and
`live_rail_wiring_status: "pending_phase2"`.

### Scope
- In-scope: defining the finality seam interface (as a shell function or small script);
  wiring it into the PERF-005 settlement window computation; emitting evidence with the
  stub fields declared above.
- Out-of-scope: implementing live rail finality callbacks; any schema migrations; any
  application code changes.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-005A
depends_on:
- PERF-005
verifier_command: bash scripts/audit/verify_perf_005a_finality_seam_stub.sh && python3 scripts/audit/validate_evidence.py --task PERF-005A --evidence evidence/phase1/perf_005a_finality_seam_stub.json
evidence_path: evidence/phase1/perf_005a_finality_seam_stub.json
files_to_change:
- tasks/PERF-005A/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_perf_005a_finality_seam_stub.sh
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/perf_005a_finality_seam_stub.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_perf_005a_finality_seam_stub.sh and exits 0.
- Evidence file exists at evidence/phase1/perf_005a_finality_seam_stub.json and is valid JSON.
- Evidence proves rail-confirmed finality seam stub is present and wired without claiming live finality.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## PERF-006 — Operational Risk Framework + Translation Layer

### Agent prompt (copy/paste)
```text
task_id: PERF-006
title: Operational Risk Framework + Translation Layer
owner_signoff: CTO
depends_on:
- PERF-005A
evidence:
  - evidence/phase1/perf_006_closeout_extension.json

Goal
- Implement the canonical DAG task intent for PERF-006: Operational Risk Framework + Translation Layer.

Requirements
- Extend verify_phase1_closeout.sh to check:
  - KPI evidence includes settlement_window_compliance_pct
  - KPI evidence references PERF‑005 artifact ID/path.

Evidence
- evidence/phase1/perf_006_closeout_extension.json
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-006
depends_on:
- PERF-005A
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/perf/verify_perf_006.sh
  || { echo MISSING_VERIFIER:scripts/perf/verify_perf_006.sh; exit 1; }; scripts/perf/verify_perf_006.sh
  --evidence evidence/phase1/perf_006__operational_risk_framework_translation_layer.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/perf_006__operational_risk_framework_translation_layer.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"PERF-006\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/perf_006__operational_risk_framework_translation_layer.json
files_to_change:
- tasks/PERF-006/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/**
- scripts/perf/verify_perf_006.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/perf_006__operational_risk_framework_translation_layer.json
  and is valid JSON.
- Evidence JSON contains task_id == 'PERF-006' and pass == true.
- tasks/PERF-006/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-ESC-001 — Escrow state machine + atomic reservation semantics

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-ESC-001
title: Escrow state machine + atomic reservation semantics
owner_signoff: CTO
depends_on:
- checkpoint/PERF-REG
evidence:
  - evidence/phase1/esc_001_state_model.json

Goal
- Implement the canonical DAG task intent for TSK-P1-ESC-001: Escrow state machine + atomic reservation semantics.

State model (must be explicit)
States:
- CREATED, AUTHORIZED, RELEASE_REQUESTED, RELEASED, CANCELED, EXPIRED

Terminal states:
- RELEASED, CANCELED, EXPIRED

Legal transitions (MUST include AUTHORIZED→EXPIRED):
- CREATED → AUTHORIZED
- CREATED → CANCELED
- CREATED → EXPIRED           (request never authorized before window)
- AUTHORIZED → RELEASE_REQUESTED
- AUTHORIZED → CANCELED       (explicit cancel by authorized party)
- AUTHORIZED → EXPIRED        (authorization window elapsed before release)
- RELEASE_REQUESTED → RELEASED
- RELEASE_REQUESTED → CANCELED
- RELEASE_REQUESTED → EXPIRED (release window elapsed; no external confirmation)

Non-custodial “release” semantics (define observable output)
- release_escrow() does NOT move money.
- It MUST:
  1) write an append-only escrow_event row with event_type=RELEASED (or RELEASE_CONFIRMED)
  2) mark escrow.state=RELEASED
  3) emit an outbox message (optional in Phase‑1) describing the release intent for downstream rails
- For Phase‑1 CI, it is acceptable if (3) is a NOOP, but (1) and (2) are mandatory and verifiable.

Requirements
1) Create tables:
   - escrow_accounts (or escrows) with tenant_id, program_id/entity_id scope, state, windows, amounts (as “authorized amount” not “held funds”)
   - escrow_events append-only
2) Enforce legal transitions in a SECURITY DEFINER function transition_escrow_state().
3) Add expiry job primitive:
   - a function expire_escrows(now) that transitions eligible CREATED/AUTHORIZED/RELEASE_REQUESTED to EXPIRED.

Evidence
- evidence/phase1/esc_001_state_model.json proving:
  - all states/transitions exist
  - illegal transitions rejected with stable SQLSTATEs
  - expiry reachable from CREATED and AUTHORIZED as specified.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-ESC-001
depends_on:
- checkpoint/PERF-REG
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_esc_001.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_esc_001.sh; exit 1; }; scripts/db/verify_tsk_p1_esc_001.sh
  --evidence evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-ESC-001\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json
files_to_change:
- tasks/TSK-P1-ESC-001/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_esc_001.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-ESC-001' and pass == true.
- tasks/TSK-P1-ESC-001/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-ESC-002 — Escrow invariants + cross-tenant protections

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-ESC-002
title: Escrow invariants + cross-tenant protections
owner_signoff: CTO
depends_on:
- TSK-P1-ESC-001
evidence:
  - evidence/phase1/esc_002_ceiling_enforcement.json

Goal
- Implement the canonical DAG task intent for TSK-P1-ESC-002: Escrow invariants + cross-tenant protections.

Requirements
1) programs table must reference program_escrow_id (FK) representing the total budget envelope.
2) reservation must be atomic:
   - SELECT ... FOR UPDATE on the escrow balance row inside authorize_escrow_reservation().
3) Provide scenario test:
   - 50 concurrent reservations must not exceed entity ceiling.

Evidence
- evidence/phase1/esc_002_ceiling_enforcement.json:
  - concurrency test results
  - reservation ledger entries
  - proof that oversubscription is prevented.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-ESC-002
depends_on:
- TSK-P1-ESC-001
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_esc_002.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_esc_002.sh; exit 1; }; scripts/db/verify_tsk_p1_esc_002.sh
  --evidence evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-ESC-002\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json
files_to_change:
- tasks/TSK-P1-ESC-002/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_esc_002.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-ESC-002' and pass == true.
- tasks/TSK-P1-ESC-002/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-001 — Participants + exception governance

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-001
title: Participants + exception governance
owner_signoff: CTO
depends_on:
- checkpoint/ESC
evidence:
  - evidence/phase1/hier_001_schema.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-001: Participants + exception governance.

Scope
- Build the participant-facing tables (`participants`, `program_supervisors`, `distribution_entities`) while reusing the existing `public.programs` table from the escrow work.
- Ensure each row references `tenant_members` for tenant attribution and denormalize `tenant_id` only where needed for tenant isolation.
- Enforce status enums, tenant-scoped uniqueness constraints, and date-range constraints.

Requirements
1) Migrations create these tables with UUID v7 defaults, strict CHECK constraints, tenant-leading indexes, and references into `programs`.
2) All foreign keys referencing members must point at `public.tenant_members`.
3) Provide SECURITY DEFINER helpers for the approval gates described in the narrative (CTO + compliance supervision).
4) `scripts/db/verify_tsk_p1_hier_001.sh` must assert:
   - the new tables exist, column/index/constraint definitions match the prompt, and references to `tenant_members`/`programs` include tenant_id matches.

Evidence
- evidence/phase1/hier_001_schema.json capturing schema fingerprint, indexes, constraints, and tenant member/program references.

Non-goals
- No runtime API endpoints in this task.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-001
depends_on:
- checkpoint/ESC
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_001.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_001.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_001.sh
  --evidence evidence/phase1/tsk_p1_hier_001__participants_exception_governance.json;
  python3 -c "import json,pathlib; p=pathlib.Path("evidence/phase1/tsk_p1_hier_001__participants_exception_governance.json");
  assert p.exists(), f"MISSING_EVIDENCE:{p}"; d=json.loads(p.read_text()); assert
  d.get("task_id") == "TSK-P1-HIER-001", d.get("task_id"); assert d.get("status") in {"PASS","DONE","OK"}"'
evidence_path: evidence/phase1/tsk_p1_hier_001__participants_exception_governance.json
files_to_change:
- tasks/TSK-P1-HIER-001/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_001.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_001__participants_exception_governance.json and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-001' and documents tenant_members/programs reuse.
- tasks/TSK-P1-HIER-001/meta.yml exists and records terminal success.
- Dependencies (checkpoint/ESC) show PASS evidence before this task runs.
- Task-specific verifier(s) run green before closeout.
failure_modes:
- Missing prompt section or execution metadata block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing/invalid/task_id mismatch/pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change => FAIL_REVIEW.
```

## TSK-P1-HIER-002 — Programs + program_escrow_id bridge

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-002
title: Programs + program_escrow_id bridge
owner_signoff: CTO
depends_on:
- TSK-P1-HIER-001
evidence:
  - evidence/phase1/hier_002_person_member.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-002: Programs + program_escrow_id bridge.

Model
- person: a human record (pseudonymous) within a tenant.
- member: a program/entity-specific enrollment of a person (can appear in multiple programs/entities as separate member rows).

Requirements
1) Create tables:
   - persons(tenant_id, person_id, person_ref_hash, created_at, status)
   - members(tenant_id, member_id, entity_id, person_id, member_ref_hash, kyc_status, enrolled_at, status, ceilings...)
2) Enforce:
   - UNIQUE(tenant_id, person_ref_hash)
   - UNIQUE(entity_id, member_ref_hash)
   - FK members.person_id → persons.person_id (and tenant_id consistency via composite FK or trigger).
3) Add verifier scripts/db/verify_hier_002.sh for schema + constraint correctness.
4) Define the policy hook for cross-tenant correlation explicitly as “Phase‑2 optional”; Phase‑1 is strict isolation.

Evidence
- evidence/phase1/hier_002_person_member.json with invariants proven.

Non-goals
- No cross-tenant identity graph implementation here.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-002
depends_on:
- TSK-P1-HIER-001
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_002.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_002.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_002.sh
  --evidence evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-HIER-002\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json
files_to_change:
- tasks/TSK-P1-HIER-002/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_002.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-002' and pass == true.
- tasks/TSK-P1-HIER-002/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-003 — Distribution entities + tenant denorm + ceilings

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-003
title: Distribution entities + tenant denorm + ceilings
owner_signoff: CTO
depends_on:
- TSK-P1-HIER-002
evidence:
  - evidence/phase1/hier_003_member_devices.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-003: Distribution entities + tenant denorm + ceilings.

Requirements
1) member_devices must include tenant_id and member_id, and enforce:
   - UNIQUE(member_id, device_id_hash)
   - optional iccid_hash
   - status enum
2) Index strategy:
   - (tenant_id, member_id)
   - (tenant_id, device_id_hash) WHERE status='ACTIVE'
   - (tenant_id, iccid_hash) WHERE iccid_hash IS NOT NULL AND status='ACTIVE'
3) Verifier scripts/db/verify_tsk_p1_hier_003.sh.

Evidence
- evidence/phase1/hier_003_member_devices.json: schema + indexes + example query plans (optional).
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-003
depends_on:
- TSK-P1-HIER-002
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_003.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_003.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_003.sh
  --evidence evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-HIER-003\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json
files_to_change:
- tasks/TSK-P1-HIER-003/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_003.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-003' and pass == true.
- tasks/TSK-P1-HIER-003/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-004 — Person model explicit + enrollment model

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-004
title: Person model explicit + enrollment model
owner_signoff: CTO
depends_on:
- TSK-P1-HIER-003
evidence:
  - evidence/phase1/hier_004_device_events.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-004: Person model explicit + enrollment model.

Requirements
1) Table member_device_events must include tenant_id, member_id, instruction_id, device_id_hash, iccid_hash, event_type, observed_at.
2) instruction_id must be a FK to ingress_attestations(instruction_id) (type must match exactly).
3) Add CHECK constraint governing nullable device_id:
   - device_id IS NULL iff event_type IN ('UNREGISTERED_DEVICE','REVOKED_DEVICE_ATTEMPT')
4) Verifier ensures append-only protections exist (trigger or permissions model).

Evidence
- evidence/phase1/hier_004_device_events.json: constraints, trigger presence, FK correctness.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-004
depends_on:
- TSK-P1-HIER-003
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_004.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_004.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_004.sh
  --evidence evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-HIER-004\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json
files_to_change:
- tasks/TSK-P1-HIER-004/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_004.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-004' and pass == true.
- tasks/TSK-P1-HIER-004/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-005 — Member devices with tenant-safe reverse lookup indexes

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-005
title: Member devices with tenant-safe reverse lookup indexes
owner_signoff: CTO
depends_on:
- TSK-P1-HIER-004
evidence:
  - evidence/phase1/hier_005_invariant_function.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-005: Member devices with tenant-safe reverse lookup indexes.

Signature (must include tenant check)
- verify_instruction_hierarchy(p_instruction_id, p_tenant_id, p_participant_id, p_program_id, p_entity_id, p_member_id, p_device_id)

Requirements
1) First check tenant→participant link; failure SQLSTATE must be P7299.
2) Then verify program→participant, entity→program, member→entity, device→member.
3) Each failure emits deterministic SQLSTATE P7300..P7307 (no gaps; stable mapping).
4) Provide unit tests / verifier that triggers each failure mode and records outputs.

Evidence
- evidence/phase1/hier_005_invariant_function.json includes:
  - list of SQLSTATEs exercised
  - pass/fail per link test
  - function definition fingerprint.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-005
depends_on:
- TSK-P1-HIER-004
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_005.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_005.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_005.sh
  --evidence evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-HIER-005\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json
files_to_change:
- tasks/TSK-P1-HIER-005/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_005.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-005' and pass == true.
- tasks/TSK-P1-HIER-005/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-006 — Append-only member_device_events anchored to ingress FK

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-006
title: Append-only member_device_events anchored to ingress FK
owner_signoff: CTO
requires_compliance_input: true
depends_on:
- TSK-P1-HIER-005
evidence:
  - evidence/phase1/hier_006_supervisor_access.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-006: Append-only member_device_events anchored to ingress FK.

Required semantics
1) READ_ONLY:
   - periodic signed aggregate report delivery (no API access; no DB access).
2) AUDIT:
   - time-bounded read-only API token scoped to program_id; returns anonymized raw records.
3) APPROVAL_REQUIRED:
   - instruction hold state PENDING_SUPERVISOR_APPROVAL + approve/reject API endpoints; timeout policy configurable.

Requirements
- Implement schema + minimal runtime endpoints/stubs sufficient for CI scenario tests.
- Emit evidence that each scope behaves as specified.

Evidence
- evidence/phase1/hier_006_supervisor_access.json: scenario results for each scope.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-006
depends_on:
- TSK-P1-HIER-005
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_006.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_006.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_006.sh
  --evidence evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-HIER-006\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json
files_to_change:
- tasks/TSK-P1-HIER-006/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_006.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-006' and pass == true.
- tasks/TSK-P1-HIER-006/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-007 — Risk formula registry (Tier-1 deterministic default)

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-HIER-007
title: Risk formula registry (Tier-1 deterministic default)
owner_signoff: CTO
depends_on:
- TSK-P1-HIER-006
evidence:
  - evidence/phase1/hier_007_program_migration.json

Goal
- Implement the canonical DAG task intent for TSK-P1-HIER-007: Risk formula registry (Tier-1 deterministic default).

Requirements
1) Create program_migration_events table recording:
   - tenant_id, person_id, from_program_id, to_program_id, migrated_at, migrated_by, reason.
2) Add a deterministic migration function migrate_person_to_program() that:
   - creates the new member row (new entity_id) while preserving person_id linkage.
3) Provide queries/verifier that can produce “unique beneficiaries across program years” per tenant.

Evidence
- evidence/phase1/hier_007_program_migration.json: migration executed + results.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-007
depends_on:
- TSK-P1-HIER-006
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/db/verify_tsk_p1_hier_007.sh
  || { echo MISSING_VERIFIER:scripts/db/verify_tsk_p1_hier_007.sh; exit 1; }; scripts/db/verify_tsk_p1_hier_007.sh
  --evidence evidence/phase1/tsk_p1_hier_007__risk_formula_registry_tier_deterministic_default.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_hier_007__risk_formula_registry_tier_deterministic_default.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-HIER-007\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_hier_007__risk_formula_registry_tier_deterministic_default.json
files_to_change:
- tasks/TSK-P1-HIER-007/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/**
- docs/PHASE*/**
- evidence/**
- scripts/db/verify_tsk_p1_hier_007.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_hier_007__risk_formula_registry_tier_deterministic_default.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-HIER-007' and pass == true.
- tasks/TSK-P1-HIER-007/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-HIER-008 — SIM swap alerts derived + formula traceability

### Goal
Implement SIM-swap alert derivation as a deterministic, formula-versioned, append-only
process. A SIM-swap alert is raised when a `member_device_events` row with `event_type
= 'SIM_SWAP_DETECTED'` is observed for a member who has an active prior ICCID hash
different from the new ICCID hash. The alert must:

1. Be derived via a SECURITY DEFINER function `derive_sim_swap_alert(p_event_id UUID)`
   that reads `member_device_events` and writes to a new `sim_swap_alerts` table (append-only).
2. Record the formula version used to derive the alert (FK to a `risk_formula_versions` or
   equivalent version registry row — the version must be non-null; Phase-0 stub version acceptable).
3. Be traceable: the alert row must include `source_event_id` FK to the triggering
   `member_device_events` row and `formula_version_id`.

The verifier must confirm: function exists, `sim_swap_alerts` table is append-only, a
sample derivation produces the correct alert row, and the formula version is recorded.

### Scope
- In-scope: `sim_swap_alerts` table migration; `derive_sim_swap_alert()` function; verifier;
  evidence.
- Out-of-scope: UI/API exposure of alerts; any cross-tenant alert aggregation; any
  non-SIM-swap alert types.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-008
depends_on:
- TSK-P1-HIER-007
verifier_command: bash scripts/db/verify_hier_008_sim_swap_alerts.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-008 --evidence evidence/phase1/hier_008_sim_swap_alerts.json
evidence_path: evidence/phase1/hier_008_sim_swap_alerts.json
files_to_change:
- tasks/TSK-P1-HIER-008/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/verify_hier_008_sim_swap_alerts.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/hier_008_sim_swap_alerts.json
acceptance_assertions:
- Verifier script exists at scripts/db/verify_hier_008_sim_swap_alerts.sh and exits 0.
- Evidence file exists at evidence/phase1/hier_008_sim_swap_alerts.json and is valid JSON.
- Evidence proves SIM-swap alerts are derived deterministically with formula/version traceability.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-HIER-009 — verify_instruction_hierarchy() + SQLSTATE test suite

### Goal
Implement `verify_instruction_hierarchy()` as specified in TSK-P1-HIER-005 (if not already
present), then produce an exhaustive SQLSTATE test suite that exercises every declared
failure path with deterministic, stable SQLSTATE codes.

Required SQLSTATE mapping (must match exactly):
- Tenant→Participant link invalid: P7299
- Participant→Program link invalid: P7300
- Program→Entity link invalid: P7301
- Entity→Member link invalid: P7302
- Member→Device link invalid: P7303
- Any gap in P7304–P7307 must be documented as reserved (not left silent)

The test suite must: (a) call `verify_instruction_hierarchy()` with known-bad inputs for
each link; (b) capture the SQLSTATE; (c) assert it matches the declared mapping; (d) emit
the mapping table in the evidence JSON as `sqlstate_mapping_verified: [{link, expected, actual, pass}]`.

All tests must be runnable without live external calls (use test fixtures in the local DB).

### Scope
- In-scope: the function implementation (if incomplete); the SQLSTATE test scripts;
  `evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json`.
- Out-of-scope: adding new hierarchy levels; changing the SQLSTATE values (they are declared above).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-009
depends_on:
- TSK-P1-HIER-008
verifier_command: bash scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-009 --evidence evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json
evidence_path: evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json
files_to_change:
- tasks/TSK-P1-HIER-009/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json
acceptance_assertions:
- Verifier script exists at scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh and exits 0.
- Evidence file exists at evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json and is valid JSON.
- Evidence proves verify_instruction_hierarchy() exists and the SQLSTATE test suite exercises the declared deterministic mappings.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-HIER-010 — program_migration_events + migration function

### Goal
Implement the `program_migration_events` table and the `migrate_person_to_program()`
function as specified in TSK-P1-HIER-007's non-goal list (if not already implemented by
HIER-007, confirm which task owns this). This task owns the implementation if HIER-007
deferred it.

Required deliverables:
1. `program_migration_events` table with: `tenant_id`, `person_id`, `from_program_id`,
   `to_program_id`, `migrated_at`, `migrated_by` (TEXT, the role/user), `reason` (TEXT, nullable),
   `new_member_id` (UUID FK to members), `created_at`.
2. `migrate_person_to_program(p_tenant_id, p_person_id, p_from_program_id, p_to_program_id,
   p_new_entity_id, p_reason)` SECURITY DEFINER function that: creates the new member row
   (new entity_id, same person_id), writes the migration event, is idempotent on duplicate
   (raises a stable SQLSTATE on duplicate call rather than creating a second row).
3. Verifier: confirms table exists, function exists, a sample migration executes correctly,
   the original member row is NOT deleted (migration is additive), and duplicate call
   raises expected SQLSTATE.

### Scope
- In-scope: the table, the function, the verifier, the evidence.
- Out-of-scope: UI/API exposure; automated migration triggers; any cross-tenant migration.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-010
depends_on:
- TSK-P1-HIER-009
verifier_command: bash scripts/db/verify_hier_010_program_migration.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-010 --evidence evidence/phase1/hier_010_program_migration.json
evidence_path: evidence/phase1/hier_010_program_migration.json
files_to_change:
- tasks/TSK-P1-HIER-010/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/verify_hier_010_program_migration.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/hier_010_program_migration.json
acceptance_assertions:
- Verifier script exists at scripts/db/verify_hier_010_program_migration.sh and exits 0.
- Evidence file exists at evidence/phase1/hier_010_program_migration.json and is valid JSON.
- Evidence proves program_migration_events table and migration function exist and execute deterministically.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-HIER-011 — Supervisor access mechanisms (READ_ONLY push, AUDIT token API, APPROVAL_REQUIRED hold queue)

### Goal
Implement the three concrete supervisor access mechanisms declared in TSK-P1-HIER-006
(if not already implemented there; confirm which task owns the implementation):

1. **READ_ONLY**: implement a signed aggregate report delivery job (`scripts/reporting/deliver_supervisor_report.sh`)
   that generates a program-scoped aggregate report (no raw records, no API access), signs it
   with the evidence signing key (from INF-006), and delivers it to a configured destination
   path. The supervisor receives the file; they have no API or DB access.

2. **AUDIT token API**: implement `POST /v1/admin/supervisor/audit-token` that creates a
   time-bounded (configurable TTL, default 24h), read-only API token scoped to a specific
   `program_id`. The token must: expire automatically, return anonymized raw records only
   (no PII fields), be revocable via `DELETE /v1/admin/supervisor/audit-token/{token_id}`.

3. **APPROVAL_REQUIRED hold queue**: implement a hold queue table `supervisor_approval_queue`
   with: `instruction_id`, `held_at`, `held_reason`, `approved_by`, `approved_at`, `status`
   (PENDING | APPROVED | REJECTED). A SECURITY DEFINER function
   `submit_for_supervisor_approval(p_instruction_id)` moves the instruction to PENDING.
   The supervisor approves via `POST /v1/admin/supervisor/approve/{instruction_id}`.

Evidence must prove all three mechanisms function independently with negative tests for
each (READ_ONLY cannot call API, AUDIT token expires, APPROVAL_REQUIRED cannot self-approve).

### Scope
- In-scope: all three mechanisms; their verifiers; evidence.
- Out-of-scope: cross-tenant supervisor access; supervisor identity federation; any non-Phase-1 rails.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-HIER-011
depends_on:
- TSK-P1-HIER-010
verifier_command: bash scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-011 --evidence evidence/phase1/hier_011_supervisor_access_mechanisms.json
evidence_path: evidence/phase1/hier_011_supervisor_access_mechanisms.json
files_to_change:
- tasks/TSK-P1-HIER-011/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- schema/**
- scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/hier_011_supervisor_access_mechanisms.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh and exits 0.
- Evidence file exists at evidence/phase1/hier_011_supervisor_access_mechanisms.json and is valid JSON.
- Evidence proves READ_ONLY push, AUDIT token API, and APPROVAL_REQUIRED hold-queue mechanisms behave as specified.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-INF-002 — Containerize services + build pipeline

### Goal
Produce deterministic, reproducible container images for all Phase-1 services and wire
them into a CI build pipeline. Required services: `ledger-api`, `executor-worker`, and the
`db-migration-job`. Each must have a `Dockerfile` (or equivalent) that: uses a pinned
base image (digest-pinned, not tag-pinned), runs as a non-root user, produces a deterministic
layer hash for identical source inputs.

The build pipeline must: (a) build all service images in a defined order; (b) output a
build manifest (`evidence/phase1/inf_002_container_build_pipeline.json`) listing each image,
its digest, and its base image digest; (c) fail if any image digest changes unexpectedly
between identical source inputs (non-determinism is a failure).

### Scope
- In-scope: Dockerfiles for the three services; CI pipeline configuration (GitHub Actions
  or equivalent); the build manifest verifier; evidence.
- Out-of-scope: pushing images to a registry (local build only in Phase-1); Kubernetes
  manifests (INF-003); secrets injection (INF-005).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-INF-002
depends_on:
- checkpoint/HIER
verifier_command: bash scripts/audit/verify_inf_002_container_build_pipeline.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-002 --evidence evidence/phase1/inf_002_container_build_pipeline.json
evidence_path: evidence/phase1/inf_002_container_build_pipeline.json
files_to_change:
- tasks/TSK-P1-INF-002/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- services/**
- scripts/audit/verify_inf_002_container_build_pipeline.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/inf_002_container_build_pipeline.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_inf_002_container_build_pipeline.sh and exits 0.
- Evidence file exists at evidence/phase1/inf_002_container_build_pipeline.json and is valid JSON.
- Evidence proves container build outputs are produced for required services and build pipeline metadata is captured.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-INF-001 — Postgres HA + backups + PITR (operator)

### Goal
Configure Postgres for high-availability and point-in-time recovery in the sandbox
environment using an operator (CloudNativePG or equivalent). Required deliverables:

1. Operator-managed Postgres cluster manifest with: primary + at least one replica,
   automated failover configuration, health probes.
2. Backup configuration: continuous WAL archiving to a local or S3-compatible store
   (MinIO in sandbox is acceptable). Verify backups are created on schedule.
3. PITR proof: demonstrate recovery to a specific timestamp by running a test restore.
   The restore must succeed and the verifier must confirm the restored DB has the expected
   schema version at the target timestamp.

Evidence must include: `ha_config_verified`, `backup_schedule_confirmed`, `pitr_test_passed`,
`restore_target_timestamp`, `restored_schema_version`.

### Scope
- In-scope: operator manifests; backup config; PITR test script; evidence.
- Out-of-scope: production-grade storage (sandbox only); cross-region replication;
  automated failover testing under load.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-INF-001
depends_on:
- TSK-P1-INF-002
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/infra/verify_tsk_p1_inf_001.sh
  || { echo MISSING_VERIFIER:scripts/infra/verify_tsk_p1_inf_001.sh; exit 1; }; scripts/infra/verify_tsk_p1_inf_001.sh
  --evidence evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-INF-001\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json
files_to_change:
- tasks/TSK-P1-INF-001/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- scripts/audit/verify_inf_001_postgres_ha_pitr.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/inf_001_postgres_ha_pitr.json
- scripts/infra/verify_tsk_p1_inf_001.sh
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_inf_001_postgres_ha_pitr.sh and exits
  0.
- Evidence file exists at evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json
  and is valid JSON.
- Evidence proves Postgres HA/backups/PITR operator posture and recovery primitives
  are configured.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-INF-005 — OpenBao + External Secrets + rotation proof

### Goal
Deploy OpenBao (open-source Vault fork) in the sandbox and configure External Secrets
Operator to sync secrets into Kubernetes. Required deliverables:

1. OpenBao deployed in the sandbox cluster with: dev mode disabled, file storage backend
   (sandbox), TLS enabled, health check endpoint responding.
2. External Secrets Operator configured with a `ClusterSecretStore` or `SecretStore` that
   authenticates to OpenBao and syncs at least two named secrets into the `symphony` namespace.
3. Rotation proof: demonstrate that rotating a secret in OpenBao causes the Kubernetes
   secret to update within the configured sync interval. Evidence must record: old secret
   version hash, new secret version hash, sync delay in seconds.

Evidence must include: `openbao_health_ok`, `eso_sync_confirmed`, `rotation_proof_passed`,
`rotation_delay_seconds`.

### Scope
- In-scope: OpenBao and ESO deployment manifests; the rotation test script; evidence.
- Out-of-scope: production HSM-backed storage; cross-cluster secret federation;
  evidence signing key management (that is INF-006).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-INF-005
depends_on:
- TSK-P1-INF-001
verifier_command: bash scripts/audit/verify_inf_005_openbao_external_secrets.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-005 --evidence evidence/phase1/inf_005_openbao_external_secrets.json
evidence_path: evidence/phase1/inf_005_openbao_external_secrets.json
files_to_change:
- tasks/TSK-P1-INF-005/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- scripts/audit/verify_inf_005_openbao_external_secrets.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/inf_005_openbao_external_secrets.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_inf_005_openbao_external_secrets.sh and exits 0.
- Evidence file exists at evidence/phase1/inf_005_openbao_external_secrets.json and is valid JSON.
- Evidence proves OpenBao + External Secrets integration and rotation proof are configured and testable.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-INF-004 — Service-to-service mTLS (mesh)

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-INF-004
title: Service-to-service mTLS (mesh)
owner_signoff: CTO
depends_on:
- TSK-P1-INF-005
evidence:
  - evidence/phase1/inf_004_service_mtls.json

Critical boundary definition (must be stated in code/docs)
- Mesh/workload identity (mTLS between services) is NOT the evidence-signing identity.
- Evidence signing keys live in OpenBao (INF-006) and are rotated independently from mesh certs.
- Therefore: do not reuse mesh certs for signing evidence payloads.

Requirements
1) Choose and implement mTLS enforcement in sandbox manifests:
   - Istio STRICT PeerAuthentication/DestinationRule OR Linkerd equivalent.
2) Provide a verifier that proves:
   - mTLS is enabled and STRICT between ledger-api and executor-worker (or the chosen services).
   - plaintext traffic is rejected.
3) Evidence must include what mechanism is used (Istio/Linkerd) and the enforced mode.

Evidence
- evidence/phase1/inf_004_service_mtls.json with:
  - enforcement_mode, resources_present, negative_test_result.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-INF-004
depends_on:
- TSK-P1-INF-005
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/infra/verify_tsk_p1_inf_004.sh
  || { echo MISSING_VERIFIER:scripts/infra/verify_tsk_p1_inf_004.sh; exit 1; }; scripts/infra/verify_tsk_p1_inf_004.sh
  --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json; python3 -c "import
  json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-INF-004\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json
files_to_change:
- tasks/TSK-P1-INF-004/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- services/**
- scripts/audit/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/**
- scripts/infra/verify_tsk_p1_inf_004.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json and
  is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-INF-004' and pass == true.
- tasks/TSK-P1-INF-004/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-INF-003 — K8s manifests + migration job + health proof

### Goal
Produce Kubernetes manifests for a full first-boot sandbox deployment and prove that the
deployment succeeds deterministically. Required deliverables:

1. Manifests for: `ledger-api` Deployment + Service, `executor-worker` Deployment,
   `db-migration-job` Job (runs-to-completion before ledger-api/executor-worker start,
   enforced via `initContainers` or Job completion gate).
2. Health probes: liveness and readiness probes for `ledger-api` and `executor-worker`
   that confirm the service is healthy post-migration.
3. Health proof: a verifier script that applies the manifests to a local cluster (kind or
   equivalent), waits for all Deployments to reach ready state, confirms the migration Job
   completed successfully, and confirms health probe endpoints respond correctly.

Evidence must include: `manifests_valid`, `migration_job_completed`, `ledger_api_ready`,
`executor_worker_ready`, `health_probe_responses`.

### Scope
- In-scope: the manifests; the health proof verifier; evidence.
- Out-of-scope: production resource limits tuning; multi-zone deployment; ingress/load
  balancer configuration (out of scope for Phase-1 sandbox).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-INF-003
depends_on:
- TSK-P1-INF-004
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/infra/verify_tsk_p1_inf_003.sh
  || { echo MISSING_VERIFIER:scripts/infra/verify_tsk_p1_inf_003.sh; exit 1; }; scripts/infra/verify_tsk_p1_inf_003.sh
  --evidence evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-INF-003\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json
files_to_change:
- tasks/TSK-P1-INF-003/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- services/**
- scripts/audit/verify_inf_003_k8s_manifests_migration_health.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/inf_003_k8s_manifests_migration_health.json
- scripts/infra/verify_tsk_p1_inf_003.sh
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_inf_003_k8s_manifests_migration_health.sh
  and exits 0.
- Evidence file exists at evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json
  and is valid JSON.
- Evidence proves K8s manifests include migration job and health checks, and manifest
  validation passes.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-INF-006 — Evidence signing key management in OpenBao + rotation + verifier

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-INF-006
title: Evidence signing key management in OpenBao + rotation + verifier
owner_signoff: CTO
depends_on:
- TSK-P1-INF-003
evidence:
  - evidence/phase1/inf_006_evidence_signing.json

Goal
- Implement the canonical DAG task intent for TSK-P1-INF-006: Evidence signing key management in OpenBao + rotation + verifier.

Requirements
1) Define signing key hierarchy:
   - root (offline / break-glass) → phase signing key (online) → per-artifact signature.
2) Implement signer integration:
   - evidence JSON is signed, and signature + key_id are stored alongside artifact.
3) Implement verifier that:
   - validates signatures for a sample set of evidence files
   - fails if OpenBao is unreachable (fail-closed for Phase‑1 gates that require signing).

Evidence
- evidence/phase1/inf_006_evidence_signing.json:
  - key_id, signature_alg, verification_passed, sample_files_checked.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-INF-006
depends_on:
- TSK-P1-INF-003
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/infra/verify_tsk_p1_inf_006.sh
  || { echo MISSING_VERIFIER:scripts/infra/verify_tsk_p1_inf_006.sh; exit 1; }; scripts/infra/verify_tsk_p1_inf_006.sh
  --evidence evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-INF-006\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json
files_to_change:
- tasks/TSK-P1-INF-006/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- services/**
- scripts/audit/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/**
- scripts/infra/verify_tsk_p1_inf_006.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-INF-006' and pass == true.
- tasks/TSK-P1-INF-006/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-TEN-001 — Tenant context required on ingress

### Goal
Enforce that every request entering the system through the ingress API carries a valid,
non-empty tenant context — and that requests missing or carrying an unrecognised tenant
context are rejected fail-closed (HTTP 401 or 403 with a structured error, never silently
processed under the wrong tenant or as a tenantless request).

Required deliverables:
1. Middleware or gateway-level tenant extraction: reads tenant_id from a declared header
   (e.g., `X-Symphony-Tenant-Id`) or from the JWT claims (document which source is
   authoritative).
2. Validation: the extracted tenant_id must exist in the `tenants` table (or equivalent
   registry). Missing or unknown tenant_id → 403 with structured error.
3. Propagation: the resolved tenant_id is stored in request context and injected into
   all downstream DB queries (prerequisite for RLS in TEN-002).
4. Verifier: proves that requests with missing tenant context are rejected, requests with
   unknown tenant_id are rejected, and requests with valid tenant_id proceed. Negative tests
   must be recorded in evidence.

### Scope
- In-scope: the middleware/gateway code; negative test cases; evidence.
- Out-of-scope: RLS policies (TEN-002); tenant onboarding API (TEN-003); any schema changes
  other than confirming the tenants table exists.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-TEN-001
depends_on:
- TSK-P1-INF-006
verifier_command: bash scripts/audit/verify_ten_001_ingress_tenant_context.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-TEN-001 --evidence evidence/phase1/ten_001_ingress_tenant_context.json
evidence_path: evidence/phase1/ten_001_ingress_tenant_context.json
files_to_change:
- tasks/TSK-P1-TEN-001/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- scripts/audit/verify_ten_001_ingress_tenant_context.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/ten_001_ingress_tenant_context.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_ten_001_ingress_tenant_context.sh and exits 0.
- Evidence file exists at evidence/phase1/ten_001_ingress_tenant_context.json and is valid JSON.
- Evidence proves ingress rejects missing/invalid tenant context and accepts valid tenant-scoped requests.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-TEN-002 — RLS isolation + leakage tests

### Goal
Enable Row Level Security on all tenant-scoped tables and prove that cross-tenant data
leakage is impossible under normal query patterns. Required deliverables:

1. RLS policies on all tables that have a `tenant_id` column: policies must be RESTRICTIVE
   (not permissive) and must reference the session variable `app.current_tenant_id` (or
   equivalent mechanism established in TEN-001 context propagation).
2. Enable RLS on each table with `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` and
   `ALTER TABLE ... FORCE ROW LEVEL SECURITY` (FORCE prevents table owners from bypassing).
3. Leakage tests: for each tenant-scoped table, prove that querying as tenant A cannot
   return rows belonging to tenant B. Tests must: (a) insert a row for tenant A; (b) set
   session to tenant B; (c) confirm the row is not visible. Each test is recorded in
   evidence with the table name, test result, and the RLS policy that blocked it.
4. Exception list: if any table is explicitly exempted from RLS (e.g., shared reference
   tables), document the exemption and the reason in evidence.

### Scope
- In-scope: RLS policies for all tenant-scoped tables; leakage tests; evidence.
- Out-of-scope: tenant onboarding (TEN-003); application-level isolation (RLS is DB-layer only).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-TEN-002
depends_on:
- TSK-P1-TEN-001
verifier_command: bash scripts/audit/verify_ten_002_rls_leakage.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-TEN-002 --evidence evidence/phase1/ten_002_rls_leakage.json
evidence_path: evidence/phase1/ten_002_rls_leakage.json
files_to_change:
- tasks/TSK-P1-TEN-002/meta.yml
- docs/tasks/phase1_prompts.md
- schema/migrations/**
- scripts/db/**
- scripts/audit/verify_ten_002_rls_leakage.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/ten_002_rls_leakage.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_ten_002_rls_leakage.sh and exits 0.
- Evidence file exists at evidence/phase1/ten_002_rls_leakage.json and is valid JSON.
- Evidence proves RLS policies are installed and cross-tenant leakage negative tests fail as expected.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-TEN-003 — Tenant onboarding API (admin)

### Goal
Implement an admin-only endpoint that creates a new tenant and initialises all required
tenant-scoped resources atomically. Required deliverables:

1. `POST /v1/admin/tenants` with body `{ tenant_id, display_name, jurisdiction_code, plan }`.
   The endpoint must: (a) insert the tenant row; (b) create the tenant's RLS session variable
   seed (if applicable); (c) emit a `TENANT_CREATED` event to the outbox for downstream
   provisioning; (d) return `{ tenant_id, created_at }`.
2. Idempotency: if the tenant_id already exists, return the existing tenant (not an error).
   Document the idempotency key.
3. Admin-only enforcement: the endpoint must require an admin API key or admin JWT claim.
   Requests without admin credentials must be rejected with 403.
4. Verifier: creates a test tenant, confirms the row exists, confirms the outbox event
   was emitted, confirms a non-admin request is rejected.

Evidence must include: `tenant_created`, `outbox_event_emitted`, `idempotency_confirmed`,
`non_admin_rejected`.

### Scope
- In-scope: the endpoint; idempotency; admin auth check; the verifier; evidence.
- Out-of-scope: tenant deletion or suspension (Phase-2); billing integration.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-TEN-003
depends_on:
- TSK-P1-TEN-002
verifier_command: bash scripts/audit/verify_ten_003_tenant_onboarding_admin.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-TEN-003 --evidence evidence/phase1/ten_003_tenant_onboarding_admin.json
evidence_path: evidence/phase1/ten_003_tenant_onboarding_admin.json
files_to_change:
- tasks/TSK-P1-TEN-003/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- scripts/audit/verify_ten_003_tenant_onboarding_admin.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/ten_003_tenant_onboarding_admin.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_ten_003_tenant_onboarding_admin.sh and exits 0.
- Evidence file exists at evidence/phase1/ten_003_tenant_onboarding_admin.json and is valid JSON.
- Evidence proves tenant onboarding admin endpoint creates tenancy initialization artifacts deterministically.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-ADP-001 — Adapter interface + deterministic contract tests

### Goal
Define the canonical adapter interface that all rail adapters (simulated and live) must
implement, and prove it with deterministic contract tests. Required deliverables:

1. Interface definition: an `IRailAdapter` interface (or equivalent, language-appropriate
   construct) with exactly these methods: `submit(instruction) → SubmitResult`,
   `query_status(rail_ref) → StatusResult`, `cancel(rail_ref) → CancelResult`. Each method's
   input/output types must be fully typed with no `any` or `object` escape hatches.
2. Contract tests: a test suite that each adapter implementation must pass. The contract
   tests must be data-driven (fixed seed inputs → fixed expected outputs) so any adapter
   can be validated by running the same suite. At minimum: one success path, one failure
   path, one cancellation path per method.
3. Contract test runner: `scripts/audit/verify_adp_001_adapter_contract_tests.sh` that
   runs the suite against the simulated adapter and records pass/fail per test case in evidence.

### Scope
- In-scope: the interface definition; contract test suite; the simulated adapter stub
  (enough to pass the contract tests); the verifier.
- Out-of-scope: live rail adapters (Phase-2); retry logic in the worker (ADP-003).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-ADP-001
depends_on:
- TSK-P1-TEN-003
verifier_command: bash scripts/audit/verify_adp_001_adapter_contract_tests.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-ADP-001 --evidence evidence/phase1/adp_001_adapter_contract_tests.json
evidence_path: evidence/phase1/adp_001_adapter_contract_tests.json
files_to_change:
- tasks/TSK-P1-ADP-001/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- tests/**
- scripts/audit/verify_adp_001_adapter_contract_tests.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/adp_001_adapter_contract_tests.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_adp_001_adapter_contract_tests.sh and exits 0.
- Evidence file exists at evidence/phase1/adp_001_adapter_contract_tests.json and is valid JSON.
- Evidence proves adapter interface contract tests run deterministically and pass.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-ADP-002 — Simulated rail adapter

### Goal
Implement a fully functional simulated rail adapter that: (a) passes all ADP-001 contract
tests, (b) supports configurable success/failure scenarios via environment variables or a
config file (so tests can exercise failure paths deterministically), and (c) simulates
realistic latency (configurable delay, default 50ms, to make perf measurements meaningful).

Required scenarios (must be configurable without code changes):
- `SIMULATE_SUCCESS`: submit succeeds, status returns SETTLED within one poll.
- `SIMULATE_TRANSIENT_FAILURE`: submit returns a retryable error; second submit succeeds.
- `SIMULATE_PERMANENT_FAILURE`: submit returns a non-retryable error; all retries fail.
- `SIMULATE_CANCEL_SUCCESS`: cancel succeeds and status returns CANCELLED.
- `SIMULATE_CANCEL_TOO_LATE`: cancel returns error (instruction already settled).

The adapter must also write a local `sim_rail_log.jsonl` (append-only, one line per call)
so tests can inspect the exact call sequence without modifying the adapter.

### Scope
- In-scope: the adapter implementation; scenario configuration; the call log; evidence.
- Out-of-scope: live rail integration; persistent state across process restarts.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-ADP-002
depends_on:
- TSK-P1-ADP-001
verifier_command: bash scripts/audit/verify_adp_002_simulated_rail_adapter.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-ADP-002 --evidence evidence/phase1/adp_002_simulated_rail_adapter.json
evidence_path: evidence/phase1/adp_002_simulated_rail_adapter.json
files_to_change:
- tasks/TSK-P1-ADP-002/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- tests/**
- scripts/audit/verify_adp_002_simulated_rail_adapter.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/adp_002_simulated_rail_adapter.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_adp_002_simulated_rail_adapter.sh and exits 0.
- Evidence file exists at evidence/phase1/adp_002_simulated_rail_adapter.json and is valid JSON.
- Evidence proves simulated rail adapter behavior matches contract semantics across success/retry/failure cases.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-ADP-003 — Worker routes by rail_type deterministically

### Goal
Implement deterministic routing in the executor-worker: given an instruction with a
`rail_type` field, the worker selects the correct adapter and dispatches to it. The routing
must be: (a) table-driven (a registry maps `rail_type` → adapter factory, not a chain of
if/else); (b) fail-closed on unknown `rail_type` (unknown type → instruction moved to
exception state with SQLSTATE-equivalent error code, not silently ignored); (c) deterministic
for identical inputs (same `rail_type` always routes to the same adapter class).

Required deliverables:
1. The routing registry (data structure mapping rail_type → adapter factory).
2. The dispatch logic that reads from the registry.
3. Fail-closed handling for unknown rail_type.
4. Verifier: runs the worker with each declared rail_type and confirms routing to the
   expected adapter; runs with an unknown rail_type and confirms the exception path is
   triggered. Evidence records `routing_table`, `tested_rail_types`, and `unknown_type_exception_confirmed`.

### Scope
- In-scope: the routing registry; dispatch logic; the fail-closed path; evidence.
- Out-of-scope: retry logic (ADP-001 contract covers retry semantics); live adapters.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-ADP-003
depends_on:
- TSK-P1-ADP-002
verifier_command: bash scripts/audit/verify_adp_003_deterministic_rail_routing.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-ADP-003 --evidence evidence/phase1/adp_003_deterministic_rail_routing.json
evidence_path: evidence/phase1/adp_003_deterministic_rail_routing.json
files_to_change:
- tasks/TSK-P1-ADP-003/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- tests/**
- scripts/audit/verify_adp_003_deterministic_rail_routing.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/adp_003_deterministic_rail_routing.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_adp_003_deterministic_rail_routing.sh and exits 0.
- Evidence file exists at evidence/phase1/adp_003_deterministic_rail_routing.json and is valid JSON.
- Evidence proves worker routing by rail_type is deterministic for identical inputs.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-LED-001 — Invariant verification in CI and in-cluster

### Goal
Make invariant verification a first-class, automated gate that runs both in CI and in the
deployed cluster (in-cluster health check or CronJob). Required deliverables:

1. A single, canonical invariant verification script: `scripts/db/verify_invariants.sh`
   that connects to the DB and runs all declared invariant checks (ledger balance integrity,
   no orphaned outbox rows, no instruction without a hierarchy link, etc.). The script exits
   0 only if all invariants pass.
2. CI integration: `verify_invariants.sh` runs in CI after every migration and after every
   test suite run. CI fails if any invariant fails.
3. In-cluster CronJob: a Kubernetes CronJob manifest that runs `verify_invariants.sh`
   on a schedule (default: every 15 minutes) and writes results to a file that the cluster
   health system can inspect.
4. Evidence: the verifier emits `evidence/phase1/led_001_invariants_ci_cluster.json` with:
   `invariants_checked` (count), `invariants_passed` (count), `invariants_failed` (list
   of names), `ci_run_confirmed`, `cronjob_manifest_present`.

### Scope
- In-scope: the verification script; CI wiring; the CronJob manifest; evidence.
- Out-of-scope: adding new invariants (that is LED-003+); alerting on invariant failures
  (Phase-2 operations).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-LED-001
depends_on:
- TSK-P1-ADP-003
verifier_command: bash scripts/audit/verify_led_001_invariants_ci_cluster.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-001 --evidence evidence/phase1/led_001_invariants_ci_cluster.json
evidence_path: evidence/phase1/led_001_invariants_ci_cluster.json
files_to_change:
- tasks/TSK-P1-LED-001/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_led_001_invariants_ci_cluster.sh
- scripts/db/**
- infra/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/led_001_invariants_ci_cluster.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_led_001_invariants_ci_cluster.sh and exits 0.
- Evidence file exists at evidence/phase1/led_001_invariants_ci_cluster.json and is valid JSON.
- Evidence proves invariant verification runs in CI and in-cluster with consistent results.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-LED-003 — Canonical message model enforcement

### Goal
Define and enforce a canonical message model for all ingress payloads. Every instruction
entering the system must conform to a versioned, schema-validated message format. Non-conformant
payloads must be rejected at the ingress boundary (before any DB write) with a structured
error that identifies the validation failure.

Required deliverables:
1. Canonical message schema: defined in `schema/messages/canonical_instruction_v1.json`
   (JSON Schema format). Required fields: `instruction_id` (UUID), `tenant_id` (UUID),
   `rail_type` (string), `amount_minor` (integer, > 0), `currency_code` (ISO 4217),
   `beneficiary_ref_hash` (string), `idempotency_key` (string), `submitted_at_utc` (ISO 8601).
2. Schema validation middleware: applied at the ingress API layer before any business logic.
   Rejection reason included in the 400 response body as `{ error: "SCHEMA_VALIDATION_FAILED",
   violations: [{field, message}] }`.
3. Schema versioning: the schema file has a `$schema_version` field. Future schema changes
   require a new version file; old versions must remain valid for in-flight instructions.
4. Verifier: submits a valid payload (accepted), a payload missing required fields (rejected),
   and a payload with wrong types (rejected). Records each test case in evidence.

### Scope
- In-scope: the schema file; the validation middleware; the verifier; evidence.
- Out-of-scope: KYC hash bridge (LED-004); message transformation (Phase-2).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-LED-003
depends_on:
- TSK-P1-LED-001
verifier_command: bash scripts/audit/verify_led_003_canonical_message_model.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-003 --evidence evidence/phase1/led_003_canonical_message_model.json
evidence_path: evidence/phase1/led_003_canonical_message_model.json
files_to_change:
- tasks/TSK-P1-LED-003/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- schema/**
- scripts/audit/verify_led_003_canonical_message_model.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/led_003_canonical_message_model.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_led_003_canonical_message_model.sh and exits 0.
- Evidence file exists at evidence/phase1/led_003_canonical_message_model.json and is valid JSON.
- Evidence proves canonical message model schema/enforcement is active and rejects nonconformant payloads.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-LED-004 — KYC hash bridge endpoint

### Goal
Implement a Phase-1 KYC hash bridge endpoint that: (a) accepts KYC verification hashes
from licensed providers, (b) validates the provider is registered in `kyc_provider_registry`,
(c) writes to `kyc_verification_records` with `retention_class = 'FIC_AML_CUSTOMER_ID'`,
and (d) does NOT expose or store any PII.

Required endpoint: `POST /v1/kyc/hash`

Request body:
```json
{
  "member_id": "<UUID>",
  "provider_code": "<string>",
  "outcome": "<string>",
  "verification_method": "<string>",
  "verification_hash": "<string>",
  "hash_algorithm": "<string>",
  "provider_signature": "<string>",
  "provider_reference": "<string>",
  "verified_at_provider": "<ISO 8601>"
}
```

Response: `{ "kyc_record_id": "<UUID>", "anchored_at": "<ISO 8601>", "outcome": "<string>" }`

Required validations:
- `provider_code` must exist in `kyc_provider_registry` with `is_active != false`.
- No PII fields accepted: if request body contains `nrc_number`, `full_name`, `date_of_birth`,
  or `photo_url`, reject with 400 and error code `PII_FIELD_REJECTED`.

Verifier must confirm: valid hash accepted and recorded, unknown provider_code rejected (404),
PII field in request body rejected (400), `retention_class` of written record equals
`FIC_AML_CUSTOMER_ID`.

### Scope
- In-scope: the endpoint; provider validation; the PII rejection guard; evidence.
- Out-of-scope: provider signature cryptographic verification (Phase-2 after key confirmed);
  kyc_hold routing (Phase-2).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-LED-004
depends_on:
- TSK-P1-LED-003
verifier_command: bash scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-004 --evidence evidence/phase1/led_004_kyc_hash_bridge_endpoint.json
evidence_path: evidence/phase1/led_004_kyc_hash_bridge_endpoint.json
files_to_change:
- tasks/TSK-P1-LED-004/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- tests/**
- scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/led_004_kyc_hash_bridge_endpoint.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh and exits 0.
- Evidence file exists at evidence/phase1/led_004_kyc_hash_bridge_endpoint.json and is valid JSON.
- Evidence proves KYC hash bridge endpoint resolves/anchors hashes without exposing raw PII.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


H-year retention archive + restore pipeline (implementation)

### Goal
Implement the three-layer WORM archive pipeline for records classified as `FIC_AML_CUSTOMER_ID`
(10-year retention) and `BFSA_FINANCIAL` (7-year retention). Required deliverables:

1. Archive script: `scripts/backup/archive_retention_records.sh` that queries tables by
   retention_class, exports records older than the current period (configurable lookback),
   writes signed JSONL to a WORM-compatible storage path (local path or S3-compatible MinIO
   in sandbox), and records the archive run in an `archive_runs` table.
2. WORM enforcement (sandbox): configure the target storage bucket with Object Lock
   (or equivalent) and confirm that archived objects cannot be deleted or overwritten during
   their retention window.
3. Restore drill: a script that reads a specific archive file, verifies its signature, and
   confirms the records are recoverable with the expected schema. The restore does not
   overwrite live data — it writes to a `restore_staging` schema or temp table.
4. Evidence: `led_002_retention_archive_restore.json` with `archive_run_id`,
   `records_archived`, `worm_enforcement_confirmed`, `restore_drill_passed`,
   `signature_verified`.

### Scope
- In-scope: the archive script; WORM config; the restore drill; evidence.
- Out-of-scope: automated deletion at end of retention period (Phase-2 legal hold
  management); multi-region replication.

#### Execution Metadata Patch Block (orchestrator source)

## TSK-P1-LED-002 — 10-year retention archive + restore pipeline (implementation)

```yaml
task_id: TSK-P1-LED-002
depends_on:
- TSK-P1-LED-004
verifier_command: bash scripts/audit/verify_led_002_retention_archive_restore.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-002 --evidence evidence/phase1/led_002_retention_archive_restore.json
evidence_path: evidence/phase1/led_002_retention_archive_restore.json
files_to_change:
- tasks/TSK-P1-LED-002/meta.yml
- docs/tasks/phase1_prompts.md
- infra/**
- scripts/audit/verify_led_002_retention_archive_restore.sh
- scripts/backup/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/led_002_retention_archive_restore.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_led_002_retention_archive_restore.sh and exits 0.
- Evidence file exists at evidence/phase1/led_002_retention_archive_restore.json and is valid JSON.
- Evidence proves 10-year retention archive pipeline and restore drill path are implemented and verifiable.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```

#### Execution Metadata Patch Block (Normalized)

```yaml
task_id: TSK-P1-LED-002
title: 10-year retention archive + restore pipeline (implementation)
depends_on:
- TSK-P1-LED-004
files_to_change:
  - scripts/retention/archive_ledger_10y.sh
  - scripts/retention/restore_ledger_archive.sh
  - scripts/verify/verify_led_retention_archive_restore_pipeline.sh
  - docs/runbooks/ledger_archive_restore.md
verifier_command: bash scripts/verify/verify_led_retention_archive_restore_pipeline.sh
evidence_path: evidence/phase1/led_retention_archive_restore_pipeline_verification.json
acceptance_assertions:
  - 10-year retention archive and restore pipeline implementation exists with deterministic archive/restore commands and manifest validation
  - Verifier exercises archive/restore pipeline contract (or simulated harness) and records exact outputs in evidence
failure_modes:
  - Only documentation/runbook added without executable archive+restore pipeline implementation
  - Verifier/evidence wrapper remains generic and does not prove archive/restore behavior
```

## TSK-P1-REG-001 — BoZ observability role + read-only views

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-REG-001
title: BoZ observability role + read-only views
owner_signoff: CTO
requires_compliance_input: true
depends_on:
- TSK-P1-LED-002
evidence:
  - evidence/phase1/boz_visibility_posture.json

Goal
- Implement the canonical DAG task intent for TSK-P1-REG-001: BoZ observability role + read-only views.

Requirements
1) DB role symphony_auditor_boz:
  - NOLOGIN (if access is via controlled channels) OR LOGIN with strict network policy (if required by sandbox)
  - SELECT-only allowlist
  - explicit denial of writes
2) Provide reconstruction query set:
  - given instruction_id/correlation_id, reconstruct: ingress attestation, dispatch attempts, finality, reversals.
3) Verifier must:
  - attempt DML as boz role and confirm denied
  - run reconstruction queries and confirm returns expected rows.

Evidence
- evidence/phase1/boz_visibility_posture.json: role privileges + negative tests + reconstruction sample.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-REG-001
depends_on:
- TSK-P1-LED-002
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_reg_001.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_reg_001.sh; exit 1; }; scripts/audit/verify_tsk_p1_reg_001.sh
  --evidence evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-REG-001\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json
files_to_change:
- tasks/TSK-P1-REG-001/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- tests/**
- scripts/audit/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/**
- scripts/audit/verify_tsk_p1_reg_001.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-REG-001' and pass == true.
- tasks/TSK-P1-REG-001/meta.yml exists and records terminal success state for the
  task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-REG-002 — Daily report endpoint + signed deterministic output

### Goal
Implement a daily regulatory report endpoint that produces a deterministic, signed output.
The report is the primary evidence artifact for BoZ observability. Required deliverables:

1. Endpoint: `GET /v1/regulatory/reports/daily?date=YYYY-MM-DD` (admin or auditor role).
   Response: a JSON report with the following fields at minimum:
   - `report_date`, `tenant_id` (optional: all tenants for BoZ role)
   - `instruction_count`, `instruction_total_minor`, `instruction_currency`
   - `exception_count_by_type` (map of exception type → count)
   - `settlement_success_pct`, `settlement_failure_pct`
   - `git_sha`, `produced_at_utc`
2. Determinism: running the same query for the same date must produce bit-identical output
   (excluding `produced_at_utc`). If the underlying data is unchanged, the report is identical.
3. Signing: the report JSON is signed using the evidence signing key from INF-006. The
   signature and key_id are returned in response headers: `X-Symphony-Signature` and
   `X-Symphony-Key-Id`.
4. Verifier: generates a report for a test date, verifies the signature, confirms determinism
   by generating the same report twice and comparing (minus produced_at_utc).

Evidence must include: `report_generated`, `signature_verified`, `determinism_confirmed`.

### Scope
- In-scope: the endpoint; signing; the determinism test; evidence.
- Out-of-scope: report delivery scheduling (Phase-2); report archiving (LED-002 covers archive).

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-REG-002
depends_on:
- TSK-P1-REG-001
verifier_command: bash scripts/audit/verify_reg_002_daily_report_signed_output.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-REG-002 --evidence evidence/phase1/reg_002_daily_report_signed_output.json
evidence_path: evidence/phase1/reg_002_daily_report_signed_output.json
files_to_change:
- tasks/TSK-P1-REG-002/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- scripts/audit/verify_reg_002_daily_report_signed_output.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/reg_002_daily_report_signed_output.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_reg_002_daily_report_signed_output.sh and exits 0.
- Evidence file exists at evidence/phase1/reg_002_daily_report_signed_output.json and is valid JSON.
- Evidence proves daily report endpoint output is deterministic and signed with evidence-signing identity.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-REG-003 — Incident workflow + 48-hour report export

### Goal
Implement a formal incident workflow and a 48-hour report export capability, satisfying
the BoZ NPS Act requirement to notify the regulator within 48 hours of a material incident.
Required deliverables:

1. Incident table: `regulatory_incidents` with: `incident_id` (UUID), `tenant_id`,
   `incident_type` (TEXT), `detected_at`, `description`, `severity` (LOW | MEDIUM | HIGH | CRITICAL),
   `status` (OPEN | UNDER_INVESTIGATION | REPORTED | CLOSED), `reported_to_boz_at` (nullable),
   `boz_reference` (nullable), `created_at`.
2. Incident registration endpoint: `POST /v1/admin/incidents` (admin role).
3. 48-hour report export: `GET /v1/regulatory/incidents/{incident_id}/report` that generates
   a structured JSON report suitable for BoZ submission. Report must include: all incident
   fields, a timeline (derived from an append-only `incident_events` table), and a signed
   evidence artifact at `evidence/phase1/reg_003_incident_48h_export.json`.
4. Verifier: registers a test incident, updates its status to UNDER_INVESTIGATION, generates
   the report, and confirms the report structure and signature.
5. The verifier must confirm: no incident report can be generated for an incident in OPEN
   status (must be UNDER_INVESTIGATION or beyond) — prevents premature BoZ notification.

### Scope
- In-scope: the incident table; registration endpoint; export endpoint; verifier; evidence.
- Out-of-scope: automated BoZ submission (Phase-2); incident escalation workflows.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-REG-003
depends_on:
- TSK-P1-REG-002
verifier_command: bash scripts/audit/verify_reg_003_incident_48h_export.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-REG-003 --evidence evidence/phase1/reg_003_incident_48h_export.json
evidence_path: evidence/phase1/reg_003_incident_48h_export.json
files_to_change:
- tasks/TSK-P1-REG-003/meta.yml
- docs/tasks/phase1_prompts.md
- services/**
- scripts/audit/verify_reg_003_incident_48h_export.sh
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/reg_003_incident_48h_export.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_reg_003_incident_48h_export.sh and exits 0.
- Evidence file exists at evidence/phase1/reg_003_incident_48h_export.json and is valid JSON.
- Evidence proves incident workflow generates a 48-hour report export artifact with required fields.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```


## TSK-P1-202 — Phase-1 closeout verifier scaffold (fail if contract missing)

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-202
title: Phase-1 closeout verifier scaffold (fail if contract missing)
owner_signoff: CTO
depends_on:
- checkpoint/BASE-OPS
evidence:
  - evidence/phase1/phase1_closeout.json

Goal
- Implement the canonical DAG task intent for TSK-P1-202: Phase-1 closeout verifier scaffold (fail if contract missing).

Requirements
1) Implement scripts/audit/verify_phase1_closeout.sh:
   - Reads phase1_contract.yml as source of truth.
   - MUST fail with explicit error if contract file is missing OR has zero required artifacts.
   - For each required artifact:
     - confirm file exists
     - confirm valid JSON
     - validate against evidence schema
2) Emit evidence/phase1/phase1_closeout.json listing required artifacts and pass/fail.

Acceptance
- Deleting phase1_contract.yml fails closeout.
- Empty required list fails closeout.
- Missing any one artifact fails closeout.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-202
depends_on:
- checkpoint/BASE-OPS
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_202.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_202.sh; exit 1; }; scripts/audit/verify_tsk_p1_202.sh
  --evidence evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-202\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json
files_to_change:
- tasks/TSK-P1-202/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- docs/PHASE1/**
- infra/**
- evidence/phase1/**
- scripts/audit/verify_tsk_p1_202.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-202' and pass == true.
- tasks/TSK-P1-202/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## PERF-004 — Perf contracts + closeout checks (extends verify_phase1_closeout.sh)

### Agent prompt (copy/paste)
```text
task_id: PERF-004
title: Perf contracts + closeout checks (extends verify_phase1_closeout.sh)
owner_signoff: CTO
depends_on:
- TSK-P1-202
evidence:
  - evidence/phase1/perf_004_closeout_extension.json

Goal
- Implement the canonical DAG task intent for PERF-004: Perf contracts + closeout checks (extends verify_phase1_closeout.sh).

Requirements
- Do not create a new closeout script; extend the scaffold.
- Add perf evidence paths and ensure schema validation.

Evidence
- evidence/phase1/perf_004_closeout_extension.json: lists new perf evidence enforced.
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: PERF-004
depends_on:
- TSK-P1-202
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/perf/verify_perf_004.sh
  || { echo MISSING_VERIFIER:scripts/perf/verify_perf_004.sh; exit 1; }; scripts/perf/verify_perf_004.sh
  --evidence evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"PERF-004\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json
files_to_change:
- tasks/PERF-004/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- scripts/perf/**
- docs/PHASE1/phase1_contract.yml
- evidence/phase1/**
- scripts/perf/verify_perf_004.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json
  and is valid JSON.
- Evidence JSON contains task_id == 'PERF-004' and pass == true.
- tasks/PERF-004/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-203 — Sandbox deploy manifests restore + posture verifier (include migration job/init)

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-203
title: Sandbox deploy manifests restore + posture verifier (include migration job/init)
owner_signoff: CTO
depends_on:
- PERF-004
evidence:
  - evidence/phase1/k8s_manifests_validation.json

Goal
- Implement the canonical DAG task intent for TSK-P1-203: Sandbox deploy manifests restore + posture verifier (include migration job/init).

Requirements
1) Add a migration Job (or initContainer) that runs BEFORE ledger-api/executor start.
2) Manifests must include:
   - ledger-api
   - executor-worker
   - migration job
   - secrets/bootstrap mechanism
3) Provide a verifier that checks manifests include migration job and required resources.

Evidence
- evidence/phase1/k8s_manifests_validation.json
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-203
depends_on:
- PERF-004
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_203.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_203.sh; exit 1; }; scripts/audit/verify_tsk_p1_203.sh
  --evidence evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-203\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json
files_to_change:
- tasks/TSK-P1-203/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- docs/PHASE1/**
- infra/**
- evidence/phase1/**
- scripts/audit/verify_tsk_p1_203.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-203' and pass == true.
- tasks/TSK-P1-203/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-204 — Exception case pack generator (script/tool, not a new service)

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-204
title: Exception case pack generator (script/tool, not a new service)
owner_signoff: CTO
depends_on:
- TSK-P1-203
evidence:
  - evidence/phase1/exception_case_pack_sample.json

Goal
- Implement the canonical DAG task intent for TSK-P1-204: Exception case pack generator (script/tool, not a new service).

Requirements
1) Implement scripts/tools/generate_exception_case_pack.sh (or .py) that:
   - takes correlation_id or instruction_id
   - gathers: ingress attestation, outbox attempts, exception chain, relevant evidence artifacts
   - emits a single JSON pack (no raw PII)
2) Validate pack against evidence schema (or a specific case-pack schema).
3) Add a verifier that generates a sample pack in CI.

Evidence
- evidence/phase1/exception_case_pack_sample.json
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-204
depends_on:
- TSK-P1-203
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_204.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_204.sh; exit 1; }; scripts/audit/verify_tsk_p1_204.sh
  --evidence evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-204\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json
files_to_change:
- tasks/TSK-P1-204/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- docs/PHASE1/**
- infra/**
- evidence/phase1/**
- scripts/audit/verify_tsk_p1_204.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-204' and pass == true.
- tasks/TSK-P1-204/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-205 — KPI evidence artifact (include settlement_window_compliance_pct)

### Agent prompt (copy/paste)
```text
task_id: TSK-P1-205
title: KPI evidence artifact (include settlement_window_compliance_pct)
owner_signoff: CTO
depends_on:
- TSK-P1-204
evidence:
  - evidence/phase1/kpis.json

Goal
- Implement the canonical DAG task intent for TSK-P1-205: KPI evidence artifact (include settlement_window_compliance_pct).

Required KPIs (minimum)
Engineering:
- ingress_success_rate
- p95_ingress_latency_ms
- retry_ceiling_respected_pct
- evidence_pack_generation_success_pct
- tenant_isolation_selftest_passed (boolean + count)

Regulatory-facing:
- settlement_window_compliance_pct (must reference PERF‑005 artifact path/id)

Requirements
- Define KPI computation method and measurement_truth for each KPI.
- Emit evidence/phase1/kpis.json and validate schema.

Evidence
- evidence/phase1/kpis.json
```

---

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-205
depends_on:
- TSK-P1-204
verifier_command: bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml
  || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/audit/verify_tsk_p1_205.sh
  || { echo MISSING_VERIFIER:scripts/audit/verify_tsk_p1_205.sh; exit 1; }; scripts/audit/verify_tsk_p1_205.sh
  --evidence evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json;
  python3 -c "import json,pathlib; p=pathlib.Path(\"evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json\");
  assert p.exists(), f\"MISSING_EVIDENCE:{p}\"; d=json.loads(p.read_text()); assert
  d.get(\"task_id\") == \"TSK-P1-205\", d.get(\"task_id\"); assert isinstance(d.get(\"status\"),
  str) and d[\"status\"] in {\"PASS\",\"DONE\",\"OK\"}, d.get(\"status\")"'
evidence_path: evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json
files_to_change:
- tasks/TSK-P1-205/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/**
- docs/PHASE1/**
- infra/**
- evidence/phase1/**
- scripts/audit/verify_tsk_p1_205.sh
acceptance_assertions:
- Evidence file exists at evidence/phase1/tsk_p1_205__kpi_evidence_artifact_include_settlement_window.json
  and is valid JSON.
- Evidence JSON contains task_id == 'TSK-P1-205' and pass == true.
- tasks/TSK-P1-205/meta.yml exists and records terminal success state for the task.
- All DAG dependencies are complete before execution starts.
- Task-specific verifier(s) described in the task narrative (if any) run green before
  closeout.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification
  => FAIL_REVIEW.
```


## TSK-P1-060 — Phase-2 followthrough program definition (only after Phase-1 mechanically closed)

### Goal
This task is a governance gate and planning document, not an implementation task. It may
only execute after `checkpoint/PHASE-1-CLOSEOUT` has been confirmed complete. Its output
is a Phase-2 program definition document and a machine-readable gate file.

Required deliverables:
1. Gate confirmation: emit `evidence/phase1/p1_060_phase2_followthrough_gate.json` that
   includes: `phase1_closeout_confirmed: true`, `phase1_closeout_evidence_sha256` (the SHA
   of `evidence/phase1/phase1_closeout.json`), `produced_at_utc`, `git_sha`.
2. Phase-2 program definition: create or update `docs/phases/PHASE2_PROGRAM.md` with:
   - The Phase-2 scope (ZRA levy live integration, KYC cryptographic verification, live rail adapters)
   - The carry-forward items from Phase-1 (any tasks deferred or noted as Phase-2 prerequisites)
   - The ordering principle for Phase-2 work (same evidence-grade standards apply)
3. The document must explicitly list all Phase-0/Phase-1 stubs that Phase-2 must activate:
   `levy_status` CHECK constraint, `kyc_hold` routing, provider signature verification,
   `period_status` CHECK constraint, `regression_classification` in PERF, live rail adapters.

This task produces NO code changes to existing files other than the gate evidence and the
program definition document.

### Scope
- In-scope: the gate evidence artifact; the Phase-2 program definition document.
- Out-of-scope: any implementation work; any schema changes; any changes to Phase-1 verifiers.

#### Execution Metadata Patch Block (orchestrator source)

```yaml
task_id: TSK-P1-060
depends_on:
- checkpoint/PHASE-1-CLOSEOUT
verifier_command: bash scripts/audit/verify_p1_060_phase2_followthrough_gate.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-060 --evidence evidence/phase1/p1_060_phase2_followthrough_gate.json
evidence_path: evidence/phase1/p1_060_phase2_followthrough_gate.json
files_to_change:
- tasks/TSK-P1-060/meta.yml
- docs/tasks/phase1_prompts.md
- scripts/audit/verify_p1_060_phase2_followthrough_gate.sh
- docs/PHASE1/phase1_contract.yml
- docs/phases/**
- evidence/phase1/p1_060_phase2_followthrough_gate.json
acceptance_assertions:
- Verifier script exists at scripts/audit/verify_p1_060_phase2_followthrough_gate.sh and exits 0.
- Evidence file exists at evidence/phase1/p1_060_phase2_followthrough_gate.json and is valid JSON.
- Evidence proves Phase-2 followthrough definition is blocked until checkpoint/PHASE-1-CLOSEOUT is complete.
failure_modes:
- Missing prompt section or missing execution metadata patch block => STOP.
- Missing phase contract file => FAIL_CLOSED.
- Evidence file missing / invalid JSON / task_id mismatch / pass != true => FAIL.
- Dependency incomplete => BLOCKED.
- Undeclared file modifications outside files_to_change without explicit justification => FAIL_REVIEW.
```



## Audit Patch Notes

- DAG task nodes processed: 54

- Existing prompt sections matched: 23

- Stub sections inserted: 31

- Missing IDs patched as stubs: TSK-CLEAN-001, TSK-CLEAN-002, TSK-P1-059, TSK-P0-102, TSK-P0-208, TSK-P1-057-FINAL, PERF-001, PERF-002, PERF-003, PERF-005A, TSK-P1-HIER-008, TSK-P1-HIER-009, TSK-P1-HIER-010, TSK-P1-HIER-011, TSK-P1-INF-002, TSK-P1-INF-001, TSK-P1-INF-005, TSK-P1-INF-003, TSK-P1-TEN-001, TSK-P1-TEN-002, TSK-P1-TEN-003, TSK-P1-ADP-001, TSK-P1-ADP-002, TSK-P1-ADP-003, TSK-P1-LED-001, TSK-P1-LED-003, TSK-P1-LED-004, TSK-P1-LED-002, TSK-P1-REG-002, TSK-P1-REG-003, TSK-P1-060
