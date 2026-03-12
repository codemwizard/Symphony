# Evidence Churn Cleanup Policy v3.3

## Summary

This policy defines how to clean a dirty working tree before a branch-batch
commit without deleting canonical proof artifacts.

In Symphony, cleanup is:
- batch-aware
- regulated-surface-aware
- fail-closed

The goal is not to make the tree look clean.
The goal is to preserve the proof set for the active branch batch and remove
only incidental local churn.

## Core Rule

A branch must preserve proof, not side effects.

For the active branch batch:
- keep all canonical proof artifacts
- keep all approval-linked artifacts
- keep all intentionally refreshed canonical artifacts
- delete only incidental, unreferenced, reproducible local-only outputs that
  are not declared branch deliverables

If a file is tracked, referenced, approval-linked, or plausibly canonical, it
is not deleted until ownership is confirmed.

## Primary Concept: Keep-Set

Before deleting anything, compute the keep-set.

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

### Generated Churn: delete

Delete a file only if all of the following are true:
- it is untracked
- it is not in the keep-set
- it is not referenced by task packs, plans, registry, or approvals
- it was created by exploratory, incidental, or local-only command execution
- it does not supersede a canonical artifact

### Ambiguous Evidence: inspect first

Inspect before deleting if any of the following are true:
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

Tracked files are not silently deleted for cleanliness.

## Deletion Predicate

A file may be deleted only if this predicate is fully true:

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

If any term is false or unknown, do not delete.

## Required Cleanup Process

Before cleanup:
1. identify the active branch batch
2. if the batch is wave-based, identify the active wave
3. compute the keep-set
4. inspect tracked modified evidence
5. delete only files that satisfy the deletion predicate
6. re-run `git status --short`
7. confirm the remaining evidence matches the batch deliverable

Do not start with deletion.
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
- `scripts/ci/clean_evidence.sh` must not be run blindly on a mixed working
  tree.
- cleanup must happen on an approved feature branch, never on `main`.

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
- proof stays
- noise goes
- tracked or ambiguous artifacts are inspected, not guessed
