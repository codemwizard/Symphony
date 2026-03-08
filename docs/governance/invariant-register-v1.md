# Symphony Invariant Register

Version: 1.0  
Status: AUTHORITATIVE BASELINE  
Owner: Architecture + Security Authority  
Applies To: code, migrations, CI gates, runtime operations, evidence production

## Purpose
This register defines invariant classes Symphony treats as non-negotiable control laws.
An invariant is considered implemented only when all are true:
1. It exists in `docs/invariants/INVARIANTS_MANIFEST.yml`.
2. It has mechanical verification (script/test) that fails closed.
3. Verification is wired into blocking CI (`.github/workflows/invariants.yml`).
4. Deterministic evidence artifact is emitted.

## Canonical Sources
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANTS_PROCESS.md`
- `docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md`
- `.github/workflows/invariants.yml`
- `scripts/dev/pre_ci.sh`

## Invariant Record Format
Each invariant record MUST include:
- `id`
- `title`
- `status` (`implemented` or `roadmap`)
- `owners`
- `verification` (script/test command)
- evidence path(s) referenced by verifier/evidence contract

## Core Invariant Domains
### 1) Migration Governance
Examples: INV-001..004, INV-041..043, INV-097..099  
Control intent: forward-only schema safety and deterministic baseline posture.

### 2) Security Posture
Examples: INV-005..010, INV-024, INV-104..110, INV-130..134  
Control intent: revoke-first privilege model, hardened definer posture, secrets/config/supply-chain fail-closed checks.

### 3) Outbox / Dispatch Reliability
Examples: INV-011..015, INV-031..034  
Control intent: idempotent enqueue, fenced claims, append-only attempts, bounded retries.

### 4) Policy Governance
Examples: INV-016..018, INV-114, INV-120..126  
Control intent: deterministic policy versioning, execution gating, finality semantics, perf-policy linkage.

### 5) Evidence Governance
Examples: INV-020, INV-028, INV-029, INV-077, INV-093, INV-103  
Control intent: schema-valid deterministic evidence with provenance and anchoring hooks.

### 6) Tenant / Isolation / Jurisdiction
Examples: INV-062..066, INV-111..116, INV-127..129, INV-133  
Control intent: tenant-safe boundaries, jurisdiction-linked controls, escrow/finality/anchor continuity.

## Status Semantics
- `implemented`: mechanical verifier exists, wired, and evidenced.
- `roadmap`: required control but incomplete mechanical enforcement.

## Promotion Rule (Roadmap -> Implemented)
Promotion is allowed only when:
1. verifier script exists and returns non-zero on violation,
2. verifier runs in blocking CI job,
3. evidence schema + artifact path are deterministic,
4. `scripts/dev/pre_ci.sh` parity path exercises same checks,
5. related docs/contracts are synchronized.

## Prohibited Claims
Do NOT claim an invariant implemented when verification field is TODO or advisory-only.
Current examples that remain non-promotable until closed: `INV-009`, `INV-039`.

## Operator Commands
- Fast invariant plane: `bash scripts/audit/run_invariants_fast_checks.sh`
- Security plane: `bash scripts/audit/run_security_fast_checks.sh`
- DB plane: `bash scripts/db/verify_invariants.sh`
- Full local parity: `scripts/dev/pre_ci.sh`

## Governance Note
This register is taxonomy/authority. Detailed per-invariant command and evidence mapping is maintained in:
`docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md`.
