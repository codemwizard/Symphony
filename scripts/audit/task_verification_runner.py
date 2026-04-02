#!/usr/bin/env python3
import argparse
import sys
import json
import subprocess
from task_gate_result import GateResult
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def run_gate(gate_script: str, task_meta_path: str) -> GateResult:
    # This is a skeleton. For now, we simulate executing a gate.
    # We invoke the gate script expecting a JSON serialized GateResult on stdout.
    try:
        result = subprocess.run(
            [gate_script, "--meta", task_meta_path],
            capture_output=True,
            text=True,
            check=True
        )
        try:
            data = json.loads(result.stdout)
            return GateResult.from_dict(data)
        except Exception as e:
            return GateResult(
                status="FAIL",
                failure_class="MALFORMED_GATE_OUTPUT",
                message=f"Gate emitted invalid output: {e}",
                gate_identity=gate_script
            )
    except subprocess.CalledProcessError as e:
        # Gate failed execution
        try:
            data = json.loads(e.stdout)
            return GateResult.from_dict(data)
        except:
            return GateResult(
                status="FAIL",
                failure_class="EXECUTION_ERROR",
                message=f"Gate exited non-zero with no valid result structure: {e.stderr}",
                gate_identity=gate_script
            )

def main():
    parser = argparse.ArgumentParser(description="Report-Only Task Verification Runner")
    parser.add_argument("--meta", required=True, help="Path to task meta.yml")
    parser.add_argument("--gates", nargs='+', default=[], help="List of gate scripts to run")
    args = parser.parse_args()

    # In a real run, we'd invoke the loader first.
    # For now, this is just runner orchestration.
    
    results = []
    has_failure = False
    
    for gate in args.gates:
        res = run_gate(gate, args.meta)
        results.append(res.to_json())
        if res.status != "PASS":
            has_failure = True
            break  # Stop on first failure per strict semantics
            
    envelope = {
        "runner_version": "1.0",
        "task_meta_path": args.meta,
        "gates_executed": len(args.gates),
        "overall_status": "FAIL" if has_failure else "PASS",
        "gate_results": [json.loads(r) for r in results]
    }
    
    print(json.dumps(envelope, indent=2, sort_keys=True))
    if has_failure:
        sys.exit(1)

if __name__ == "__main__":
    main()
