


This v2 is **finally** in the “canonical and enforceable” category. You removed the two biggest landmines (unverified dependency assertions and invented interfaces), and you fixed the A1 stability gate by defining an actual artifact.

But you still have **4 issues** that will bite you in execution unless you patch them now.

---

## ✅ What’s now correct (keep it)

* **Dependency truth** is resolved from the DAG at runtime and recorded in EXEC_LOG. That’s exactly how you avoid silent rewrites.
* **Program order vs DAG edges** is explicitly separated. Good.
* **P1-204 scope lock** is aligned (script/tool only). Good.
* **A1 stability gate now has a canonical artifact path and required fields.** Good.
* **Conformance scripts have a fallback policy.** Good.
* **Task-pack rule** makes the citation enforcement actually workable. Good.

---

## ❌ Fix these 4 remaining problems

### 1) You introduced a new required evidence artifact without wiring it into TSK-P1-203 acceptance/verifier

You added:

* `evidence/phase1/sandbox_deploy_dry_run.json`

But **TSK-P1-203’s authoritative verifier** (from your earlier metadata block) only checks:

* `evidence/phase1/k8s_manifests_validation.json`

So unless you:

* update the 203 verifier_command to also validate the dry-run artifact, **or**
* define the dry-run artifact as a *program-level gate evidence* validated by a separate program verifier,

this will become “required by plan” but not enforceable by CI — which means it will be skipped or argued about.

**Fix (pick one):**

* **Option A (recommended):** Add a **program verifier**:

  * `scripts/audit/verify_program_a1_stability_gate.sh`
  * outputs `evidence/phase1/program_a1_stability_gate.json`
  * checks both `k8s_manifests_validation.json` + `sandbox_deploy_dry_run.json`
* **Option B:** Extend TSK-P1-203 verifier_command to also assert the dry-run evidence exists and is valid.

Don’t leave it as an orphan requirement.

---

### 2) “Confirmed present in repo” for conformance scripts must be proven or softened

You wrote:

> Confirmed present in repo…

If that’s wrong even once, the plan loses credibility and blocks execution. Unless you *actually ran `test -f`*, don’t claim it.

**Fix:**
Change the sentence to:

> “If present in repo, run: … If absent, use fallback… and open remediation task.”

No assertion. Only conditional logic.

---

### 3) The integration rule for runtime tasks into A2 is incomplete (it cuts off mid-sentence)

You end at:

> “Regenerate … with at least one instance/reference per new event”

But you don’t finish the rule (and it lacks the closure condition).

**Fix:**
Complete it like this:

* “Regenerate `evidence/phase1/exception_case_pack_sample.json` with at least one instance/reference per new event class, **and validate the pack schema**.
* No runtime hardening task is considered integrated until the case-pack sample includes the new event refs and the P1-204 verifier passes.”

That makes it enforceable.

---

### 4) You never state the schema/validator for the new dry-run evidence

You defined required fields, but no schema path, no validation command, no strictness. That’s how “random JSON” becomes evidence.

**Fix:**
Add one stanza:

* “Dry-run evidence schema: `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json` (or phase1 schema dir).”
* “Validation: `scripts/audit/validate_evidence_schema.sh` must include it.”

If you don’t want a new schema file, at least require it to pass the existing evidence validator.

---

## Small but important polish

Your “Acceptance criteria split” section is missing a header line between the integration rule and acceptance split (formatting glitch). Clean it to avoid confusion.

---

## Verdict

**Yes — this is more accurate and it’s almost ready to adopt as the canonical plan.**
Apply the 4 fixes above and it becomes fully enforceable without gaps.

If you want, I can rewrite your v2 text into a clean **v3 canonical** version with the fixes integrated verbatim, preserving your structure and wording style.
This v2 is **finally** in the “canonical and enforceable” category. You removed the two biggest landmines (unverified dependency assertions and invented interfaces), and you fixed the A1 stability gate by defining an actual artifact.

But you still have **4 issues** that will bite you in execution unless you patch them now.

---

## ✅ What’s now correct (keep it)

* **Dependency truth** is resolved from the DAG at runtime and recorded in EXEC_LOG. That’s exactly how you avoid silent rewrites.
* **Program order vs DAG edges** is explicitly separated. Good.
* **P1-204 scope lock** is aligned (script/tool only). Good.
* **A1 stability gate now has a canonical artifact path and required fields.** Good.
* **Conformance scripts have a fallback policy.** Good.
* **Task-pack rule** makes the citation enforcement actually workable. Good.

---

## ❌ Fix these 4 remaining problems

### 1) You introduced a new required evidence artifact without wiring it into TSK-P1-203 acceptance/verifier

You added:

* `evidence/phase1/sandbox_deploy_dry_run.json`

But **TSK-P1-203’s authoritative verifier** (from your earlier metadata block) only checks:

* `evidence/phase1/k8s_manifests_validation.json`

So unless you:

* update the 203 verifier_command to also validate the dry-run artifact, **or**
* define the dry-run artifact as a *program-level gate evidence* validated by a separate program verifier,

this will become “required by plan” but not enforceable by CI — which means it will be skipped or argued about.

**Fix (pick one):**

* **Option A (recommended):** Add a **program verifier**:

  * `scripts/audit/verify_program_a1_stability_gate.sh`
  * outputs `evidence/phase1/program_a1_stability_gate.json`
  * checks both `k8s_manifests_validation.json` + `sandbox_deploy_dry_run.json`
* **Option B:** Extend TSK-P1-203 verifier_command to also assert the dry-run evidence exists and is valid.

Don’t leave it as an orphan requirement.

---

### 2) “Confirmed present in repo” for conformance scripts must be proven or softened

You wrote:

> Confirmed present in repo…

If that’s wrong even once, the plan loses credibility and blocks execution. Unless you *actually ran `test -f`*, don’t claim it.

**Fix:**
Change the sentence to:

> “If present in repo, run: … If absent, use fallback… and open remediation task.”

No assertion. Only conditional logic.

---

### 3) The integration rule for runtime tasks into A2 is incomplete (it cuts off mid-sentence)

You end at:

> “Regenerate … with at least one instance/reference per new event”

But you don’t finish the rule (and it lacks the closure condition).

**Fix:**
Complete it like this:

