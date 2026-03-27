#!/usr/bin/env python3
import argparse
import sys
import yaml
import json
from pathlib import Path
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from task_gate_result import GateResult

def main():
    parser = argparse.ArgumentParser(description="Report-Only Task Contract Gate")
    parser.add_argument("--meta", required=True, help="Path to task meta.yml")
    args = parser.parse_args()

    meta_path = Path(args.meta)
    
    if not meta_path.exists():
        res = GateResult(
            status="FAIL",
            failure_class="MISSING_META",
            message=f"Task metadata file missing: {meta_path}",
            gate_identity="task_contract_gate.py"
        )
        print(res.to_json())
        sys.exit(0)
    
    try:
        with open(meta_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except Exception as e:
        res = GateResult(
            status="FAIL",
            failure_class="UNPARSEABLE_YAML",
            message=f"Failed to parse YAML: {e}",
            gate_identity="task_contract_gate.py"
        )
        print(res.to_json())
        sys.exit(0) 

    if not isinstance(data, dict):
        res = GateResult(
            status="FAIL",
            failure_class="ROOT_NOT_DICT",
            message="Root of meta.yml must be a dictionary.",
            gate_identity="task_contract_gate.py"
        )
        print(res.to_json())
        sys.exit(0)

    # Required fields Check
    required_fields = ["schema_version", "phase", "task_id", "title", "owner_role", "status", "touches"]
    missing = [f for f in required_fields if f not in data]
    
    if missing:
        res = GateResult(
            status="FAIL",
            failure_class="MISSING_FIELDS",
            message=f"Missing required fields: {', '.join(missing)}",
            gate_identity="task_contract_gate.py"
        )
        print(res.to_json())
        sys.exit(0)

    # Touch-path resolution check
    touches = data.get("touches", [])
    if not isinstance(touches, list):
        res = GateResult(
            status="FAIL",
            failure_class="INVALID_TOUCHES",
            message="'touches' must be a list of paths.",
            gate_identity="task_contract_gate.py"
        )
        print(res.to_json())
        sys.exit(0)
        
    repo_root = Path(__file__).resolve().parent.parent.parent
    invalid_paths = []
    
    for t in touches:
        try:
            # We enforce that all resolved relative paths don't traverse above repo root
            # using clean string checks rather than strict exists() since files may be newly created
            p = t.replace('\\', '/')
            if '..' in p.split('/'):
                invalid_paths.append(str(t))
        except Exception:
            invalid_paths.append(str(t))

    if invalid_paths:
        res = GateResult(
            status="FAIL",
            failure_class="INVALID_TOUCH_PATHS",
            message=f"Touch paths contain unsafe traversal: {', '.join(invalid_paths)}",
            gate_identity="task_contract_gate.py"
        )
        print(res.to_json())
        sys.exit(0)

    res = GateResult(
        status="PASS",
        failure_class="NONE",
        message="Task pack contract validation passed.",
        gate_identity="task_contract_gate.py"
    )
    print(res.to_json())
    sys.exit(0)

if __name__ == "__main__":
    main()
