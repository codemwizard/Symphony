-- TSK-P0-LEVY-004 hardening
-- Forward-only fix: remove regex ambiguity from period code checks by using explicit
-- digit character classes. This avoids backslash-escape interpretation drift.

ALTER TABLE IF EXISTS public.levy_calculation_records
  DROP CONSTRAINT IF EXISTS levy_calculation_records_reporting_period_check;

ALTER TABLE IF EXISTS public.levy_calculation_records
  ADD CONSTRAINT levy_calculation_records_reporting_period_check
  CHECK (
    reporting_period IS NULL
    OR reporting_period ~ '^[0-9]{4}-[0-9]{2}$'
  );

ALTER TABLE IF EXISTS public.levy_remittance_periods
  DROP CONSTRAINT IF EXISTS levy_remittance_periods_period_code_check;

ALTER TABLE IF EXISTS public.levy_remittance_periods
  ADD CONSTRAINT levy_remittance_periods_period_code_check
  CHECK (period_code ~ '^[0-9]{4}-[0-9]{2}$');
