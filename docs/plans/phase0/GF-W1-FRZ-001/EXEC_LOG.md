# Execution Log: GF-W1-FRZ-001

- Governance documents correctly installed.
- Found ID collision between payment invariants (INV-135..145) and green finance invariants. Renumbered the green finance invariants to INV-159..169 across `NEUTRAL_HOST_INVARIANT_ENTRIES.md` and all GF-W1 tasks.
- Appended INV-159..169 as roadmap entries into `INVARIANTS_MANIFEST.yml`.
- `verify_core_contract_gate.sh` required a regex fix (`grep -e`) to parse negative checks.
- `verify_task_meta_schema.sh` required a type conversion fix (int schema_version -> str) and an exception for `pilot_scope_ref: not_applicable`.
- `bash scripts/audit/verify_core_contract_gate.sh --fixtures` passed all 8 fixtures.
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --task GF-W1-FRZ-001` passed.
- `evidence/phase0/core_contract_gate.json` successfully emitted.
