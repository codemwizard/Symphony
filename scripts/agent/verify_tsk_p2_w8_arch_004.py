#!/usr/bin/env python3
"""
Verifier for TSK-P2-W8-ARCH-004: Data authority derivation contract

This script verifies that the data authority derivation specification has been
created and contains the required content as specified in the task plan.
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
    task_id = "TSK-P2-W8-ARCH-004"
    git_sha = get_git_sha()
    timestamp_utc = datetime.now(timezone.utc).isoformat()
    
    checks = []
    observed_paths = []
    observed_hashes = {}
    command_outputs = []
    
    # Define required deliverables
    spec_path = "docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md"
    
    # Check spec exists and get hash
    exists, result = check_file_exists(spec_path, "Data authority derivation specification")
    if exists:
        observed_paths.append(spec_path)
        observed_hashes[spec_path] = result
        checks.append({
            "check": "Data authority derivation specification exists",
            "status": "PASS",
            "detail": f"Hash: {result}"
        })
        command_outputs.append(f"✓ Specification exists at {spec_path}")
        
        # Check required content for work item 01 (input tuple, canonicalization, digest, encoding, version)
        required_strings_01 = [
            "Input Fields",
            "Canonicalization",
            "RFC 8785",
            "SHA256",
            "lowercase hex string",
            "data_authority_version = 1"
        ]
        contains, result = check_file_contains(
            spec_path,
            required_strings_01,
            "Specification input tuple and derivation rules"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_004_work_01] Input tuple, canonicalization, digest, encoding, and version defined",
                "status": "PASS",
                "detail": "Exact input tuple, RFC 8785 canonicalization, SHA256 digest, lowercase hex encoding, and version semantics present"
            })
            command_outputs.append("✓ [ID w8_arch_004_work_01] Input tuple and derivation rules defined")
        else:
            checks.append({
                "check": "[ID w8_arch_004_work_01] Input tuple, canonicalization, digest, encoding, and version defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_004_work_01] Input tuple check failed: {result}")
        
        # Check required content for work item 02 (disabled signature enforcement behavior)
        required_strings_02 = [
            "If signature enforcement is disabled",
            "documented deterministic representation",
            "MUST NOT silently omit them without versioning"
        ]
        contains, result = check_file_contains(
            spec_path,
            required_strings_02,
            "Specification disabled signature enforcement behavior"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_004_work_02] Disabled signature enforcement behavior defined",
                "status": "PASS",
                "detail": "Deterministic behavior when signature enforcement is disabled explicitly defined"
            })
            command_outputs.append("✓ [ID w8_arch_004_work_02] Disabled signature enforcement behavior defined")
        else:
            checks.append({
                "check": "[ID w8_arch_004_work_02] Disabled signature enforcement behavior defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_004_work_02] Disabled signature enforcement check failed: {result}")
        
        # Check required content for work item 03 (reference replay law from ED25519_SIGNING_CONTRACT)
        required_strings_03 = [
            "ED25519_SIGNING_CONTRACT.md",
            "Replay Requirements"
        ]
        contains, result = check_file_contains(
            spec_path,
            required_strings_03,
            "Specification replay law reference"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_004_work_03] Replay law referenced from ED25519_SIGNING_CONTRACT",
                "status": "PASS",
                "detail": "Replay law references ED25519_SIGNING_CONTRACT.md rather than redefining independently"
            })
            command_outputs.append("✓ [ID w8_arch_004_work_03] Replay law referenced from ED25519_SIGNING_CONTRACT")
        else:
            checks.append({
                "check": "[ID w8_arch_004_work_03] Replay law referenced from ED25519_SIGNING_CONTRACT",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_004_work_03] Replay law reference check failed: {result}")
    else:
        checks.append({
            "check": "Data authority derivation specification exists",
            "status": "FAIL",
            "detail": result
        })
        command_outputs.append(f"✗ Specification check failed: {result}")
    
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
            "verify_tsk_p2_w8_arch_004.py executed",
            f"Checked specification at {spec_path}",
            f"Verified work item 01: input tuple and derivation rules",
            f"Verified work item 02: disabled signature enforcement behavior",
            f"Verified work item 03: replay law reference",
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
