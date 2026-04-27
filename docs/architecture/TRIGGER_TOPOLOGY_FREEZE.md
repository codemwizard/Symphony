# state_transitions Trigger Topology Freeze

## Contract Status
**LOCKED** (Pre-Dispatcher Consolidation Phase)

## Rationale
The `state_transitions` table currently relies on 9 independent triggers to enforce its invariants. Because PostgreSQL triggers fire in alphabetical order by name, the system's correctness is highly sensitive to naming, timing (`BEFORE` vs `AFTER`), event type (`INSERT`, `UPDATE`, `DELETE`), and orientation (`FOR EACH ROW`).

To prevent silent behavioral drift or the accidental invalidation of cryptographic lineage before the final dispatcher consolidation phase, this topology is frozen.

## Frozen Baseline

Any deviation from this exact baseline in count, name, function binding, timing, event, or orientation is a **hard failure** and will break the CI pipeline.

| Trigger Name | Timing | Event | Orientation | Bound Function |
|--------------|--------|-------|-------------|----------------|
| `ai_01_update_current_state` | AFTER | INSERT | FOR EACH ROW | `update_current_state` |
| `bd_01_deny_state_transitions_mutation` | BEFORE | DELETE OR UPDATE | FOR EACH ROW | `deny_state_transitions_mutation` |
| `bi_01_enforce_transition_authority` | BEFORE | INSERT OR UPDATE | FOR EACH ROW | `enforce_transition_authority` |
| `bi_02_enforce_execution_binding` | BEFORE | INSERT OR UPDATE | FOR EACH ROW | `enforce_execution_binding` |
| `bi_03_enforce_transition_state_rules` | BEFORE | INSERT OR UPDATE | FOR EACH ROW | `enforce_transition_state_rules` |
| `bi_04_enforce_transition_signature` | BEFORE | INSERT OR UPDATE | FOR EACH ROW | `enforce_transition_signature` |
| `bi_05_enforce_state_transition_authority` | BEFORE | INSERT OR UPDATE | FOR EACH ROW | `enforce_state_transition_authority` |
| `bi_06_upgrade_authority_on_execution_binding` | BEFORE | INSERT OR UPDATE | FOR EACH ROW | `upgrade_authority_on_execution_binding` |
| `tr_add_signature_placeholder` | BEFORE | INSERT | FOR EACH ROW | `add_signature_placeholder_posture` |

## Enforcement
This baseline is strictly enforced by `scripts/db/verify_trigger_topology_freeze.sh`. Do not modify this document or add/rename triggers on `state_transitions` without explicit approval from the Security & Architecture Authority.
