import yaml
import glob
from pathlib import Path

for meta_file in glob.glob("tasks/GF-W1-*/meta.yml"):
    print(f"Fixing {meta_file}")
    with open(meta_file, "r") as f:
        content = f.read()
    
    # We want to add pre_ci.sh to the verification block
    # It might be easier to just do string replacement
    
    if "bash scripts/dev/pre_ci.sh" not in content:
        content = content.replace("verification:\n", "verification:\n  - bash scripts/dev/pre_ci.sh\n")
    
    with open(meta_file, "w") as f:
        f.write(content)
