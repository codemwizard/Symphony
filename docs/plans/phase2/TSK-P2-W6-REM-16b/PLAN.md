# Implementation Plan: TSK-P2-W6-REM-16b

## Mission
Resolve the `P7601` collision by modifying `docs/contracts/sqlstate_map.yml`.
- Evict legacy `P7601` (adjustment recipient input is not permitted) and reassign it to `P7504`.
- Assign `P7601` to Wave 6 Policy Authority (state transition rejected because no matching state rule permits the requested state movement).
- Add the `P76xx` range ownership to `wave6`.

## Deliverables
- Modification to `docs/contracts/sqlstate_map.yml`.
- Execution of `check_sqlstate_map_drift.sh` and generation of evidence.
