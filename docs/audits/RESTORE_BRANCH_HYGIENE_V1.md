# RESTORE_BRANCH_HYGIENE_V1

## Purpose
Define a deterministic branch-hygiene process before running the full restoration program, so hidden branch-only functionality is not lost and restoration starts from a clean, auditable branch topology.

## Regression cause analysis (why this happened)
1. Scope de-sync between implementation and contract
- Previously implemented pilot/hardening capabilities were deleted while related expectations existed in historical docs/tests.
- Result: practical capability regression even when current contract still passed.

2. Mixed branch history and integration complexity
- Multiple long-lived local branches (`feature`, `integration`, `backup`, `master`, and a local branch named `origin/main`) increased confusion over true source-of-truth history.
- Result: harder to reason about what is merged vs branch-local.

3. Lack of enforced branch hygiene checkpoints
- No mandatory archival + unique-commit inventory before branch cleanup.
- Result: risk of hidden functionality being dropped during local cleanup.

4. Contract-first placeholder risk
- Adding required contract items before verifiers/evidence exist can create dangling or fake-green states.
- Result: CI instability or drift.

5. Migration restoration complexity
- Deleted migrations (`0032`, `0033`) cannot be naively restored without compatibility planning.
- Result: potential double-apply hazards in environments with divergent state.

## Branch-hygiene target state
- Keep only:
1. `main`
2. One major restoration branch: `feature/full-restoration-program`
3. Short-lived stage branches: `feature/restoration-prN-*` (created per PR, deleted after merge)

## Branch-hygiene process (explicit)
1. Capture branch inventory
- Save `git branch -vv` and a per-branch unique-commit report (`main..branch`).

2. Preserve recovery points before deletion
- Create immutable archive tags for every local branch tip:
  - format: `archive/branch-<sanitized_branch_name>-<date>`
- Create a full repository bundle:
  - `git bundle create /tmp/symphony-branch-archives/symphony_all_refs_<date>.bundle --all`

3. Normalize `main` tracking
- Remove misleading local branch named `origin/main` if present.
- Re-fetch remote-tracking `refs/remotes/origin/main`.
- Set upstream of local `main` to `origin/main`.

4. Create major restoration branch
- Create `feature/full-restoration-program` from `main`.

5. Prune non-target local branches (after archival only)
- Delete all branches except:
  - `main`
  - `feature/full-restoration-program`
- Future stage branches are disposable and should be removed after PR merge.

6. Emit post-cleanup proof
- Save post-hygiene branch list, archive tag list, and bundle path.

## Safety guarantees
- No branch deletion before:
  - archive tag created,
  - bundle created,
  - unique-commit report captured.
- Any deleted branch tip is recoverable via archive tag or bundle.

## What this process does not do
- It does not rewrite remote history.
- It does not auto-merge hidden commits.
- It does not restore deleted functionality by itself; it only creates a safe starting topology for restoration PRs.

## Operational handoff into restoration
After branch hygiene:
1. Work only on `feature/full-restoration-program` and stage branches.
2. Execute staged restoration PRs in planned order (PR-1..PR-8).
3. Require `scripts/dev/pre_ci.sh` pass on each stage before PR merge.

## Artifacts generated in this cleanup run
- `docs/audits/branch_hygiene/branch_inventory_2026-02-18.txt`
- `docs/audits/branch_hygiene/unique_commits_vs_main_2026-02-18.md`
- `docs/audits/branch_hygiene/post_hygiene_summary_2026-02-18.txt`
- `/tmp/symphony-branch-archives/symphony_all_refs_2026-02-18.bundle`

