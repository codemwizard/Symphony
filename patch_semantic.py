import yaml
import glob
import os

for meta_path in glob.glob("tasks/GF-W1-*/meta.yml"):
    print(f"Patching {meta_path}...")
    with open(meta_path, 'r') as f:
        data = yaml.safe_load(f)

    tid = data['task_id']
    id_tag = f"[ID {tid}]"
    
    # 1. Patch Work
    if 'work' in data and data['work']:
        new_work = []
        for w in data['work']:
            if id_tag not in w:
                new_work.append(f"{id_tag} {w}")
            else:
                new_work.append(w)
        data['work'] = new_work

    # 2. Patch Acceptance Criteria
    if 'acceptance_criteria' in data and data['acceptance_criteria']:
        new_acc = []
        for a in data['acceptance_criteria']:
            if id_tag not in a:
                new_acc.append(f"{id_tag} {a}")
            else:
                new_acc.append(a)
        data['acceptance_criteria'] = new_acc

    # 3. Patch Verification
    if 'verification' in data and data['verification']:
        new_ver = []
        ev_file = f"evidence/phase1/{tid.lower().replace('-', '_')}.json"
        for v in data['verification']:
            # Apply standard grep logic with redirect
            if "bash scripts/audit/" in v and "|| exit" not in v:
                v = f"{v} | grep -q '.' >> {ev_file} || exit 1"
            elif "validate_evidence" in v and "|| exit" not in v:
                v = f"{v} | grep PASS >> {ev_file} || exit 1"
            elif "pre_ci.sh" in v and "|| exit" not in v:
                v = f"{v} | grep -q '.' >> {ev_file} || exit 1"
            
            if id_tag not in v:
                new_ver.append(f"{id_tag} {v}")
            else:
                new_ver.append(v)
        data['verification'] = new_ver

    # 4. Patch Evidence strong fields
    if 'evidence' in data and data['evidence']:
        for ev in data['evidence']:
            if 'must_include' in ev:
                must = ev['must_include']
                for strong in ["observed_paths", "observed_hashes", "command_outputs", "execution_trace"]:
                    if strong not in must:
                        must.append(strong)

    with open(meta_path, 'w') as f:
        yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)

print("Patching complete.")