* “Regenerate `evidence/phase1/exception_case_pack_sample.json` with at least one instance/reference per new event class, **and validate the pack schema**.
* No runtime hardening task is considered integrated until the case-pack sample includes the new event refs and the P1-204 verifier passes.”

That makes it enforceable.

---

### 4) You never state the schema/validator for the new dry-run evidence

You defined required fields, but no schema path, no validation command, no strictness. That’s how “random JSON” becomes evidence.

**Fix:**
Add one stanza:

* “Dry-run evidence schema: `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json` (or phase1 schema dir).”
* “Validation: `scripts/audit/validate_evidence_schema.sh` must include it.”

If you don’t want a new schema file, at least require it to pass the existing evidence validator.

---

## Small but important polish

Your “Acceptance criteria split” section is missing a header line between the integration rule and acceptance split (formatting glitch). Clean it to avoid confusion.

---

## Verdict

**Yes — this is more accurate and it’s almost ready to adopt as the canonical plan.**
Apply the 4 fixes above and it becomes fully enforceable without gaps.

If you want, I can rewrite your v2 text into a clean **v3 canonical** version with the fixes integrated verbatim, preserving your structure and wording style.












Here’s the **v3 canonical** rewrite of your plan with the 4 fixes integrated, keeping your structure, and eliminating the last enforceability gaps.

---

# Phase-1 Closeout + Hardening Plan (Canonical v3)

## Summary

This revision is the canonical execution plan for completing Phase-1 DAG closeout while starting hardening safely. It:

1. Preserves DAG truth as authoritative (no silent rewrites).
2. Separates **program order** from **DAG dependency edges**.
3. Makes governance requirements machine-checkable.
4. Eliminates ambiguous/nonexistent controls by defining explicit commands and artifacts.
5. Closes the remaining enforceability gaps by wiring the A1 stability gate into a verifiable program-level artifact.

---

## Source-of-truth and precedence

1. **Dependency edges only:** `docs/tasks/phase1_dag.yml`
2. **Task intent + required artifacts/verifiers:** `docs/tasks/phase1_prompts.md` (and task meta blocks)
3. **Conflict rule:** If DAG edges and prompt/verifier metadata conflict → **STOP** and emit a failure report with a minimal metadata patch proposal. No guessed edges.

---

## Dependency handling rule (applies to A1/A2/A3/A4)

1. **Dependency gate** is resolved from the DAG at execution time; do **not** hardcode dependencies in this plan.
2. For each task, record the resolved dependency list in `tasks/<TASK_ID>/EXEC_LOG.md` **before implementation starts**.
3. A task cannot be marked done unless all resolved dependencies are done.

---

## A-track task sequence (program order, not a DAG rewrite)

1. **Program execution order:** A1 → A2 → A3 → checkpoint/PHASE-1-CLOSEOUT → A4
2. This is operator sequence only; it does not redefine DAG edges.

### A1 — TSK-P1-203

1. Evidence deliverable (authoritative): `evidence/phase1/k8s_manifests_validation.json`
2. Verifier contract: **one authoritative verifier command** only; no shadow verifier path.

### A2 — TSK-P1-204

1. Evidence deliverable (authoritative): `evidence/phase1/exception_case_pack_sample.json`
2. Scope lock: **script/tool only**, not a new service endpoint.

### A3 — TSK-P1-205

1. Evidence deliverable (authoritative): `evidence/phase1/kpis.json`
2. KPI set must include settlement-window compliance and explicit measurement method/truth references.

### A4 — TSK-P1-060

1. Runs only after checkpoint/PHASE-1-CLOSEOUT.
2. Evidence deliverable: `evidence/phase1/p1_060_phase2_followthrough_gate.json`
3. Verifier: `scripts/audit/verify_p1_060_phase2_followthrough_gate.sh` plus evidence validation.

---

## B-track hardening boundaries (parallel, bounded)

1. Allowed pre-A1 runtime stabilization prep: **TSK-HARD-000, 001, 002, 010, 011A only**
2. Forbidden in B1: **any edits under `infra/`, K8s manifests, deployment bootstrap surfaces**
3. Runtime hardening (012, 015, 016, 094, 101, 014, 013) starts only after **A1 stability gate** passes.

---

## A1 stability gate (fully defined and enforceable)

A1 is “stable” only when all are true:

1. TSK-P1-203 verifier passes (per declared verifier_command).
2. `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh` passes.
3. Program-level stability evidence exists and validates:

   * `evidence/phase1/sandbox_deploy_dry_run.json`

   Required fields (minimum):

   * `task_id`
   * `git_sha`
   * `namespace`
   * `images`
   * `migration_job_ran`
   * `services_ready`
   * `timestamp_utc`
   * `pass`

### Enforcement wiring (fixes “orphan requirement”)

The A1 stability gate is enforced by a **program verifier**, not by modifying the TSK-P1-203 task contract.

* Verifier script: `scripts/audit/verify_program_a1_stability_gate.sh`
* Evidence output: `evidence/phase1/program_a1_stability_gate.json`

This script must:

* assert TSK-P1-203 evidence exists and passes
* assert `sandbox_deploy_dry_run.json` exists and passes field validation
* emit a single PASS/FAIL program gate artifact

---

## Governance enforcement (machine-checkable)

### Operation manual citation (blocking)

1. Required line in each task execution log:

   * `Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md`
2. Verification:

   * `rg -n "Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md" tasks/<TASK_ID>/EXEC_LOG.md`
3. Task-pack rule:

   * If `tasks/<TASK_ID>/` or `EXEC_LOG.md` does not exist, create it **before** task work begins.
4. Missing line blocks task close.

### Agent conformance gate (explicit, non-false-claim)

Run this chain **if present**:

