# PLAN: GF-W1-REM-002

[ID gf_w1_rem_002]

## Objective

Remove all rogue-agent migration filenames and fake `verify_gf_w1_fnc_*` verifier references from the seven GF-W1-FNC-001 through GF-W1-FNC-007A task meta.yml files, replacing them with the canonical migration filenames and the pre_ci-registered verifier script names.

## Rogue → Canonical Mapping

| Task | Rogue migration name | Canonical migration name | Canonical verifier |
|---|---|---|---|
| FNC-001 | `0107_gf_register_activate_project.sql` | `0107_gf_fn_project_registration.sql` | `scripts/db/verify_gf_fnc_001.sh` |
| FNC-002 | `0108_gf_record_monitoring_record.sql` | `0108_gf_fn_monitoring_ingestion.sql` | `scripts/db/verify_gf_fnc_002.sh` |
| FNC-003 | `0109_gf_attach_evidence_functions.sql` | `0109_gf_fn_evidence_lineage.sql` | `scripts/db/verify_gf_fnc_003.sh` |
| FNC-004 | `0110_gf_authority_decision_functions.sql` | `0110_gf_fn_regulatory_transitions.sql` | `scripts/db/verify_gf_fnc_004.sh` |
| FNC-005 | `0084_gf_asset_batch_functions.sql` | `0111_gf_fn_asset_lifecycle.sql` | `scripts/db/verify_gf_fnc_005.sh` |
| FNC-006 | `0086_gf_verifier_token.sql` | `0112_gf_fn_verifier_read_token.sql` | `scripts/db/verify_gf_fnc_006.sh` |
| FNC-007A | `0104_gf_confidence_enforcement.sql` | `0113_gf_fn_confidence_enforcement.sql` | `scripts/audit/verify_gf_fnc_007a.sh` |

## Execution Details

For each meta.yml, replace all occurrences of the rogue migration filename and the `verify_gf_w1_fnc_*` pattern with the canonical equivalents using targeted `sed` substitutions. Affected fields: `touches:`, `work:`, `acceptance_criteria:`, `verification:`. Run `verify_gf_w1_rem_002.sh` to confirm and emit evidence.

## Constraints

- Must not modify any functional acceptance criteria logic — only the filename strings.
- Must not touch `tasks/GF-W1-FNC-007B/meta.yml` (Security Guardian — GF-W1-REM-004).
- Changes are documentary only; no schema or script logic changes.

## Verification

```bash
bash scripts/audit/verify_gf_w1_rem_002.sh
python3 scripts/audit/validate_evidence.py --task GF-W1-REM-002 --evidence evidence/phase1/gf_w1_rem_002.json
bash scripts/dev/pre_ci.sh
```
