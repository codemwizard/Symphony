# TSK-P1-TEN-002 PLAN

Task: TSK-P1-TEN-002

## Scope
- Enforce restrictive tenant RLS policies on every public table with a `tenant_id` column.
- Force RLS (`ENABLE` + `FORCE`) to prevent owner bypass.
- Add leakage verification proving tenant B cannot read tenant A rows under `app.current_tenant_id` session context.

## Verification
- `bash scripts/audit/verify_ten_002_rls_leakage.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-TEN-002 --evidence evidence/phase1/ten_002_rls_leakage.json`
- `scripts/dev/pre_ci.sh`