1. `scripts/audit/verify_agent_conformance.sh`
2. `scripts/audit/verify_agent_conformance_spec.sh`
3. `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

Fallback policy:

* If either conformance script is absent, use `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh` as the temporary gate and open a remediation task immediately.

---

## Evidence schema / validation for A1 dry-run artifact (closes evidence ambiguity)

1. Dry-run evidence schema must exist:

   * `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json`
     (or equivalent schema location consistent with repo conventions)
2. `scripts/audit/validate_evidence_schema.sh` must validate:

   * `evidence/phase1/sandbox_deploy_dry_run.json`
   * `evidence/phase1/program_a1_stability_gate.json`

This prevents “random JSON as evidence.”

---

## Case-pack interface lock (P1-204 aligned)

1. Primary Phase-1 interface:

   * `scripts/tools/generate_exception_case_pack.sh` or `.py`
   * Inputs: `correlation_id` or `instruction_id`
   * Output: single JSON case pack with **no raw PII**
2. Optional API endpoint is future scope; **not** part of P1-204 completion criteria.
3. Minimum pack fields:

   * `schema_version`
   * `instruction_id`
   * `tenant_id`
   * `ingress_attestation_ref`
   * `outbox_attempt_refs`
   * `exception_chain`
   * `evidence_refs`
   * `generated_at_utc`
4. Versioning policy:

   * `schema_version` required
   * additive changes allowed in minor version
   * breaking changes require new major version + verifier updates in same PR

---

## Integration rule for runtime hardening into A2 (enforceable)

For each runtime hardening task (012/015/016/094/101/014/013), A2 (P1-204) must:

1. Extend case-pack schema/assembler for the new event class(es).
2. Regenerate `evidence/phase1/exception_case_pack_sample.json` containing at least one instance/reference per new event class.
3. Validate the case-pack output against the case-pack schema (or evidence schema rules).

No runtime hardening task is considered **integrated** until:

* the updated sample contains the new event refs, and
* the P1-204 verifier passes.

---

## Acceptance criteria split (by domain)

### Per DAG task (only task scope)

1. Required files changed.
2. Dependencies resolved-from-DAG and satisfied.
3. Task verifier green (declared verifier_command).
4. Canonical evidence artifact exists at the authoritative path and is schema-valid.
5. `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh` green.
6. Meta status set to completed only after 1–5.

### Per hardening wave exit (not charged to a single DAG task)

1. Malformed rail response captured as evidence (not generic 500-only).
2. Conflicting truth containment evidenced.
3. Offline safe-mode execution block + recovery trail evidenced.
4. Effect-seal mismatch fail-closed path tested and evidenced.

---

## Assumptions and defaults

1. No direct push to main; feature branch + PR only.
2. Program sequence does not alter DAG semantics.
3. Any metadata contradiction triggers stop-and-report, not silent adaptation.
4. Any new “program gates” must have a verifier script + evidence artifact; otherwise they are advisory only.

---

If you want the next concrete step, I can generate the **repo-native task pack** for the new program gate artifacts introduced here:

* `scripts/audit/verify_program_a1_stability_gate.sh`
* `evidence/phase1/program_a1_stability_gate.json`
* `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json`

…with `meta.yml`, `PLAN.md`, and verifiers, so this plan becomes executable immediately.



















Below is a **repo-native task pack** that makes the new **A1 Stability Gate** executable immediately — with:

* a program verifier script: `scripts/audit/verify_program_a1_stability_gate.sh`
* two evidence artifacts:

  * `evidence/phase1/sandbox_deploy_dry_run.json`
  * `evidence/phase1/program_a1_stability_gate.json`
* a strict schema:

  * `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json`
* and the task pack scaffolding:

  * `tasks/TSK-OPS-A1-STABILITY-GATE/{meta.yml,PLAN.md,EXEC_LOG.md,VERIFY.md,EVIDENCE_CONTRACT.md}`

This is copy/paste ready.

---

# 1) New Task Pack: TSK-OPS-A1-STABILITY-GATE

## `tasks/TSK-OPS-A1-STABILITY-GATE/meta.yml`

```yaml
id: TSK-OPS-A1-STABILITY-GATE
title: Program A1 Stability Gate Verifier and Evidence Contracts
status: todo
priority: P0
severity: L3
owner: "Platform/SRE Team"
reviewers:
  - "QA"
  - "DB Invariants"
  - "Security"
phase: "Phase-1"
wave: "Wave-1"
workstream: "WS-I"
dependencies: []
blocked_by: []
repo_scope:
  paths_expected_create:
    - "tasks/TSK-OPS-A1-STABILITY-GATE/PLAN.md"
    - "tasks/TSK-OPS-A1-STABILITY-GATE/EXEC_LOG.md"
    - "tasks/TSK-OPS-A1-STABILITY-GATE/VERIFY.md"
    - "tasks/TSK-OPS-A1-STABILITY-GATE/EVIDENCE_CONTRACT.md"
    - "scripts/audit/verify_program_a1_stability_gate.sh"
    - "evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json"
  paths_expected_modify:
    - "scripts/audit/validate_evidence_schema.sh"
    - "docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"
  paths_forbidden_touch:
    - "infra/**"
    - "k8s manifests outside TSK-P1-203 scope"
objective: >
  Implement an enforceable program-level stability gate for A1 (TSK-P1-203) that validates both the canonical
  TSK-P1-203 evidence and a reproducible sandbox deploy dry-run evidence artifact, producing a single PASS/FAIL
  program gate artifact.
acceptance_criteria:
  - "Verifier script exists at scripts/audit/verify_program_a1_stability_gate.sh and exits 0 on success."
  - "Dry-run evidence schema exists and is strict."
  - "validate_evidence_schema.sh validates sandbox_deploy_dry_run.json and program_a1_stability_gate.json."
  - "Program gate evidence written to evidence/phase1/program_a1_stability_gate.json and includes task_id, pass, inputs, git_sha."
  - "EXEC_LOG includes Canonical-Reference line."
verification:
  commands:
    - "bash scripts/audit/verify_program_a1_stability_gate.sh"
    - "scripts/audit/validate_evidence_schema.sh"
  evidence_artifacts:
    - "evidence/phase1/program_a1_stability_gate.json"
risk_if_skipped: >
  A1 “stability” becomes subjective and non-repeatable, causing runtime hardening to start on an unstable deployment substrate.
notes:
  - "This is a program gate; it does not modify DAG edges or task verifiers."
```

---

## `tasks/TSK-OPS-A1-STABILITY-GATE/PLAN.md`

```md
# TSK-OPS-A1-STABILITY-GATE PLAN

