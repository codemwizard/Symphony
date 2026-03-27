# TSK-P1-240 PLAN — Implement Verifier Integrity & Proof Enforcement Gate

Task: TSK-P1-240
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-239
failure_signature: PHASE1.GOVERNANCE.TSK-P1-240.PROOF_GRAPH_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Enforce provable task integrity, moving away from structural or semantic plausibility. After this task, you cannot pass verification by deploying fake contents into required boundaries.

Every task must form a **closed proof graph**:
`objective → work → acceptance → verification → evidence`

Every edge in that graph must be explicitly declared and statically checkable, linked by explicit ID references or direct file path overlaps. No task may pass if verification commands lack an explicit failure state, if evidence is not logically derived from system inspection, or if acceptance criteria are orphaned.

---

## Architectural Context

TSK-P1-239 enforced that tasks MUST declare Stop Conditions, Verifier limits, and explicit negative checks. TSK-P1-240 builds the **police system**. It explicitly drops heuristic "guessing" (length/keywords) in favor of Graph Validation, Failure-Based Verification Obligation, and Proof-Carrying Evidence constraints.

---

## Pre-conditions

- [x] TSK-P1-239 is status=completed and evidence passes validation.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_plan_semantic_alignment.py` | CREATE | Core enforcement engine validating the proof graph |
| `docs/operations/TASK_CREATION_PROCESS.md` | MODIFY | Add the Integrity & Proof gate |
| `scripts/audit/verify_tsk_p1_240.sh` | CREATE | Verifier for this task |
| `evidence/phase1/tsk_p1_240_semantic_alignment.json` | CREATE | Output artifact |
| `tasks/TSK-P1-240/meta.yml` | MODIFY | Update status to completed upon success |
| `docs/plans/phase1/TSK-P1-240/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals are detected without hard failing** -> STOP

---

## Implementation Steps

### Step 1: Write `verify_plan_semantic_alignment.py`
**What:** Build the enforcement-grade proof graph scanner.
**How:**
1. **Graph Builder:** Parse `objective`, `work`, `acceptance_criteria`, `verification`, `evidence`. Build dependency mappings via text overlap and explicit references.
2. **Orphan Detector:** Assert `NO_ORPHANS == true` and `GRAPH_CONNECTED == true`. Fail loudly if disconnected.
3. **Verifier Analyzer:** Reject no-op commands (`exit 0`, `echo PASS`) and require external state dependencies (DB, file, command output). Reject self-referential greps.
4. **Failure Inference (Lightweight):** Ensure verification commands have both positive and negative structural domains such that symbolical missing artifacts cause `FAIL` (does not execute or mutate real files).
5. **Evidence Validator:** Evidence JSONs must feature `observed_paths`, `observed_hashes`, `command_outputs`, and `execution_trace`. Reject static payloads. Verification commands must explicitly link their actions to generating these outputs.
6. **Drift-Density Escalation:** Track weak signals (vague stop conditions, weak greps, shallow mappings). `< 3` emit WARNING, `>= 3` emit FAIL.
**Done when:** The script enforces all static graph constraints without relying on string length or basic keyword heuristics.

### Step 2: Implement Positive/Negative Test Suite (`verify_tsk_p1_240.sh`)
**What:** Write N1-N5 and P1.
**How:**
Feed dummy plans and verification scripts into `verify_plan_semantic_alignment.py`:
- `N1`: Feed an `exit 0` verifier. Expect explicit reject.
- `N2`: Feed an orphan acceptance line. Expect reject.
- `N3`: Feed evidence written as a static JSON string. Expect reject.
- `N4`: Feed a verifier that passes even when a target source file is missing in symbolic evaluation. Expect reject.
- `N5`: Feed a verifier that only checks the contents of its own PLAN.md. Expect reject.
- `P1`: Feed a perfectly mapped task pack. Expect pass.
**Done when:** N1-N5 explicitly fail for the specified reasons; P1 passes.

### Step 3: Integrate into `TASK_CREATION_PROCESS.md`
**What:** Update the sequence in docs.
**How:** Add "Step 3c — Verify proof graph integrity" calling `python3 scripts/audit/verify_plan_semantic_alignment.py --plan <PLAN_MD> --meta <META_YML>`, marking it explicitly as a hard-stop gate.
**Done when:** The gate is permanently installed in the sequence diagram / numbered list.

### Step 4: Emit evidence
**What:** Run verifier and check evidence schema to generate the Phase 1 trace.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_240.sh
python3 scripts/audit/validate_evidence.py \
  --task TSK-P1-240 \
  --evidence evidence/phase1/tsk_p1_240_semantic_alignment.json
```
**Done when:** Commands exit 0 and evidence format complies.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p1_240.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py \
  --task TSK-P1-240 \
  --evidence evidence/phase1/tsk_p1_240_semantic_alignment.json

# 3. Full local parity check
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_240_semantic_alignment.json`

Required fields:
- `task_id`: "TSK-P1-240"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects
- `graph_validation_enabled`: true
- `cheat_patterns_blocked`: ["N1", "N2", "N3", "N4", "N5"]

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Simulating missing artifacts risks being misunderstood as runtime mutation | UNPREDICTABLE | Do simulations purely against AST semantics (symbolic execution only) or in an explicit `--dry-run` branch context |
| Evidence standards block UI/Doc-only tasks | FALSE POSITIVES | Force Evidence Verifier to accept file hashes standard for doc-only touches |
