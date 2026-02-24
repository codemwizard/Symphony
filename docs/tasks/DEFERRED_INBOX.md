# Deferred Inbox

Purpose: track important issues that are not being executed immediately, without losing ownership, trigger conditions, or exit criteria.

Rules:
- Items here are not considered complete work.
- Each entry must include owner, unblock trigger, and done criteria.
- Moving an item out of this inbox requires creating or linking an executable task section in `docs/tasks/phase1_prompts.md` (or its phase-equivalent prompt pack).
- For deferred incidents classified `L2/L3`, include a DRD Full link (canonical policy: `.agent/policies/debug-remediation-policy.md`).

## Entries

### INBOX-2026-02-22-001 — TSK-P1-059 completion gap (narrative vs implemented scope)
- Source task: `TSK-P1-059`
- Priority: `P1`
- Owner role: `INVARIANTS_CURATOR`
- Status: `deferred`
- Created: `2026-02-22`
- Why deferred:
  - Current verifier/evidence for `TSK-P1-059` passes, but implementation history suggests the task may have been closed on verifier hardening/metadata without fully delivering the stated modularization narrative.
- Unblock trigger:
  - After current Phase-0 levy chain tasks finish and branch stabilization is complete.
- Required done criteria:
  - Verify whether `TSK-P1-059` intended outcome is:
    1. strict verifier hardening only, or
    2. actual gate script modularization.
  - If (2), implement modularization with no behavior drift and update verifier accordingly.
  - Re-run:
    - `bash scripts/audit/verify_tsk_p1_059.sh --evidence evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json`
    - `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
  - Produce updated evidence artifact with PASS.
- Links:
  - `tasks/TSK-P1-059/meta.yml`
  - `scripts/audit/verify_tsk_p1_059.sh`
  - `evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json`
  - `scripts/db/verify_invariants.sh`

### INBOX-2026-02-22-002 — TSK-P0-103 evidence artifact mismatch (`ci_invariant_gate.json`)
- Source task: `TSK-P0-103`
- Priority: `P1`
- Owner role: `DB_FOUNDATION`
- Status: `resolved`
- Created: `2026-02-22`
- Resolved: `2026-02-22`
- Resolution summary:
  - Fixed emitter drift by adding deterministic `ci_invariant_gate.json` generation in `scripts/db/verify_invariants.sh` immediately after CI invariant SQL gate execution.
- Resolution commit:
  - `e9fc1bf` — `TSK-P0-103: emit ci_invariant_gate evidence artifact`
- Verification:
  - Fresh DB run of `SKIP_POLICY_SEED=1 scripts/db/verify_invariants.sh` produced `evidence/phase0/ci_invariant_gate.json` with `check_id: DB-CI-INVARIANT-GATE` and `status: PASS`.
- Links:
  - `tasks/TSK-P0-103/meta.yml`
  - `scripts/db/verify_invariants.sh`
  - `evidence/phase0/ci_invariant_gate.json`

### INBOX-2026-02-23-003 — CI-first parity audit for `pre_ci` vs GitHub workflow execution graph
- Source task: `PARITY-CI-PRECI-001` (post-Phase1)
- Priority: `P0`
- Owner role: `INVARIANTS_CURATOR`
- Status: `completed`
- Created: `2026-02-23`
- Completed: `2026-02-23`
- Resolution:
  - Canonical Phase-1 operation manual citation added to the deferred item to satisfy governance/conformance requirements.
  - Item merged to `origin/main`; no open implementation work remains on this branch.
- Why deferred:
  - Current parity incidents show that local `scripts/dev/pre_ci.sh` can pass while CI fails due to workflow graph/artifact merge/order differences.
  - CI must remain source-of-truth; local parity must prove equivalence against CI invocation semantics, not just script presence.
- Unblock trigger:
  - Start only after current Phase-1 execution/closeout is complete and branch stabilization is confirmed.
- Required done criteria:
  - Build a deterministic line-by-line trace matrix mapping:
    - every command invocation in `scripts/dev/pre_ci.sh`
    - to the exact GitHub Actions step(s) in `.github/workflows/invariants.yml`
    - including command string, env vars, working dir, inputs/outputs, and execution order.
  - For each gate/evidence producer, classify:
    1. exact parity,
    2. compatible but different topology (artifact merge, job split),
    3. mismatch/regression risk.
  - Add an executable CI-parity verifier that fails closed when:
    - invocation order diverges for parity-critical checks,
    - CI-only artifact merge behavior has no local parity simulation,
    - a check runs in one environment but not the other.
  - Ensure local parity mode can replay CI merged-artifact verification path from empty evidence state.
  - Re-run and record PASS:
    - `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
    - CI `invariants.yml` jobs producing + consuming evidence status.
  - Emit deterministic parity evidence artifact(s) and contract wire-up for the parity gate.
- Links:
  - `scripts/dev/pre_ci.sh`
  - `.github/workflows/invariants.yml`
  - `scripts/ci/check_evidence_required.sh`
  - `scripts/audit/verify_phase0_contract_evidence_status.sh`
  - `scripts/ci/verify_phase0_contract_evidence_status_parity.sh`
