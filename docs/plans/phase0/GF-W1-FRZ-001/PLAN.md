# Plan: GF-W1-FRZ-001

**Task:** Merge governance package v2 to establish green finance policy baseline
**Status:** Completed

## Steps
1. Copy governance files into `docs/operations/`.
2. Add Green Finance invariant entries into `INVARIANTS_MANIFEST.yml` (renumbered to avoid collision: INV-159 to INV-169).
3. Replace `verify_core_contract_gate.sh` and `verify_task_meta_schema.sh` with the fixed v2 versions.
4. Run self-tests and confirm all fixtures pass.
5. Generate evidence JSON for the core contract gate.
