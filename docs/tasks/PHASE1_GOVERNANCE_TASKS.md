# Phase-1 Governance Tasks (Execution-Ready)

This index tracks governance rewrite tasks derived from `Symphony_Governance_Implementation_Plan.docx`.

| Task ID | Owner Role | Status | Plan | Log |
|---|---|---|---|---|
| TSK-P1-241 | SUPERVISOR | completed | docs/plans/phase1/TSK-P1-241/PLAN.md | docs/plans/phase1/TSK-P1-241/EXEC_LOG.md |
| TSK-P1-242 | SUPERVISOR | planned | docs/plans/phase1/TSK-P1-242/PLAN.md | docs/plans/phase1/TSK-P1-242/EXEC_LOG.md |
| TSK-P1-243 | SECURITY_GUARDIAN | planned | docs/plans/phase1/TSK-P1-243/PLAN.md | docs/plans/phase1/TSK-P1-243/EXEC_LOG.md |
| TSK-P1-244 | SECURITY_GUARDIAN | planned | docs/plans/phase1/TSK-P1-244/PLAN.md | docs/plans/phase1/TSK-P1-244/EXEC_LOG.md |
| TSK-P1-245 | SECURITY_GUARDIAN | planned | docs/plans/phase1/TSK-P1-245/PLAN.md | docs/plans/phase1/TSK-P1-245/EXEC_LOG.md |
| TSK-P1-246 | QA_VERIFIER | planned | docs/plans/phase1/TSK-P1-246/PLAN.md | docs/plans/phase1/TSK-P1-246/EXEC_LOG.md |
| TSK-P1-248 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TSK-P1-248/PLAN.md | docs/plans/phase1/TSK-P1-248/EXEC_LOG.md |
| TSK-P1-249 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TSK-P1-249/PLAN.md | docs/plans/phase1/TSK-P1-249/EXEC_LOG.md |
| TSK-P1-250 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TSK-P1-250/PLAN.md | docs/plans/phase1/TSK-P1-250/EXEC_LOG.md |
| TSK-P1-251 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TSK-P1-251/PLAN.md | docs/plans/phase1/TSK-P1-251/EXEC_LOG.md |
| TSK-P1-252 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TSK-P1-252/PLAN.md | docs/plans/phase1/TSK-P1-252/EXEC_LOG.md |
| TSK-P1-253 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TSK-P1-253/PLAN.md | docs/plans/phase1/TSK-P1-253/EXEC_LOG.md |
| TSK-P1-254 | QA_VERIFIER | completed | docs/plans/phase1/TSK-P1-254/PLAN.md | docs/plans/phase1/TSK-P1-254/EXEC_LOG.md |
| TSK-P1-255 | QA_VERIFIER | in_progress | docs/plans/phase1/TSK-P1-255/PLAN.md | docs/plans/phase1/TSK-P1-255/EXEC_LOG.md |

## Evidence Push Fixed-Point Recovery

- DRD Full casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Execution order: `TSK-P1-250` + `TSK-P1-251` + `TSK-P1-252` -> `TSK-P1-253` -> `TSK-P1-254` -> `TSK-P1-255`
- Wave intent: restore a true pre-push fixed point so `bash scripts/dev/pre_ci.sh` leaves the tracked tree clean after a commit.

## Runtime Integrity Wave Assignment

- Wave branch: `security/wave-1-runtime-integrity-children`
- Approval package: `approvals/2026-03-26/BRANCH-security-wave-1-runtime-integrity-children.md`
- Parent excluded from implementation wave: `TSK-P1-241` is the completed scheduling task and is not part of the execution batch.
- Serial execution order: `TSK-P1-242` -> `TSK-P1-243` -> `TSK-P1-244` + `TSK-P1-245` -> `TSK-P1-246`
- Assigned agents:
  - `TSK-P1-242` -> `supervisor`
  - `TSK-P1-243` -> `security_guardian`
  - `TSK-P1-244` -> `security_guardian`
  - `TSK-P1-245` -> `security_guardian`
  - `TSK-P1-246` -> `qa_verifier`
