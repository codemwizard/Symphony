# Deferred Inbox

Purpose: track important issues that are not being executed immediately, without losing ownership, trigger conditions, or exit criteria.

Rules:
- Items here are not considered complete work.
- Each entry must include owner, unblock trigger, and done criteria.
- Moving an item out of this inbox requires creating or linking an executable task section in `docs/tasks/phase1_prompts.md` (or its phase-equivalent prompt pack).
- For deferred incidents classified `L2/L3`, include a DRD Full link (canonical policy: `.agent/policies/debug-remediation-policy.md`).

## Entries

### INBOX-2026-03-26-001 — [RESOLVED via TSK-P1-242] Runtime host-path and ownership decision bound to existing SECURITY_GUARDIAN surface scripts/audit/**
- Source task:
  - `TSK-P1-241`
- Priority: `P1`
- Owner role: `ARCHITECT`
- Status: `deferred`
- Created: `2026-03-26`
- Classification: `L1`
- Why deferred:
  - The runtime-integrity sandbox line was decomposed into narrower repo-local work because the original bundle was too broad for the anti-drift task discipline.
  - `scripts/runtime/**` is not an existing owned path in `AGENTS.md`, so the guarded execution controls cannot be scheduled honestly by assuming that host location.
  - The host-path and ownership decision must be revisited through the child-task graph created under `TSK-P1-241`, not settled ad hoc during implementation.
- Unblock trigger:
  - Start after the TSK-P1-241 parent task pack is ready and the first child-task graph is registered repo-locally.
- Required done criteria:
  - Create an executable child task that resolves the canonical host path for the guarded runtime controls.
  - Name the owning agent surface for that path or explicitly rehost the implementation in an already-owned surface.
  - Confirm the host-path decision is reflected in the child-task `touches`, plan, verification, and evidence contract.
  - Ensure no runtime implementation task starts before that authority decision is represented by an executable repo-local task.
- Resolution path:
  - `TSK-P1-242`
- Links:
  - `tasks/TSK-P1-241/meta.yml`
  - `docs/plans/phase1/TSK-P1-241/PLAN.md`
  - `tasks/TSK-P1-242/meta.yml`
  - `docs/plans/phase1/TSK-P1-242/PLAN.md`
  - `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
  - `AGENTS.md`

### INBOX-2026-03-10-006 — CI-discovered fixes can land without remediation artifact freshness
- Source incident:
  - `phase1/debug-process-069-072`
  - `docs/process/DEBUG_PROCESS_MATERIAL_GAIN_ANALYSIS_2026-03-10.md`
- Priority: `P1`
- Owner role: `INVARIANTS_CURATOR`
- Status: `resolved`
- Created: `2026-03-10`
- Classification: `L1`
- Why deferred:
  - The recent CI import-path failure on `phase1/debug-process-069-072` required a real branch fix, but the remediation/task artifacts were not automatically forced to update in the same change.
  - This proves the current debug-process hardening remains incomplete: it improves triage and escalation, but it does not yet fail closed when a post-CI fix is made without refreshing the relevant remediation trace or task execution log.
  - As a result, an agent can still repair a CI-only bug while leaving remediation history stale unless it remembers to update it manually.
- Resolution:
  - Implemented by `TSK-P1-073`.
- Required done criteria:
  - Create and execute a task that enforces remediation/task artifact freshness after CI-discovered fixes.
  - Detect when a branch changes after a failing CI incident and require at least one of:
    - remediation casefile update,
    - task `EXEC_LOG.md` update,
    - or another approved remediation trace artifact update.
  - Add a verifier that fails when code or verifier logic changes after a CI incident but no remediation/task log changed with it.
  - Ensure the verifier works for both normal task casefiles and `REM-*` remediation casefiles.
  - Emit evidence proving the freshness rule is enforced.
- Links:
  - `docs/process/debug-remediation-policy.md`
  - `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
  - `docs/process/DEBUG_PROCESS_MATERIAL_GAIN_ANALYSIS_2026-03-10.md`
  - `tasks/TSK-P1-069/meta.yml`
  - `tasks/TSK-P1-070/meta.yml`
  - `tasks/TSK-P1-071/meta.yml`
  - `tasks/TSK-P1-072/meta.yml`

