# Symphony CI Gate Specification

Version: 1.0  
Status: AUTHORITATIVE BASELINE  
Owner: Security + Platform + Architecture  
Primary Workflow: `.github/workflows/invariants.yml`

## Purpose
Define mandatory merge/release gate behavior for Symphony using current mechanical contracts.
No approval may override a mandatory failing gate without an exception record and explicit approval metadata.

## Gate Classes (Current Symphony)
### Gate A: Mechanical Invariants
Workflow job: `mechanical_invariants`  
Purpose: enforce structural change rules, invariant promotion constraints, exception template validity, task-plan/log presence, and ordered checks.

Core commands include:
- `scripts/audit/enforce_change_rule.sh`
- `scripts/audit/enforce_invariant_promotion.sh`
- `scripts/audit/verify_exception_template.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/verify_agent_conformance.sh`
- `scripts/audit/run_phase0_ordered_checks.sh`

Fail mode: BLOCK MERGE.

### Gate B: Security Scan
Workflow job: `security_scan`  
Purpose: fail-closed security checks (secrets, semgrep/rules, dependency audit, security lints).

Primary commands/hook paths:
- `scripts/audit/run_security_fast_checks.sh`
- `scripts/security/scan_secrets.sh`
- `scripts/security/dotnet_dependency_audit.sh`
- `security/semgrep/rules.yml`

Fail mode: BLOCK MERGE.

### Gate C: DB Invariants
Workflow job: `db_verify_invariants`  
Purpose: schema/migration + DB invariant verification on test Postgres.

Primary command:
- `scripts/db/verify_invariants.sh`

Fail mode: BLOCK MERGE.

### Gate D: Evidence Contract Gate
Workflow job: `phase0_evidence_gate`  
Purpose: ensure evidence contract requirements are satisfied and status semantics remain valid.

Primary commands/hook paths:
- `scripts/ci/check_evidence_required.sh`
- `scripts/ci/verify_phase0_contract_evidence_status_parity.sh`

Fail mode: BLOCK MERGE.

### Gate E: Local Pre-CI Parity
Local runner: `scripts/dev/pre_ci.sh`  
Purpose: catch CI failures before push with ordered checks, DB verification parity, and phase-gated closeout checks.

Fail mode: STOP LOCAL PUSH/WORKFLOW ADVANCE.

## Required Pipeline Ordering (Logical)
1. Mechanical invariants
2. Security scan
3. DB invariants
4. Evidence contract gate

Release-affecting work must also pass local parity (`pre_ci.sh`) before PR finalization.

## Canonical Drift Rules
This specification is derivative, not primary. It must defer to:
- `.github/workflows/invariants.yml` for actual blocking workflow job names and execution topology.
- `scripts/dev/pre_ci.sh` for local parity behavior.
- `docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md` for exact invariant-to-command/evidence mapping.
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` for approval and regulated-surface requirements.

## Mandatory Fail-Closed Conditions
A change MUST fail when any of the following occurs:
1. Structural change without invariant linkage or valid exception.
2. Invariant promoted without mechanical verifier/evidence linkage.
3. Security scan failure (secret, vuln, policy lint).
4. DB invariant verification failure.
5. Required evidence missing or schema-invalid.

## Exception Policy
Exceptions must be:
- time-boxed,
- created from `docs/invariants/exceptions/EXCEPTION_TEMPLATE.md`,
- linked to remediation task/plan,
- validated by `scripts/audit/verify_exception_template.sh`.

Exceptions are not allowed for foundational fail-closed controls unless explicitly approved in canonical policy documents.

## Required CI Artifacts
At minimum:
- detector artifacts (`/tmp/invariants_ai/pr.diff`, `/tmp/invariants_ai/detect.json`)
- phase evidence artifacts (`evidence/**`)
- security evidence outputs (`evidence/phase0/security_*.json`)
- DB verification evidence outputs per invariant script

## Canonical References
- `.github/workflows/invariants.yml`
- `scripts/dev/pre_ci.sh`
- `docs/invariants/INVARIANTS_PROCESS.md`
- `docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md`
- `docs/contracts/SECURITY_REMEDIATION_DOD.yml`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