- Immediate starter: `TSK-P1-242` is the first startable child because it depends only on the completed parent task.
- Wave verification rule: run `bash scripts/dev/pre_ci.sh` once after the full child-task wave is implemented; do not run `pre_ci.sh` as a per-task closeout command inside this batch.
| TASK-GOV-C1 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-C1/PLAN.md | docs/plans/phase1/TASK-GOV-C1/EXEC_LOG.md |
| TASK-GOV-C2C3 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-C2C3/PLAN.md | docs/plans/phase1/TASK-GOV-C2C3/EXEC_LOG.md |
| TASK-GOV-C4O4 | QA_VERIFIER | completed | docs/plans/phase1/TASK-GOV-C4O4/PLAN.md | docs/plans/phase1/TASK-GOV-C4O4/EXEC_LOG.md |
| TASK-GOV-C5 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-GOV-C5/PLAN.md | docs/plans/phase1/TASK-GOV-C5/EXEC_LOG.md |
| TASK-GOV-C6 | INVARIANTS_CURATOR | completed | docs/plans/phase1/TASK-GOV-C6/PLAN.md | docs/plans/phase1/TASK-GOV-C6/EXEC_LOG.md |
| TASK-GOV-C7 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-C7/PLAN.md | docs/plans/phase1/TASK-GOV-C7/EXEC_LOG.md |
| TASK-GOV-O1 | QA_VERIFIER | completed | docs/plans/phase1/TASK-GOV-O1/PLAN.md | docs/plans/phase1/TASK-GOV-O1/EXEC_LOG.md |
| TASK-GOV-O2 | QA_VERIFIER | completed | docs/plans/phase1/TASK-GOV-O2/PLAN.md | docs/plans/phase1/TASK-GOV-O2/EXEC_LOG.md |
| TASK-GOV-O3 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-O3/PLAN.md | docs/plans/phase1/TASK-GOV-O3/EXEC_LOG.md |
| TASK-GOV-AWC3 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-AWC3/PLAN.md | docs/plans/phase1/TASK-GOV-AWC3/EXEC_LOG.md |
| TASK-GOV-AWC4 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-AWC4/PLAN.md | docs/plans/phase1/TASK-GOV-AWC4/EXEC_LOG.md |
| TASK-GOV-AWC5 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-AWC5/PLAN.md | docs/plans/phase1/TASK-GOV-AWC5/EXEC_LOG.md |
| TASK-GOV-AWC6 | ARCHITECT | completed | docs/plans/phase1/TASK-GOV-AWC6/PLAN.md | docs/plans/phase1/TASK-GOV-AWC6/EXEC_LOG.md |
| TASK-GOV-AWC7 | QA_VERIFIER | completed | docs/plans/phase1/TASK-GOV-AWC7/PLAN.md | docs/plans/phase1/TASK-GOV-AWC7/EXEC_LOG.md |
| TASK-INV-134 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-INV-134/PLAN.md | docs/plans/phase1/TASK-INV-134/EXEC_LOG.md |
| TASK-OI-01 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-OI-01/PLAN.md | docs/plans/phase1/TASK-OI-01/EXEC_LOG.md |
| TASK-OI-02 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-OI-02/PLAN.md | docs/plans/phase1/TASK-OI-02/EXEC_LOG.md |
| TASK-OI-03 | QA_VERIFIER | completed | docs/plans/phase1/TASK-OI-03/PLAN.md | docs/plans/phase1/TASK-OI-03/EXEC_LOG.md |
| TASK-OI-04 | QA_VERIFIER | completed | docs/plans/phase1/TASK-OI-04/PLAN.md | docs/plans/phase1/TASK-OI-04/EXEC_LOG.md |
| TASK-OI-05 | QA_VERIFIER | completed | docs/plans/phase1/TASK-OI-05/PLAN.md | docs/plans/phase1/TASK-OI-05/EXEC_LOG.md |
| TASK-OI-06 | QA_VERIFIER | completed | docs/plans/phase1/TASK-OI-06/PLAN.md | docs/plans/phase1/TASK-OI-06/EXEC_LOG.md |
| TASK-OI-07 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-OI-07/PLAN.md | docs/plans/phase1/TASK-OI-07/EXEC_LOG.md |
| TASK-OI-08 | ARCHITECT | completed | docs/plans/phase1/TASK-OI-08/PLAN.md | docs/plans/phase1/TASK-OI-08/EXEC_LOG.md |
| TASK-OI-09 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-OI-09/PLAN.md | docs/plans/phase1/TASK-OI-09/EXEC_LOG.md |
| TASK-OI-10 | ARCHITECT | completed | docs/plans/phase1/TASK-OI-10/PLAN.md | docs/plans/phase1/TASK-OI-10/EXEC_LOG.md |
| TASK-OI-11 | QA_VERIFIER | completed | docs/plans/phase1/TASK-OI-11/PLAN.md | docs/plans/phase1/TASK-OI-11/EXEC_LOG.md |
| TASK-INVPROC-01 | ARCHITECT | completed | docs/plans/phase1/TASK-INVPROC-01/PLAN.md | docs/plans/phase1/TASK-INVPROC-01/EXEC_LOG.md |
| TASK-INVPROC-02 | INVARIANTS_CURATOR | completed | docs/plans/phase1/TASK-INVPROC-02/PLAN.md | docs/plans/phase1/TASK-INVPROC-02/EXEC_LOG.md |
| TASK-INVPROC-03 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-INVPROC-03/PLAN.md | docs/plans/phase1/TASK-INVPROC-03/EXEC_LOG.md |
| TASK-INVPROC-04 | INVARIANTS_CURATOR | completed | docs/plans/phase1/TASK-INVPROC-04/PLAN.md | docs/plans/phase1/TASK-INVPROC-04/EXEC_LOG.md |
| TASK-INVPROC-05 | QA_VERIFIER | completed | docs/plans/phase1/TASK-INVPROC-05/PLAN.md | docs/plans/phase1/TASK-INVPROC-05/EXEC_LOG.md |
| TASK-INVPROC-06 | SECURITY_GUARDIAN | completed | docs/plans/phase1/TASK-INVPROC-06/PLAN.md | docs/plans/phase1/TASK-INVPROC-06/EXEC_LOG.md |
| ENF-000 | ARCHITECT | completed | docs/plans/phase1/ENF-000/PLAN.md | docs/plans/phase1/ENF-000/EXEC_LOG.md |
| ENF-001 | ARCHITECT | completed | docs/plans/phase1/ENF-001/PLAN.md | docs/plans/phase1/ENF-001/EXEC_LOG.md |
| ENF-002 | SECURITY_GUARDIAN | completed | docs/plans/phase1/ENF-002/PLAN.md | docs/plans/phase1/ENF-002/EXEC_LOG.md |
| ENF-003A | ARCHITECT | completed | docs/plans/phase1/ENF-003A/PLAN.md | docs/plans/phase1/ENF-003A/EXEC_LOG.md |
| ENF-003B | SECURITY_GUARDIAN | completed | docs/plans/phase1/ENF-003B/PLAN.md | docs/plans/phase1/ENF-003B/EXEC_LOG.md |
| ENF-004 | ARCHITECT | completed | docs/plans/phase1/ENF-004/PLAN.md | docs/plans/phase1/ENF-004/EXEC_LOG.md |

## Symphony Enforcement v2 Wave Assignment

