#!/usr/bin/env python3
"""
Verifier for TSK-P2-W8-GOV-001: Wave 8 governance truth repair

This script verifies that all governance artifacts have been created and contain
the required content as specified in the task plan.
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

def get_git_sha():
    """Get the current Git commit SHA."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return "unknown"

def check_file_exists(path, description):
    """Check if a file exists and return its hash."""
    if not os.path.exists(path):
        return False, f"{description} not found at {path}"
    
    try:
        result = subprocess.run(
            ["sha256sum", path],
            capture_output=True,
            text=True,
            check=True
        )
        file_hash = result.stdout.split()[0]
        return True, file_hash
    except subprocess.CalledProcessError:
        return False, f"Failed to compute hash for {path}"

def check_file_contains(path, required_strings, description):
    """Check if a file contains required strings."""
    if not os.path.exists(path):
        return False, f"{description} not found at {path}"
    
    try:
        with open(path, 'r') as f:
            content = f.read()
        
        missing = []
        for req in required_strings:
            if req not in content:
                missing.append(req)
        
        if missing:
            return False, f"{description} missing required strings: {', '.join(missing)}"
        
        return True, "OK"
    except Exception as e:
        return False, f"Failed to read {path}: {e}"

def main():
    """Main verification function."""
    task_id = "TSK-P2-W8-GOV-001"
    git_sha = get_git_sha()
    timestamp_utc = datetime.now(timezone.utc).isoformat()
    
    checks = []
    observed_paths = []
    observed_hashes = {}
    command_outputs = []
    
    # Define required deliverables
    deliverables = {
        "docs/governance/WAVE8_GOVERNANCE_REMEDIATION_ADR.md": {
            "description": "Governance remediation ADR",
            "required_strings": [
                "asset_batches",
                "Contract authority outranks implementation authority",
                "No advisory fallback"
            ]
        },
        "docs/governance/WAVE8_TASK_STATUS_MATRIX.md": {
            "description": "Task status matrix",
            "required_strings": [
                "TSK-P2-REG-",
                "Scaffold",
                "TSK-P2-W8-GOV-001"
            ]
        },
        "docs/governance/WAVE8_FALSE_COMPLETION_REVOCATION_LEDGER.md": {
            "description": "False completion revocation ledger",
            "required_strings": [
                "Revocation Criteria",
                "TSK-P2-REG-",
                "TSK-P2-W8-DB-007"
            ]
        },
        "docs/governance/WAVE8_MIGRATION_HEAD_TRUTH_TABLE.md": {
            "description": "Migration head truth table",
            "required_strings": [
                "asset_batches",
                "0172",
                "0180"
            ]
        },
        "docs/governance/WAVE8_CLOSURE_RUBRIC.md": {
            "description": "Closure rubric",
            "required_strings": [
                "asset_batches",
                "Evidence Completeness",
                "Regulated Surface Compliance"
            ]
        },
        "docs/governance/WAVE8_PROOF_INTEGRITY_THREAT_REGISTER.md": {
            "description": "Proof integrity threat register",
            "required_strings": [
                "Detached Function Proof",
                "Grep Proof",
                "Reflection-Only Surface Proof",
                "Toy-Crypto Proof"
            ]
        },
        "docs/governance/WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md": {
            "description": "Evidence admissibility policy",
            "required_strings": [
                "Admissible Proof Forms",
                "Inadmissible Proof Forms",
                "Reflection-Only Surface Proof"
            ]
        },
        "docs/governance/WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md": {
            "description": "False completion pattern catalog",
            "required_strings": [
                "Detached Function Proof",
                "Grep Proof",
                "Toy-Crypto Proof",
                "Mirrored-Vector Fraud"
            ]
        }
    }
    
    # Check each deliverable
    all_passed = True
    for file_path, spec in deliverables.items():
        # Check file exists and get hash
        exists, result = check_file_exists(file_path, spec["description"])
        if exists:
            observed_paths.append(file_path)
            observed_hashes[file_path] = result
            checks.append({
                "check": f"{spec['description']} exists",
                "status": "PASS",
                "detail": f"Hash: {result}"
            })
            command_outputs.append(f"✓ {spec['description']} exists at {file_path}")
            
            # Check required content
            contains, result = check_file_contains(
                file_path,
                spec["required_strings"],
                spec["description"]
            )
            if contains:
                checks.append({
                    "check": f"{spec['description']} content validation",
                    "status": "PASS",
                    "detail": "All required strings present"
                })
                command_outputs.append(f"✓ {spec['description']} contains required content")
            else:
                all_passed = False
                checks.append({
                    "check": f"{spec['description']} content validation",
                    "status": "FAIL",
                    "detail": result
                })
                command_outputs.append(f"✗ {spec['description']} content validation failed: {result}")
        else:
            all_passed = False
            checks.append({
                "check": f"{spec['description']} exists",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ {spec['description']}: {result}")
    
    # Check PHASE2_TASKS.md was updated
    phase2_path = "docs/tasks/PHASE2_TASKS.md"
    exists, result = check_file_contains(
        phase2_path,
        ["Wave 8 Closure Track", "TSK-P2-W8-GOV-001", "TSK-P2-W8-DB-007a"],
        "PHASE2_TASKS.md"
    )
    if exists:
        checks.append({
            "check": "PHASE2_TASKS.md updated",
            "status": "PASS",
            "detail": "Wave 8 Closure Track registered"
        })
        command_outputs.append("✓ PHASE2_TASKS.md updated with Wave 8 Closure Track")
    else:
        all_passed = False
        checks.append({
            "check": "PHASE2_TASKS.md updated",
            "status": "FAIL",
            "detail": result
        })
        command_outputs.append(f"✗ PHASE2_TASKS.md change validation failed: {result}")
    
    # Build evidence
    evidence = {
        "task_id": task_id,
        "git_sha": git_sha,
        "timestamp_utc": timestamp_utc,
        "status": "PASS" if all_passed else "FAIL",
        "checks": checks,
        "observed_paths": observed_paths,
        "observed_hashes": observed_hashes,
        "command_outputs": command_outputs,
        "execution_trace": [
            "verify_tsk_p2_w8_gov_001.py executed",
            f"Checked {len(deliverables)} governance deliverables",
            f"Checked PHASE2_TASKS.md update",
            f"Total checks: {len(checks)}",
            f"Passed: {sum(1 for c in checks if c['status'] == 'PASS')}",
            f"Failed: {sum(1 for c in checks if c['status'] == 'FAIL')}"
        ]
    }
    
    # Output evidence
    print(json.dumps(evidence, indent=2))
    
    # Exit with appropriate code
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
