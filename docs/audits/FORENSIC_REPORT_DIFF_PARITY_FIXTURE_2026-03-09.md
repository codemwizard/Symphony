# Forensic Report: Diff Semantics Parity Fixture Worktree Escape

Date: 2026-03-09  
Reporter: Codex Supervisor  
Scope: `scripts/audit/test_diff_semantics_parity.sh` and its invocation path from `scripts/audit/run_phase0_ordered_checks.sh`

## Executive Summary

During execution of the Phase-0 ordered checks from a temporary worktree used for the `TSK-P1-019..024` batch, the parity fixture that is supposed to operate inside a disposable repository produced repository state that matched its test fixture on the caller worktree instead of remaining isolated.

The observable failure signature was:

- branch changed to `feature`
- new commits with messages:
  - `baseline`
  - `committed change`
- fixture files appeared in the contaminated worktree:
  - `file.txt`
  - `staged_only.txt`

The fixture script itself was written to use `git -C "$tmp_dir"` and looked isolated on paper. Tracing showed the actual escape mechanism was inherited Git plumbing state. In hostile Git environments, `git -C` is not sufficient if `GIT_DIR` and `GIT_WORK_TREE` are inherited from the parent shell or hook context.

The fix was to quarantine the fixture by explicitly clearing Git plumbing variables for:

- every Git call inside the fixture
- the nested shell that sources `scripts/lib/git_diff_range_only.sh`
- the Phase-0 runner that invokes the fixture

## Incident Conditions

The issue was observed while running local guarded checks from a temporary worktree created for the `TSK-P1-019..024` implementation batch.

Known execution context:

- parent repo path: `/home/mwiza/workspace/Symphony`
- contaminated temp worktree path: `/tmp/Symphony_batch_019_024_fresh`
- fixture under investigation:
  - `scripts/audit/test_diff_semantics_parity.sh`
- calling path:
  - `.githooks/pre-push`
  - `scripts/dev/pre_ci.sh`
  - `scripts/audit/run_phase0_ordered_checks.sh`
  - `scripts/audit/test_diff_semantics_parity.sh`

At the time of investigation, the primary repo itself also had a damaged Git config state:

- `.git/config` contained `core.bare=true`
- `.git/config` contained temporary CI identity values:
  - `user.name=CI`
  - `user.email=ci@example.com`

Those were not valid steady-state repo settings and were repaired during containment.

## Software and Hardware Environment

Collected from the live host on 2026-03-09:

- Date:
  - `Mon Mar 9 13:14:25 UTC 2026`
- Kernel:
  - `Linux symphony 6.8.0-101-generic #101-Ubuntu SMP PREEMPT_DYNAMIC Mon Feb 9 10:15:05 UTC 2026 x86_64`
- OS:
  - `Ubuntu 24.04.4 LTS (Noble Numbat)`
- Git:
  - `git version 2.43.0`
- Bash:
  - `GNU bash, version 5.2.21(1)-release`
- Python:
  - `Python 3.12.3`
- Docker:
  - `Docker version 29.2.1, build a5c7197`
- CPU:
  - `Intel(R) Core(TM) i5-2450M CPU @ 2.50GHz`
  - `4` logical CPUs
  - x86_64

## Impact

### Direct Impact

The disposable batch worktree at `/tmp/Symphony_batch_019_024_fresh` was corrupted with fixture state unrelated to the intended task batch.

Observed state:

- branch: `feature`
- reflog entries:
  - `commit: baseline`
  - `checkout: moving from main to feature`
  - `commit: committed change`
- fixture file state:
  - `D file.txt`
  - `D staged_only.txt`

### Secondary Impact

The main repository at `/home/mwiza/workspace/Symphony` was also left with invalid local Git plumbing:

- `core.bare=true`
- `user.name=CI`
- `user.email=ci@example.com`

That state prevented ordinary `git status` and other worktree operations until repaired.

## Evidence

### 1. Contaminated Worktree Reflog

From `/tmp/Symphony_batch_019_024_fresh`:

```text
c8852db0 HEAD@{2026-03-09 12:48:44 +0000}: commit (amend): committed change
b7a55982 HEAD@{2026-03-09 12:45:30 +0000}: commit: committed change
bfc1ecc5 HEAD@{2026-03-09 12:45:30 +0000}: checkout: moving from main to feature
bfc1ecc5 HEAD@{2026-03-09 12:45:30 +0000}: Branch: renamed refs/heads/phase1/batch-019-020-022-023-024-fresh to refs/heads/main
bfc1ecc5 HEAD@{2026-03-09 12:45:30 +0000}: commit: baseline
```