- Source staging directory: `symphony-enforcement-v2/`
- Umbrella plan: `docs/plans/phase1/ENF-ENFORCEMENT-V2/PLAN.md`
- Serial-safe execution order: ENF-000 → ENF-001 → ENF-002 → ENF-003A → ENF-003B → ENF-004
- ENF-003 from MANIFEST is split: ENF-003A (ARCHITECT, scripts/agent/**) and ENF-003B (SECURITY_GUARDIAN, scripts/audit/**)
- Governance file approvals required before: ENF-001 and ENF-003A (both touch scripts/agent/run_task.sh)
- ENF-003A and ENF-003B can be implemented in parallel after ENF-001 is done
- ENF-004 must be last (references outputs of ENF-002 and ENF-003A)
| ENF-005 | SECURITY_GUARDIAN | completed | docs/plans/phase1/ENF-005/PLAN.md | docs/plans/phase1/ENF-005/EXEC_LOG.md |

### ENF-005 notes
- Depends on ENF-002 (verify_drd_casefile.sh must be installed first)
- Human sysadmin prerequisite: sudoers entry for agent OS user — see docs/plans/phase1/ENF-005/EXEC_LOG.md
- Can be applied after ENF-002; does not block ENF-003A, ENF-003B, or ENF-004

## Demo Deployment Runbook Hardening Pack

### TSK-P1-DEMO-018 — Create the operator-grade host-based E2E demo runbook ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-017`
- **Touches:** `docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md`, `scripts/audit/verify_tsk_p1_demo_018.sh`, `evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** create the primary host-based runbook, define clean deployment checkout rules, split API vs browser smoke, and make step-level pass/fail/evidence explicit
- **Acceptance Criteria:** runbook is operator-executable, smoke ownership is clear, teardown and rotation closeout are explicit, Kubernetes is secondary
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_018.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-018 --evidence evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`
- **Failure Modes:** branch-name theater remains; API/browser smoke still mixed; task/run evidence conflated; evidence file missing

### TSK-P1-DEMO-019 — Add hardened reproducible demo server snapshot capture ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-018`
- **Touches:** `scripts/dev/capture_demo_server_snapshot.sh`, `scripts/audit/verify_tsk_p1_demo_019.sh`, `evidence/phase1/tsk_p1_demo_019_server_snapshot.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** create the server snapshot script with root-bounded output handling, safe permissions, process/network/resource capture, and HMAC-based env fingerprinting
- **Acceptance Criteria:** snapshot bundle is reproducible, safe, root-bounded, and sufficient for debugging
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_019.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-019 --evidence evidence/phase1/tsk_p1_demo_019_server_snapshot.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_019_server_snapshot.json`
- **Failure Modes:** insufficient debug state; permissive outputs; ambiguous compose detection; evidence file missing

### TSK-P1-DEMO-020 — Add fail-closed host-based demo runner with explicit process control ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-018`, `TSK-P1-DEMO-019`, `TSK-P1-DEMO-021`
- **Touches:** `scripts/dev/run_demo_e2e.sh`, `scripts/audit/verify_tsk_p1_demo_020.sh`, `evidence/phase1/tsk_p1_demo_020_demo_runner.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** create the fail-closed runner with fresh-fetch source gating, explicit process supervision, single-active-run default, structured summary, and machine-readable browser smoke artifact
- **Acceptance Criteria:** runner is deterministic, fail-closed, and separates server-side API smoke from Dell browser smoke
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_020.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-020 --evidence evidence/phase1/tsk_p1_demo_020_demo_runner.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_020_demo_runner.json`
- **Failure Modes:** stale remote state accepted; process handling ad hoc; smoke checks mixed; evidence file missing

### TSK-P1-DEMO-021 — ~~Define executable demo key OpenBao TLS and rotation policy~~ RETIRED (superseded by TSK-P1-215/216)
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-018`
- **Touches:** `docs/security/SYMPHONY_DEMO_KEY_AND_ROTATION_POLICY.md`, `scripts/audit/verify_tsk_p1_demo_021.sh`, `evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** create the executable demo security policy, resolve OpenBao truth, label weaker posture correctly, and operationalize rotation closeout
- **Acceptance Criteria:** policy is executable, non-signoff posture is labeled correctly, and secret non-exposure includes HTML/bootstrap surfaces
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_021.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-021 --evidence evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json`
- **Failure Modes:** OpenBao remains ambiguous; weak posture misrepresented as readiness; evidence file missing

### TSK-P1-DEMO-022 — ~~Reconcile provisioning and checklist docs with the strict host-based execution contract~~ RETIRED (superseded by TSK-P1-217/218)
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-017`, `TSK-P1-DEMO-018`, `TSK-P1-DEMO-020`, `TSK-P1-DEMO-021`
- **Touches:** `docs/operations/PHASE1_DEMO_DEPLOY_AND_TEST_CHECKLIST.md`, `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`, `scripts/audit/verify_tsk_p1_demo_022.sh`, `evidence/phase1/tsk_p1_demo_022_doc_reconciliation.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** reconcile conflicting docs, define deterministic provisioning contract inside the E2E flow, and make teardown/retention behavior explicit
- **Acceptance Criteria:** operators no longer need to improvise and conflicting language is removed or clearly deprecated
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_022.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-022 --evidence evidence/phase1/tsk_p1_demo_022_doc_reconciliation.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_022_doc_reconciliation.json`
- **Failure Modes:** provisioning remains a seam; teardown remains ambiguous; evidence file missing

### TSK-P1-DEMO-023 — Create the strict start-now checklist for demo deployment and end-to-end rehearsal ✅ completed
- **Owner:** QA_VERIFIER
- **Depends on:** `TSK-P1-DEMO-020`, `TSK-P1-DEMO-021`, `TSK-P1-DEMO-022`
- **Touches:** `docs/operations/SYMPHONY_DEMO_START_NOW_CHECKLIST.md`, `scripts/audit/verify_tsk_p1_demo_023.sh`, `evidence/phase1/tsk_p1_demo_023_start_now_checklist.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** create a strict go/no-go startup checklist for host-based rehearsal-only deployment, separate start readiness from signoff readiness, and define explicit stop and success criteria
- **Acceptance Criteria:** operators can decide whether to start end-to-end deployment now without conflating rehearsal readiness with signoff readiness
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_023.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-023 --evidence evidence/phase1/tsk_p1_demo_023_start_now_checklist.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_023_start_now_checklist.json`
- **Failure Modes:** checklist still conflates readiness classes; stop criteria missing; evidence file missing

### TSK-P1-DEMO-024 — Align demo health endpoints with deployment probes
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-014`
- **Touches:** `services/ledger-api/dotnet/src/LedgerApi/Program.cs`, `infra/sandbox/k8s/ledger-api-deployment.yaml`, `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md`, `scripts/audit/verify_tsk_p1_demo_024.sh`, `evidence/phase1/tsk_p1_demo_024_health_probe_parity.json`
- **Invariants:** `INV-105`, `INV-119`, `INVPROC-06`
- **Work:** align the app health route set and the deployment probe targets so the documented and deployed demo runtime agree on real health endpoints
- **Acceptance Criteria:** the app, k8s manifests, and deployment guide agree on the supported probe route set and fresh deploys no longer fail because probes target missing routes
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_024.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-024 --evidence evidence/phase1/tsk_p1_demo_024_health_probe_parity.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_024_health_probe_parity.json`
- **Failure Modes:** probes still hit missing routes; the guide documents the wrong health route set; evidence file missing

### TSK-P1-DEMO-025 — ~~Complete the host-based demo deployment runtime contract~~ RETIRED (superseded by TSK-P1-220)
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-024`
- **Touches:** `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md`, `docs/operations/PHASE1_DEMO_DEPLOY_AND_TEST_CHECKLIST.md`, `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`, `scripts/audit/verify_tsk_p1_demo_025.sh`, `evidence/phase1/tsk_p1_demo_025_runtime_contract.json`
- **Invariants:** `INV-105`, `INV-119`, `INVPROC-06`
- **Work:** document the full host-based runtime contract, including required env vars, the UI/read-key relationship, Kestrel on `8080`, and `psql` as a required host dependency
- **Acceptance Criteria:** the deployment guide lists the full runtime contract and does not imply nginx or IIS is required for the supported host-based demo path
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_025.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-025 --evidence evidence/phase1/tsk_p1_demo_025_runtime_contract.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_025_runtime_contract.json`
- **Failure Modes:** required env vars remain undocumented; `psql` remains undocumented; the guide still overstates non-Kestrel servers; evidence file missing

### TSK-P1-DEMO-026 — ~~Keep admin credentials server-side for privileged demo actions~~ RETIRED (superseded by TSK-P1-218/219)
- **Owner:** SUPERVISOR
- **Depends on:** `TASK-UI-WIRE-004`, `TSK-P1-DEMO-025`
- **Touches:** `services/ledger-api/dotnet/src/LedgerApi/**`, `src/supervisory-dashboard/**`, `docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md`, `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md`, `scripts/audit/verify_tsk_p1_demo_026.sh`, `evidence/phase1/tsk_p1_demo_026_server_side_admin_proxy.json`
- **Invariants:** `INV-077`, `INV-105`, `INV-119`
- **Work:** mediate privileged pilot-demo actions server-side so `ADMIN_API_KEY` stays server-side and the browser uses only browser-safe same-origin flows
- **Acceptance Criteria:** admin credentials never appear in browser source/bootstrap payloads and privileged actions still work through server-side mediation
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_026.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-026 --evidence evidence/phase1/tsk_p1_demo_026_server_side_admin_proxy.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_026_server_side_admin_proxy.json`
- **Failure Modes:** admin secrets leak to the browser, privileged routes are called directly with admin semantics, or the UI-wire mediation model is weakened; evidence file missing

### TSK-P1-DEMO-027 — ~~Finish the operator demo gate split~~ RETIRED (superseded by TSK-P1-220/221)
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-015`, `TSK-P1-DEMO-025`, `TSK-P1-DEMO-026`
- **Touches:** `scripts/dev/pre_ci_demo.sh`, `scripts/dev/pre_ci.sh`, `scripts/dev/**`, `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md`, `docs/operations/PHASE1_DEMO_DEPLOY_AND_TEST_CHECKLIST.md`, `scripts/audit/verify_tsk_p1_demo_027.sh`, `evidence/phase1/tsk_p1_demo_027_demo_gate_split.json`
- **Invariants:** `INV-105`, `INV-119`, `INVPROC-06`
- **Work:** finish the lean operator demo gate so routine demo bring-up uses an explicitly enumerated narrower verifier set plus runtime readiness checks, while `pre_ci.sh` remains the engineering gate
- **Acceptance Criteria:** operators have a distinct deterministic demo gate and the docs stop directing routine demo bring-up through full `pre_ci.sh`
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_027.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-027 --evidence evidence/phase1/tsk_p1_demo_027_demo_gate_split.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_027_demo_gate_split.json`
- **Failure Modes:** deployment still depends on full `pre_ci.sh`; the operator gate is ambiguous or duplicates full `pre_ci`; evidence file missing

### TSK-P1-DEMO-028 — Complete image build flow while keeping host-based publish as the supported demo path ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-024`, `TSK-P1-DEMO-025`
- **Touches:** `services/ledger-api/Dockerfile`, `services/executor-worker/Dockerfile`, `scripts/dev/build_demo_images.sh`, `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md`, `scripts/audit/verify_tsk_p1_demo_028.sh`, `evidence/phase1/tsk_p1_demo_028_image_flow.json`
- **Invariants:** `INV-105`, `INV-119`, `INVPROC-06`
- **Work:** replace placeholder image behavior with a reproducible image build path while keeping host-based `dotnet publish` on Kestrel as the supported demo bring-up path
- **Acceptance Criteria:** the repo has a real image build flow, but the deployment guide still clearly identifies host-based publish as the supported demo path
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_028.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-028 --evidence evidence/phase1/tsk_p1_demo_028_image_flow.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_028_image_flow.json`
- **Failure Modes:** Dockerfiles remain placeholder-only, the guide overstates image build as the primary path, or evidence is missing

### TSK-P1-DEMO-029 — ~~Create the demo provisioning sample pack and signoff threshold guide~~ RETIRED (superseded by TSK-P1-218)
- **Owner:** QA_VERIFIER
- **Depends on:** `TSK-P1-DEMO-017`, `TSK-P1-DEMO-021`, `TSK-P1-DEMO-022`, `TSK-P1-DEMO-023`
- **Touches:** `docs/operations/GREENTECH4CE_DEMO_PROVISIONING_SAMPLE_PACK.md`, `docs/operations/GREENTECH4CE_DEMO_PROVISIONING_SAMPLE_PACK.sample.json`, `scripts/audit/verify_tsk_p1_demo_029.sh`, `evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** create a governed demo provisioning sample pack with fixed sample values and exact repo-backed commands, plus explicit signoff-threshold guidance for what the sample pack does and does not prove
- **Acceptance Criteria:** document and JSON agree on the sample set, exact sample commands are present for repo-backed endpoints, and signoff limitations are explicit
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_029.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-029 --evidence evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`
- **Failure Modes:** fake APIs introduced; repo-backed vs operator-confirmed state blurred; signoff overclaimed; evidence file missing

### TSK-P1-DEMO-030 — Repair the demo task-line collision and move deployment work to a clean main-based branch
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-023`
- **Touches:** `docs/audits/GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md`, `tasks/TSK-P1-DEMO-024/**`, `tasks/TSK-P1-DEMO-025/**`, `tasks/TSK-P1-DEMO-026/**`, `tasks/TSK-P1-DEMO-027/**`, `tasks/TSK-P1-DEMO-028/**`, `tasks/TSK-P1-DEMO-029/**`, `tasks/TSK-P1-DEMO-030/meta.yml`, `docs/plans/phase1/TSK-P1-DEMO-024/**`, `docs/plans/phase1/TSK-P1-DEMO-025/**`, `docs/plans/phase1/TSK-P1-DEMO-026/**`, `docs/plans/phase1/TSK-P1-DEMO-027/**`, `docs/plans/phase1/TSK-P1-DEMO-028/**`, `docs/plans/phase1/TSK-P1-DEMO-029/**`, `docs/plans/phase1/TSK-P1-DEMO-030/**`, `docs/plans/phase1/REM-2026-03-14_demo-030-git-audit-fix/**`, `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`, `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-e.*`, `approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.*`, `evidence/phase1/approval_metadata.json`, `scripts/audit/verify_tsk_p1_demo_030.sh`, `evidence/phase1/tsk_p1_demo_030_branch_repair.json`
- **Invariants:** `INV-105`, `INV-119`, `INV-133`
- **Work:** restore canonical `024..028`, move the sample-pack task to `029`, relocate deployment repair work onto a clean branch from parity-restored local `main`, and close any Git-mutation audit gap introduced by the branch repair before the final parity pass
- **Acceptance Criteria:** local `main` parity is restored first, canonical `024..028` meanings are restored, the provisioning sample-pack task exists only as `029`, and approval metadata references only the repaired branch scope
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_030.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-030 --evidence evidence/phase1/tsk_p1_demo_030_branch_repair.json`
- **Evidence:** `evidence/phase1/tsk_p1_demo_030_branch_repair.json`
- **Failure Modes:** canonical demo task line remains wrong; sample-pack task still occupies `024`; deployment repair remains on Wave-E branch; evidence file missing

## Security Optimization Traceability Audit Remediation Pack

## RLS Verification Spine Wave 1 Pack
**Reference:** see [RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md](RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md) for the canonical pickup guide and strictly enforced execution sequence.

### TSK-P1-222 — Repair the TSK-RLS-ARCH-001 task contract so that Wave 1 implementation stays truthful and fail-closed
- **Owner:** SUPERVISOR
- **Depends on:** none
- **Touches:** `tasks/TSK-RLS-ARCH-001/meta.yml`, `docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md`, `docs/plans/phase1/TSK-RLS-ARCH-001/EXEC_LOG.md`, `scripts/audit/verify_tsk_p1_222.sh`, `evidence/phase1/tsk_p1_222_rls_contract_repair.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** narrow the parent RLS task contract to the staged three-plan execution model, align the parent plan/log handoff, and add a deterministic verifier for contract drift
- **Acceptance Criteria:** the parent task declares truthful Wave 1 scope and authority, handoff to the companion plans is explicit, and the task-specific verifier emits contract-repair evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_222.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-222 --evidence evidence/phase1/tsk_p1_222_rls_contract_repair.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_222_rls_contract_repair.json`
- **Failure Modes:** parent RLS task still declares omnibus implementation scope; Wave 1 execution order remains ambiguous; evidence file missing

### TSK-P1-223 — Build a task metadata loader primitive so that Wave 1 verification can read task contracts deterministically
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-222`
- **Touches:** `scripts/audit/task_meta_loader.py`, `scripts/audit/verify_tsk_p1_223.sh`, `evidence/phase1/tsk_p1_223_task_meta_loader.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement a deterministic task metadata loader, reject malformed metadata explicitly, and add a verifier for repeatable valid/invalid loader behavior
- **Acceptance Criteria:** valid metadata loads deterministically, malformed metadata fails closed, and the verifier emits loader evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_223.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-223 --evidence evidence/phase1/tsk_p1_223_task_meta_loader.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_223_task_meta_loader.json`
- **Failure Modes:** loader returns different structures for identical input; malformed metadata is accepted silently; evidence file missing

### TSK-P1-224 — Build a report-only task verification runner and gate result contract so that Wave 1 has one orchestrated execution path
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-223`
- **Touches:** `scripts/audit/task_verification_runner.py`, `scripts/audit/task_gate_result.py`, `scripts/audit/verify_tsk_p1_224.sh`, `evidence/phase1/tsk_p1_224_runner_contract.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** create the report-only runner skeleton, define the shared gate result contract, and verify dry-run execution plus malformed gate-result rejection
- **Acceptance Criteria:** one ordered runner path exists, malformed gate results are rejected, and the verifier emits runner-contract evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_224.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-224 --evidence evidence/phase1/tsk_p1_224_runner_contract.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_224_runner_contract.json`
- **Failure Modes:** multiple verification entry points remain; malformed gate output passes through the runner; evidence file missing

### TSK-P1-225 — Implement a report-only contract gate so that Wave 1 can reject invalid task packs through one runner path
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-224`
- **Touches:** `scripts/audit/task_contract_gate.py`, `scripts/audit/verify_tsk_p1_225.sh`, `evidence/phase1/tsk_p1_225_contract_gate.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement the first report-only task contract gate, enforce structured output through the shared runner, and verify valid/invalid task-pack behavior
- **Acceptance Criteria:** invalid task packs fail through the contract gate, failures remain structured, and the verifier emits contract-gate evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_225.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-225 --evidence evidence/phase1/tsk_p1_225_contract_gate.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_225_contract_gate.json`
- **Failure Modes:** invalid task pack passes through the contract gate; failures are emitted without structured fields; evidence file missing

### TSK-P1-226 — Implement proof-blocker detection and hard stop so that Wave 1 cannot fake progress when verification is not honest
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-224`, `TSK-P1-225`
- **Touches:** `scripts/audit/task_proof_blocker_gate.py`, `scripts/audit/verify_tsk_p1_226.sh`, `evidence/phase1/tsk_p1_226_proof_blocker.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement proof-blocker classification, halt downstream execution on blocked proof paths, and verify blocked versus unblocked behavior
- **Acceptance Criteria:** blocked proof paths emit `PROOF_BLOCKED`, downstream execution stops, and the verifier emits proof-blocker evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_226.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-226 --evidence evidence/phase1/tsk_p1_226_proof_blocker.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_226_proof_blocker.json`
- **Failure Modes:** runner continues after proof prerequisites are missing; blocked path still emits misleading downstream state; evidence file missing

## RLS Anti-Drift Wave 2 Pack

### TSK-P1-227 — Harden the canonical task template so all future task packs must declare anti-drift boundaries and proof limits
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-222`
- **Touches:** `tasks/_template/meta.yml`, `scripts/audit/verify_tsk_p1_227.sh`, `evidence/phase1/tsk_p1_227_template_hardening.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** harden the canonical task template with required anti-drift boundary fields, strengthen template guidance against authoring theater, and verify fixture rejection for missing hardened sections
- **Acceptance Criteria:** the shared template requires the hardened anti-drift contract shape, guidance names key authoring anti-patterns explicitly, and the verifier emits template-hardening evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_227.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-227 --evidence evidence/phase1/tsk_p1_227_template_hardening.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_227_template_hardening.json`
- **Failure Modes:** canonical template still permits omission of anti-drift sections; fixture task missing hardened sections passes strict validation; evidence file missing

### TSK-P1-228 — Harden the task creation process so anti-drift authoring rules become canonical repo policy
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-227`
- **Touches:** `docs/operations/TASK_CREATION_PROCESS.md`, `scripts/audit/verify_tsk_p1_228.sh`, `evidence/phase1/tsk_p1_228_process_hardening.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** codify anti-drift authoring rules in the canonical task-creation process, prohibit placeholder proof language, and verify the required process rules are present
- **Acceptance Criteria:** anti-drift authoring becomes canonical process policy, placeholder verification is prohibited, and the verifier emits process-hardening evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_228.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-228 --evidence evidence/phase1/tsk_p1_228_process_hardening.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_228_process_hardening.json`
- **Failure Modes:** task-creation process still leaves anti-drift authoring optional; dishonest proof-language gaps remain permissible; evidence file missing

### TSK-P1-229 — Implement a report-only parity verifier so task YAML and companion docs cannot silently diverge
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-227`, `TSK-P1-228`, `TSK-P1-224`
- **Touches:** `scripts/audit/task_parity_gate.py`, `scripts/audit/verify_tsk_p1_229.sh`, `evidence/phase1/tsk_p1_229_task_parity.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement the report-only parity gate, compare YAML with companion docs and index registration, and emit shared-contract parity findings for aligned and mismatched fixtures
- **Acceptance Criteria:** parity drift is surfaced deterministically through the shared gate result shape, aligned fixtures pass cleanly, and the verifier emits parity evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_229.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-229 --evidence evidence/phase1/tsk_p1_229_task_parity.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_229_task_parity.json`
- **Failure Modes:** YAML and human companion docs diverge silently; parity output does not conform to the shared gate result contract; evidence file missing

### TSK-P1-230 — Implement a report-only task-pack authoring gate so hollow or incomplete task contracts fail readiness truthfully
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-227`, `TSK-P1-228`, `TSK-P1-229`, `TSK-P1-224`
- **Touches:** `scripts/audit/task_authoring_gate.py`, `scripts/audit/verify_tsk_p1_230.sh`, `evidence/phase1/tsk_p1_230_authoring_gate.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement the report-only authoring gate, emit the shared result contract, define the first Pack B transition model, and verify drift-density escalation across hollow and repeated-warning fixtures
- **Acceptance Criteria:** hollow authoring contracts fail truthfully, the gate declares promotion and rollback rules, repeated weak signals escalate deterministically, and the verifier emits authoring-gate evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_230.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-230 --evidence evidence/phase1/tsk_p1_230_authoring_gate.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_230_authoring_gate.json`
- **Failure Modes:** authoring gate emits output outside the shared contract; repeated weak signals do not escalate; report-only gate has no promotion or rollback model; evidence file missing

### TSK-P1-231 — Implement a report-only scope ceiling and objective-work-touches alignment gate so fake narrowness is surfaced before implementation begins
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-227`, `TSK-P1-224`, `TSK-P1-229`, `TSK-P1-230`
- **Touches:** `scripts/audit/task_scope_gate.py`, `scripts/audit/verify_tsk_p1_231.sh`, `evidence/phase1/tsk_p1_231_scope_alignment.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement scope-ceiling and objective-work-touches alignment checks, emit confidence-bounded scoring and severity, and verify oversized plus fake-narrowness fixtures
- **Acceptance Criteria:** obvious breadth and hidden conceptual drift are both surfaced, low-confidence heuristics do not overclaim authority, and the verifier emits scope-alignment evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_231.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-231 --evidence evidence/phase1/tsk_p1_231_scope_alignment.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_231_scope_alignment.json`
- **Failure Modes:** scope gate treats low-confidence heuristics as hard authority; fake narrowness remains invisible; scope gate duplicates structural checks owned elsewhere; evidence file missing

### TSK-P1-232 — Implement a report-only proof-integrity gate so declared verification, acceptance criteria, evidence, and proof guarantees must align
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-224`, `TSK-P1-225`, `TSK-P1-227`, `TSK-P1-230`, `TSK-P1-231`
- **Touches:** `scripts/audit/task_proof_integrity_gate.py`, `scripts/audit/verify_tsk_p1_232.sh`, `evidence/phase1/tsk_p1_232_proof_integrity.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement the report-only proof-integrity gate, enforce contract-level proof-chain mapping, keep the gate out of semantic runtime analysis, and verify decorative-verifier, orphan-evidence, and overclaimed-proof fixtures
- **Acceptance Criteria:** proof-chain mismatches are surfaced through the shared contract, the gate stays contract-bounded, high-confidence structural mismatches are visible, and the verifier emits proof-integrity evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_232.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-232 --evidence evidence/phase1/tsk_p1_232_proof_integrity.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_232_proof_integrity.json`
- **Failure Modes:** proof-integrity gate claims semantic or runtime truth beyond declared contract alignment; unsupported acceptance criteria are not surfaced as critical proof findings; output does not use shared contract; evidence file missing

### TSK-P1-233 — Implement a report-only dependency truth validator so downstream tasks cannot proceed on socially assumed upstream completion
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-232`
- **Touches:** `scripts/audit/task_dependency_truth_gate.py`, `scripts/audit/verify_tsk_p1_233.sh`, `evidence/phase1/tsk_p1_233_dependency_truth.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement the dependency-truth gate, validate upstream proof and required outputs, and verify dependency-complete-but-unproven plus missing-output fixtures
- **Acceptance Criteria:** socially assumed dependency completion is surfaced, findings use the shared contract, and the verifier emits dependency-truth evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_233.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-233 --evidence evidence/phase1/tsk_p1_233_dependency_truth.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_233_dependency_truth.json`
- **Failure Modes:** dependency truth gate allows socially assumed upstream completion; missing dependency outputs are not surfaced; evidence file missing

### TSK-P1-234 — Define the canonical verify-task entrypoint so task verification has one sanctioned execution shell
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-224`
- **Touches:** `scripts/audit/verify_task.sh`, `scripts/audit/verify_tsk_p1_234.sh`, `evidence/phase1/tsk_p1_234_verify_task_entrypoint.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** define the sanctioned `verify-task` shell entrypoint, document the canonical invocation contract, and verify it is mechanically distinguishable from bypass paths
- **Acceptance Criteria:** task verification has one explicit sanctioned shell entrypoint, later authority checks can judge canonical versus bypass invocation, and the verifier emits entrypoint evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_234.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-234 --evidence evidence/phase1/tsk_p1_234_verify_task_entrypoint.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_234_verify_task_entrypoint.json`
- **Failure Modes:** canonical verify-task entrypoint remains undefined or ambiguous; entrypoint task silently expands into bypass-detection logic; evidence file missing

### TSK-P1-235 — Detect and classify non-canonical verification execution so bypass outputs are treated as non-authoritative
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-234`
- **Touches:** `scripts/audit/task_execution_authority_gate.py`, `scripts/audit/verify_tsk_p1_235.sh`, `evidence/phase1/tsk_p1_235_execution_authority.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** implement execution-authority classification, detect direct invocation and partial runner bypass, and verify that bypass outputs are marked non-authoritative through the shared contract
- **Acceptance Criteria:** non-canonical verification outputs are classified as non-authoritative, the gate provides one clear corrective next action, and the verifier emits execution-authority evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_235.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-235 --evidence evidence/phase1/tsk_p1_235_execution_authority.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_235_execution_authority.json`
- **Failure Modes:** non-canonical verification outputs remain authoritative; direct invocation is indistinguishable from canonical flow; evidence file missing

### TSK-P1-238 — Repair execution-order authority drift so anti-hallucination task metadata, registry, and pickup guidance agree
- **Owner:** SUPERVISOR
- **Depends on:** none
- **Touches:** `tasks/TSK-P1-227/meta.yml`, `tasks/TSK-P1-234/meta.yml`, `tasks/TSK-P1-235/meta.yml`, `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md`, `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`, `scripts/audit/verify_tsk_p1_238.sh`, `evidence/phase1/tsk_p1_238_order_authority.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** repair the execution-order authority model so task metadata, pickup guidance, and governance-index discoverability agree; deduplicate downstream backlog items in the pickup guide; add a verifier that detects order-authority drift
- **Acceptance Criteria:** metadata no longer contradicts the canonical anti-hallucination sequence, the pickup guide backlog is deduplicated and unambiguous, the main task index points to the pickup guide, and the verifier emits order-authority evidence
- **Verification:** `bash scripts/audit/verify_tsk_p1_238.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-238 --evidence evidence/phase1/tsk_p1_238_order_authority.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_238_order_authority.json`
- **Failure Modes:** task metadata and pickup guidance still disagree on next-eligible task; duplicate downstream backlog aliases remain; primary governance index omits the pickup-guide reference; evidence file missing

### TSK-P1-239 — Harden PLAN_TEMPLATE.md and TASK_CREATION_PROCESS.md with mandatory anti-drift verifier design requirements
- **Owner:** ARCHITECT
- **Depends on:** none
- **Touches:** `docs/contracts/templates/PLAN_TEMPLATE.md`, `docs/operations/TASK_CREATION_PROCESS.md`, `scripts/audit/verify_plan_anti_drift.sh`, `evidence/phase1/tsk_p1_239_template_hardening.json`, `tasks/TSK-P1-239/meta.yml`
- **Invariants:** `INV-GOV-TEMPLATE-001`, `INV-GOV-TEMPLATE-002`, `INV-GOV-TEMPLATE-003`
- **Work:** Add mandatory Stop Conditions and Verifier Design blocks to PLAN_TEMPLATE.md, rewrite subjective "Done when" examples, add a Verifier Design Review gate to TASK_CREATION_PROCESS.md, and create verify_plan_anti_drift.sh to mechanically enforce the 5 anti-drift rules.
- **Acceptance Criteria:** PLAN_TEMPLATE.md requires Stop Conditions and Verifier Design blocks, subjective language is removed, TASK_CREATION_PROCESS.md has the new gate, and verify_plan_anti_drift.sh exits non-zero precisely when required anti-drift sections or honest wording is missing.
- **Verification:** `bash scripts/audit/verify_plan_anti_drift.sh docs/contracts/templates/PLAN_TEMPLATE.md`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-239 --evidence evidence/phase1/tsk_p1_239_template_hardening.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_239_template_hardening.json`
- **Failure Modes:** PLAN_TEMPLATE.md lacks Stop Conditions; Verifier Design block missing; done-when examples subjective; creation process lacks gate; verify_plan_anti_drift.sh missing; evidence file missing

### TSK-P1-240 — Implement Verifier Integrity & Proof Enforcement Gate to mathematically validate task proof graphs
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** `TSK-P1-239`
- **Touches:** `scripts/audit/verify_plan_semantic_alignment.py`, `docs/operations/TASK_CREATION_PROCESS.md`, `evidence/phase1/tsk_p1_240_semantic_alignment.json`, `tasks/TSK-P1-240/meta.yml`
- **Invariants:** `INV-GOV-TEMPLATE-004`, `INV-GOV-TEMPLATE-005`
- **Work:** Create verify_plan_semantic_alignment.py using a graph-based enforcement model to require a closed proof mapping (objective->work->acceptance->verification->evidence), enforce failure-based verification (verifiers must fail under simulation), enforce proof-carrying evidence (no static declarations), and detect high drift-density.
- **Acceptance Criteria:** The script rejects orphaned nodes, simulates failure conditions to detect "no-op" verifiers, rejects static evidence lacking execution traces, and uses drift density escalation to hard-fail weak signals. Includes 5 new N-tests (N1: no-op, N2: orphan, N3: fake evidence, N4: non-failing, N5: self-referential).
- **Verification:** `bash scripts/audit/verify_tsk_p1_240.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-240 --evidence evidence/phase1/tsk_p1_240_semantic_alignment.json`; `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_240_semantic_alignment.json`
- **Failure Modes:** Scanner relies on length or semantic heuristics instead of mapping; accepts a verifier that cannot fail; accepts static evidence; allows high drift density to pass; evidence file missing

### TSK-P1-206 — Rebaseline the security optimization traceability audit to current repo truth ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** none
- **Touches:** `docs/tasks/2026-03-14_security_optimization_traceability_audit.md`, `scripts/audit/verify_tsk_p1_206.sh`, `evidence/phase1/tsk_p1_206_audit_truth_rebaseline.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** correct the audit document, remove stale command-log claims, and align severity language with current localhost-only exposure posture
- **Acceptance Criteria:** audit reflects current repo truth and no longer overstates exposure or stale failures
- **Verification:** `bash scripts/audit/verify_tsk_p1_206.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-206 --evidence evidence/phase1/tsk_p1_206_audit_truth_rebaseline.json`
- **Evidence:** `evidence/phase1/tsk_p1_206_audit_truth_rebaseline.json`
- **Failure Modes:** stale failures remain; severity language still overstated; evidence file missing

### TSK-P1-207 — Harden supervisor API privileged routes and token transport ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `R-000`, `TSK-P1-HIER-011`
- **Touches:** `services/supervisor_api/server.py`, `scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh`, `scripts/audit/verify_tsk_p1_207.sh`, `evidence/phase1/tsk_p1_207_supervisor_api_auth_hardening.json`
- **Invariants:** `INV-119`, `INV-133`
- **Work:** add explicit authn/authz, validate `ADMIN_API_KEY`, move audit-token reads to `Authorization: Bearer`, harden parse errors, and remove raw DB-detail leakage
- **Acceptance Criteria:** no privileged route is unauthenticated, query-token transport is rejected, and failure handling is deterministic
- **Verification:** `bash scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh`; `bash scripts/audit/verify_tsk_p1_207.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-207 --evidence evidence/phase1/tsk_p1_207_supervisor_api_auth_hardening.json`
- **Evidence:** `evidence/phase1/tsk_p1_207_supervisor_api_auth_hardening.json`
- **Failure Modes:** auth gap remains; query-token transport remains; DB error detail still leaks; evidence file missing

### TSK-P1-208 — Restore admin-only auth boundary for pilot-demo instruction generation ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-026`
- **Touches:** `services/ledger-api/dotnet/src/LedgerApi/Program.cs`, `src/supervisory-dashboard/index.html`, `scripts/audit/verify_task_ui_wire_004.sh`, `scripts/audit/verify_tsk_p1_208.sh`, `evidence/phase1/tsk_p1_208_pilot_demo_generate_auth_boundary.json`
- **Invariants:** `INV-077`, `INV-119`
- **Work:** replace evidence-read auth with admin auth for the pilot-demo generate route, preserve operator-cookie defense in depth, and keep the UI on server-side mediation
- **Acceptance Criteria:** `verify_task_ui_wire_004.sh` passes, the route is admin-guarded, the cookie layer remains, and no admin secret reaches the browser
- **Verification:** `bash scripts/audit/verify_task_ui_wire_004.sh`; `bash scripts/audit/verify_tsk_p1_208.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-208 --evidence evidence/phase1/tsk_p1_208_pilot_demo_generate_auth_boundary.json`
- **Evidence:** `evidence/phase1/tsk_p1_208_pilot_demo_generate_auth_boundary.json`
- **Failure Modes:** route still uses evidence-read auth; cookie layer removed; browser sees admin secret; evidence file missing

### TSK-P1-209 — Reconcile supervisory UI compatibility alias traceability ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-DEMO-008`
- **Touches:** `src/supervisory-dashboard/index.html`, `scripts/audit/verify_tsk_p1_demo_008.sh`, `scripts/audit/verify_tsk_p1_209.sh`, `evidence/phase1/tsk_p1_209_ui_traceability_cleanup.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** make `export-trigger` and `raw-artifact-drilldown` behavior unambiguous and add verifier-backed UI control inventory for aliases vs real controls
- **Acceptance Criteria:** compatibility alias behavior is no longer ambiguous and the inventory verifier passes
- **Verification:** `bash scripts/audit/verify_tsk_p1_demo_008.sh`; `bash scripts/audit/verify_tsk_p1_209.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-209 --evidence evidence/phase1/tsk_p1_209_ui_traceability_cleanup.json`
- **Evidence:** `evidence/phase1/tsk_p1_209_ui_traceability_cleanup.json`
- **Failure Modes:** alias ambiguity remains; inventory missing; evidence file missing

### TSK-P1-210 — Remove supervisory fallback duplication and repeated reveal-model scans ✅ completed
- **Owner:** SUPERVISOR
- **Depends on:** `TSK-P1-208`, `TSK-P1-209`
- **Touches:** `src/supervisory-dashboard/index.html`, `services/ledger-api/dotnet/src/LedgerApi/ReadModels/SupervisoryRevealReadModelHandler.cs`, `scripts/audit/verify_tsk_p1_210.sh`, `evidence/phase1/tsk_p1_210_supervisory_optimization.json`
- **Invariants:** `INV-105`, `INV-119`
- **Work:** consolidate fallback logic into a shared helper and reduce repeated reveal-model scans without changing behavior
- **Acceptance Criteria:** fallback semantics stay identical and reveal/detail output remains behaviorally stable while duplication drops
- **Verification:** `bash scripts/audit/verify_tsk_p1_210.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-P1-210 --evidence evidence/phase1/tsk_p1_210_supervisory_optimization.json`; `bash scripts/dev/pre_ci.sh`
- **Evidence:** `evidence/phase1/tsk_p1_210_supervisory_optimization.json`
- **Failure Modes:** fallback semantics drift; output shape changes unexpectedly; evidence file missing

## Wave 4 GF — Schema Governance Gates

### GF-W1-GOV-005A — Ownership/reference-order fail-closed verifier
- **Owner:** Security Guardian
- **Depends on:** GF-W1-SCH-008
- **Blocks:** GF-W1-SCH-009
- **Touches:** `scripts/audit/verify_gf_w1_gov_005a.sh`, `evidence/phase1/gf_w1_gov_005a.json`
- **Work:** Static analysis of all 9 GF Phase 0 migration SQL files: verify all files present; verify no forward FK references; verify no sector nouns in table names; emit evidence JSON
- **Acceptance Criteria:** all 9 migration files present; zero forward FK violations; zero sector-noun violations; `verify_gf_w1_gov_005a.sh` exits 0; `evidence/phase1/gf_w1_gov_005a.json` status=PASS
- **Verification:** `bash scripts/audit/verify_gf_w1_gov_005a.sh`
- **Evidence:** `evidence/phase1/gf_w1_gov_005a.json`
- **Failure Modes:** any GF migration file absent => FAIL; forward FK reference detected => CRITICAL_FAIL; sector noun in table name => CRITICAL_FAIL; evidence missing => FAIL

## Wave 5 Sabotage Remediation Pack

Covers reversal of rogue-agent damage from a failed Wave 5 attempt. Tasks provide governance coverage for corrections applied to pre_ci stubs, task meta.yml files, and companion PLAN.md files. Execution order: GF-W1-REM-001, GF-W1-REM-002, GF-W1-REM-004 (parallel) → GF-W1-REM-003.

### GF-W1-REM-001 — Correct stale migration number references in Wave 5 pre_ci verifier stubs
- **Owner:** DB Foundation Agent
- **Depends on:** none
- **Blocks:** GF-W1-FNC-001 through GF-W1-FNC-006
- **Touches:** `scripts/db/verify_gf_fnc_001.sh`, `scripts/db/verify_gf_fnc_002.sh`, `scripts/db/verify_gf_fnc_003.sh`, `scripts/db/verify_gf_fnc_004.sh`, `scripts/db/verify_gf_fnc_005.sh`, `scripts/db/verify_gf_fnc_006.sh`, `scripts/db/verify_gf_w1_rem_001.sh`, `evidence/phase1/gf_w1_rem_001.json`
- **Work:** Replace stale `0088`–`0093` migration refs with correct `0107`–`0112` in all 6 stubs; confirm each stub exits 0 PENDING; emit evidence
- **Acceptance Criteria:** `grep -E "008[89]_|009[0-3]_"` across all 6 stubs returns zero matches; all stubs exit 0 PENDING; `verify_gf_w1_rem_001.sh` exits 0 PASS
- **Verification:** `bash scripts/db/verify_gf_w1_rem_001.sh`; `python3 scripts/audit/validate_evidence.py --task GF-W1-REM-001 --evidence evidence/phase1/gf_w1_rem_001.json`
- **Evidence:** `evidence/phase1/gf_w1_rem_001.json`
- **Failure Modes:** stale migration ref remains in any stub => FAIL; evidence missing => FAIL

### GF-W1-REM-002 — Remove rogue migration names and fake verifier refs from GF-W1-FNC-001–007A meta.yml files
- **Owner:** Architect
- **Depends on:** none
- **Blocks:** GF-W1-FNC-001 through GF-W1-FNC-007A; GF-W1-REM-003
- **Touches:** `tasks/GF-W1-FNC-001/meta.yml`, `tasks/GF-W1-FNC-002/meta.yml`, `tasks/GF-W1-FNC-003/meta.yml`, `tasks/GF-W1-FNC-004/meta.yml`, `tasks/GF-W1-FNC-005/meta.yml`, `tasks/GF-W1-FNC-006/meta.yml`, `tasks/GF-W1-FNC-007A/meta.yml`, `scripts/audit/verify_gf_w1_rem_002.sh`, `evidence/phase1/gf_w1_rem_002.json`
- **Work:** Replace all rogue migration filenames and `verify_gf_w1_fnc_*` refs in 7 FNC meta.yml files with canonical equivalents; emit evidence
- **Acceptance Criteria:** grep for rogue patterns across all 7 meta.yml files returns zero matches; `verify_gf_w1_rem_002.sh` exits 0 PASS
- **Verification:** `bash scripts/audit/verify_gf_w1_rem_002.sh`; `python3 scripts/audit/validate_evidence.py --task GF-W1-REM-002 --evidence evidence/phase1/gf_w1_rem_002.json`
- **Evidence:** `evidence/phase1/gf_w1_rem_002.json`
- **Failure Modes:** rogue ref remains in any meta.yml => FAIL; evidence missing => FAIL

### GF-W1-REM-003 — Remove rogue migration filename refs from GF-W1-FNC-002 through GF-W1-FNC-007A PLAN.md files
- **Owner:** Architect
- **Depends on:** GF-W1-REM-002
- **Blocks:** GF-W1-FNC-002, GF-W1-FNC-003, GF-W1-FNC-004, GF-W1-FNC-005, GF-W1-FNC-006, GF-W1-FNC-007A
- **Touches:** `docs/plans/phase1/GF-W1-FNC-002/PLAN.md`, `docs/plans/phase1/GF-W1-FNC-003/PLAN.md`, `docs/plans/phase1/GF-W1-FNC-004/PLAN.md`, `docs/plans/phase1/GF-W1-FNC-005/PLAN.md`, `docs/plans/phase1/GF-W1-FNC-006/PLAN.md`, `docs/plans/phase1/GF-W1-FNC-007A/PLAN.md`, `scripts/audit/verify_gf_w1_rem_003.sh`, `evidence/phase1/gf_w1_rem_003.json`
- **Work:** Replace rogue migration names in Execution Details of FNC-003–007A PLAN.md files; confirm FNC-002 already correct; emit evidence (scope expanded during implementation after final grep revealed additional rogue refs in FNC-005/006/007A)
- **Acceptance Criteria:** grep for rogue migration patterns across all 6 FNC PLAN.md files returns zero matches; `verify_gf_w1_rem_003.sh` exits 0 PASS
- **Verification:** `bash scripts/audit/verify_gf_w1_rem_003.sh`; `python3 scripts/audit/validate_evidence.py --task GF-W1-REM-003 --evidence evidence/phase1/gf_w1_rem_003.json`
- **Evidence:** `evidence/phase1/gf_w1_rem_003.json`
- **Failure Modes:** rogue migration name remains in any PLAN.md => FAIL; evidence missing => FAIL

### GF-W1-REM-004 — Remove rogue verify_gf_w1_fnc_007b refs from GF-W1-FNC-007B meta.yml
- **Owner:** Security Guardian Agent
- **Depends on:** none
- **Blocks:** GF-W1-FNC-007B
- **Touches:** `tasks/GF-W1-FNC-007B/meta.yml`, `scripts/audit/verify_gf_w1_rem_004.sh`, `evidence/phase1/gf_w1_rem_004.json`
- **Work:** Replace all 4 `verify_gf_w1_fnc_007b` occurrences in FNC-007B meta.yml with `verify_gf_fnc_007b`; emit evidence
- **Acceptance Criteria:** grep for `verify_gf_w1_fnc_007b` in FNC-007B meta.yml returns zero matches; `verify_gf_w1_rem_004.sh` exits 0 PASS
- **Verification:** `bash scripts/audit/verify_gf_w1_rem_004.sh`; `python3 scripts/audit/validate_evidence.py --task GF-W1-REM-004 --evidence evidence/phase1/gf_w1_rem_004.json`
- **Evidence:** `evidence/phase1/gf_w1_rem_004.json`
- **Failure Modes:** rogue verifier ref remains in FNC-007B meta.yml => FAIL; evidence missing => FAIL

## RLS Architecture Remediation Pack

### TSK-RLS-ARCH-001 — Remediate RLS architecture to deterministic dual-policy system
- **Owner:** DB_FOUNDATION
- **Priority:** CRITICAL
- **Risk Class:** SECURITY
- **Blast Radius:** DB_SCHEMA
- **Depends on:** none
- **Touches:** `schema/rls_tables.yml`, `schema/migrations/0095_rls_dual_policy_architecture.sql`, `schema/migrations/0095_pre_snapshot.sql`, `schema/migrations/0095_rollback.sql`, `scripts/db/run_migration_0095.sh`, `scripts/db/phase0_rls_enumerate.py`, `scripts/db/lint_rls_born_secure.py`, `scripts/audit/verify_gf_rls_runtime.sh`, `tests/rls_runtime/test_rls_dual_policy_access.sh`, `scripts/db/verify_migration_bootstrap.sh`, `docs/invariants/rls_trust_model.md`, `docs/invariants/rls_trust_boundaries.md`, `evidence/phase1/rls_arch/tsk_rls_arch_001.json`
- **Invariants:** `INV-RLS-001`, `INV-RLS-002`, `INV-RLS-003`, `INV-RLS-004`, `INV-RLS-005`, `INV-RLS-006`
- **Work:** YAML registry declaration, Phase 0 enumeration and validation (FK + NOT NULL + NOT DEFERRABLE), atomic single-transaction migration (destructive reset + structural preservation + idempotent deterministic generation + post-gen sanity assertion + runtime coverage kill switch), dual tenant getters + mandatory setter, declarative lint, binary drift verifier, 21 adversarial tests, bootstrap gate, admin DEFINER functions with OWNER TO symphony_reader, trust boundary documentation
- **Acceptance Criteria:** every tenant table has exactly 1P+1R policy, runtime kill switch prevents uncovered tables, all 21 adversarial tests pass, bootstrap gate passes with 0 errors, lint rejects manual policy creation
- **Verification:** `bash scripts/db/run_migration_0095.sh`; `python3 scripts/db/lint_rls_born_secure.py schema/migrations/0095_*.sql`; `bash scripts/audit/verify_gf_rls_runtime.sh`; `bash tests/rls_runtime/test_rls_dual_policy_access.sh`; `bash scripts/db/verify_migration_bootstrap.sh`; `python3 scripts/audit/validate_evidence.py --task TSK-RLS-ARCH-001 --evidence evidence/phase1/rls_arch/tsk_rls_arch_001.json`
- **Evidence:** `evidence/phase1/rls_arch/tsk_rls_arch_001.json`
- **Failure Modes:** table with tenant_id not in rls_tables.yml => CRITICAL_FAIL; migration partially applied => CRITICAL_FAIL; adversarial test fails => CRITICAL_FAIL; lint passes manual policy => FAIL; evidence file missing => FAIL
