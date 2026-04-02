# REMEDIATION EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

- created_at_utc: 2026-03-30T12:02:08Z
- action: remediation casefile scaffold created

## 2026-03-30 — Second failure (TSK-P1-063)
- Root cause: reset_evidence_gate.sh, verify_enf_003b.sh, verify_enf_005.sh not listed in GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md
- Fix: added three entries to audit doc table
- verify_tsk_p1_063.sh exit 0 PASS after fix

## 2026-03-30 — Third failure (Baseline drift)
- Root cause: schema/baselines/current/0001_baseline.sql predated migrations 0107-0110
- Fix: created fresh Docker DB using symphony superuser, applied all migrations 0001-0110, ran generate_baseline_snapshot.sh; baseline now contains all 4 GF Phase 1 function sets (10 matches confirmed)
- TSK-P1-063 (git audit) also resolved: added reset_evidence_gate.sh, verify_enf_003b.sh, verify_enf_005.sh to GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md

## 2026-03-30 — Fourth failure (wrong_policy_count authority_decisions)
- Root cause: 0110 created authority_decisions_jurisdiction_access policy while 0103 rls_jurisdiction_isolation_authority_decisions still existed → 2 policies, verifier expects 1
- Fix: added DROP POLICY IF EXISTS rls_jurisdiction_isolation_authority_decisions to 0110 before CREATE POLICY
- verify_gf_fnc_004.sh still passes; baseline regenerated (hash: d02b730...)
