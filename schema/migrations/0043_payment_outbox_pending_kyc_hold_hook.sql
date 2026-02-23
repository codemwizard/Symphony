-- no_tx
-- TSK-P0-KYC-003: Phase-0 expand-first structural hook for Phase-2 KYC hold routing.

ALTER TABLE public.payment_outbox_pending
    ADD COLUMN IF NOT EXISTS kyc_hold BOOLEAN DEFAULT NULL;

COMMENT ON COLUMN public.payment_outbox_pending.kyc_hold IS
    'Phase-0 structural hook. NULL until Phase-2 KYC-gated routing logic '
    'sets this field. TRUE = instruction is held pending beneficiary KYC '
    'verification. FALSE = KYC gate passed, instruction may proceed. '
    'NULL = KYC gate not yet evaluated (pre-Phase-2 state for all rows). '
    'DO NOT read or write this column in application runtime until Phase-2. '
    'When TRUE, Phase-2 exception engine opens a KYC_HOLD exception record.';
