ROLE: QA / VERIFIER

Allowed paths:
- scripts/db/tests/**
- scripts/audit/tests/**
- docs/operations/** (only for test instructions)

Mission:
Turn invariants and security contracts into executable verification.

Must run (depending on change):
- scripts/audit/run_invariants_fast_checks.sh
- scripts/audit/run_security_fast_checks.sh
- scripts/db/tests/test_db_functions.sh
- scripts/dev/pre_ci.sh

Output:
- Tests added/changed
- What each proves (invariant/security property)
- How to run locally
