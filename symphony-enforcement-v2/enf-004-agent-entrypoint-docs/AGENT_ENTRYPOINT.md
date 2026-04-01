# Agent Entrypoint (Canonical)

Read this file first on every session start, before modifying repository files.

## Pre-Step -- Check for Rejection Context, DRD Lockout, and Evidence Ack

Before mode classification, check for `.agent/rejection_context.md`.

If it exists:
1. Read it fully -- it contains the real failure reason and artifact paths.
2. Check `DRD_STATUS` in the file:
   - If `DRD_STATUS: ACTIVE_LOCKOUT` -- you are mechanically blocked from running
     `pre_ci.sh` (exits 99) and `run_task.sh` (exits 99). You MUST create the
     remediation casefile using the `DRD_SCAFFOLD_CMD` shown in the file, then
     clear the lockout with `bash scripts/audit/verify_drd_casefile.sh --clear`.
     Do not attempt to remove the lockout file directly.
   - If `DRD_STATUS: NOT_ACTIVE` -- default to REMEDIATE mode unless the human
     explicitly states otherwise.
3. Check for evidence ack gate state:
   - If `.toolchain/evidence_ack/<TASK_ID>.required` exists, `run_task.sh` will
     exit 51 on the next run until you write a valid ack file. Read the failure
     artifacts first, then create the ack file as directed by the exit message.
   - If the retry count is >= 3, `run_task.sh` will exit 50 (hard block). A human
     must run `bash scripts/audit/reset_evidence_gate.sh <TASK_ID>` to clear it.
4. Do not begin new implementation work until the prior failure is resolved.
5. The artifact paths in the file are the source of truth -- do not infer or
   assume what they contain.

If it does not exist: proceed to Step 1 normally.

---

## Step 1 -- Determine the operating mode

Before writing any file, determine which mode applies.
See: `docs/operations/AGENT_PROMPT_ROUTER.md`

Permitted modes:
- CREATE-TASK
- RESUME-TASK
- IMPLEMENT-TASK
- REMEDIATE
- PUSH-READY-CHECK

Mode selection may use non-mutating inspection of the repository to resolve
discoverable facts, such as whether `tasks/<TASK_ID>/meta.yml` exists or
whether a referenced task is already partially created.

If the prompt still does not map to exactly one mode after non-mutating
inspection: STOP. Ask the human which mode applies. Do not guess.

## Step 2 -- Execute the selected mode

Follow `docs/operations/AGENT_PROMPT_ROUTER.md` for the selected mode.
The boot sequence below applies only to IMPLEMENT-TASK mode.

## Boot Sequence (IMPLEMENT-TASK mode only)

1. Stop if current branch is `main`.
2. Run conformance gate:
   `scripts/audit/verify_agent_conformance.sh`
3. Run local parity gate:
   `scripts/dev/pre_ci.sh`
4. Run task:
   `scripts/agent/run_task.sh <TASK_ID>`

If any step fails: stop immediately and open or update remediation trace.
Do not retry without remediation discipline.

## Canonical References

- `docs/operations/AGENT_PROMPT_ROUTER.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/POLICY_PRECEDENCE.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
