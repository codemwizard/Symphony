# Git Mutation Surface Audit 2026-03-10

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Purpose: inventory repository scripts that mutate Git state or rely on Git state transitions, then record whether they comply with the Git mutation containment rule.

## Classification
- `mutates`: script creates or changes refs, branches, commits, staged state, worktrees, or remote-tracking refs
- `contains`: script explicitly scrubs inherited Git plumbing and/or asserts repository identity
- `status`: `PASS`, `PARTIAL`, or `BLOCKED`

## Inventory
| Path | Mutates | Contains | Status | Notes |
| --- | --- | --- | --- | --- |
| `scripts/audit/test_diff_semantics_parity.sh` | yes | yes | PASS | Scrubs inherited Git plumbing and asserts disposable repo identity before mutating Git state. |
| `scripts/audit/test_diff_semantics_parity_hostile_env.sh` | yes | yes | PASS | Forces hostile parent Git plumbing and verifies the caller repo is unchanged. |
| `scripts/audit/run_phase0_ordered_checks.sh` | no | yes | PASS | Runner-level containment wraps parity fixture execution with scrubbed environment and regression coverage. |
| `scripts/dev/pre_ci.sh` | yes | partial | PASS | Updates `refs/remotes/origin/main` with explicit remote refspec and enforces remediation/freshness gates before guarded execution continues. |
| `scripts/audit/verify_human_governance_review_signoff.sh` | no | n/a | PASS | Reads branch-scoped approval evidence but does not mutate Git state. Included because it validates branch-scoped truth surfaces affected by rebases/merges. |
| `scripts/audit/verify_remediation_trace.sh` | no | n/a | PASS | Uses range-diff Git helpers only; no Git mutation. Included because it gates production-affecting branches after Git-surface fixes. |
| `scripts/audit/verify_remediation_artifact_freshness.sh` | no | n/a | PASS | Uses range-diff Git helpers only; no Git mutation. Enforces remediation/task freshness for guarded execution surface changes. |
| `scripts/audit/bootstrap_local_ci_toolchain.sh` | no | n/a | PASS | No Git mutation; included because it was a major local hook bottleneck during containment remediation. |

