#!/bin/bash
# inject_v3_sections.sh — Add v3 template fields to all W5-FIX meta.yml files
# Inserts between "invariants: []" and "# ── Work items"

set -euo pipefail
cd /home/mwiza/workspaces/Symphony-Demo/Symphony

inject_v3() {
    local TASK_ID="$1"
    local MIGRATION_NUM="$2"
    local MIGRATION_DESC="$3"
    local BLAST="$4"       # DB_SCHEMA or CI_GATES
    local REG_PATHS="$5"   # regulated paths (pipe-separated)
    local MIG_DEPS="$6"    # migration deps YAML block
    local TABLE_DEPS="$7"  # table deps YAML block
    local DELIVERABLES="$8" # deliverable files (pipe-separated)

    local META="tasks/${TASK_ID}/meta.yml"
    local TASK_SLUG=$(echo "$TASK_ID" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

    # Check if v3 sections already exist
    if grep -q 'regulated_surface_compliance:' "$META" 2>/dev/null; then
        echo "SKIP $TASK_ID — v3 sections already present"
        return
    fi

    # Build the v3 block
    local V3_BLOCK=""

    # 1. Deliverable files
    V3_BLOCK+="
# ── Deliverable files (for churn control) ─────────────────────────────────
deliverable_files:"
    IFS='|' read -ra DFILES <<< "$DELIVERABLES"
    for df in "${DFILES[@]}"; do
        V3_BLOCK+="
  - ${df}"
    done

    # 2. Regulated Surface Compliance
    if [ "$BLAST" = "DB_SCHEMA" ]; then
        V3_BLOCK+="

# ── Regulated Surface Compliance (CRITICAL) ────────────────────────────────
regulated_surface_compliance:
  enabled: true
  approval_workflow: stage_a_stage_b
  stage_a_required_before_edit: true
  regulated_paths:"
        IFS='|' read -ra RPATHS <<< "$REG_PATHS"
        for rp in "${RPATHS[@]}"; do
            V3_BLOCK+="
    - ${rp}"
        done
        V3_BLOCK+="
  must_read:
    - docs/operations/REGULATED_SURFACE_PATHS.yml
    - docs/operations/approval_metadata.schema.json"
    else
        # CI_GATES tasks still touch scripts/db or scripts/audit which are regulated
        V3_BLOCK+="

# ── Regulated Surface Compliance (CRITICAL) ────────────────────────────────
regulated_surface_compliance:
  enabled: true
  approval_workflow: stage_a_only
  stage_a_required_before_edit: true
  regulated_paths:"
        IFS='|' read -ra RPATHS <<< "$REG_PATHS"
        for rp in "${RPATHS[@]}"; do
            V3_BLOCK+="
    - ${rp}"
        done
        V3_BLOCK+="
  must_read:
    - docs/operations/REGULATED_SURFACE_PATHS.yml"
    fi

    # 3. Remediation Trace Compliance (ALL tasks)
    V3_BLOCK+="

# ── Remediation Trace Compliance (CRITICAL) ────────────────────────────────
remediation_trace_compliance:
  enabled: true
  required_markers:
    - failure_signature
    - origin_task_id
    - repro_command
    - verification_commands_run
    - final_status
  marker_location: EXEC_LOG.md
  append_only: true
  markers_required_at_edit: true
  must_read:
    - docs/operations/REMEDIATION_TRACE_WORKFLOW.md"

    # 4. Database Connection (DB_SCHEMA tasks and DB-querying QA tasks)
    if [ "$BLAST" = "DB_SCHEMA" ] || [ "$TASK_ID" = "TSK-P2-W5-FIX-10" ] || [ "$TASK_ID" = "TSK-P2-W5-FIX-12" ] || [ "$TASK_ID" = "TSK-P2-W5-FIX-13" ]; then
        V3_BLOCK+="

# ── Database Connection ────────────────────────────────────────────────────
database_connection:
  enabled: true
  connection_string_format: \"postgresql://<user>:<password>@<host>:<port>/<database>\"
  example_connection_string: \"postgresql://symphony_admin:symphony_pass@localhost:5432/symphony\"
  container_name: symphony-postgres
  database_url_env_var: DATABASE_URL
  setup_command: \"export DATABASE_URL=\\\"postgresql://symphony_admin:symphony_pass@localhost:5432/symphony\\\"\""
    else
        V3_BLOCK+="

# ── Database Connection ────────────────────────────────────────────────────
database_connection:
  enabled: false"
    fi

    # 5. Migration Dependencies (DB_SCHEMA tasks only)
    if [ "$BLAST" = "DB_SCHEMA" ]; then
        V3_BLOCK+="

# ── Migration Dependencies ─────────────────────────────────────────────────
migration_dependencies:
  enabled: true
  required_migrations:
${MIG_DEPS}
  table_dependencies:
${TABLE_DEPS}
  verification_step: \"Confirm all referenced tables exist in earlier migrations\""
    else
        V3_BLOCK+="

# ── Migration Dependencies ─────────────────────────────────────────────────
migration_dependencies:
  enabled: false"
    fi

    # Insert after "invariants: []" line
    local INV_LINE=$(grep -n '^invariants: \[\]' "$META" | head -1 | cut -d: -f1)
    if [ -z "$INV_LINE" ]; then
        echo "ERROR: Cannot find 'invariants: []' in $META"
        return 1
    fi

    # Use sed to insert after invariants line
    local TMPFILE=$(mktemp "${META}.XXXXXX")
    head -n "$INV_LINE" "$META" > "$TMPFILE"
    echo "$V3_BLOCK" >> "$TMPFILE"
    echo "" >> "$TMPFILE"
    tail -n +"$((INV_LINE + 1))" "$META" >> "$TMPFILE"
    mv "$TMPFILE" "$META"

    echo "OK $TASK_ID — v3 sections injected after line $INV_LINE"
}

# ═══════════════════════════════════════════════════════════════════════════
# FIX-01: Column mismatch (migration 0145)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-01" "0145" "Fix column reference" "DB_SCHEMA" \
    "schema/migrations/0145_fix_enforce_transition_authority_column.sql" \
    "    - \"0134\": \"policy_decisions table with policy_decision_id PK\"
    - \"0137\": \"state_transitions table with policy_decision_id column\"
    - \"0140\": \"enforce_transition_authority() with broken column reference\"" \
    "    - \"policy_decisions\": \"must exist with column policy_decision_id (PK)\"
    - \"state_transitions\": \"must exist with column policy_decision_id\"" \
    "schema/migrations/0145_fix_enforce_transition_authority_column.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_01.sh|evidence/phase2/tsk_p2_w5_fix_01.json|docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-02: entity_type (migration 0146)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-02" "0146" "Add entity_type to state_rules" "DB_SCHEMA" \
    "schema/migrations/0146_add_entity_type_to_state_rules.sql" \
    "    - \"0139\": \"state_rules table and enforce_transition_state_rules() function\"
    - \"0145\": \"enforce_transition_authority() with corrected column (FIX-01)\"" \
    "    - \"state_rules\": \"must exist (from migration 0139)\"
    - \"state_transitions\": \"must exist with entity_type column\"" \
    "schema/migrations/0146_add_entity_type_to_state_rules.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_02.sh|evidence/phase2/tsk_p2_w5_fix_02.json|docs/plans/phase2/TSK-P2-W5-FIX-02/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-03: FKs (migration 0147)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-03" "0147" "Add FKs to state_transitions" "DB_SCHEMA" \
    "schema/migrations/0147_add_fks_to_state_transitions.sql" \
    "    - \"0134\": \"policy_decisions table with policy_decision_id PK\"
    - \"0137\": \"state_transitions table with execution_id and policy_decision_id\"
    - \"0146\": \"state_rules entity_type (FIX-02)\"" \
    "    - \"execution_records\": \"must exist with execution_id PK\"
    - \"policy_decisions\": \"must exist with policy_decision_id PK\"
    - \"state_transitions\": \"must exist with execution_id and policy_decision_id columns\"" \
    "schema/migrations/0147_add_fks_to_state_transitions.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_03.sh|evidence/phase2/tsk_p2_w5_fix_03.json|docs/plans/phase2/TSK-P2-W5-FIX-03/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-04: SECURITY DEFINER (migration 0148)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-04" "0148" "SECURITY DEFINER hardening" "DB_SCHEMA" \
    "schema/migrations/0148_harden_trigger_functions_security_definer.sql" \
    "    - \"0139\": \"enforce_transition_state_rules()\"
    - \"0140\": \"enforce_transition_authority()\"
    - \"0141\": \"enforce_transition_signature()\"
    - \"0142\": \"enforce_execution_binding()\"
    - \"0143\": \"deny_state_transitions_mutation()\"
    - \"0144\": \"update_current_state()\"
    - \"0147\": \"FK constraints (FIX-03)\"" \
    "    - \"state_transitions\": \"must exist with all triggers attached\"" \
    "schema/migrations/0148_harden_trigger_functions_security_definer.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_04.sh|evidence/phase2/tsk_p2_w5_fix_04.json|docs/plans/phase2/TSK-P2-W5-FIX-04/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-05: Trigger ordering (migration 0149)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-05" "0149" "Trigger rename for ordering" "DB_SCHEMA" \
    "schema/migrations/0149_rename_triggers_deterministic_order.sql" \
    "    - \"0137\": \"state_transitions triggers (trg_enforce_state_transition_authority, trg_upgrade_authority_on_execution_binding)\"
    - \"0139\": \"trg_enforce_transition_state_rules\"
    - \"0140\": \"trg_enforce_transition_authority\"
    - \"0141\": \"trg_enforce_transition_signature\"
    - \"0142\": \"trg_enforce_execution_binding\"
    - \"0143\": \"trg_deny_state_transitions_mutation\"
    - \"0144\": \"trg_06_update_current\"
    - \"0148\": \"SECURITY DEFINER (FIX-04)\"" \
    "    - \"state_transitions\": \"must exist with all 8 triggers attached\"" \
    "schema/migrations/0149_rename_triggers_deterministic_order.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_05.sh|evidence/phase2/tsk_p2_w5_fix_05.json|docs/plans/phase2/TSK-P2-W5-FIX-05/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-06: ON DELETE RESTRICT (migration 0150)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-06" "0150" "FK ON DELETE RESTRICT" "DB_SCHEMA" \
    "schema/migrations/0150_fix_state_current_fk_restrict.sql" \
    "    - \"0138\": \"state_current table with fk_last_transition ON DELETE CASCADE\"
    - \"0149\": \"trigger rename (FIX-05)\"" \
    "    - \"state_current\": \"must exist with fk_last_transition constraint\"
    - \"state_transitions\": \"must exist (referenced by FK)\"" \
    "schema/migrations/0150_fix_state_current_fk_restrict.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_06.sh|evidence/phase2/tsk_p2_w5_fix_06.json|docs/plans/phase2/TSK-P2-W5-FIX-06/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-07: NOT NULL verify (migration 0151)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-07" "0151" "Verify NOT NULL on current_state" "DB_SCHEMA" \
    "schema/migrations/0151_verify_not_null_state_current.sql" \
    "    - \"0138\": \"state_current table with current_state column\"
    - \"0150\": \"FK RESTRICT (FIX-06)\"" \
    "    - \"state_current\": \"must exist with current_state column\"" \
    "schema/migrations/0151_verify_not_null_state_current.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_07.sh|evidence/phase2/tsk_p2_w5_fix_07.json|docs/plans/phase2/TSK-P2-W5-FIX-07/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-08: SQLSTATE codes (migration 0152)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-08" "0152" "Add GF SQLSTATE codes" "DB_SCHEMA" \
    "schema/migrations/0152_add_sqlstate_codes_to_triggers.sql" \
    "    - \"0139\": \"enforce_transition_state_rules() with RAISE statements\"
    - \"0140\": \"enforce_transition_authority() with RAISE statements\"
    - \"0141\": \"enforce_transition_signature() with RAISE statements\"
    - \"0142\": \"enforce_execution_binding() with RAISE statements\"
    - \"0143\": \"deny_state_transitions_mutation() with RAISE statements\"
    - \"0151\": \"NOT NULL verify (FIX-07)\"" \
    "    - \"state_transitions\": \"must exist with all trigger functions\"" \
    "schema/migrations/0152_add_sqlstate_codes_to_triggers.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_08.sh|evidence/phase2/tsk_p2_w5_fix_08.json|docs/plans/phase2/TSK-P2-W5-FIX-08/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-09: Signature posture (migration 0153)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-09" "0153" "Signature placeholder posture" "DB_SCHEMA" \
    "schema/migrations/0153_set_signature_placeholder_posture.sql" \
    "    - \"0141\": \"enforce_transition_signature() and verify_ed25519_signature()\"
    - \"0152\": \"SQLSTATE codes (FIX-08)\"" \
    "    - \"state_transitions\": \"must exist with transition_hash column\"" \
    "schema/migrations/0153_set_signature_placeholder_posture.sql|schema/migrations/MIGRATION_HEAD|scripts/db/verify_tsk_p2_w5_fix_09.sh|evidence/phase2/tsk_p2_w5_fix_09.json|docs/plans/phase2/TSK-P2-W5-FIX-09/EXEC_LOG.md|docs/architecture/THREAT_MODEL.md|docs/architecture/COMPLIANCE_MAP.md|schema/baselines/current/0001_baseline.sql|docs/decisions/ADR-0010-baseline-policy.md|evidence/phase0/schema_hash.txt|evidence/phase0/baseline_governance.json|evidence/phase0/baseline_drift.json|evidence/phase0/structural_doc_linkage.json"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-10: Verifier trigger name (CI_GATES)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-10" "N/A" "Fix verifier trigger name" "CI_GATES" \
    "scripts/db/verify_tsk_p2_preauth_005_08.sh" \
    "" "" \
    "scripts/db/verify_tsk_p2_preauth_005_08.sh|evidence/phase2/tsk_p2_w5_fix_10.json|docs/plans/phase2/TSK-P2-W5-FIX-10/EXEC_LOG.md"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-11: Meta migration refs (CI_GATES)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-11" "N/A" "Correct meta migration refs" "CI_GATES" \
    "scripts/audit/verify_meta_migration_refs.sh" \
    "" "" \
    "scripts/audit/verify_meta_migration_refs.sh|evidence/phase2/tsk_p2_w5_fix_11.json|docs/plans/phase2/TSK-P2-W5-FIX-11/EXEC_LOG.md"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-12: Behavioral verifiers (CI_GATES)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-12" "N/A" "Convert to behavioral verifiers" "CI_GATES" \
    "scripts/db/verify_tsk_p2_preauth_005_00.sh|scripts/db/verify_tsk_p2_preauth_005_01.sh|scripts/db/verify_tsk_p2_preauth_005_02.sh|scripts/db/verify_tsk_p2_preauth_005_03.sh|scripts/db/verify_tsk_p2_preauth_005_04.sh|scripts/db/verify_tsk_p2_preauth_005_05.sh|scripts/db/verify_tsk_p2_preauth_005_06.sh|scripts/db/verify_tsk_p2_preauth_005_07.sh|scripts/db/verify_tsk_p2_preauth_005_08.sh" \
    "" "" \
    "scripts/db/verify_tsk_p2_preauth_005_00.sh|scripts/db/verify_tsk_p2_preauth_005_01.sh|scripts/db/verify_tsk_p2_preauth_005_02.sh|scripts/db/verify_tsk_p2_preauth_005_03.sh|scripts/db/verify_tsk_p2_preauth_005_04.sh|scripts/db/verify_tsk_p2_preauth_005_05.sh|scripts/db/verify_tsk_p2_preauth_005_06.sh|scripts/db/verify_tsk_p2_preauth_005_07.sh|scripts/db/verify_tsk_p2_preauth_005_08.sh|evidence/phase2/tsk_p2_w5_fix_12.json|docs/plans/phase2/TSK-P2-W5-FIX-12/EXEC_LOG.md"

# ═══════════════════════════════════════════════════════════════════════════
# FIX-13: Integration verifier (CI_GATES)
# ═══════════════════════════════════════════════════════════════════════════
inject_v3 "TSK-P2-W5-FIX-13" "N/A" "Integration verifier" "CI_GATES" \
    "scripts/db/verify_wave5_state_machine_integration.sh" \
    "" "" \
    "scripts/db/verify_wave5_state_machine_integration.sh|evidence/phase2/tsk_p2_w5_fix_13.json|docs/plans/phase2/TSK-P2-W5-FIX-13/EXEC_LOG.md"

echo ""
echo "=== VERIFICATION ==="
for t in TSK-P2-W5-FIX-{01,02,03,04,05,06,07,08,09,10,11,12,13}; do
    HAS_REG=$(grep -c 'regulated_surface_compliance:' "tasks/${t}/meta.yml" 2>/dev/null || echo 0)
    HAS_REM=$(grep -c 'remediation_trace_compliance:' "tasks/${t}/meta.yml" 2>/dev/null || echo 0)
    HAS_DB=$(grep -c 'database_connection:' "tasks/${t}/meta.yml" 2>/dev/null || echo 0)
    HAS_MIG=$(grep -c 'migration_dependencies:' "tasks/${t}/meta.yml" 2>/dev/null || echo 0)
    HAS_DEL=$(grep -c 'deliverable_files:' "tasks/${t}/meta.yml" 2>/dev/null || echo 0)
    echo "$t: reg=$HAS_REG rem=$HAS_REM db=$HAS_DB mig=$HAS_MIG del=$HAS_DEL"
done
