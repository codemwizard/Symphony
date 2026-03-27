# Plan: GF-W1-FRZ-002

**Task:** Wire pilot containment policy into AGENTS.md as a hard agent constraint
**Status:** Completed

## Steps
1. Append pilot containment policy hard constraint into `AGENTS.md` (section `Hard constraints`).
2. Append `AGENTIC_SDLC_PILOT_POLICY.md`, `PILOT_REJECTION_PLAYBOOK.md`, `AGENT_GUARDRAILS_GREEN_FINANCE.md` to the `Must read` list of the DB Foundation Agent and Invariants Curator Agent.
3. Verify changes with grep.
4. Verify changes don't break CI by running `pre_ci.sh`.
5. Write execution log and evidence record.
