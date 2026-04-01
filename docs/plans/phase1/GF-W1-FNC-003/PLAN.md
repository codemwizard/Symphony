# PLAN: GF-W1-FNC-003

[ID gf_w1_fnc_003]

## Objective
To implement `attach_evidence` and `link_evidence_to_record` logic for cryptographic lineage binding.

## Execution Details
Establishes the capability to natively capture evidence proofs from adapter layers and explicitly link them into the `project_evidence` and `evidence_edges` graphs safely through parameters. Requires `SECURITY DEFINER` constraints on `0109_gf_fn_evidence_lineage.sql`.

## Constraints
- Must not modify any core schema tables from Phase 0 directly.

## Verification
A dedicated bash verifier will inspect the SQL output mathematically to ensure `SECURITY DEFINER` logic is correctly formed and will emit success JSON.
