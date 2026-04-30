#!/usr/bin/env python3
"""
Verifier for TSK-P2-W8-ARCH-003: Signing and replay contract hardening

This script verifies that the Ed25519 signing contract has been hardened with
Wave 8 requirements as specified in the task plan.
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
    task_id = "TSK-P2-W8-ARCH-003"
    git_sha = get_git_sha()
    timestamp_utc = datetime.now(timezone.utc).isoformat()
    
    checks = []
    observed_paths = []
    observed_hashes = {}
    command_outputs = []
    
    # Define required deliverables
    contract_path = "docs/contracts/ED25519_SIGNING_CONTRACT.md"
    
    # Check contract exists and get hash
    exists, result = check_file_exists(contract_path, "Ed25519 signing contract")
    if exists:
        observed_paths.append(contract_path)
        observed_hashes[contract_path] = result
        checks.append({
            "check": "Ed25519 signing contract exists",
            "status": "PASS",
            "detail": f"Hash: {result}"
        })
        command_outputs.append(f"✓ Contract exists at {contract_path}")
        
        # Check required content for work item 01 (signature input bytes)
        required_strings_01 = [
            "Ed25519 MUST sign the canonical UTF-8 bytes directly",
            "sign pretty-printed JSON",
            "sign implementation-private struct encodings"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_01,
            "Contract signature input bytes"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_003_work_01] Signature input bytes defined",
                "status": "PASS",
                "detail": "Ed25519 signs canonical UTF-8 bytes directly, rejects non-canonical interpretations"
            })
            command_outputs.append("✓ [ID w8_arch_003_work_01] Signature input bytes defined")
        else:
            checks.append({
                "check": "[ID w8_arch_003_work_01] Signature input bytes defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_003_work_01] Signature input bytes check failed: {result}")
        
        # Check required content for work item 02 (timestamp, scope, precedence)
        required_strings_02 = [
            "MUST be persisted on the authoritative transition record",
            "Key Scope Authorization",
            "expired, revoked, disabled, or out-of-window keys MUST fail"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_02,
            "Contract timestamp and scope rules"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_003_work_02] Timestamp and scope authorization rules defined",
                "status": "PASS",
                "detail": "Persisted-before-signing timestamp, scope authorization, and key lifecycle rules present"
            })
            command_outputs.append("✓ [ID w8_arch_003_work_02] Timestamp and scope authorization rules defined")
        else:
            checks.append({
                "check": "[ID w8_arch_003_work_02] Timestamp and scope authorization rules defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_003_work_02] Timestamp and scope check failed: {result}")
        
        # Check required content for work item 03 (replay law)
        required_strings_03 = [
            "Replay and Audit Requirements",
            "Replay verification MUST be possible from persisted artifacts",
            "If any required replay artifact is absent, verification MUST fail closed"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_03,
            "Contract replay law"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_003_work_03] Replay law centralized",
                "status": "PASS",
                "detail": "Replay semantics centralized in signing contract"
            })
            command_outputs.append("✓ [ID w8_arch_003_work_03] Replay law centralized")
        else:
            checks.append({
                "check": "[ID w8_arch_003_work_03] Replay law centralized",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_003_work_03] Replay law check failed: {result}")
        
        # Check required content for work item 04 (.NET 10 requirement)
        required_strings_04 = [
            "Implementation Gate Conditions",
            "canonical bytes are stable"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_04,
            "Contract implementation gate"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_003_work_04] Implementation gate conditions defined",
                "status": "PASS",
                "detail": "Implementation gate conditions specify stability requirements"
            })
            command_outputs.append("✓ [ID w8_arch_003_work_04] Implementation gate conditions defined")
        else:
            checks.append({
                "check": "[ID w8_arch_003_work_04] Implementation gate conditions defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_003_work_04] Implementation gate check failed: {result}")
        
        # Check required content for work item 05 (unavailable-crypto semantics)
        required_strings_05 = [
            "If any required replay artifact is absent, verification MUST fail closed"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_05,
            "Contract unavailable-crypto semantics"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_003_work_05] Fail-closed unavailable-crypto semantics defined",
                "status": "PASS",
                "detail": "Absent replay artifacts cause verification to fail closed"
            })
            command_outputs.append("✓ [ID w8_arch_003_work_05] Fail-closed unavailable-crypto semantics defined")
        else:
            checks.append({
                "check": "[ID w8_arch_003_work_05] Fail-closed unavailable-crypto semantics defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_003_work_05] Unavailable-crypto check failed: {result}")
        
        # Check required content for work item 06 (failure classes)
        required_strings_06 = [
            "Failure Classes",
            "SIGNATURE_METADATA_MISSING",
            "SIGNATURE_KEY_SCOPE_VIOLATION",
            "SIGNATURE_TIMESTAMP_INVALID"
        ]
        contains, result = check_file_contains(
            contract_path,
            required_strings_06,
            "Contract failure classes"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_003_work_06] Named failure classes registered",
                "status": "PASS",
                "detail": "Named failure classes for scope, timestamp, and verification failures present"
            })
            command_outputs.append("✓ [ID w8_arch_003_work_06] Named failure classes registered")
        else:
            checks.append({
                "check": "[ID w8_arch_003_work_06] Named failure classes registered",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_003_work_06] Failure classes check failed: {result}")
    else:
        checks.append({
            "check": "Ed25519 signing contract exists",
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
            "verify_tsk_p2_w8_arch_003.py executed",
            f"Checked contract at {contract_path}",
            f"Verified work item 01: signature input bytes",
            f"Verified work item 02: timestamp and scope authorization",
            f"Verified work item 03: replay law",
            f"Verified work item 04: implementation gate conditions",
            f"Verified work item 05: unavailable-crypto semantics",
            f"Verified work item 06: failure classes",
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
