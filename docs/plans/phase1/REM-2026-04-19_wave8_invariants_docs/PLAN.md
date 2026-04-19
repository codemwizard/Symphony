# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.REMEDIATION.TRACE

origin_gate_id: pre_ci.verify_remediation_trace
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Fix pre_ci.sh failures for Wave 8 regulatory extensions implementation
- Address DDL lock risk lint failure for migration 0128
- Align invariants documentation with manifest changes (INV-169 promoted to implemented, INV-178 added)
- Regenerate INVARIANTS_QUICK.md after manifest updates

## Initial Hypotheses
- Migration 0128 uses ALTER TABLE ADD COLUMN which is flagged as risky DDL pattern
- Solution: Add migration to DDL allowlist with appropriate justification
- INV-169 was promoted to implemented status in manifest but docs were not updated
- INV-178 was added as implemented in manifest but docs were not updated
- Solution: Update INVARIANTS_ROADMAP.md and INVARIANTS_IMPLEMENTED.md accordingly
- INVARIANTS_QUICK.md needs regeneration to reflect manifest changes

## Root Cause
- Wave 8 implementation included migration 0128 with ALTER TABLE statement that requires allowlisting
- Invariant registration (INV-178) and promotion (INV-169) were completed but documentation was not synchronized
- INVARIANTS_QUICK.md is mechanically generated and was not regenerated after manifest changes

## Fix Sequence
1. Add DDL-ALLOW-0107 to docs/security/ddl_allowlist.json for migration 0128
2. Remove INV-169 from docs/invariants/INVARIANTS_ROADMAP.md (now implemented)
3. Add INV-169 and INV-178 to docs/invariants/INVARIANTS_IMPLEMENTED.md
4. Regenerate docs/invariants/INVARIANTS_QUICK.md via scripts/audit/generate_invariants_quick.py
5. Commit all changes
6. Run pre_ci.sh to verify all checks pass

## Verification
- pre_ci.sh passes all checks including DDL lock risk lint and invariants docs consistency
