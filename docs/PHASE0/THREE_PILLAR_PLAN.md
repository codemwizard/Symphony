# Three‑Pillar Program (Native‑First) — Phase‑0 Plan

## Objectives
- Make **Security, Integrity, and Governance** explicit control planes with clear ownership and enforcement.
- Ensure all controls are **mechanical, evidence‑backed, and fail‑closed**.
- Keep Phase‑0 **native‑first** (no compatibility shims); normalize schemas and tooling instead.

## Principles (Non‑Negotiable)
- **Evidence belongs to gates, not tasks.** Tasks reference gate IDs; control planes declare evidence.
- **Status semantics are uniform:** `PASS | FAIL | SKIPPED` (uppercase only).
- **CI is authoritative** and installs pinned tooling.
- **All planes run on every change** in pre‑CI and CI.

## Phase A — Canonical Foundations

### A1) Evidence schema + status normalization
- Define required evidence fields: `check_id`, `timestamp_utc`, `git_sha`, `status` (+ optional `schema_fingerprint`).
- `SKIPPED` is first‑class in schema.
- Validate **all** `evidence/phase0/*.json` and fail on any malformed file.

### A2) YAML normalization (schema + conventions)
- Enforce `lower_snake_case` keys across:
  - `tasks/**/meta.yml`
  - `docs/**/*.yml`
  - `.github/**/*.yml`
- Enforce canonical meta schema (required keys, arrays vs strings).
- Forbid mixed variants (`Depends On:` + `depends_on`).

### A3) CI tooling is native
- CI installs **pinned** PyYAML + ripgrep.
- Pre‑CI fails without tools unless an explicit dev override is set.

## Phase B — Control Planes (Explicit Gates)

### B0) Gate registry rules
- Gate IDs: `SEC-Gxx`, `INT-Gxx`, `GOV-Gxx`.
- Evidence paths: `evidence/phase0/<plane>_<gate>.json`.
- No wildcard evidence paths in contracts.

### B1) CONTROL_PLANES.yml
- Create `docs/control_planes/CONTROL_PLANES.yml`.
- Each gate declares `gate_id`, `plane`, `script`, `evidence`, optional `standards`.

### B2) Control‑plane drift check
- Implement `scripts/audit/verify_control_planes_drift.sh`.
- Fail‑closed on missing gates or mismatched evidence.

## Phase C — Security Plane Expansion (Static‑Only)
- Secrets/credential scan across `src/**`, `.github/**`, `infra/**`.
- .NET dependency audit:
  - `dotnet list package --vulnerable --include-transitive`
  - fail on High/Critical (thresholds configurable later).
- Secure config lint (infra + workflows).
- Insecure pattern lint (static code patterns).

## Phase D — Integrity Plane Contract Semantics
- Contract rows reference **gate IDs**, not evidence paths.
- Evidence status rules:
  - completed ⇒ **PASS** required
  - not completed ⇒ **SKIPPED or PASS** allowed
  - FAIL always fails

## Phase E — Governance (Compliance)
- Expand compliance mapping to include:
  - PCI DSS v4.0
  - NIST CSF / 800‑53
  - OWASP ASVS
  - ISO‑20022
  - ISO‑27001:2022 / 27002
- Verifier outputs evidence (manifest is not evidence).

## Phase F — Pre‑CI / CI Order (Native)
1. YAML lint + meta schema lint
2. Control‑plane drift check
3. Run Security plane checks
4. Run Integrity plane checks
5. Run Governance plane checks
6. Evidence schema validation
7. Contract evidence status check

## Execution Guarantee
- All planes run **on every change** in pre‑CI and CI.
- Evidence must be mechanically valid before acceptance.