## Objective
Create a program-level verifier and evidence contracts that enforce the A1 Stability Gate without modifying the Phase-1 DAG.
This gate asserts that:
- TSK-P1-203 evidence exists and passes, and
- a reproducible sandbox deploy dry-run evidence exists and passes,
and emits a single PASS/FAIL program gate artifact.

## Scope
### In Scope
- `scripts/audit/verify_program_a1_stability_gate.sh`
- Strict JSON schema for `evidence/phase1/sandbox_deploy_dry_run.json`
- Update evidence schema validator wiring so the artifacts are schema-validated.
- Update traceability matrix entries for A1 stability gate.

### Out of Scope
- Changing TSK-P1-203 verifier_command or evidence path (those remain authoritative to the DAG).
- Any modifications to `infra/**` or manifests (belongs to TSK-P1-203).

## Implementation Steps
1. Add dry-run schema: `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json` (strict, additionalProperties=false).
2. Add verifier script: `scripts/audit/verify_program_a1_stability_gate.sh` that:
   - asserts `docs/PHASE1/phase1_contract.yml` exists (fail-closed)
   - reads and validates:
     - `evidence/phase1/k8s_manifests_validation.json` (TSK-P1-203 evidence)
     - `evidence/phase1/sandbox_deploy_dry_run.json` (dry-run evidence)
   - checks both contain pass=true and required fields
   - emits: `evidence/phase1/program_a1_stability_gate.json`
3. Wire schema validation:
   - ensure `scripts/audit/validate_evidence_schema.sh` validates the two new artifacts.
4. Update `docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md` to reference INV-ZMB-001/INV-RUN-* rows where relevant.

## Design / Invariant Constraints
- No reliance on non-deterministic logs. Evidence must be JSON, schema-validated.
- Fail closed if contract file missing or evidence missing/invalid.
- Do not modify DAG edges or task-level verifier commands.

