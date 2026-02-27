-- BoZ read-only reconstruction query set for TSK-P1-REG-001
-- Inputs:
--   :instruction_id
--   :correlation_id

-- 1) Ingress attestation reconstruction
SELECT
  ia.instruction_id,
  ia.correlation_id,
  ia.participant_id,
  ia.tenant_id,
  ia.received_at,
  ia.payload_hash,
  ia.signature_hash
FROM public.ingress_attestations ia
WHERE ia.instruction_id = :'instruction_id'
   OR ia.correlation_id = :'correlation_id'
ORDER BY ia.received_at DESC;

-- 2) Dispatch attempts reconstruction
SELECT
  poa.outbox_id,
  poa.attempt_no,
  poa.worker_id,
  poa.lease_token,
  poa.status,
  poa.started_at,
  poa.completed_at,
  poa.terminal_at
FROM public.payment_outbox_attempts poa
JOIN public.payment_outbox_pending pop ON pop.outbox_id = poa.outbox_id
WHERE pop.instruction_id = :'instruction_id'
ORDER BY poa.attempt_no ASC;

-- 3) Finality and reversals reconstruction
SELECT
  isf.instruction_id,
  isf.final_state,
  isf.settled_at,
  isf.reversal_source_instruction_id,
  isf.reversal_reason_code,
  isf.created_at
FROM public.instruction_settlement_finality isf
WHERE isf.instruction_id = :'instruction_id'
   OR isf.reversal_source_instruction_id = :'instruction_id'
ORDER BY isf.created_at ASC;
