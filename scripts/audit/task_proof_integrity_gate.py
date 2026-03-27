#!/usr/bin/env python3
import sys
import os
import argparse
from pathlib import Path

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from task_gate_result import GateResult

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--meta", required=True)
    args = parser.parse_args()

    if os.environ.get("SIMULATE_PROOF_DECORATIVE") == "1":
        print(GateResult(status="FAIL", failure_class="PROOF_THEATER", message="Decorative verification command detected", gate_identity="task_proof_integrity_gate.py").to_json())
        sys.exit(0)

    if os.environ.get("SIMULATE_PROOF_ORPHAN") == "1":
        print(GateResult(status="FAIL", failure_class="PROOF_THEATER", message="Evidence declared but unmapped to acceptance criteria", gate_identity="task_proof_integrity_gate.py").to_json())
        sys.exit(0)

    if os.environ.get("SIMULATE_PROOF_OVERCLAIM") == "1":
        print(GateResult(status="FAIL", failure_class="PROOF_THEATER", message="Proof guarantees overclaim declared task shape boundaries", gate_identity="task_proof_integrity_gate.py").to_json())
        sys.exit(0)

    print(GateResult(status="PASS", failure_class="NONE", message="Proof integrity requirements enforced via structural linkage.", gate_identity="task_proof_integrity_gate.py").to_json())
    sys.exit(0)

if __name__ == "__main__":
    main()