These strings exactly match the fixture actions in `scripts/audit/test_diff_semantics_parity.sh`.

### 2. Contaminated Worktree Status

From `/tmp/Symphony_batch_019_024_fresh`:

```text
## feature
...
D file.txt
D staged_only.txt
?? services/ledger-api/dotnet/src/LedgerApi/evidence/
```

The deleted `file.txt` and `staged_only.txt` names exactly match the fixture file names.

### 3. Broken Main Repo Git Config

Observed in `/home/mwiza/workspace/Symphony/.git/config` before repair:

```ini
[core]
    bare = true
...
[user]
    email = ci@example.com
    name = CI
```

This state is not valid for a normal local working tree and materially changes Git command behavior.

## Full Trace Performed

### Trace A: Fixture in Normal Environment

Command:

```bash
bash -x scripts/audit/test_diff_semantics_parity.sh
```

Result:

- fixture passed
- temporary repo was isolated
- output:
  - `Diff semantics parity fixtures passed.`

Important trace excerpt:

```text
+ mktemp -d
+ git -C /tmp/tmp.jtLnKetC8a init -q
+ git -C /tmp/tmp.jtLnKetC8a config user.email ci@example.com
+ git -C /tmp/tmp.jtLnKetC8a config user.name CI
+ git -C /tmp/tmp.jtLnKetC8a branch -M main
+ git -C /tmp/tmp.jtLnKetC8a checkout -q -b feature
+ bash -lc 'source .../git_diff_range_only.sh; cd /tmp/tmp.jtLnKetC8a; git_changed_files_range "$BASE_REF" "$HEAD_REF"'
```

Conclusion:

- the script logic is not intrinsically broken under clean shell conditions

### Trace B: Hostile Git Plumbing Reproduction

Command used to reproduce the mechanism:

```bash
export GIT_DIR=/home/mwiza/workspace/Symphony/.git
export GIT_WORK_TREE=/home/mwiza/workspace/Symphony
BASE_REF=main HEAD_REF=HEAD bash -x scripts/audit/test_diff_semantics_parity.sh
```

Before the quarantine fix, inherited Git plumbing could redirect Git behavior away from the disposable repo.

After the quarantine fix, the same hostile-env reproduction passed and did not mutate the parent repo.

Verified post-fix:

```text
status=0
before_head=6e569cc4d6468e8f4438c0bb5d45fc71c9473925
after_head=6e569cc4d6468e8f4438c0bb5d45fc71c9473925
before_branch=fix/parity-fixture-quarantine
after_branch=fix/parity-fixture-quarantine
```

That proves containment.

## Root Cause

### Primary Root Cause

The fixture assumed that `git -C "$tmp_dir"` was enough to guarantee isolation.

That assumption is false when Git plumbing variables are inherited by the shell:

- `GIT_DIR`
- `GIT_WORK_TREE`
- `GIT_INDEX_FILE`
- `GIT_COMMON_DIR`
- `GIT_OBJECT_DIRECTORY`
- `GIT_ALTERNATE_OBJECT_DIRECTORIES`
- `GIT_PREFIX`

Git gives those variables precedence over ordinary working-directory discovery. In that state, the fixture can operate on the caller repo while appearing to target the disposable repo path.

### Contributing Factors

1. The fixture delegated part of its logic to a nested shell:

```bash
bash -lc "source '$ROOT_DIR/scripts/lib/git_diff_range_only.sh'; cd '$tmp_dir'; git_changed_files_range ..."
```

Without environment scrubbing, that nested shell inherited the same hostile Git plumbing.

2. The Phase-0 runner invoked the fixture without sanitizing Git plumbing:

- `scripts/audit/run_phase0_ordered_checks.sh`

3. The main repo itself was already in a damaged local config state:

- `core.bare=true`
- CI identity persisted in `.git/config`

That made diagnosis harder and increased the probability of surprising Git behavior.

## Exact Reproduction Procedure

This reproduces the dangerous mechanism safely in a controlled environment.

### Reproduction A: Demonstrate the Mechanism

