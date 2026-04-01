# PLAN: GF-W1-REM-003

[ID gf_w1_rem_003]

## Objective

Replace rogue migration filenames in the Execution Details sections of GF-W1-FNC-002 through GF-W1-FNC-007A PLAN.md files so they match the canonical names confirmed by GF-W1-REM-002.

## Files Requiring Correction

| PLAN.md | Rogue filename | Canonical filename |
|---|---|---|
| `docs/plans/phase1/GF-W1-FNC-002/PLAN.md` | `0108_gf_record_monitoring_record.sql` | `0108_gf_fn_monitoring_ingestion.sql` *(already fixed)* |
| `docs/plans/phase1/GF-W1-FNC-003/PLAN.md` | `0109_gf_attach_evidence_functions.sql` | `0109_gf_fn_evidence_lineage.sql` |
| `docs/plans/phase1/GF-W1-FNC-004/PLAN.md` | `0110_gf_authority_decision_functions.sql` | `0110_gf_fn_regulatory_transitions.sql` |
| `docs/plans/phase1/GF-W1-FNC-005/PLAN.md` | `0084_gf_asset_batch_functions.sql` | `0111_gf_fn_asset_lifecycle.sql` |
| `docs/plans/phase1/GF-W1-FNC-006/PLAN.md` | `0086_gf_verifier_token.sql` | `0112_gf_fn_verifier_read_token.sql` |
| `docs/plans/phase1/GF-W1-FNC-007A/PLAN.md` | `0104_gf_confidence_enforcement.sql` | `0113_gf_fn_confidence_enforcement.sql` |

## Execution Details

Apply targeted `sed` substitutions to FNC-003, FNC-004, FNC-005, FNC-006, and FNC-007A PLAN.md files. Confirm FNC-002 PLAN.md is already correct. Run `verify_gf_w1_rem_003.sh` to confirm zero stale refs across all 6 files and emit evidence.

## Constraints

- Changes are documentary only — no functional logic, no schema changes.
- Must not modify any PLAN.md sections beyond the Execution Details migration filename strings.
- Depends on GF-W1-REM-002 completing first (meta/doc parity evaluated together).

## Verification

```bash
bash scripts/audit/verify_gf_w1_rem_003.sh
python3 scripts/audit/validate_evidence.py --task GF-W1-REM-003 --evidence evidence/phase1/gf_w1_rem_003.json
bash scripts/dev/pre_ci.sh
```
