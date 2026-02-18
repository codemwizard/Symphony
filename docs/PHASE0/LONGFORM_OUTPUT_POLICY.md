# Long-Form Output Policy (Chat vs File)

## Purpose

Some CLI chat UIs truncate or clip streamed output, which can silently drop critical sentences in long (and sometimes short) responses.
This policy defines an **opt-in** mechanism for producing **long-form content as repo files** while keeping **chat output short**.

## Default Mode

**OFF by default.**

When OFF:
- Chat responses may include long-form content.
- No requirement to write long responses to disk.

## Toggle (Opt-In)

Set this environment variable to enable file-first long-form output:

```bash
export SYMPHONY_LONGFORM_TO_FILE=1
```

To disable (return to default):

```bash
unset SYMPHONY_LONGFORM_TO_FILE
```

## Behavior When Enabled

When `SYMPHONY_LONGFORM_TO_FILE=1`:
- The assistant MUST write long-form content to a `.md` file in one of:
  - `docs/PHASE0/` (phase policy, closeout, narratives)
  - `docs/plans/phase0/<casefile>/` (task plans, execution logs, remediation casefiles)
- The assistant MUST print **only a short summary in chat**:
  - file path(s) written
  - 3–7 bullets maximum
  - next command(s) to run (if applicable), on 1–3 lines

## What Counts As “Long-Form”

Any response that is likely to exceed a CLI viewport or is audit-relevant should be treated as long-form. In practice, if any of these apply, write to file:
- More than ~20 lines of prose
- Detailed audit reports, compliance mappings, regulator narratives
- Plans with many tasks, checklists, or matrices
- Any response that includes multi-step procedures with rationale

When in doubt: **write to file**.

## File Placement Rules

Use the smallest-scope location that matches the content:
- `docs/PHASE0/`:
  - policies and repo-wide procedures
  - Phase-0 closeout documents
  - narratives intended for auditors/regulators
- `docs/plans/phase0/<TSK-...>/`:
  - `PLAN.md` and `EXEC_LOG.md` content that belongs to a specific task
- `docs/plans/phase0/<REM-...>/`:
  - remediation trace casefiles

## Naming Conventions

- Policy documents: `docs/PHASE0/<TOPIC>_POLICY.md`
- Reports: `docs/PHASE0/<TOPIC>_REPORT.md`
- Task artifacts: `docs/plans/phase0/<TSK-ID>_<slug>/{PLAN.md,EXEC_LOG.md}`
- Remediation artifacts: `docs/plans/phase0/<REM-date>_<slug>/{PLAN.md,EXEC_LOG.md}`

## Chat Summary Template (When Enabled)

Include, in order:
1. File written: `<path>`
2. Summary bullets (3–7)
3. Commands to verify (optional)

Example:

```text
Wrote: docs/PHASE0/EXAMPLE_REPORT.md
- Finding A: ...
- Finding B: ...
- Next: ...

Verify:
- bash scripts/dev/pre_ci.sh
```

## Non-Goals

- This policy does not change mechanical gates or CI behavior.
- This policy does not require new scripts unless a specific plan/task introduces enforcement.