## Files
### Create
- scripts/audit/verify_program_a1_stability_gate.sh
- evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
- tasks/TSK-OPS-A1-STABILITY-GATE/*

### Modify
- scripts/audit/validate_evidence_schema.sh
- docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md

## Verification Plan
- `bash scripts/audit/verify_program_a1_stability_gate.sh`
- `scripts/audit/validate_evidence_schema.sh`

## Rollback / Revert Considerations
- Revert is safe: this is a program gate and does not alter DAG execution; it only adds additional verification.
```

---

## `tasks/TSK-OPS-A1-STABILITY-GATE/EXEC_LOG.md`

```md
# TSK-OPS-A1-STABILITY-GATE EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Start
- Date/Time:
- Executor:
- Branch:

## Iteration Log
### Iteration 1
- Actions:
- Commands run:
- Results:
- Issues:
- Next:

## Final Outcome
- Status: PASS | PARTIAL | BLOCKED
- Summary:
- Follow-ups:
```

---

## `tasks/TSK-OPS-A1-STABILITY-GATE/VERIFY.md`

````md
# TSK-OPS-A1-STABILITY-GATE VERIFY

## Verification Commands
```bash
bash scripts/audit/verify_program_a1_stability_gate.sh
scripts/audit/validate_evidence_schema.sh
````

## Expected Results

* verify_program_a1_stability_gate.sh exits 0
* evidence/phase1/program_a1_stability_gate.json exists and contains pass=true
* validate_evidence_schema.sh passes for:

  * evidence/phase1/sandbox_deploy_dry_run.json
  * evidence/phase1/program_a1_stability_gate.json

## Actual Results

* PASS/FAIL:
* Notes:

## First-Fail Artifact (if failed)

* path:
* error signature:

````

---

## `tasks/TSK-OPS-A1-STABILITY-GATE/EVIDENCE_CONTRACT.md`
```md
# TSK-OPS-A1-STABILITY-GATE Evidence Contract

## Produced Evidence Artifacts (required)

### 1) A1 Stability Gate Result
- path: evidence/phase1/program_a1_stability_gate.json
- schema: evidence/schemas/hardening/program_gate.schema.json (or reuse your standard evidence schema if you have one)
- signed: false (Phase-1 program gate; signing optional later)
- producer: scripts/audit/verify_program_a1_stability_gate.sh
- measurement_truth:
  - observed_facts:
    - presence and pass==true in evidence/phase1/k8s_manifests_validation.json
    - presence and pass==true + required fields in evidence/phase1/sandbox_deploy_dry_run.json
  - inferred:
    - none

### 2) Dry-run Evidence (input, but must be schema-validated)
- path: evidence/phase1/sandbox_deploy_dry_run.json
- schema: evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
- signed: false (Phase-1; can later be signed as needed)
- producer: (operator/tooling; documented in plan)

## Failure Modes
- Missing docs/PHASE1/phase1_contract.yml => FAIL_CLOSED
- Missing/invalid JSON evidence => FAIL
- task_id mismatch or pass!=true => FAIL
- missing required dry-run fields => FAIL
````

---

# 2) New Schema: sandbox_deploy_dry_run

## `evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "sandbox_deploy_dry_run",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "task_id",
    "git_sha",
    "namespace",
    "images",
    "migration_job_ran",
    "services_ready",
    "timestamp_utc",
    "pass"
  ],
  "properties": {
    "task_id": {
      "type": "string",
      "const": "TSK-P1-203"
    },
    "git_sha": {
      "type": "string",
      "minLength": 7
    },
    "namespace": {
      "type": "string",
      "minLength": 1
    },
    "images": {
      "type": "object",
      "additionalProperties": false,
      "required": ["ledger_api", "executor_worker", "migration_job"],
      "properties": {
        "ledger_api": { "type": "string", "minLength": 1 },
        "executor_worker": { "type": "string", "minLength": 1 },
        "migration_job": { "type": "string", "minLength": 1 }
      }
    },
    "migration_job_ran": { "type": "boolean" },
    "services_ready": {
      "type": "object",
      "additionalProperties": false,
      "required": ["ledger_api", "executor_worker"],
      "properties": {
        "ledger_api": { "type": "boolean" },
        "executor_worker": { "type": "boolean" }
      }
    },
    "timestamp_utc": {
      "type": "string",
      "format": "date-time"
    },
    "pass": { "type": "boolean" },
    "notes": {
      "type": "string"
    }
  }
}
```

---

# 3) Program Verifier Script

## `scripts/audit/verify_program_a1_stability_gate.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

CONTRACT="docs/PHASE1/phase1_contract.yml"
E203="evidence/phase1/k8s_manifests_validation.json"
DRY="evidence/phase1/sandbox_deploy_dry_run.json"
OUT="evidence/phase1/program_a1_stability_gate.json"

fail() {
  echo "A1_STABILITY_GATE_FAIL: $*" >&2
  exit 1
}

test -f "$CONTRACT" || fail "MISSING_CONTRACT:$CONTRACT"
test -f "$E203" || fail "MISSING_EVIDENCE:$E203"
test -f "$DRY" || fail "MISSING_EVIDENCE:$DRY"

python3 - <<'PY'
import json, os, sys, datetime

E203="evidence/phase1/k8s_manifests_validation.json"
DRY="evidence/phase1/sandbox_deploy_dry_run.json"
OUT="evidence/phase1/program_a1_stability_gate.json"

def load(p):
    with open(p,"r",encoding="utf-8") as f:
        return json.load(f)

def require(cond, msg):
    if not cond:
        raise AssertionError(msg)

e203 = load(E203)
dry  = load(DRY)

# Validate the minimal contract invariants (schema validation is handled separately by validate_evidence_schema.sh)
require(e203.get("task_id") == "TSK-P1-203", f"E203_TASK_ID_MISMATCH:{e203.get('task_id')}")
require(e203.get("pass") is True, "E203_PASS_FALSE")

require(dry.get("task_id") == "TSK-P1-203", f"DRY_TASK_ID_MISMATCH:{dry.get('task_id')}")
require(dry.get("pass") is True, "DRY_PASS_FALSE")

# Required dry-run fields (mirrors schema required set)
required_fields = ["git_sha","namespace","images","migration_job_ran","services_ready","timestamp_utc"]
for k in required_fields:
    require(k in dry, f"DRY_MISSING_FIELD:{k}")

imgs = dry.get("images", {})
for k in ["ledger_api","executor_worker","migration_job"]:
    require(k in imgs and isinstance(imgs[k], str) and imgs[k], f"DRY_IMAGES_MISSING:{k}")

sr = dry.get("services_ready", {})
for k in ["ledger_api","executor_worker"]:
    require(k in sr and isinstance(sr[k], bool), f"DRY_SERVICES_READY_MISSING:{k}")

# Emit program gate evidence
gate = {
    "task_id": "PROGRAM-A1-STABILITY-GATE",
    "pass": True,
    "git_sha": dry.get("git_sha"),
    "inputs": {
        "tsk_p1_203_evidence": E203,
        "sandbox_deploy_dry_run": DRY
    },
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "measurement_truth": {
        "observed_facts": [
            {"path": E203, "assertions": ["task_id==TSK-P1-203", "pass==true"]},
            {"path": DRY,  "assertions": ["task_id==TSK-P1-203", "pass==true", "required_fields_present"]}
        ],
        "inferred": []
    }
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(gate, f, indent=2, sort_keys=True)
print("OK")
PY

echo "OK: wrote $OUT"
```

**Note:** this script intentionally does *minimal semantic checks* and defers strict schema validation to `validate_evidence_schema.sh`, as per your program rules.

---

# 4) Minimal Example Dry-Run Evidence (template)

## `evidence/phase1/sandbox_deploy_dry_run.json` (template you can copy)

```json
{
  "task_id": "TSK-P1-203",
  "git_sha": "REPLACE_WITH_GIT_SHA",
  "namespace": "sandbox",
  "images": {
    "ledger_api": "REPLACE_IMAGE",
    "executor_worker": "REPLACE_IMAGE",
    "migration_job": "REPLACE_IMAGE"
  },
  "migration_job_ran": true,
  "services_ready": {
    "ledger_api": true,
    "executor_worker": true
  },
  "timestamp_utc": "2026-02-27T00:00:00Z",
  "pass": true,
  "notes": "Populate with details of the dry-run deploy for this commit."
}
```

---

# 5) Wiring Schema Validation

You’ll need to ensure your schema validator includes the new schema and checks the two JSONs. Since repos differ, here’s the safe pattern:

### In `scripts/audit/validate_evidence_schema.sh`, add (conceptually):

* include `evidence/schemas/hardening/*.schema.json`
* validate:

  * `evidence/phase1/sandbox_deploy_dry_run.json` against the new schema
  * `evidence/phase1/program_a1_stability_gate.json` against your standard evidence schema (or create one if missing)

If you don’t have a standard schema for “program gate evidence”, tell me what you *do* have (file name/path) and I’ll align the output JSON to it. If you’d rather keep it self-validated, we can add a `program_gate.schema.json` too.

---

## What you now have

* A hard, enforceable “A1 stability” gate that doesn’t touch DAG edges.
* A strict schema preventing “random JSON evidence”.
* A program verifier emitting a single PASS/FAIL artifact.
* A repo-native task pack to track and review the work.

If you want the next layer: I can also generate a **companion verifier** `scripts/audit/verify_program_wave1_exit_gate.sh` that checks the Wave-1 exit evidence list (malformed, conflict, offline, effect-seal), using the same pattern.



















Below is the **companion program gate** for **Wave-1 exit** (malformed capture, conflicting truth containment, offline safe-mode, effect-seal mismatch). It mirrors the A1 Stability Gate pattern:

* **Verifier script:** `scripts/audit/verify_program_wave1_exit_gate.sh`
* **Canonical program evidence:** `evidence/phase1/program_wave1_exit_gate.json`
* **Canonical “inputs” evidence files (one per exit condition):**

  * `evidence/phase1/wave1_exit/malformed_response_capture.json`
  * `evidence/phase1/wave1_exit/conflicting_truth_containment.json`
  * `evidence/phase1/wave1_exit/offline_safe_mode_block.json`
  * `evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json`
* **Strict schema** for each input evidence file under: `evidence/schemas/hardening/wave1_exit/*`

This is **ready-to-copy**.

---

# 1) New Task Pack: TSK-OPS-WAVE1-EXIT-GATE

## `tasks/TSK-OPS-WAVE1-EXIT-GATE/meta.yml`

```yaml
id: TSK-OPS-WAVE1-EXIT-GATE
title: Program Wave-1 Exit Gate Verifier and Evidence Contracts
status: todo
priority: P0
severity: L3
owner: "Platform/SRE Team"
reviewers:
  - "QA"
  - "DB Invariants"
  - "Security"
phase: "Hardening"
wave: "Wave-1"
workstream: "Program Gates"
dependencies: []
blocked_by: []
repo_scope:
  paths_expected_create:
    - "tasks/TSK-OPS-WAVE1-EXIT-GATE/PLAN.md"
    - "tasks/TSK-OPS-WAVE1-EXIT-GATE/EXEC_LOG.md"
    - "tasks/TSK-OPS-WAVE1-EXIT-GATE/VERIFY.md"
    - "tasks/TSK-OPS-WAVE1-EXIT-GATE/EVIDENCE_CONTRACT.md"
    - "scripts/audit/verify_program_wave1_exit_gate.sh"
    - "evidence/schemas/hardening/wave1_exit/malformed_response_capture.schema.json"
    - "evidence/schemas/hardening/wave1_exit/conflicting_truth_containment.schema.json"
    - "evidence/schemas/hardening/wave1_exit/offline_safe_mode_block.schema.json"
    - "evidence/schemas/hardening/wave1_exit/effect_seal_mismatch_fail_closed.schema.json"
  paths_expected_modify:
    - "scripts/audit/validate_evidence_schema.sh"
    - "docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"
  paths_forbidden_touch:
    - "infra/**"
    - "k8s manifests (belongs to TSK-P1-203)"
objective: >
  Implement an enforceable program gate for Wave-1 exit that validates the four mandatory negative-path capabilities
  via schema-validated evidence inputs and emits a single PASS/FAIL program gate artifact.
acceptance_criteria:
  - "Verifier script exists at scripts/audit/verify_program_wave1_exit_gate.sh and exits 0 on success."
  - "All four Wave-1 exit input evidence schemas exist and are strict (additionalProperties=false)."
  - "validate_evidence_schema.sh validates the four input evidence files and the program gate evidence."
  - "Program gate evidence written to evidence/phase1/program_wave1_exit_gate.json with pass=true when all inputs pass."
  - "EXEC_LOG includes Canonical-Reference line."
verification:
  commands:
    - "bash scripts/audit/verify_program_wave1_exit_gate.sh"
    - "scripts/audit/validate_evidence_schema.sh"
  evidence_artifacts:
    - "evidence/phase1/program_wave1_exit_gate.json"
risk_if_skipped: >
  Wave-1 completion becomes subjective; downstream waves proceed without proven containment under Zambia-real failure modes.
notes:
  - "This is a program gate; it does not replace per-task verifiers."
```

---

## `tasks/TSK-OPS-WAVE1-EXIT-GATE/PLAN.md`

```md
# TSK-OPS-WAVE1-EXIT-GATE PLAN

## Objective
Create a program-level verifier and strict evidence contracts that define Wave-1 completion as a deterministic check:

Wave-1 Exit requires evidence for:
1) Malformed rail response captured as evidence event (no generic 500-only behavior)
2) Conflicting-truth containment (bank YES vs MMO NO etc.)
3) Offline safe-mode execution block + replay trail
4) Effect-seal mismatch fail-closed with evidence

## Scope
### In Scope
- One strict schema per required Wave-1 exit proof
- Program verifier script that checks the four proofs exist and pass
- Emission of a single consolidated gate evidence artifact

### Out of Scope
- Implementing the runtime features themselves (those remain in their hardening tasks)
- Editing infra/ or deployment manifests

## Canonical Evidence Paths (inputs)
- evidence/phase1/wave1_exit/malformed_response_capture.json
- evidence/phase1/wave1_exit/conflicting_truth_containment.json
- evidence/phase1/wave1_exit/offline_safe_mode_block.json
- evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json

## Output Evidence Path (program gate)
- evidence/phase1/program_wave1_exit_gate.json

## Implementation Steps
1) Add strict schemas under evidence/schemas/hardening/wave1_exit/*.schema.json
2) Add verifier script scripts/audit/verify_program_wave1_exit_gate.sh
3) Wire schemas into scripts/audit/validate_evidence_schema.sh
4) Update docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md to reference the gate

## Verification
- bash scripts/audit/verify_program_wave1_exit_gate.sh
- scripts/audit/validate_evidence_schema.sh
```

---

## `tasks/TSK-OPS-WAVE1-EXIT-GATE/EXEC_LOG.md`

```md
# TSK-OPS-WAVE1-EXIT-GATE EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Start
- Date/Time:
- Executor:
- Branch:

## Work
- Actions:
- Commands run:
- Results:

## Final Outcome
- Status: PASS | PARTIAL | BLOCKED
- Summary:
```

---

## `tasks/TSK-OPS-WAVE1-EXIT-GATE/VERIFY.md`

````md
# TSK-OPS-WAVE1-EXIT-GATE VERIFY

## Commands
```bash
bash scripts/audit/verify_program_wave1_exit_gate.sh
scripts/audit/validate_evidence_schema.sh
````

## Expected

* verifier exits 0
* evidence/phase1/program_wave1_exit_gate.json exists with pass=true
* input evidence files exist and are schema-valid

````

---

## `tasks/TSK-OPS-WAVE1-EXIT-GATE/EVIDENCE_CONTRACT.md`
```md
# TSK-OPS-WAVE1-EXIT-GATE Evidence Contract

## Input Evidence (must exist and pass)

### 1) Malformed Response Capture
- path: evidence/phase1/wave1_exit/malformed_response_capture.json
- schema: evidence/schemas/hardening/wave1_exit/malformed_response_capture.schema.json

### 2) Conflicting Truth Containment
- path: evidence/phase1/wave1_exit/conflicting_truth_containment.json
- schema: evidence/schemas/hardening/wave1_exit/conflicting_truth_containment.schema.json

### 3) Offline Safe Mode Block
- path: evidence/phase1/wave1_exit/offline_safe_mode_block.json
- schema: evidence/schemas/hardening/wave1_exit/offline_safe_mode_block.schema.json

### 4) Effect Seal Mismatch Fail-Closed
- path: evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json
- schema: evidence/schemas/hardening/wave1_exit/effect_seal_mismatch_fail_closed.schema.json

## Output Evidence (program gate)
- path: evidence/phase1/program_wave1_exit_gate.json
- producer: scripts/audit/verify_program_wave1_exit_gate.sh
- semantics: pass=true only if all four input proofs have pass=true and required fields are present

## Failure Modes
- missing any input file => FAIL
- invalid JSON => FAIL
- schema invalid => FAIL (via validate_evidence_schema)
- pass!=true => FAIL
````

---

# 2) Strict Schemas for the Four Wave-1 Exit Proofs

These are intentionally **small** and **strict**. They force the team to provide the minimum facts needed to claim the capability is real.

## `evidence/schemas/hardening/wave1_exit/malformed_response_capture.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "wave1_exit_malformed_response_capture",
  "type": "object",
  "additionalProperties": false,
  "required": ["task_id", "pass", "git_sha", "scenario", "evidence_refs", "timestamp_utc"],
  "properties": {
    "task_id": { "type": "string" },
    "pass": { "type": "boolean" },
    "git_sha": { "type": "string", "minLength": 7 },
    "scenario": {
      "type": "object",
      "additionalProperties": false,
      "required": ["name", "rail", "response_kind", "truncation_policy"],
      "properties": {
        "name": { "type": "string" },
        "rail": { "type": "string" },
        "response_kind": { "type": "string", "enum": ["HTML", "BINARY", "GARBAGE", "OVERSIZED_STREAM", "INVALID_JSON"] },
        "truncation_policy": {
          "type": "object",
          "additionalProperties": false,
          "required": ["max_capture_bytes", "hashing_mode"],
          "properties": {
            "max_capture_bytes": { "type": "integer", "minimum": 1024, "maximum": 1048576 },
            "hashing_mode": { "type": "string", "enum": ["STREAMING", "TRUNCATED_PREFIX_ONLY"] }
          }
        }
      }
    },
    "evidence_refs": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "timestamp_utc": { "type": "string", "format": "date-time" },
    "notes": { "type": "string" }
  }
}
```

## `evidence/schemas/hardening/wave1_exit/conflicting_truth_containment.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "wave1_exit_conflicting_truth_containment",
  "type": "object",
  "additionalProperties": false,
  "required": ["task_id", "pass", "git_sha", "scenario", "containment_state", "evidence_refs", "timestamp_utc"],
  "properties": {
    "task_id": { "type": "string" },
    "pass": { "type": "boolean" },
    "git_sha": { "type": "string", "minLength": 7 },
    "scenario": {
      "type": "object",
      "additionalProperties": false,
      "required": ["name", "rail", "bank_signal", "mmo_signal"],
      "properties": {
        "name": { "type": "string" },
        "rail": { "type": "string" },
        "bank_signal": { "type": "string", "enum": ["YES", "NO", "SILENT", "MALFORMED"] },
        "mmo_signal": { "type": "string", "enum": ["YES", "NO", "SILENT", "MALFORMED"] }
      }
    },
    "containment_state": { "type": "string", "minLength": 1 },
    "evidence_refs": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "timestamp_utc": { "type": "string", "format": "date-time" },
    "notes": { "type": "string" }
  }
}
```

## `evidence/schemas/hardening/wave1_exit/offline_safe_mode_block.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "wave1_exit_offline_safe_mode_block",
  "type": "object",
  "additionalProperties": false,
  "required": ["task_id", "pass", "git_sha", "offline_window", "blocked_actions", "evidence_refs", "timestamp_utc"],
  "properties": {
    "task_id": { "type": "string" },
    "pass": { "type": "boolean" },
    "git_sha": { "type": "string", "minLength": 7 },
    "offline_window": {
      "type": "object",
      "additionalProperties": false,
      "required": ["started_at_utc", "ended_at_utc", "reason"],
      "properties": {
        "started_at_utc": { "type": "string", "format": "date-time" },
        "ended_at_utc": { "type": "string", "format": "date-time" },
        "reason": { "type": "string" }
      }
    },
    "blocked_actions": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["action", "fail_closed", "queued_for_replay"],
        "properties": {
          "action": { "type": "string" },
          "fail_closed": { "type": "boolean", "const": true },
          "queued_for_replay": { "type": "boolean" }
        }
      }
    },
    "evidence_refs": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "timestamp_utc": { "type": "string", "format": "date-time" },
    "notes": { "type": "string" }
  }
}
```

## `evidence/schemas/hardening/wave1_exit/effect_seal_mismatch_fail_closed.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "wave1_exit_effect_seal_mismatch_fail_closed",
  "type": "object",
  "additionalProperties": false,
  "required": ["task_id", "pass", "git_sha", "scenario", "fail_closed", "evidence_refs", "timestamp_utc"],
  "properties": {
    "task_id": { "type": "string" },
    "pass": { "type": "boolean" },
    "git_sha": { "type": "string", "minLength": 7 },
    "scenario": {
      "type": "object",
      "additionalProperties": false,
      "required": ["name", "seal_generation_point", "seal_check_point"],
      "properties": {
        "name": { "type": "string" },
        "seal_generation_point": { "type": "string" },
        "seal_check_point": { "type": "string" }
      }
    },
    "fail_closed": { "type": "boolean", "const": true },
    "evidence_refs": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "timestamp_utc": { "type": "string", "format": "date-time" },
    "notes": { "type": "string" }
  }
}
```

---

# 3) Program Verifier Script

## `scripts/audit/verify_program_wave1_exit_gate.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

CONTRACT="docs/PHASE1/phase1_contract.yml"

IN_MAL="evidence/phase1/wave1_exit/malformed_response_capture.json"
IN_CON="evidence/phase1/wave1_exit/conflicting_truth_containment.json"
IN_OFF="evidence/phase1/wave1_exit/offline_safe_mode_block.json"
IN_SEA="evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json"

OUT="evidence/phase1/program_wave1_exit_gate.json"

fail() { echo "WAVE1_EXIT_GATE_FAIL: $*" >&2; exit 1; }

test -f "$CONTRACT" || fail "MISSING_CONTRACT:$CONTRACT"
test -f "$IN_MAL" || fail "MISSING_EVIDENCE:$IN_MAL"
test -f "$IN_CON" || fail "MISSING_EVIDENCE:$IN_CON"
test -f "$IN_OFF" || fail "MISSING_EVIDENCE:$IN_OFF"
test -f "$IN_SEA" || fail "MISSING_EVIDENCE:$IN_SEA"

python3 - <<'PY'
import json, os, datetime

inputs = [
  "evidence/phase1/wave1_exit/malformed_response_capture.json",
  "evidence/phase1/wave1_exit/conflicting_truth_containment.json",
  "evidence/phase1/wave1_exit/offline_safe_mode_block.json",
  "evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json",
]
out = "evidence/phase1/program_wave1_exit_gate.json"

def load(p):
  with open(p,"r",encoding="utf-8") as f:
    return json.load(f)

def require(cond, msg):
  if not cond:
    raise AssertionError(msg)

loaded = [load(p) for p in inputs]

# Minimal semantic contract: each input must claim pass=true and carry a git_sha
git_shas = set()
for i,(p,d) in enumerate(zip(inputs, loaded), start=1):
  require(isinstance(d, dict), f"INPUT_NOT_OBJECT:{p}")
  require(d.get("pass") is True, f"INPUT_PASS_FALSE:{p}")
  sha = d.get("git_sha")
  require(isinstance(sha,str) and len(sha)>=7, f"INPUT_GIT_SHA_MISSING:{p}")
  git_shas.add(sha)

# Stronger rule: all inputs should normally refer to the same commit
# (if you intentionally allow cross-commit, remove this invariant)
require(len(git_shas) == 1, f"GIT_SHA_MISMATCH:{sorted(git_shas)}")
git_sha = next(iter(git_shas))

gate = {
  "task_id": "PROGRAM-WAVE1-EXIT-GATE",
  "pass": True,
  "git_sha": git_sha,
  "inputs": {
    "malformed_response_capture": inputs[0],
    "conflicting_truth_containment": inputs[1],
    "offline_safe_mode_block": inputs[2],
    "effect_seal_mismatch_fail_closed": inputs[3],
  },
  "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "measurement_truth": {
    "observed_facts": [
      {"path": inputs[0], "assertions": ["pass==true"]},
      {"path": inputs[1], "assertions": ["pass==true"]},
      {"path": inputs[2], "assertions": ["pass==true"]},
      {"path": inputs[3], "assertions": ["pass==true"]}
    ],
    "inferred": []
  }
}

os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out,"w",encoding="utf-8") as f:
  json.dump(gate, f, indent=2, sort_keys=True)
print("OK")
PY

echo "OK: wrote $OUT"
```

---

# 4) Input Evidence Templates (copy/paste)

Create these once, then your runtime hardening tasks regenerate them as they implement the behaviors.

## `evidence/phase1/wave1_exit/malformed_response_capture.json`

```json
{
  "task_id": "TSK-HARD-016",
  "pass": true,
  "git_sha": "REPLACE_WITH_GIT_SHA",
  "scenario": {
    "name": "malformed-html-404",
    "rail": "BANK_X",
    "response_kind": "HTML",
    "truncation_policy": {
      "max_capture_bytes": 8192,
      "hashing_mode": "TRUNCATED_PREFIX_ONLY"
    }
  },
  "evidence_refs": [
    "evidence/phase1/....json"
  ],
  "timestamp_utc": "2026-02-27T00:00:00Z",
  "notes": "Proof that malformed response is captured as evidence with hard truncation + streaming-safe hashing."
}
```

## `evidence/phase1/wave1_exit/conflicting_truth_containment.json`

```json
{
  "task_id": "TSK-HARD-015",
  "pass": true,
  "git_sha": "REPLACE_WITH_GIT_SHA",
  "scenario": {
    "name": "bank-yes-mmo-no",
    "rail": "MMO_Y",
    "bank_signal": "YES",
    "mmo_signal": "NO"
  },
  "containment_state": "FINALITY_CONFLICT",
  "evidence_refs": [
    "evidence/phase1/....json"
  ],
  "timestamp_utc": "2026-02-27T00:00:00Z",
  "notes": "Proof that contradictory truth triggers deterministic containment and does not finalize unsafely."
}
```

## `evidence/phase1/wave1_exit/offline_safe_mode_block.json`

```json
{
  "task_id": "TSK-HARD-094",
  "pass": true,
  "git_sha": "REPLACE_WITH_GIT_SHA",
  "offline_window": {
    "started_at_utc": "2026-02-27T00:00:00Z",
    "ended_at_utc": "2026-02-27T01:00:00Z",
    "reason": "simulated-network-outage"
  },
  "blocked_actions": [
    { "action": "execute_release_attempt", "fail_closed": true, "queued_for_replay": true }
  ],
  "evidence_refs": [
    "evidence/phase1/....json"
  ],
  "timestamp_utc": "2026-02-27T01:00:00Z",
  "notes": "Proof offline safe mode fail-closes execution and preserves replay trail."
}
```

## `evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json`

```json
{
  "task_id": "TSK-HARD-012",
  "pass": true,
  "git_sha": "REPLACE_WITH_GIT_SHA",
  "scenario": {
    "name": "seal-mismatch-blocks-execution",
    "seal_generation_point": "quorum_complete",
    "seal_check_point": "execution_insert"
  },
  "fail_closed": true,
  "evidence_refs": [
    "evidence/phase1/....json"
  ],
  "timestamp_utc": "2026-02-27T00:00:00Z",
  "notes": "Proof that effect_seal mismatch blocks execution and emits decision evidence."
}
```

---

# 5) Wiring `validate_evidence_schema.sh`

Minimum expectation:

* validate the 4 inputs against their schemas
* validate `evidence/phase1/program_wave1_exit_gate.json` against your standard evidence schema (or add one if missing)

If you don’t have a standard schema for program gate evidence, add:

`evidence/schemas/hardening/program_gate.schema.json` (similar to the A1 gate output) and validate against it.

---

## Why this is the correct enforcement shape

* It makes Wave-1 “done” **binary**, based on evidence, not narrative.
* It forces **the team to generate proof** for the four Zambia-critical failure modes.
* It prevents downstream waves from proceeding on “we think it works”.

If you want, I can also generate a **single combined input evidence file** (instead of 4) to reduce operational overhead — but the four-file model is stricter and makes ownership clear (each exit condition maps cleanly to a hardening task).
