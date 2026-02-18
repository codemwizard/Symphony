# Structural Detector Scoping: Implementation Plan and Tasks

## Goal
Make structural-change detection accurate and fair by limiting “structural” classification to true schema/security changes (SQL, migrations, security scripts, workflows), while still retaining full `matches[]` output for debugging. This prevents doc/prompt/test mentions of keywords from forcing invariants updates or CI failures.

## What the process is trying to achieve
The change-rule gate exists to ensure that **real structural changes** (DDL/privilege/security changes and migration adds/deletes) are always accompanied by the required invariants documentation updates or approved exceptions. The process should:
- **Catch real structural changes** reliably (e.g., SQL migrations, privilege changes).
- **Avoid false positives** from non-structural files that mention keywords in prose (docs/prompts/tests).
- **Align local and CI behavior**, so developers see the same failures before push.

## Scope
Patches covered:
- `scripts/audit/detect_structural_changes.py`
- `scripts/audit/enforce_change_rule.sh`
- `scripts/audit/tests/test_detect_structural_changes.py`

## Non-Goals
- Changing invariants requirements or exception policy.
- Altering database schema or migration content.
- Phase-2 policy rotation work.

## Implementation Plan
1) **Scope detector to eligible structural paths**
   - DDL patterns count as structural **only** in:
     - `schema/migrations/**/*.sql`
     - (optional) `migrations/**/*.sql` if that directory exists
   - Security patterns count as structural **only** in:
     - `schema/migrations/**/*.sql` (and `migrations/**/*.sql` if used)
     - `scripts/security/**`, `scripts/db/**`, `.github/workflows/**`
   - Security keyword hits in `docs/**`, `.cursor/**`, `.github/codex/prompts/**`,
     and `scripts/audit/tests/**` must **not** flip `structural_change=true`.
   - Keep `matches[]` entries for all files, but ensure **only eligible paths flip `structural_change=true`**.
   - Add metadata fields for debugging (reason types, matched files, match counts).

2) **Align the change-rule gate with detector output**
   - Have `enforce_change_rule.sh` run the detector and short-circuit when `structural_change=false`.
   - Allow a CI-provided override (`STRUCTURAL_CHANGE`) while still normalizing values.
   - Print a concise summary when structural changes are detected.

3) **Update unit tests to reflect scoped detection**
   - Test A: structural keyword in docs → `structural_change=false`.
   - Test B: same keyword in migration SQL → `structural_change=true`.

4) **Stability requirements for errors and output**
   - Detector summary should remain deterministic.
   - `primary_reason` must be `other` (or empty) when `structural_change=false`.
   - Metadata fields (`reason_types`, `matched_files`, `match_counts`) exist with stable types even when empty.
   - Test expectations should match stable error/summary strings.

## Tasks List
### A) Detector scoping and metadata
- [ ] Add eligible-path logic for DDL/security/migration detection.
- [ ] Keep `matches[]` for all hits, but only eligible paths count toward `structural_change`.
- [ ] Add metadata fields: `reason_types`, `primary_reason`, `matched_files`, `match_counts`.

### B) Change-rule gate alignment
- [ ] Make `enforce_change_rule.sh` run the detector and skip enforcement if non-structural.
- [ ] Normalize `STRUCTURAL_CHANGE` override values.
- [ ] Emit a short structural summary when applicable.

### C) Unit test alignment
- [ ] Update `scripts/audit/tests/test_detect_structural_changes.py` to use eligible structural paths.
- [ ] Add/adjust a test ensuring docs-only keyword hits do not set `structural_change=true`.

### D) Verification
- [ ] `python3 -m py_compile scripts/audit/detect_structural_changes.py`
- [ ] `bash -n scripts/audit/enforce_change_rule.sh`
- [ ] `python3 -m unittest -q scripts.audit.tests.test_detect_structural_changes`

## Success Criteria
- Doc/prompt/test-only keyword mentions no longer trigger `structural_change=true`.
- Real structural edits still trigger the change-rule gate.
- Local pre-checks and CI agree on structural vs non-structural detection.
- Detector output includes useful metadata for debugging.
