# SEC-002 PLAN

Task: SEC-002
Owner role: SUPERVISOR
Depends on: FP-001
failure_signature: PHASE1.SEC.002.REQUIRED

## objective
Security scan truthfulness repair

## scope
- Canonicalize required scan roots so CI and evidence runs cover the same code roots.
- Require services/ and relevant scripts/ to be scanned with per-root target counts.
- Make Python scan parity fail closed and add required-root zero-target failure.

## acceptance_criteria
- Scan roots are aligned across CI and evidence generation.
- Evidence includes scanned-root counts and zero-target required roots fail the build.
- Python parity verification fails closed when expected findings disappear.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/audit/verify_scan_scope.sh`
- `bash scripts/audit/verify_semgrep_languages.sh`
- `python3 scripts/audit/validate_evidence.py --task SEC-002 --evidence evidence/security/sec_002_scan_scope_truth.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not weaken existing scan jobs to make the task pass.
- Do not suppress findings to achieve green status.

## evidence_output
- `evidence/security/sec_002_scan_scope_truth.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/audit/verify_scan_scope.sh`
- `bash scripts/audit/verify_semgrep_languages.sh`
- `python3 scripts/audit/validate_evidence.py --task SEC-002 --evidence evidence/security/sec_002_scan_scope_truth.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
