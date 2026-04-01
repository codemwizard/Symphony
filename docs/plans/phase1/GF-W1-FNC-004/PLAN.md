# PLAN: GF-W1-FNC-004

[ID gf_w1_fnc_004]

## Objective
To implement `record_authority_decision` and `attempt_lifecycle_transition` logic so that status changes are cryptographically and operationally governed.

## Execution Details
Establishes the capability to record verifier and issuer authority decisions against batches, and safely attempt state transitions. Requires `SECURITY DEFINER` constraints on `0110_gf_fn_regulatory_transitions.sql`.

## Constraints
- Must not modify any core schema tables from Phase 0 directly.

## Verification
A dedicated bash verifier will inspect the SQL output mathematically to ensure `SECURITY DEFINER` logic is correctly formed and will emit success JSON.
