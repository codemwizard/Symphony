# Evidence Churn Cleanup Policy v3.4

## Summary

This policy defines how to prepare a dirty working tree for a branch-batch
commit without permanently deleting or losing canonical proof artifacts and local exploratory files.

In Symphony, cleanup is:
- batch-aware
- regulated-surface-aware
- fail-closed

The goal is not to make the tree look clean.
The goal is to preserve the proof set for the active branch batch and safely exclude
incidental local churn from the commit, leaving it untracked or unstaged rather than permanently deleting it.

## Core Rule

A branch must preserve proof, not side effects.

For the active branch batch:
- keep all canonical proof artifacts
- keep all approval-linked artifacts
- keep all intentionally refreshed canonical artifacts
- exclude incidental, unreferenced, reproducible local-only outputs from the commit (leave them untracked or unstaged).
- **never use `rm`, `git clean -df`, or permanent deletion commands during active development.**

If a file is tracked, referenced, approval-linked, or plausibly canonical, it
is never excluded from the commit or deleted until ownership is explicitly confirmed.

## Primary Concept: Keep-Set

Before excluding anything from a commit, compute the keep-set.

The keep-set is the complete set of files that must remain in the branch
because they prove the active batch.

Build the keep-set from:
1. active batch task packs
   Source:
   - `tasks/**/meta.yml`
2. active batch planning and execution docs
   Source:
   - `docs/plans/**/PLAN.md`
   - `docs/plans/**/EXEC_LOG.md`
3. verifier registry
   Source:
   - `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`
4. approval artifacts
   Source:
   - `evidence/phase1/approval_metadata.json`
   - `approvals/**`
5. intentionally refreshed canonical artifacts required by the batch

If a file is in the keep-set, it stays.

Approval-linked artifacts are always in the keep-set for the active batch.

## Evidence Classes

### Canonical Evidence: keep

Keep a file if any of the following is true:
- it is declared in `meta.yml` for a task in the active batch
- it is referenced by the active batch `PLAN.md` or `EXEC_LOG.md`
- it is emitted by a verifier registered for the active batch
- it is approval evidence
- it is a canonical artifact intentionally refreshed by the active batch
- it is required for a verifier or governance gate to pass truthfully

### Generated Churn: exclude (Do Not Delete)

Exclude a file from the active commit (leave it untracked) only if all of the following are true:
- it is untracked
- it is not in the keep-set
- it is not referenced by task packs, plans, registry, or approvals
- it was created by exploratory, incidental, or local-only command execution
- it does not supersede a canonical artifact

### Ambiguous Evidence: inspect first

Inspect before excluding a file from the commit if any of the following are true:
- the file is tracked
- the file is under `evidence/**`
- the file is referenced from task packs, plans, registry, or approvals
- the filename matches a canonical task-evidence pattern
- the file may supersede an existing canonical artifact
- the file is linked to approval metadata or regulated-surface changes

## Tracked Evidence Rule

Tracked evidence is never treated as disposable churn.

If a tracked evidence file is removed, replaced, or superseded, that action
must be:
- intentional
- justified by the active batch
- recorded in the batch log or remediation notes

Tracked files are not silently excluded or permanently deleted for cleanliness.

## Exclusion Predicate

A file may be excluded from the commit (left untracked) only if this predicate is fully true:

- `untracked == true`
- `in_keep_set == false`
- `referenced == false`
- `approval_linked == false`
- `canonical_candidate == false`
- `supersedes_canonical == false`

Where `canonical_candidate == true` if any of these are true:
- the file is tracked and located under `evidence/**`
- the file is approval-linked evidence for the active batch
- the file is referenced by `meta.yml`, `PLAN.md`, `EXEC_LOG.md`, verifier
  registry, or approvals
- the filename matches declared evidence naming for an active-batch task
- the file appears to replace an existing tracked evidence artifact

If any term is false or unknown, do not exclude it without manual inspection. Never permanently delete it.

