-- TSK-P0-KYC-001 follow-up hardening
-- Remove full uniqueness on (jurisdiction_code, provider_code) so historical
-- rows can coexist across validity windows while partial active uniqueness remains.

ALTER TABLE public.kyc_provider_registry
    DROP CONSTRAINT IF EXISTS kyc_provider_unique_active_per_jurisdiction;
