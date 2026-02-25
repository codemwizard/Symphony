-- 0054_hier_008_member_device_events_sim_swap_type.sql
-- Forward-only follow-up for TSK-P1-HIER-008:
-- include SIM_SWAP_DETECTED in member_device_events event semantics.

ALTER TABLE public.member_device_events
  DROP CONSTRAINT IF EXISTS member_device_events_event_type_check;

ALTER TABLE public.member_device_events
  DROP CONSTRAINT IF EXISTS member_device_events_device_id_event_type_chk;

ALTER TABLE public.member_device_events
  ADD CONSTRAINT member_device_events_event_type_check
  CHECK (event_type IN ('ENROLLED_DEVICE','UNREGISTERED_DEVICE','REVOKED_DEVICE_ATTEMPT','SIM_SWAP_DETECTED'));

ALTER TABLE public.member_device_events
  ADD CONSTRAINT member_device_events_device_id_event_type_chk CHECK (
    (device_id IS NULL) = (event_type IN ('UNREGISTERED_DEVICE','REVOKED_DEVICE_ATTEMPT'))
  );