## Branch-Wide Non-Churn Rule

Batch scoping is a keep-set construction tool, not permission to ignore older
intentional branch work.

After computing the active-batch keep-set, inspect the full branch worktree and
classify every modified file into exactly one of these states:
- `commit_now`
- `leave_unstaged_as_churn`
- `stop_for_manual_ownership_review`

A file must be classified as `commit_now` if all of the following are true:
- it does not satisfy the churn exclusion predicate
- it is intentional branch work rather than incidental local output
- it belongs to the current feature branch's deliverable set, even if it
  predates the most recent remediation, verifier run, or sub-batch

The agent must not treat valid branch work as disposable merely because:
- it is outside the most recent active batch
- it was created before the latest remediation case
- it is not required to satisfy the newest narrow verifier failure
- the branch name or most recent task suggests a smaller local commit scope

If a file is neither provable churn nor provably unrelated to the branch, do
not leave it behind silently. Either include it in an intentional branch commit
or stop for manual ownership review.

## Required Cleanup Process

Before cleanup:
1. identify the active branch batch
2. if the batch is wave-based, identify the active wave
3. compute the keep-set
4. inspect the full branch worktree, not just the newest task or remediation slice
5. classify every modified file as `commit_now`, `leave_unstaged_as_churn`, or `stop_for_manual_ownership_review`
6. inspect tracked modified evidence
7. leave untracked or unstage files that satisfy the exclusion predicate (DO NOT use `rm`)
8. re-run `git status --short`
9. confirm the staged set contains all non-churn branch work intended for the branch deliverable, not merely the newest batch subset

Do not start with exclusion or deletion.
Start with keep-set construction.

If ownership of an evidence file cannot be determined from the keep-set and
references, stop cleanup and inspect manually.

## Safe Command Discipline

Minimum inspection commands:

```bash
git status --short
```

For a candidate file:

```bash
rg -n "<filename>|approval_metadata|<task_id>" tasks docs approvals scripts evidence
```

For batch evidence discovery:

```bash
rg -n "evidence/phase1/" tasks docs/plans docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml approvals
```

Do not run broad cleanup commands against `evidence/**` unless the keep-set
has already been computed.

## Repo-Specific Constraints

- `evidence/**` is a regulated surface.
- approval metadata is canonical evidence, not noise.
- branch-batch commits preserve the proof set for that batch, not every
  artifact ever generated locally.
- batch-aware cleanup does not authorize leaving intentional non-churn branch
  deliverables uncommitted just because they are outside the newest sub-batch.
- `scripts/ci/clean_evidence.sh` must not be run blindly on a mixed working
  tree.
- cleanup must happen on an approved feature branch, never on `main`.
- `rm` and `git clean` are strictly prohibited during the active commit preparation lifecycle.

## The Safe Lifecycle for Permanent Deletion

A clean work tree is ONLY to be cleared or permanently cleaned up *after* the following conditions are met:
1. The branch-batch commit has been successfully created locally.
2. The commit has been pushed to the remote repository (`origin`).
3. The branch has been successfully merged into the canonical `main` branch.
4. The local repository has performed a `git fetch` and `git merge` (or `git pull`) on the local `main` branch to synchronize with the remote.

Only after this confirmed synchronization with the merged `main` state is it safe to permanently delete lingering untracked local "noise" files.

## Final Standard

A branch batch should contain only:
- code and docs required for the batch
- approval artifacts required for the batch
- evidence that proves the batch truthfully

It should not contain:
- unrelated prior-batch evidence churn
- exploratory local outputs
- duplicate unreferenced snapshots
- temporary generated artifacts with no canonical role

In short:
- proof stays in the commit
- noise is excluded from the commit (but kept on disk)
- non-churn branch work is classified and committed intentionally, even when it
  predates the newest narrow batch
- tracked or ambiguous artifacts are inspected, not guessed
- permanent deletion happens only after a confirmed remote merge
