# Execution Log: GF-W1-FRZ-002

- Verified `AGENTS.md` current structure.
- Modified `## Hard constraints` to explicitly require the green finance containment rule.
- Added the 3 required governance documents to the `Must read:` list under `### DB Foundation Agent` and `### Invariants Curator Agent`.
- Ran `grep -q "AGENTIC_SDLC_PILOT_POLICY" AGENTS.md` and `grep -q "PILOT_REJECTION_PLAYBOOK" AGENTS.md` which passed successfully.
- Triggered `pre_ci.sh` to ensure `AGENTS.md` formatting remains structurally intact.
- Wrote evidence file to `evidence/phase0/agents_md_green_finance_wiring.json`.
