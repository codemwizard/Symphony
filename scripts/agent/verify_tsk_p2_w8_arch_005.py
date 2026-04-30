#!/usr/bin/env python3
"""
Verifier for TSK-P2-W8-ARCH-005: System design patch for authoritative trigger model

This script verifies that the system design has been patched with Wave 8
requirements as specified in the task plan.
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
    task_id = "TSK-P2-W8-ARCH-005"
    git_sha = get_git_sha()
    timestamp_utc = datetime.now(timezone.utc).isoformat()
    
    checks = []
    observed_paths = []
    observed_hashes = {}
    command_outputs = []
    
    # Define required deliverables
    design_path = "docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md"
    
    # Check design exists and get hash
    exists, result = check_file_exists(design_path, "Data authority system design")
    if exists:
        observed_paths.append(design_path)
        observed_hashes[design_path] = result
        checks.append({
            "check": "Data authority system design exists",
            "status": "PASS",
            "detail": f"Hash: {result}"
        })
        command_outputs.append(f"✓ Design exists at {design_path}")
        
        # Check required content for work item 01 (asset_batches as authoritative boundary)
        required_strings_01 = [
            "Wave 8",
            "asset_batches",
            "sole authoritative boundary",
            "Contract documents",
            "define Wave 8 semantics",
            "SQL runtime behavior must conform"
        ]
        contains, result = check_file_contains(
            design_path,
            required_strings_01,
            "Design Wave 8 authoritative boundary"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_005_work_01] Wave 8 authoritative boundary defined",
                "status": "PASS",
                "detail": "asset_batches named as sole authoritative Wave 8 boundary, contract authority distinguished from SQL runtime"
            })
            command_outputs.append("✓ [ID w8_arch_005_work_01] Wave 8 authoritative boundary defined")
        else:
            checks.append({
                "check": "[ID w8_arch_005_work_01] Wave 8 authoritative boundary defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_005_work_01] Wave 8 authoritative boundary check failed: {result}")
        
        # Check required content for work item 02 (one dispatcher trigger, equality invariants, no lexical order)
        required_strings_02 = [
            "single dispatcher trigger",
            "Cross-Table Equality Invariants",
            "Zero Lexical Trigger-Order Reliance",
            "explicit invocation order"
        ]
        contains, result = check_file_contains(
            design_path,
            required_strings_02,
            "Design dispatcher trigger and equality invariants"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_005_work_02] One dispatcher trigger and equality invariants defined",
                "status": "PASS",
                "detail": "One dispatcher trigger, explicit equality invariants, zero lexical trigger-order reliance present"
            })
            command_outputs.append("✓ [ID w8_arch_005_work_02] One dispatcher trigger and equality invariants defined")
        else:
            checks.append({
                "check": "[ID w8_arch_005_work_02] One dispatcher trigger and equality invariants defined",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_005_work_02] Dispatcher trigger check failed: {result}")
        
        # Check required content for work item 03 (no-credit, no advisory fallback, unavailable-crypto hard-fail)
        required_strings_03 = [
            "No-Credit Rule",
            "No Advisory Fallback Rule",
            "Unavailable-Crypto Hard-Fail Rule"
        ]
        contains, result = check_file_contains(
            design_path,
            required_strings_03,
            "Design Wave 8 rules"
        )
        if contains:
            checks.append({
                "check": "[ID w8_arch_005_work_03] Wave 8 rules recorded",
                "status": "PASS",
                "detail": "No-credit, no advisory fallback, and unavailable-crypto hard-fail rules recorded"
            })
            command_outputs.append("✓ [ID w8_arch_005_work_03] Wave 8 rules recorded")
        else:
            checks.append({
                "check": "[ID w8_arch_005_work_03] Wave 8 rules recorded",
                "status": "FAIL",
                "detail": result
            })
            command_outputs.append(f"✗ [ID w8_arch_005_work_03] Wave 8 rules check failed: {result}")
    else:
        checks.append({
            "check": "Data authority system design exists",
            "status": "FAIL",
            "detail": result
        })
        command_outputs.append(f"✗ Design check failed: {result}")
    
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
            "verify_tsk_p2_w8_arch_005.py executed",
            f"Checked design at {design_path}",
            f"Verified work item 01: Wave 8 authoritative boundary",
            f"Verified work item 02: dispatcher trigger and equality invariants",
            f"Verified work item 03: Wave 8 rules",
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
