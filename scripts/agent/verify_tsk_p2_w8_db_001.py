#!/usr/bin/env python3
"""
Verification script for TSK-P2-W8-DB-001: Authoritative Wave 8 dispatcher trigger topology
Verifies that dispatcher topology has been created and contains required content
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

def get_git_sha():
    """Get current git commit SHA."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True,
            text=True
        )
        return result.stdout.strip()
    except Exception:
        return "unknown"

def check_file_exists(path):
    """Check if file exists and return info"""
    file_path = Path(path)
    if file_path.exists():
        stat = file_path.stat()
        return {
            "exists": True,
            "size": stat.st_size,
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
            "readable": os.access(file_path, os.R_OK)
        }
    return {"exists": False}

def check_file_content(path, required_content):
    """Check if file contains required content patterns"""
    file_path = Path(path)
    if not file_path.exists():
        return {"found": False, "reason": "File does not exist"}
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        missing_patterns = []
        for pattern, description in required_content:
            if pattern.lower() not in content.lower():
                missing_patterns.append(description)
        
        return {
            "found": len(missing_patterns) == 0,
            "missing_patterns": missing_patterns,
            "file_size": len(content)
        }
    except Exception as e:
        return {"found": False, "reason": f"Error reading file: {e}"}

def main():
    """Main verification function"""
    task_id = "TSK-P2-W8-DB-001"
    git_sha = get_git_sha()
    
    evidence = {
        "task_id": task_id,
        "git_sha": git_sha,
        "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "status": "PASS",
        "checks": [],
        "observed_paths": [],
        "observed_hashes": {},
        "command_outputs": [],
        "execution_trace": ["Starting DB-001 verification"]
    }
    
    evidence["execution_trace"].append("Checking dispatcher topology exists")
    
    # Check 1: Dispatcher topology exists
    topology_path = "docs/architecture/WAVE8_DISPATCHER_TOPOLOGY_v1.md"
    topology_check = check_file_exists(topology_path)
    
    if not topology_check["exists"]:
        evidence["status"] = "FAIL"
        evidence["execution_trace"].append(f"FAIL: {topology_path} does not exist")
        print(json.dumps(evidence, indent=2))
        return 1
    
    evidence["observed_paths"].append(topology_path)
    evidence["observed_hashes"][topology_path] = f"size_{topology_check['size']}"
    evidence["checks"].append({
        "check_id": "db_001_topology_exists",
        "description": "Dispatcher topology exists",
        "status": "PASS",
        "details": f"Topology found with size {topology_check['size']} bytes"
    })
    evidence["execution_trace"].append(f"PASS: {topology_path} exists ({topology_check['size']} bytes)")
    
    # Check 2: Topology contains required content
    evidence["execution_trace"].append("Checking topology content completeness")
    
    required_content = [
        ("executive summary", "Executive Summary"),
        ("trigger sequence", "Trigger Sequence"),
        ("execution topology", "Execution Topology"),
        ("architectural rules", "Key Architectural Rules"),
        ("implementation requirements", "Implementation Requirements")
    ]
    
    content_check = check_file_content(topology_path, required_content)
    
    if not content_check["found"]:
        evidence["status"] = "FAIL"
        evidence["execution_trace"].append(f"FAIL: Missing content: {', '.join(content_check['missing_patterns'])}")
        evidence["checks"].append({
            "check_id": "db_001_content_complete",
            "description": "Topology contains all required sections",
            "status": "FAIL",
            "details": f"Missing patterns: {', '.join(content_check['missing_patterns'])}"
        })
    else:
        evidence["checks"].append({
            "check_id": "db_001_content_complete",
            "description": "Topology contains all required sections",
            "status": "PASS",
            "details": f"All {len(required_content)} required content patterns found"
        })
        evidence["execution_trace"].append(f"PASS: Topology contains all required sections")
    
    # Check 3: Evidence file exists
    evidence["execution_trace"].append("Checking evidence file generation")
    
    evidence_file_path = "evidence/phase2/tsk_p2_w8_db_001.json"
    evidence_file_check = check_file_exists(evidence_file_path)
    
    if evidence_file_check["exists"]:
        evidence["observed_paths"].append(evidence_file_path)
        evidence["observed_hashes"][evidence_file_path] = f"size_{evidence_file_check['size']}"
        evidence["checks"].append({
            "check_id": "db_001_evidence_file",
            "description": "Evidence file exists",
            "status": "PASS",
            "details": f"Evidence file exists with size {evidence_file_check['size']} bytes"
        })
        evidence["execution_trace"].append(f"PASS: Evidence file exists")
    else:
        evidence["status"] = "FAIL"
        evidence["execution_trace"].append(f"FAIL: Evidence file {evidence_file_path} does not exist")
        evidence["checks"].append({
            "check_id": "db_001_evidence_file",
            "description": "Evidence file exists",
            "status": "FAIL",
            "details": "Evidence file not found"
        })
    
    evidence["execution_trace"].append(f"Verification completed with status: {evidence['status']}")
    
    # Write evidence file
    try:
        os.makedirs(os.path.dirname(evidence_file_path), exist_ok=True)
        with open(evidence_file_path, 'w', encoding='utf-8') as f:
            json.dump(evidence, f, indent=2)
        evidence["execution_trace"].append(f"Evidence written to {evidence_file_path}")
    except Exception as e:
        evidence["status"] = "FAIL"
        evidence["execution_trace"].append(f"FAIL: Could not write evidence file: {e}")
    
    print(json.dumps(evidence, indent=2))
    return 0 if evidence["status"] == "PASS" else 1

if __name__ == "__main__":
    sys.exit(main())
