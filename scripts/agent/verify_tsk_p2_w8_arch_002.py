#!/usr/bin/env python3
"""
Verifier for TSK-P2-W8-ARCH-002: Transition hash contract

This script verifies that the transition hash contract has been created and
contains the required content as specified in the task plan.
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone

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
    task_id = "TSK-P2-W8-ARCH-002"
    git_sha = get_git_sha()
    timestamp_utc = datetime.now(timezone.utc).isoformat()
    
    checks = []
    observed_paths = []
    observed_hashes = {}
    command_outputs = []
    
    # Define required deliverables
    contract_path = "docs/contracts/TRANSITION_HASH_CONTRACT.md"
    
    # Check contract exists and get hash
    exists, result = check_file_exists(contract_path, "Transition hash contract")
    if exists:
        observed_paths.append(contract_path)
        observed_hashes[contract_path] = result
        checks.append({
            "check": "Transition hash contract exists",
            "status": "PASS",
            "detail": f"Hash: {result}"
        })
        command_outputs.append(f"✓ Contract exists at {contract_path}")
        
        # Check required content for work item 01 (field set and prohibited extras)
        required_strings_01 = [
            "project_id",
            "entity_type",
            "entity_id",
            "from_state",
            "to_state",
            "execution_id",
            "interpretation_version_id",
            "policy_decision_id",
            "MUST NOT be included",
            "signature",
            "data_authority"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_01,
            "Contract field set and prohibited extras"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_002_work_01] Field set and prohibited extras defined",
                "status": "PASS",
                "detail": "Input fields and prohibited extras explicitly defined"
            })
            command_outputs.append("✓ [ID w8_arch_002_work_01] Field set and prohibited extras defined")
        else:
            checks.append({
                "check": "[ID w8_arch_002_work_01] Field set and prohibited extras defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_002_work_01] Field set check failed: {result}")
        
        # Check required content for work item 02 (SHA-256, encoding, ordering)
        required_strings_02 = [
            "SHA-256",
            "lowercase hexadecimal",
            "RFC 8785",
            "hash computation occurs before signature generation",
            "Ordering Constraints"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_02,
            "Contract hash algorithm and ordering"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_002_work_02] SHA-256, encoding, and ordering defined",
                "status": "PASS",
                "detail": "RFC 8785 canonicalization, SHA-256, lowercase hex, hash-before-signature ordering present"
            })
            command_outputs.append("✓ [ID w8_arch_002_work_02] SHA-256, encoding, and ordering defined")
        else:
            checks.append({
                "check": "[ID w8_arch_002_work_02] SHA-256, encoding, and ordering defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_002_work_02] Hash algorithm check failed: {result}")
        
        # Check required content for work item 03 (mismatch semantics and failure classes)
        required_strings_03 = [
            "Mismatch MUST result in rejection",
            "TRANSITION_HASH_INPUT_INVALID",
            "TRANSITION_HASH_CANONICALIZATION_FAILURE",
            "TRANSITION_HASH_MISMATCH"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_03,
            "Contract mismatch semantics and failure classes"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_002_work_03] Mismatch semantics and failure classes defined",
                "status": "PASS",
                "detail": "Fail-closed mismatch semantics and named failure classes present"
            })
            command_outputs.append("✓ [ID w8_arch_002_work_03] Mismatch semantics and failure classes defined")
        else:
            checks.append({
                "check": "[ID w8_arch_002_work_03] Mismatch semantics and failure classes defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_002_work_03] Mismatch semantics check failed: {result}")
    else:
        checks.append({
            "check": "Transition hash contract exists",
            "status": "FAIL",
            "detail": result
        })
        command_outputs.append(f"✗ Contract check failed: {result}")
    
    # Determine overall status
    all_passed = all(check["status"] == "PASS" for check in checks)
    
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
            "verify_tsk_p2_w8_arch_002.py executed",
            f"Checked contract at {contract_path}",
            f"Verified work item 01: field set and prohibited extras",
            f"Verified work item 02: SHA-256, encoding, and ordering",
            f"Verified work item 03: mismatch semantics and failure classes",
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
