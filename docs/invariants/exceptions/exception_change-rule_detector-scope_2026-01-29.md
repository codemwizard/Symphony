---
exception_id: EXC-2026-01-29-01
inv_scope: change-rule
expiry: 2026-02-05
follow_up_ticket: FOLLOWUP-CHANGE-RULE-SCOPING
reason: Change-rule detector scoping adjustments are structural but docs linkage is pending; allow this PR to proceed.
author: codex
created_at: 2026-01-29
---

# Exception: change-rule detector scoping update

## Reason

This change updates structural detection and the change-rule gate to prevent false positives from docs/prompts/tests.
It is structural in tooling terms, but invariants documentation linkage will be added in the follow-up.

## Mitigation

- Unit tests updated to enforce scoped detection behavior.
- Detector now only flips `structural_change=true` for eligible structural paths.
- Pre-CI runs the same change-rule gate as CI.
