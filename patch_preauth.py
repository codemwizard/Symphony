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

def fix_plpgsql_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if 'v_interp UUID :=' not in content:
        content = re.sub(r'(DECLARE\s+)', r'\1v_interp UUID := gen_random_uuid();\n    ', content)

    content = re.sub(r'(INSERT INTO execution_records[^\n]*\n\s*VALUES\s*\([^\)]*?),\s*gen_random_uuid\(\)', r'\1, v_interp', content)

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

for f in files_plpgsql:
    fix_plpgsql_file(f)

print("Preauth files patched.")
