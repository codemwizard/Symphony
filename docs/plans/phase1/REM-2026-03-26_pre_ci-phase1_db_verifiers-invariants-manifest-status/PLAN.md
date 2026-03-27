# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

template_type: DRD_FULL
incident_class: governance-schema-mismatch
severity: L2
status: RESOLVED
owner: Architect
branch: security/wave-1-runtime-integrity-children
first_failing_signal: scripts/audit/validate_invariants_manifest.py
failure_signature: PRECI.DB.ENVIRONMENT
first_observed_utc: 2026-03-26T18:20:30Z
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: bash scripts/dev/pre_ci.sh
verification_commands_run: python3 scripts/audit/validate_invariants_manifest.py && bash scripts/audit/run_invariants_fast_checks.sh
final_status: PASS

## Scope
- Remediate the invariant manifest schema failure triggered during `pre_ci.phase1_db_verifiers`.
- Normalize invalid `status: planned` values in `docs/invariants/INVARIANTS_MANIFEST.yml` to the allowed taxonomy.
- Keep the fix limited to manifest taxonomy and remediation trace artifacts.

scope_boundary:
- In scope: `docs/invariants/INVARIANTS_MANIFEST.yml`, this remediation casefile, targeted invariants verification.
- Out of scope: changing invariant meaning, adding new verifiers, rerunning full `scripts/dev/pre_ci.sh`, unrelated DB or task-pack failures.

## Initial Hypotheses
- The manifest validator rejects `planned` because only `implemented` and `roadmap` are allowed.
- The file contains stale terminology from earlier drafts, so normalization to `roadmap` should clear the gate without changing enforcement semantics.

## Timeline
- 2026-03-26T18:20:30Z: `scripts/dev/pre_ci.sh` failed in `scripts/audit/validate_invariants_manifest.py` with multiple invalid `status 'planned'` errors.
- 2026-03-26T18:24:00Z: confirmed from `validate_invariants_manifest.py` that the only allowed statuses are `implemented` and `roadmap`.
- 2026-03-26T18:26:00Z: patched the invalid manifest entries and explanatory comments to use `roadmap`.
- 2026-03-26T18:27:00Z: reran targeted invariants verification.
- 2026-03-26T18:31:00Z: `check_docs_match_manifest.py` exposed missing roadmap coverage for `INV-159` through `INV-169`.
- 2026-03-26T18:34:00Z: updated `docs/invariants/INVARIANTS_ROADMAP.md` to include the missing roadmap invariants.
- 2026-03-26T18:36:00Z: reran targeted manifest and docs-consistency verification; both passed. A broader rerun advanced to the separate `verify_human_governance_review_signoff.sh` blocker.

## Root Causes
- The manifest schema evolved to `implemented|roadmap`, but several entries and comments still used the deprecated `planned` label.

## Contributing Factors
- Mixed terminology remained in both entry data and nearby commentary, so the file contradicted its own declared schema.
- Full `pre_ci.sh` exposed the mismatch late because earlier gates did not exercise the manifest parser.

## Decision Points
- Preserve semantics by renaming only the invalid status taxonomy rather than promoting any invariant to `implemented`.
- Record a DRD-full remediation casefile because the branch had already seen two non-converging `pre_ci` attempts with changing first blockers.

## Final Solution Summary
- Replaced all invalid `status: planned` entries with `status: roadmap`.
- Updated nearby explanatory comments so the manifest text aligns with the validator contract.
- Added the missing roadmap entries to `docs/invariants/INVARIANTS_ROADMAP.md` so docs coverage matches the normalized manifest state.

## Prevention Actions
- Owner: Architect
  Enforcement: keep `scripts/audit/validate_invariants_manifest.py` in fast invariants checks and pre-CI.
  Metric: zero invalid manifest-status values in branch diffs.
  Status: active
  Target Date: 2026-03-26
