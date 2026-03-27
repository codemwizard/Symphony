#!/usr/bin/env python3
import argparse
import sys
import json
import yaml

def load_task_meta(file_path: str) -> dict:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except Exception as e:
        sys.stderr.write(f"ERROR: Failed to parse YAML -> {e}\n")
        sys.exit(1)
        
    if not isinstance(data, dict):
        sys.stderr.write("ERROR: Root of meta.yml must be a dictionary.\n")
        sys.exit(1)
        
    required_fields = ["task_id", "schema_version", "status", "touches"]
    for field in required_fields:
        if field not in data:
            sys.stderr.write(f"ERROR: Malformed metadata. Missing required field: {field}\n")
            sys.exit(1)
            
    return data

def main():
    parser = argparse.ArgumentParser(description="Deterministic Task Metadata Loader")
    parser.add_argument("--meta", required=True, help="Path to the task meta.yml file")
    args = parser.parse_args()
    
    data = load_task_meta(args.meta)
    
    # Output deterministic JSON to stdout for runner consumption
    print(json.dumps(data, indent=2, sort_keys=True))

if __name__ == "__main__":
    main()
