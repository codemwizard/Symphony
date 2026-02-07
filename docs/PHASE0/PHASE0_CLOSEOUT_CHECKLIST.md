# Phase-0 Closeout Checklist (Authoritative)

Date: 2026-02-07

Purpose: provide a single checklist that a human can sign off while still being tied to mechanical enforcement (gates, invariants, evidence artifacts).

Primary source for mechanical mapping:
- `docs/PHASE0/CLOSEOUT_CHECKLIST_MATRIX.md`

Primary verification command (local parity runner):
- `scripts/dev/pre_ci.sh`

## Checklist

### A) Phase-0 Definition of Done (DoD)

- [x] Phase-0 invariants are declared in `docs/invariants/INVARIANTS_MANIFEST.yml` and are mechanically verified or explicitly marked roadmap with a blocking gate/task.
- [x] CI and local pre-push produce evidence artifacts under `evidence/phase0/` for core Phase-0 gates (repo structure, evidence provenance, N-1, lock-risk, idempotency zombie, OpenBao smoke, batching, routing fallback).
- [x] N-1 compatibility gate and lock-risk DDL lint are enforced and fail-closed.
- [x] Evidence schema and generator exist; evidence artifacts are uploaded in CI and are not committed to git.
- [x] OpenBao dev parity harness exists (compose + bootstrap + deny test) and is verified mechanically.
- [x] Repo structure and agent/task governance are enforced by mechanical checkers.
- [x] Task metadata exists for Phase-0 tasks (`tasks/TSK-P0-###/meta.yml`) and is validated by contract and task-evidence gates.

### B) Migration and Deployment Safety (Expand/Contract)

- [x] Forward-only migrations; applied migrations immutable (checksum ledger).
- [x] Migrations contain no top-level BEGIN/COMMIT (runner-owned transaction wrapper).
- [x] Baseline snapshot does not drift; baseline governance enforced (migration + ADR required for baseline changes).
- [x] N-1 compatibility (blue/green forward-only posture) gate enforced.
- [x] No-tx discipline supported and documented for CONCURRENTLY.
- [x] Blocking DDL guarded (lock-risk lint + allowlist governance).
- [x] Phase-0 expand/contract guardrails enforced (no cleanup marker; no ADD COLUMN NOT NULL; no destructive DDL).
- [x] PK/FK type stability guardrail enforced (waiver mechanism required).

### C) Core Integrity and Exception Containment

- [x] Revoke-first posture enforced (deny-by-default privileges).
- [x] No runtime DDL (PUBLIC/runtime roles do not regain CREATE on schemas).
- [x] SECURITY DEFINER search_path hardening enforced.
- [x] Outbox append-only and lease-fencing semantics enforced (no weakening of append-only guarantees).
- [x] Revocation tables present and append-only.
- [x] Table conventions gate enforced for registered ledger/txn tables (explicit allowlist).

### D) Security Controls (Phase-0 Appropriate)

- [x] Secrets scan enforced.
- [x] Secure config lint enforced.
- [x] Dependency audit enforced.
- [x] Insecure patterns lint enforced.
- [x] SAST baseline present (Semgrep); CI pinning enforced; evidence emitted.
- [x] Security posture documents required for Phase-0 exist and are mechanically verified for presence and manifest reference (key management, audit logging retention/review, secure SDLC).

### E) Evidence-Grade Governance

- [x] Evidence schema validation enforced.
- [x] Task evidence contract enforced (fail-closed definitions, explicit failure modes).
- [x] Phase-0 contract is authoritative and validated.
- [x] Contract evidence status semantics enforced (completed + evidence_required drives required artifacts).
- [x] Evidence harness integrity gate enforced (anti-bypass).
- [x] Compliance manifest verification enforced.
- [x] Remediation trace workflow exists and remediation trace gate is enforced for production-affecting changes (Option 2, low noise).

### F) Business Hooks and Readiness (Phase-0 Safe)

- [x] Participant registry schema hook exists and is mechanically verified.
- [x] Evidence pack signing/anchoring schema hooks exist and are mechanically verified.
- [x] Explicit REVOKE hygiene applied to new business tables and mechanically verified.
- [x] ISO 20022 readiness docs and contract registry presence gate exists (Phase-0 safe posture).
- [x] Zero Trust posture docs gate exists (Phase-0 safe posture).

## Mechanical proof (how to verify)

Run:
```bash
scripts/dev/pre_ci.sh
```

Expected:
- PASS
- Evidence artifacts written under `evidence/phase0/*.json`

For CI-equivalent local run (wipe + full pipeline):
```bash
CI_WIPE=1 DATABASE_URL=postgres://symphony_admin:symphony_pass@127.0.0.1:5432/symphony \
  scripts/ci/run_ci_locally.sh
```

