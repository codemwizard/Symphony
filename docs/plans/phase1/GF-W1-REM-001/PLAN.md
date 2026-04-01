# PLAN: GF-W1-REM-001

[ID gf_w1_rem_001]

## Objective

Correct stale migration number references in the 6 Wave 5 pre_ci verifier stub scripts (`verify_gf_fnc_001.sh` through `verify_gf_fnc_006.sh`), replacing the rogue agent's `0088`–`0093` slot numbers with the correct post-schema-table numbers `0107`–`0112`.

## Background

The gap between migration `0080` and `0095` was pre-reserved. The rogue agent populated the 6 stubs with numbers from that gap (`0088`–`0093`). GF function migrations must come **after** the GF schema tables (`0097`–`0106`); the correct slots are `0107`–`0112`. Until corrected, pre_ci cannot verify any Wave 5 work.

## Migration Number Mapping

| Stub | Old (rogue) | Correct |
|---|---|---|
| `verify_gf_fnc_001.sh` | `0088_gf_fn_project_registration.sql` | `0107_gf_fn_project_registration.sql` |
| `verify_gf_fnc_002.sh` | `0089_gf_fn_monitoring_ingestion.sql` | `0108_gf_fn_monitoring_ingestion.sql` |
| `verify_gf_fnc_003.sh` | `0090_gf_fn_evidence_lineage.sql` | `0109_gf_fn_evidence_lineage.sql` |
| `verify_gf_fnc_004.sh` | `0091_gf_fn_regulatory_transitions.sql` | `0110_gf_fn_regulatory_transitions.sql` |
| `verify_gf_fnc_005.sh` | `0092_gf_fn_asset_lifecycle.sql` | `0111_gf_fn_asset_lifecycle.sql` |
| `verify_gf_fnc_006.sh` | `0093_gf_fn_verifier_read_token.sql` | `0112_gf_fn_verifier_read_token.sql` |

## Execution Details

For each stub, apply `sed` substitution replacing the old migration number prefix with the correct one. Confirm via grep that zero stale refs remain. Run each stub to confirm PENDING output. Run `verify_gf_w1_rem_001.sh` to emit evidence.

## Constraints

- Must not modify any migration SQL content.
- Must not alter stub verification logic — only the migration filename reference changes.
- Stubs must exit 0 with PENDING after correction (they reference files that don't yet exist).

## Verification

```bash
bash scripts/db/verify_gf_w1_rem_001.sh
python3 scripts/audit/validate_evidence.py --task GF-W1-REM-001 --evidence evidence/phase1/gf_w1_rem_001.json
bash scripts/dev/pre_ci.sh
```
