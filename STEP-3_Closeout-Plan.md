# Step 3 Closeout Plan — Role-Boundary Proofs & Append-Only Proof

## Objective
Finalize Phase 3 by tightening role-boundary tests and ensuring append-only trigger proofs are distinct, deterministic, and audit-grade.

## Scope
- Outbox role-boundary proofs (A–E).
- Append-only trigger proof separation.
- Test hygiene (env handling, deterministic data).
- Privilege model alignment with tests.

## Fixes and Improvements to Implement

### 1) Split role-boundary vs trigger-proof tests
- **Role-boundary test**: executor UPDATE/DELETE on `payment_outbox_attempts` must assert **`42501`** only.
- **Trigger-proof test**: run UPDATE/DELETE as a privileged principal (DB owner via `queryNoRole`) and assert **`P0001`**.
- Outcome: two explicit tests instead of one mixed expectation.

### 2) SQLSTATE allowlist corrections
- **Remove `0LP01`** from role-boundary assertions.
- For role-boundary checks (INSERT/SELECT/TRUNCATE): allow **`42501`** only.
- For trigger-proof checks: allow **`P0001`** only.
- For TRUNCATE: keep **`42501`** only unless you actually observe another code.

### 3) Make executor UPDATE/DELETE attempts non-noop
- Insert a real `payment_outbox_attempts` row (via `queryNoRole`) and then attempt UPDATE/DELETE as executor.
- Use unique identifiers per test run (unique `instruction_id`, `idempotency_key`, `participant_id`).

### 4) `queryNoRole` import and `NODE_ENV` handling
- **Import path**: verify `import('symphony/libs/db/testOnly')` resolves in tests. If not, switch to a relative import.
- **Avoid mutating `process.env.NODE_ENV` inside a test file**:
  - Prefer setting `NODE_ENV=test` in the test command/CI env.
  - If mutation is unavoidable, save/restore in `before/after` to avoid cross-suite leakage.

### 5) Privilege model alignment
- Confirm explicit revoke for `participant_outbox_sequences`:
  - `REVOKE SELECT ON participant_outbox_sequences FROM symphony_readonly, symphony_auditor;`
- Decide whether a privileged role should have UPDATE/DELETE for trigger-proof testing.
  - If none, rely on DB owner connection for trigger-proof.
  - If yes, add a dedicated admin/migration role with UPDATE/DELETE but still blocked by trigger.

### 6) Debug-visibility improvement (optional)
- When SQLSTATE assertion fails, log the extracted SQLSTATE to help CI diagnosis.

## Additional Tighteners (Recommended)
### A) Keep role-boundary UPDATE/DELETE privilege-only
- Seed a real row via `queryNoRole`, then attempt UPDATE/DELETE as executor and assert **`42501`**.
- Keep trigger-proof entirely separate using `queryNoRole` with **`P0001`**.

### B) CI should set NODE_ENV explicitly
- Ensure the test command or CI environment sets `NODE_ENV=test`.
- Avoid per-file mutation when possible.

### C) Unique data everywhere
- Use unique `instruction_id`, `participant_id`, `idempotency_key`, and `sequence_id` to avoid collisions in parallel runs.

### D) SQLSTATE mismatch diagnostics
- When assertion fails, log the observed SQLSTATE for fast CI triage.

## Appendix — outboxAppendOnlyTrigger.spec.ts Tighteners
### A) Avoid mutating NODE_ENV in-test
- Prefer `NODE_ENV=test` in the command or CI env.
- If mutation is required, save/restore around the test.

### B) Unique test data
- Use unique `instruction_id`, `participant_id`, and `idempotency_key` per test run.

### C) Failure diagnostics
- Log the observed SQLSTATE when it is not `P0001` to make CI failures obvious.

### D) File naming hygiene
- Ensure the file name is `outboxAppendOnlyTrigger.spec.ts` (no typo) so globs pick it up.

## Definition of Done
- Role-boundary tests assert **only** privilege SQLSTATEs (`42501`).
- Trigger-proof test asserts **`P0001`** using a principal that can reach the trigger (DB owner via `queryNoRole`).
- No ambiguous mixed expectations.
- Test data is unique per run; no shared-state flakiness.
- `NODE_ENV` handled consistently across tests.

## Files to Update (Planned)
- `tests/unit/outboxPrivileges.spec.ts`
- `tests/unit/outboxAppendOnlyTrigger.spec.ts` (if adding privileged role variant)
- `schema/v1/011_privileges.sql` (only if role model changes)
