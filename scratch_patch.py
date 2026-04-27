import os
import re

files_plpgsql = [
    "scripts/db/verify_tsk_p2_preauth_005_01.sh",
    "scripts/db/verify_tsk_p2_preauth_005_03.sh",
    "scripts/db/verify_tsk_p2_preauth_005_04.sh",
    "scripts/db/verify_tsk_p2_preauth_005_05.sh",
    "scripts/db/verify_tsk_p2_preauth_005_06.sh",
    "scripts/db/verify_tsk_p2_preauth_005_07.sh",
    "scripts/db/verify_tsk_p2_preauth_005_08.sh"
]

files_shell = [
    "scripts/db/verify_tsk_p2_w5_fix_01.sh",
    "scripts/db/verify_tsk_p2_w5_fix_02.sh",
    "scripts/db/verify_tsk_p2_w5_fix_03.sh"
]

file_mixed = "scripts/db/verify_wave5_state_machine_integration.sh"

def fix_plpgsql_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Add v_interp to DECLARE if not there
    if 'v_interp UUID :=' not in content:
        content = re.sub(r'(DECLARE\s+)', r'\1v_interp UUID := gen_random_uuid();\n    ', content)

    # 2. Update execution_records insert to use v_interp instead of gen_random_uuid()
    # Pattern: VALUES (v_exec, v_proj, v_tenant, gen_random_uuid(), 'ih', 'oh', 'rv', 'pending')
    content = re.sub(r'(INSERT INTO execution_records[^\n]*\n\s*VALUES\s*\([^\)]*?),\s*gen_random_uuid\(\)', r'\1, v_interp', content)

    # 3. Add interpretation_version_id to positive test insert
    # Pattern: INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature)
    # VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_exec, v_pol, 'testhash1', repeat('0', 128));
    content = content.replace(
        'signature)', 
        'signature, interpretation_version_id)'
    )
    content = content.replace(
        "repeat('0', 128));",
        "repeat('0', 128), v_interp);"
    )

    with open(filepath, 'w') as f:
        f.write(content)

def fix_shell_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # I already added interpretation_version_id to columns and gen_random_uuid() to VALUES in these via sed earlier.
    # So I just need to replace gen_random_uuid() with the subquery.
    content = content.replace(
        "encode(sha256('test'::bytea), 'hex'), gen_random_uuid()",
        "encode(sha256('test'::bytea), 'hex'), (SELECT interpretation_version_id FROM execution_records WHERE execution_id = '$VALID_EXEC_ID')"
    )
    
    with open(filepath, 'w') as f:
        f.write(content)

def fix_mixed_file(filepath):
    # The integration script has PL/pgSQL blocks but I ran sed on it earlier
    with open(filepath, 'r') as f:
        content = f.read()
    
    # First revert my sed changes
    content = content.replace('signature, interpretation_version_id)', 'signature)')
    content = content.replace("repeat('0', 128), gen_random_uuid());", "repeat('0', 128));")
    
    with open(filepath, 'w') as f:
        f.write(content)
        
    # Then apply plpgsql fix
    fix_plpgsql_file(filepath)


for f in files_plpgsql:
    fix_plpgsql_file(f)

for f in files_shell:
    fix_shell_file(f)
    
fix_mixed_file(file_mixed)

print("All files patched cleanly.")
