# TSK-P1-INT-002 Plan

Task ID: TSK-P1-INT-002

## objective
Integrity verifier stack plus synchronous governed chain population

## scope
1. Dependency completion: TSK-P1-INT-001.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Preserve signed-artifact validation and append-only verification behavior.
2. Implement synchronous hash-chain population for governed instructions and evidence events.
3. Enforce same-transaction commit boundary between governed event and chain record.
4. Measure latency delta on declared reference hardware and emit verifiable benchmark evidence.

## acceptance_criteria
- Chain records exist for governed instructions and evidence events.
- Chain updates commit in the same transaction boundary as the attested event.
- Broken-chain fixtures fail verification in both governed domains.
- Declared reference hardware is explicit in evidence.
- Measured chain-population latency delta is <=100ms on declared reference hardware.
- Evidence declares measurement method as p95 wall-clock transaction delta over at least 100 runs, comparing equivalent flows with and without chain population.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_002.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_002.sh
verification_commands_run:
- dotnet run --no-launch-profile --project services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj -- --self-test-integrity-chain
- python3 - <<'PY'
  import json
  from pathlib import Path
  path = Path("evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json")
  payload = json.loads(path.read_text(encoding="utf-8"))
  assert payload["status"] == "PASS"
  assert payload["latency_ms"]["chain_population_delta"] <= payload["latency_ms"]["threshold"]
  print("PASS")
  PY
- bash scripts/audit/verify_tsk_p1_int_002.sh
final_status: planned
origin_task_id: TSK-P1-INT-002
origin_gate_id: TSK_P1_INT_002
