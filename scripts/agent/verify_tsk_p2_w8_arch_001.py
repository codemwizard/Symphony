#!/usr/bin/env python3
"""
Verifier for TSK-P2-W8-ARCH-001: Canonical attestation payload contract

This script verifies that the canonical attestation payload contract has been
created and contains the required content as specified in the task plan.
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
    task_id = "TSK-P2-W8-ARCH-001"
    git_sha = get_git_sha()
    timestamp_utc = datetime.now(timezone.utc).isoformat()
    
    checks = []
    observed_paths = []
    observed_hashes = {}
    command_outputs = []
    
    # Define required deliverables
    contract_path = "docs/contracts/CANONICAL_ATTESTATION_PAYLOAD_v1.md"
    
    # Check contract exists and get hash
    exists, result = check_file_exists(contract_path, "Canonical attestation payload contract")
    if exists:
        observed_paths.append(contract_path)
        observed_hashes[contract_path] = result
        checks.append({
            "check": "Canonical attestation payload contract exists",
            "status": "PASS",
            "detail": f"Hash: {result}"
        })
        command_outputs.append(f"✓ Contract exists at {contract_path}")
        
        # Check required content for work item 01 (field set)
        required_strings_01 = [
            "contract_version",
            "canonicalization_version",
            "project_id",
            "entity_type",
            "entity_id",
            "from_state",
            "to_state",
            "execution_id",
            "interpretation_version_id",
            "policy_decision_id",
            "transition_hash",
            "occurred_at"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_01,
            "Contract field set"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_001_work_01] Field set defined",
                "status": "PASS",
                "detail": "All 12 fields present"
            })
            command_outputs.append("✓ [ID w8_arch_001_work_01] Field set defined with all 12 fields")
        else:
            checks.append({
                "check": "[ID w8_arch_001_work_01] Field set defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_001_work_01] Field set check failed: {result}")
        
        # Check required content for work item 02 (canonicalization rules)
        required_strings_02 = [
            "Null values are forbidden",
            "lowercase canonical 8-4-4-4-12 form",
            "RFC 3339 format",
            "RFC 8785",
            "UTF-8"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_02,
            "Contract canonicalization rules"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_001_work_02] Canonicalization rules defined",
                "status": "PASS",
                "detail": "Null, UUID, timestamp, UTF-8, and canonicalization rules present"
            })
            command_outputs.append("✓ [ID w8_arch_001_work_02] Canonicalization rules defined")
        else:
            checks.append({
                "check": "[ID w8_arch_001_work_02] Canonicalization rules defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_001_work_02] Canonicalization rules check failed: {result}")
        
        # Check required content for work item 03 (byte-level test vectors)
        required_strings_03 = [
            "Byte-Level Test Vectors",
            "Canonical JSON",
            "UTF-8 bytes",
            "SHA-256 hash"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_03,
            "Contract test vectors"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_001_work_03] Byte-level test vectors present",
                "status": "PASS",
                "detail": "Test vectors with canonical JSON and byte representation present"
            })
            command_outputs.append("✓ [ID w8_arch_001_work_03] Byte-level test vectors present")
        else:
            checks.append({
                "check": "[ID w8_arch_001_work_03] Byte-level test vectors present",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_001_work_03] Test vectors check failed: {result}")
        
        # Check required content for work item 04 (link to closure rubric)
        required_strings_04 = [
            "WAVE8_CLOSURE_RUBRIC",
            "authoritative source",
            "downstream"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_04,
            "Contract closure rubric link"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_001_work_04] Linked to Wave 8 closure rubric",
                "status": "PASS",
                "detail": "Contract references closure rubric as authoritative source"
            })
            command_outputs.append("✓ [ID w8_arch_001_work_04] Linked to Wave 8 closure rubric")
        else:
            checks.append({
                "check": "[ID w8_arch_001_work_04] Linked to Wave 8 closure rubric",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_001_work_04] Closure rubric link check failed: {result}")
    else:
        checks.append({
            "check": "Canonical attestation payload contract exists",
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
            "verify_tsk_p2_w8_arch_001.py executed",
            f"Checked contract at {contract_path}",
            f"Verified work item 01: field set definition",
            f"Verified work item 02: canonicalization rules",
            f"Verified work item 03: byte-level test vectors",
            f"Verified work item 04: closure rubric link",
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
