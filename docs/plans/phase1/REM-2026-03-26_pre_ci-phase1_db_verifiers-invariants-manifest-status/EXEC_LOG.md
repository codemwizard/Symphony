# REMEDIATION EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

template_type: DRD_FULL
incident_class: governance-schema-mismatch
severity: L2
status: RESOLVED
owner: Architect
branch: security/wave-1-runtime-integrity-children
first_failing_signal: scripts/audit/validate_invariants_manifest.py
failure_signature: PRECI.DB.ENVIRONMENT
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: bash scripts/dev/pre_ci.sh
verification_commands_run: python3 scripts/audit/validate_invariants_manifest.py && python3 scripts/audit/check_docs_match_manifest.py
final_status: PASS

- created_at_utc: 2026-03-26T18:20:30Z
- action: inspected `docs/invariants/INVARIANTS_MANIFEST.yml` and confirmed the failing entries used `status: planned`.
- action: inspected `scripts/audit/validate_invariants_manifest.py` and confirmed `ALLOWED_STATUS = {implemented, roadmap}`.
- root_cause: manifest taxonomy drift left deprecated `planned` values in a schema that only accepts `implemented` and `roadmap`.
- fix_applied: changed INV-009, INV-039, INV-048, INV-130 through INV-133, and INV-159 through INV-169 from `planned` to `roadmap`; updated adjacent comments to match.
- action: reran `bash scripts/audit/run_invariants_fast_checks.sh`, which advanced to a docs-coverage failure because `docs/invariants/INVARIANTS_ROADMAP.md` did not yet list INV-159 through INV-169.
- fix_applied: added INV-159 through INV-169 to `docs/invariants/INVARIANTS_ROADMAP.md` and aligned the roadmap intro text with the manifest taxonomy.
- verification_result: `python3 scripts/audit/validate_invariants_manifest.py` and `python3 scripts/audit/check_docs_match_manifest.py` both passed after the normalization and roadmap-doc update.
- note: a broader rerun then exposed a separate approval-truth blocker in `scripts/audit/verify_human_governance_review_signoff.sh`; that blocker is out of scope for this specific manifest-status remediation.