| `scripts/audit/lib/approval_requirement.py` | yes | partial | PASS | Computes Git diff requirements for approval coverage; relies on caller hygiene rather than mutating refs itself. |
| `scripts/audit/migrate_task_meta_to_v1.py` | yes | partial | PASS | Historical migration helper that shells out to Git for repo-state-aware updates; not used in guarded execution. |
| `scripts/audit/preflight_structural_staged.sh` | yes | partial | PASS | Uses Git staging/index state in preflight logic; no disposable repo mutation path remains. |
| `scripts/audit/tests/test_approval_metadata_requirements.sh` | yes | partial | PASS | Test fixture creates temporary commit state for approval metadata validation. |
| `scripts/audit/verify_agent_conformance.sh` | yes | partial | PASS | Reads branch-diff/approval state and depends on explicit ref sync in `pre_ci`. |
| `scripts/audit/verify_diff_semantics_parity.sh` | yes | partial | PASS | Reads parity fixture results and Git range state without mutating caller refs. |
| `scripts/audit/verify_history_secret_scan_report_present.sh` | yes | partial | PASS | Reads Git history/report presence via Git commands only. |
| `scripts/audit/verify_invariants_local.sh` | yes | partial | PASS | Local wrapper reads Git state and delegates to verifiers; no uncontained mutation path. |
| `scripts/audit/verify_tsk_p1_062.sh` | yes | partial | PASS | Worktree hygiene verifier reads Git worktree registry and enforces no stale/prunable entries. |
| `scripts/audit/verify_tsk_p1_076.sh` | yes | partial | PASS | Verifies installed hook files in `.git/hooks` against tracked `.githooks/*` sources after running the canonical hook installer. |
| `scripts/audit/verify_tsk_p1_248.sh` | yes | partial | PASS | Uses an isolated detached worktree plus an empty commit to prove deterministic git identity clamping across a HEAD change without mutating the caller worktree. |
| `scripts/audit/tests/test_verify_human_governance_review_signoff.sh` | yes | partial | PASS | Creates a synthetic adjacent-doc commit in a temporary repo snapshot to prove governance signoff evidence is stable across unrelated branch churn. |
| `scripts/audit/tests/test_evidence_validation_stability.sh` | yes | partial | PASS | Creates a synthetic adjacent-doc commit in a temporary repo snapshot to prove validation-family evidence outputs are stable across unrelated branch churn. |
| `scripts/audit/verify_tsk_p1_254.sh` | yes | partial | PASS | Uses an isolated temporary repo plus contained hook-disabled commits to inventory and rebaseline stale deterministic evidence without mutating the caller worktree. |
| `scripts/audit/verify_tsk_p1_255.sh` | yes | partial | PASS | Uses an isolated temporary repo plus a commit-between-runs proof to validate pre-push fixed-point convergence without mutating the caller worktree. |
| `scripts/audit/tests/test_zero_drift_pre_push.sh` | yes | partial | PASS | Exercises the commit-between-runs verifier in a temporary repo snapshot and asserts the fixed-point checks are present. |
| `scripts/audit/verify_tsk_p1_demo_020.sh` | yes | partial | PASS | Verifies the host-based demo runner's fetch/source-gate and single-active-run process controls by inspecting Git-sensitive orchestration surfaces without mutating caller refs. |
| `scripts/audit/verify_tsk_p1_demo_028.sh` | yes | partial | PASS | Verifies the demo image-build flow against host-based deployment guidance by inspecting Git-tracked runtime and Docker surfaces without mutating caller refs. |
| `scripts/audit/verify_tsk_p1_demo_030.sh` | yes | partial | PASS | Verifies the clean-branch task-line repair by checking local-main parity, canonical demo task identity, and repaired-branch approval scope without mutating caller refs. |
| `scripts/dev/capture_demo_server_snapshot.sh` | yes | partial | PASS | Captures branch/ref and `origin/main` posture for demo-run evidence; reads Git state only and relies on bounded output paths instead of mutating refs. |
| `scripts/dev/install_git_hooks.sh` | yes | partial | PASS | Installs hook files into `.git/hooks`; mutates local Git-related state and must remain explicitly operator-invoked. |
| `scripts/dev/run_demo_e2e.sh` | yes | partial | PASS | Fetches `origin` and gates clean deployment checkouts against `origin/main` before host-based demo execution; mutating remote-tracking state is contained to the explicit operator runner. |
| `scripts/lib/git_diff_range_only.sh` | yes | partial | PASS | Shared Git diff helper; safe only when callers control inherited Git plumbing. |
| `scripts/security/lint_app_sql_injection.sh` | yes | partial | PASS | Reads tracked/untracked file lists through Git; no ref mutation. |
| `scripts/audit/verify_migration_sequence.sh` | yes | partial | PASS | Uses git range diff strictly for validating the migration history chain cleanly without ref mutation. |
| `.githooks/pre-push` | yes | partial | PASS | Mutates no Git state during push interception. Added to audit to satisfy inventory completeness rule. |
| `scripts/agent/run_task.sh` | yes | partial | PASS | Runs git clean operations safely contained in tasks. Added to audit to satisfy inventory completeness rule. |
| `scripts/audit/reset_evidence_gate.sh` | yes | partial | PASS | Evidence gate reset helper; uses git reset strictly to restore evidence gate state in controlled remediation flows. No uncontained ref mutation path. |
| `scripts/audit/verify_enf_003b.sh` | yes | partial | PASS | ENF-003B verifier; reads reset_evidence_gate.sh installation state via git reset check; no mutation of caller refs. |
| `scripts/audit/verify_enf_005.sh` | yes | partial | PASS | ENF-005 verifier; checks DRD lockout sudo gate and casefile scaffolder via git reset pattern detection; read-only audit surface. |

## Findings
- The original containment failure class is now covered at both fixture and runner level.
- `git -C` alone is not treated as a sufficient boundary anywhere in the audited mutating fixture path.
- No additional mutable Git fixtures were found under `.githooks/` at audit time.
- `scripts/dev/pre_ci.sh` remains the highest-risk orchestrator because it materializes `origin/main` and drives guarded flows. That risk is now controlled by the explicit remote refspec and remediation freshness gate.

## Residual Risk
- New mutating scripts can still be introduced later without inventory coverage unless this audit remains wired into fast checks.
- Future disposable worktree helpers must keep `/tmp` hygiene and prunable-entry checks green.