### INBOX-2026-03-10-005 — DRD declaration exists in PR template but is not mechanically enforced
- Source incident:
  - `.github/pull_request_template.md`
  - `docs/process/debug-remediation-policy.md`
  - `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- Priority: `P1`
- Owner role: `INVARIANTS_CURATOR`
- Status: `deferred`
- Created: `2026-03-10`
- Classification: `L1`
- Why deferred:
  - The PR template includes a `DRD Declaration` section, but it is still manual-only.
  - Current branch workflow allows remediation/DRD policy to be satisfied in casefiles and evidence while the PR body remains blank.
  - There is no mechanical linkage today from remediation metadata, approval metadata, or `pre_ci` debug state into the PR declaration fields.
  - This creates a process-truth gap: the PR surface can imply DRD discipline without actually proving severity classification or DRD linkage.
- Unblock trigger:
  - Start after the current debug-process hardening branch is merged and the branch/push path is stable again.
- Required done criteria:
  - Create an executable task for PR/DRD enforcement.
  - Define the canonical mapping from remediation/debug metadata to PR declaration fields:
    - severity,
    - DRD required or not required,
    - Lite link,
    - Full link.
  - Add a verifier or CI gate that fails when:
    - DRD is required by policy but the PR declaration is blank,
    - a DRD link is required but missing,
    - the PR declaration contradicts remediation casefile metadata.
  - Prefer machine-populating the PR declaration or emitting a deterministic PR compliance summary instead of relying on manual checkboxes alone.
  - Update the PR template to reference the mechanical verifier explicitly.
  - Emit evidence showing that the PR DRD declaration is truthful and policy-aligned.
- Links:
  - `.github/pull_request_template.md`
  - `docs/process/debug-remediation-policy.md`
  - `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
  - `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
  - `docs/process/DEBUG_PROCESS_MATERIAL_GAIN_ANALYSIS_2026-03-10.md`

### INBOX-2026-03-10-004 — Debug/remediation process is too easy to bypass during local gate failures
- Source incident:
  - `docs/audits/FORENSIC_REPORT_DIFF_PARITY_FIXTURE_2026-03-09.md`
  - `docs/process/DEBUG_PROCESS_MATERIAL_GAIN_ANALYSIS_2026-03-10.md`
- Priority: `P1`
- Owner role: `SUPERVISOR`
- Status: `deferred`
- Created: `2026-03-10`
- Classification: `L2`
- DRD Full:
  - `docs/audits/FORENSIC_REPORT_DIFF_PARITY_FIXTURE_2026-03-09.md`
- Why deferred:
  - Recent push/debug failures showed the current remediation process is documented but still too easy to ignore during repeated local `pre_ci` and pre-push failures.
  - The concrete failure sequence mixed four distinct failure classes:
    1. unsafe `origin/main` parity fetch handling,
    2. mutable Git fixture containment escape,
    3. concurrent toolchain bootstrap contention across worktrees,
    4. expired exception-state records blocking unrelated branches.
  - The process exists, but the repo does not yet force fail-first triage, failure-layer classification, remediation scaffolding, or two-strike escalation strongly enough to stop retry thrash.
- Unblock trigger:
  - Start after the currently rebased branch push backlog is cleared and local branch transport returns to stable behavior.
- Required done criteria:
  - Implement executable tasks:
    - `TSK-P1-069`
    - `TSK-P1-070`
    - `TSK-P1-071`
    - `TSK-P1-072`
  - Add a mechanical fail-first triage banner to `pre_ci` / push-path failures.
  - Add a remediation casefile scaffolder that is faster than ad hoc manual setup.
  - Add failure-layer taxonomy output so agents can distinguish branch-content failures from shared local/environment failures.
  - Add two-strike non-convergence escalation so repeated local reruns force remediation discipline.
  - Re-run local gate flow and confirm the new process surfaces on failure before repeated retries.
- Links:
  - `docs/process/debug-remediation-policy.md`
  - `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
  - `docs/process/DEBUG_PROCESS_MATERIAL_GAIN_ANALYSIS_2026-03-10.md`
  - `docs/audits/FORENSIC_REPORT_DIFF_PARITY_FIXTURE_2026-03-09.md`
  - `docs/tasks/phase1_prompts.md`
  - `tasks/TSK-P1-069/meta.yml`
  - `tasks/TSK-P1-070/meta.yml`
  - `tasks/TSK-P1-071/meta.yml`
  - `tasks/TSK-P1-072/meta.yml`

### INBOX-2026-03-10-007 — Local hook topology is inconsistent and the two-level gate model is not explicitly enforced
- Source incident:
  - `.githooks/pre-push`
  - `scripts/dev/install_git_hooks.sh`
  - `scripts/dev/pre_ci.sh`
- Priority: `P1`
- Owner role: `SUPERVISOR`
- Status: `resolved`
- Created: `2026-03-10`
- Classification: `L1`
- Why deferred:
  - Local guarded execution is correct in principle, but the current hook topology is too implicit and too easy to misread.
  - Active execution currently comes from tracked `.githooks/*`, while the installer writes to `.git/hooks`, creating topology ambiguity.
  - The intended local gate model is also under-specified: a lighter `pre_flight` should run just after commit, while the heavier `pre_ci` should remain the push-time parity gate.
  - This should be fixed deliberately, not opportunistically while the local working-tree and bootstrap behavior are still being stabilized.
- Unblock trigger:
  - Start after current branch/process stabilization work is merged and the repo is back to a clean, low-drift local state.
- Resolution:
  - Implemented by `TSK-P1-074`, `TSK-P1-075`, and `TSK-P1-076`.
- Required done criteria:
  - Implement executable tasks:
    - `TSK-P1-074`
    - `TSK-P1-075`
    - `TSK-P1-076`
  - Normalize the local hook installation/source model so tracked hook templates and active installed hooks are unambiguous.
  - Make the light `pre_flight` gate and heavy push-time `pre_ci` gate explicit in both docs and scripts.
  - Add a verifier that fails if installed local hooks diverge from the documented two-level gate topology.
  - Emit evidence proving the normalized hook topology and gate split are active.
- Links:
  - `docs/process/DEBUG_PROCESS_MATERIAL_GAIN_ANALYSIS_2026-03-10.md`
  - `.githooks/pre-push`
  - `scripts/dev/install_git_hooks.sh`
  - `scripts/dev/pre_ci.sh`
  - `tasks/TSK-P1-074/meta.yml`
  - `tasks/TSK-P1-075/meta.yml`
  - `tasks/TSK-P1-076/meta.yml`

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
