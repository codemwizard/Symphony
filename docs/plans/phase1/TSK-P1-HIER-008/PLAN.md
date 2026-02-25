# TSK-P1-HIER-008 PLAN

Task: TSK-P1-HIER-008
Owner role: SUPERVISOR
Depends on: TSK-P1-HIER-007
failure_signature: PHASE1.TSK.P1.HIER.008.SIM_SWAP_ALERT_TRACEABILITY

## objective
Implement deterministic SIM-swap alert derivation with formula-version traceability, aligned to the canonical prompt metadata:
- verifier script `scripts/db/verify_hier_008_sim_swap_alerts.sh`
- evidence file `evidence/phase1/hier_008_sim_swap_alerts.json`
- terminal task metadata at `tasks/TSK-P1-HIER-008/meta.yml`

## implementation
- Add migration `0053_hier_008_sim_swap_alerts.sql` creating append-only `sim_swap_alerts`.
- Add hardened SECURITY DEFINER `public.derive_sim_swap_alert(p_event_id UUID)`:
  - reads `member_device_events`
  - resolves active prior ICCID hash
  - records non-null `formula_version_id`
  - enforces deterministic one-alert-per-source-event behavior.
- Add verifier assertions for function hardening, append-only posture, derived row correctness, and idempotency.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_hier_008_sim_swap_alerts.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-008 --evidence evidence/phase1/hier_008_sim_swap_alerts.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_hier_008_sim_swap_alerts.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-008 --evidence evidence/phase1/hier_008_sim_swap_alerts.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
