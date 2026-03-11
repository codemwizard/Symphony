# PLAN — GreenTech4CE Demo Implementation (Phase 1 Delta)

Task Program ID: GREENTECH4CE-DEMO-PROGRAM
Owner role: SUPERVISOR
Phase: 1
failure_signature: PHASE1.DEMO.PROGRAM.BLOCKED_OR_DRIFT

## objective
Deliver a truthful, verifier-backed GreenTech4CE demo aligned to UC-01 and UC-01-E:
- governed ingress and proof-gated release
- signed instruction file egress
- supervisory reveal dashboard
- reporting/export surface
- deterministic HOLD/AUTHORIZE evidence paths

## scope
In scope:
1. Pre-coding lock for DB/tenant/proof-type registry decisions.
2. Evidence edge completion: SMS secure link, browser upload, Geolocation API capture, MSISDN submitter match.
3. Signed instruction file egress with tamper-detection checksum.
4. Supplier allowlist and supplier-direct routing controls.
5. Supervisory dashboard backend + non-technical UI.
6. Reporting export pack (JSON + PDF).
7. Demo replay harness + fallback artifacts + success-criteria gate.

Out of scope:
1. Live direct rail integration (NFS/ZIPSS/ZECHL).
2. BoZ sandbox participation claims.
3. Phase-2 accounting redesign.

## dependency_order
Wave 0 (Gate):
- TSK-P1-DEMO-001

Wave A:
- TSK-P1-DEMO-002
- TSK-P1-DEMO-003
- TSK-P1-DEMO-004
- TSK-P1-DEMO-005

Wave B:
- TSK-P1-DEMO-006
- TSK-P1-DEMO-007

Wave C:
- TSK-P1-DEMO-013
- TSK-P1-DEMO-014
- TSK-P1-DEMO-015

Wave D:
- TSK-P1-DEMO-008
- TSK-P1-DEMO-009

Wave E:
- TSK-P1-DEMO-010
- TSK-P1-DEMO-011

Optional lane:
- TSK-P1-DEMO-012 (blocked)
- TSK-P1-DEMO-016 (conditional; only if DEMO-013 execution proves project/assembly coupling blocks clean extraction)

## acceptance_criteria
1. PRD CRITICAL/HIGH deltas are implemented with verifier-backed evidence.
2. Day 61–90 reveal script runs deterministically from reset.
3. Unsupported claims remain explicitly unclaimed.
4. Phase-1 boundary is preserved (no Phase-2 leakage in demo narrative).
5. Decoupling lane (DEMO-013/014/015) remains non-expansion only:
   - no business logic changes
   - no schema changes
   - no new product features
6. Decoupling lane is timeboxed to 2-3 engineering days; overrun requires re-approval.

## remediation_trace
failure_signature: PHASE1.DEMO.PROGRAM.BLOCKED_OR_DRIFT
repro_command: RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh
verification_commands_run:
- RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh
final_status: planned
origin_task_id: GREENTECH4CE-DEMO-PROGRAM
origin_gate_id: PHASE1_DEMO_IMPLEMENTATION
