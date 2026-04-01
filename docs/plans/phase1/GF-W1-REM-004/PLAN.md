# PLAN: GF-W1-REM-004

[ID gf_w1_rem_004]

## Objective

Replace all 4 occurrences of `verify_gf_w1_fnc_007b` in `tasks/GF-W1-FNC-007B/meta.yml` with the canonical `verify_gf_fnc_007b`, removing the rogue agent's `w1_` infix naming pattern from the Security Guardian task contract.

## Fields Requiring Correction in tasks/GF-W1-FNC-007B/meta.yml

| Field | Rogue value | Canonical value |
|---|---|---|
| `touches:` | `scripts/audit/verify_gf_w1_fnc_007b.sh` | `scripts/audit/verify_gf_fnc_007b.sh` |
| `work:` | `verify_gf_w1_fnc_007b.sh` | `verify_gf_fnc_007b.sh` |
| `acceptance_criteria:` | `verify_gf_w1_fnc_007b.sh exits 0` | `verify_gf_fnc_007b.sh exits 0` |
| `verification:` | `bash scripts/audit/verify_gf_w1_fnc_007b.sh` | `bash scripts/audit/verify_gf_fnc_007b.sh` |

## Execution Details

Apply a single `sed -i 's/verify_gf_w1_fnc_007b/verify_gf_fnc_007b/g'` substitution to `tasks/GF-W1-FNC-007B/meta.yml`. Confirm via grep that zero `verify_gf_w1_fnc_007b` refs remain. Run `verify_gf_w1_rem_004.sh` to emit evidence.

## Constraints

- Changes are documentary only — no script logic, no schema changes.
- Must not touch any other meta.yml file.
- The target script (`scripts/audit/verify_gf_fnc_007b.sh`) does not need to exist yet; its creation is GF-W1-FNC-007B implementation scope.

## Verification

```bash
bash scripts/audit/verify_gf_w1_rem_004.sh
python3 scripts/audit/validate_evidence.py --task GF-W1-REM-004 --evidence evidence/phase1/gf_w1_rem_004.json
bash scripts/dev/pre_ci.sh
```
