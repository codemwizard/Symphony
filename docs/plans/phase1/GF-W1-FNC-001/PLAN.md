# PLAN: GF-W1-FNC-001

[ID gf_w1_fnc_001]

## Objective
To implement `register_project` and `activate_project` foundation functions, establishing the origin event for green finance tracking.

## Execution Details
This task will create database migrations housing `SECURITY DEFINER` hardened functions. The implementations will interact with the `projects` table built in `0097_gf_projects.sql`.

## Constraints
- Must not modify any core schema tables from Phase 0 directly.
- Functions must execute only via configured operational roles.

## Verification
A dedicated bash verifier will inspect the SQL output mathematically to ensure `SECURITY DEFINER` logic is correctly formed and will emit success JSON.
