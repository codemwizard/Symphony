# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.STRUCTURAL.CHANGE_RULE

origin_gate_id: pre_ci.enforce_change_rule
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: PASS

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.
- The pre_ci.sh script failed due to a structural change (TSK-P1-217 DDL migration) lacking an accompanying update to threat or compliance documentation.

## Initial Hypotheses
- The structural change detector correctly identified `0076_onboarding_control_plane.sql` as a DDL change.
- `enforce_change_rule.sh` correctly requires `THREAT_MODEL.md` or `COMPLIANCE_MAP.md` updates when DDL changes are introduced.
- We must add a new entry to `THREAT_MODEL.md` documenting the onboarding control plane and key domain separation.
