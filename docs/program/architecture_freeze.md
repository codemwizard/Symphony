# Sprint 1 Architecture Freeze

Scope: canonical Sprint 1 security revamp wave.

## No-touch zones
- Applied migrations under `schema/migrations/**`
- Append-only evidence semantics under `evidence/**` contracts and validators
- Runtime privilege posture, SECURITY DEFINER hardening, and RLS boundaries
- Phase-1 contract gate semantics and closeout truth surfaces

## Allowed change zones
- `services/supervisor_api/**` for dangerous-sink removal
- `services/ledger-api/dotnet/**` for trust-boundary hardening and command-integrity proofs
- `scripts/security/**`, `scripts/audit/**`, `scripts/db/**` for verifier and gate upgrades
- `docs/invariants/**`, `docs/PHASE1/**`, `docs/program/**`, `tasks/**`, `docs/plans/**`

## Change rule
Any Sprint 1 change touching a no-touch zone requires explicit rollback notes, remediation trace coverage, and pre-CI proof before merge.