```bash
cd /home/mwiza/workspace/Symphony

export GIT_DIR="$PWD/.git"
export GIT_WORK_TREE="$PWD"
BASE_REF=main HEAD_REF=HEAD bash -x scripts/audit/test_diff_semantics_parity.sh
```

Expected pre-fix risk:

- Git calls inside the fixture can resolve against the parent repo instead of the disposable repo

Expected post-fix result:

- fixture still passes
- parent repo branch and HEAD remain unchanged

### Reproduction B: Verify Containment

```bash
cd /home/mwiza/workspace/Symphony

before_head="$(git rev-parse HEAD)"
before_branch="$(git rev-parse --abbrev-ref HEAD)"

export GIT_DIR="$PWD/.git"
export GIT_WORK_TREE="$PWD"
BASE_REF=main HEAD_REF=HEAD bash -x scripts/audit/test_diff_semantics_parity.sh

after_head="$(git rev-parse HEAD)"
after_branch="$(git rev-parse --abbrev-ref HEAD)"

printf 'before_head=%s\nafter_head=%s\nbefore_branch=%s\nafter_branch=%s\n' \
  "$before_head" "$after_head" "$before_branch" "$after_branch"
```

Success criteria:

- `before_head == after_head`
- `before_branch == after_branch`
- fixture output contains:
  - `Diff semantics parity fixtures passed.`

## Fix Implemented

### File 1

`scripts/audit/test_diff_semantics_parity.sh`

Changes:

1. Added `GIT_ENV_UNSET` list clearing inherited Git plumbing.
2. Added `safe_git()` wrapper:

```bash
safe_git() {
  env "${GIT_ENV_UNSET[@]}" git "$@"
}
```

3. Replaced all fixture `git` calls with `safe_git`.
4. Added disposable-repo assertions:

```bash
tmp_git_dir="$(safe_git -C "$tmp_dir" rev-parse --absolute-git-dir)"
tmp_top="$(safe_git -C "$tmp_dir" rev-parse --show-toplevel)"
```

The script now aborts if:

- top-level repo is not exactly `"$tmp_dir"`
- git dir is not exactly `"$tmp_dir/.git"`

5. Sanitized the nested shell invocation used for `git_changed_files_range`.

### File 2

`scripts/audit/run_phase0_ordered_checks.sh`

Changed:

```bash
run env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_PREFIX scripts/audit/test_diff_semantics_parity.sh
```

This adds caller-side containment even if the fixture is executed from hooks or worktrees with inherited Git plumbing.

## Repo Repair Performed

The following repairs were required in the main repo before continued work:

```bash
git --git-dir=/home/mwiza/workspace/Symphony/.git --work-tree=/home/mwiza/workspace/Symphony config core.bare false
git -C /home/mwiza/workspace/Symphony config user.name codemwizard
git -C /home/mwiza/workspace/Symphony config user.email mwizapnyirenda@gmail.com
```

## Verification After Fix

Commands run:

```bash
bash scripts/audit/test_diff_semantics_parity.sh
bash scripts/audit/verify_diff_semantics_parity.sh
```

Results:

- `Diff semantics parity fixtures passed.`
- `Diff semantics parity verification passed.`

Hostile-env verification also passed with unchanged parent repo `HEAD` and branch.

## Residual Risk

1. The contaminated temp worktree still exists for forensics:
   - `/tmp/Symphony_batch_019_024_fresh`
2. The stale prunable worktree entry still exists:
   - `/tmp/symphony-t103-fix-HR0NqF`
3. Any other local fixtures that rely on `git -C` without scrubbing Git plumbing may have the same class of bug.

## Recommended Follow-Up

1. Add a regression test specifically for hostile Git plumbing inheritance.
2. Audit other scripts for unguarded `git -C` usage inside hooks or nested shells.
3. Remove or archive the contaminated temp worktree once forensic retention is no longer needed.
4. Recreate the `TSK-P1-019..024` batch from clean `main` after this quarantine branch is merged.

## Final Conclusion

This was a real containment failure class, not a false alarm.

The parity fixture was not adequately isolated against inherited Git plumbing. The contaminated worktree state and reflog prove that the fixture’s synthetic branch, commits, and files escaped into a real worktree context.

The implemented fix addresses the actual failure mode:

- scrub Git plumbing inside the fixture
- scrub Git plumbing at the Phase-0 runner call site
- assert disposable-repo identity before proceeding

That is the correct containment posture for a fixture that creates branches and commits as part of its test logic.
