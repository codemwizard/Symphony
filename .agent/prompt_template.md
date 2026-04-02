# Symphony Agent Prompt Template
# TARGET: .agent/prompt_template.md
#
# PURPOSE: Standardises every agent invocation. The five sections ensure
# that the four things most subject to context decay are always present:
# (1) rejection context, (2) file scope, (3) system invariants, (4) stop rules.
# Everything else defers to meta.yml to avoid two sources of truth.

---

## REJECTION CONTEXT
[If .agent/rejection_context.md exists, paste its FULL contents here.]
[If it does not exist, write: NONE -- no prior failure in this session.]
[If DRD_STATUS is ACTIVE_LOCKOUT: do not proceed past this section until casefile
 is created and lockout cleared with: bash scripts/audit/verify_drd_casefile.sh --clear]

---

## TASK
TASK_ID: [e.g. GF-W1-SCH-002A]
Read the full task contract at: tasks/[TASK_ID]/meta.yml

Do not re-state all meta.yml fields here -- read the file directly.
The meta.yml is the source of truth. This prompt does not override it.

---

## ALLOWED FILES
[Copy the `touches` list from meta.yml EXACTLY -- one path per line.]
[You may not modify any file not on this list.]
[Scope drift = immediate STOP and report to human.]

---

## SYSTEM INVARIANTS
These are re-stated every invocation because they are subject to context decay.

- NEVER interact with main branch in any form (checkout, push, pull, reset, merge, rebase).
- NEVER suppress command output (>/dev/null). All output must be captured as artifacts.
- NEVER assume a command succeeded without reading its stdout/stderr artifact.
- NEVER fabricate evidence or approval hashes. SHA256 hex (64 lowercase chars) only.
- NEVER modify governance files (.githooks/, scripts/audit/, scripts/dev/pre_ci.sh,
  scripts/agent/run_task.sh, .github/workflows/) without explicit human approval.
- STOP on ambiguity -- incomplete work is always preferred over incorrect work.
- All execution must go through run_task.sh.
- If DRD lockout is active: create casefile FIRST, then clear with verify_drd_casefile.sh --clear.
- Never use raw rm to clear lockout or evidence gate files.

---

## EXECUTION RULES
- If command output is not explicitly present in stdout/stderr artifacts: assume FAILURE.
- If verification fails: stop, read artifacts, enter REMEDIATE mode.
- If this is your second failed attempt on the same signature: DRD Full is mandatory.
  Do not retry. Do not modify the failing script. Create the casefile first.
- If the same failure signature occurs twice, consult docs/operations/failure_index.md
  before attempting any fix -- prior incidents for that signature are indexed there.
- Do not modify files outside the ALLOWED FILES list above.
- Do not run pre_ci.sh if a DRD lockout file exists at .toolchain/pre_ci_debug/drd_lockout.env.
- If run_task.sh exits 51 (evidence ack required): read the failure artifacts at
  tmp/task_runs/<TASK_ID>/ then write the ack file as directed before retrying.
- If run_task.sh exits 50 (retry hard block): do not attempt to reset yourself.
  Report to the human -- only they may run reset_evidence_gate.sh.

---

## EXPECTED ARTIFACTS
[List the evidence paths from meta.yml evidence: field.]
[These must exist and be fresh (matching current RUN_ID) before task can be marked completed.]

---

## FAILURE REGISTRY REFERENCE
If your failure matches a known signature, check the playbook before guessing:
- docs/operations/failure_index.md  -- searchable index of all prior incidents
- docs/operations/failure_signatures.yml  -- signatures with playbook links
- docs/troubleshooting/  -- per-signature diagnostic guides
