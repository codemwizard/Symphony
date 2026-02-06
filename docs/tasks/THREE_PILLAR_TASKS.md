# Three‑Pillar Program — Task List (Native‑First)

## Canonical Meta Schema
All tasks must conform to the schema in `tasks/_template/meta.yml`.

---

## TSK‑P0‑056 — Evidence schema canonicalization
- **Owner:** ARCHITECT
- **Depends on:** none
- **Touches:** `docs/architecture/evidence_schema.json`, `scripts/audit/validate_evidence_schema.sh`, `docs/PHASE0/phase0_contract.yml`
- **Invariant:** NEW INV‑077 (Evidence schema normalized)
- **Work:**
  - Define required fields (`check_id`, `timestamp_utc`, `git_sha`, `status`, optional `schema_fingerprint`).
  - Treat `SKIPPED` as first‑class.
  - Validate all `evidence/phase0/*.json` and fail on malformed files.
- **Evidence:** `evidence/phase0/evidence_validation.json`

## TSK‑P0‑057 — YAML normalization + meta schema enforcement
- **Owner:** ARCHITECT
- **Depends on:** TSK‑P0‑056
- **Touches:** `tasks/**/meta.yml`, `tasks/_template/meta.yml`, `docs/operations/STYLE_GUIDE.md`, `scripts/audit/lint_yaml_conventions.sh`
- **Invariant:** NEW INV‑078 (YAML conventions enforced)
- **Work:**
  - Convert all YAML keys to `lower_snake_case`.
  - Enforce canonical meta schema (arrays vs strings).
  - Forbid mixed keys (`Depends On:` + `depends_on`).
- **Evidence:** `evidence/phase0/yaml_conventions_lint.json`

## TSK‑P0‑062 — Normalize legacy task metas to canonical schema
- **Owner:** ARCHITECT
- **Depends on:** TSK‑P0‑057
- **Touches:** `tasks/TSK-P0-050/meta.yml` … `tasks/TSK-P0-055/meta.yml`
- **Invariant:** NEW INV‑082 (Task meta schema consistency)
- **Work:**
  - Convert legacy task metas to lower_snake_case keys and canonical schema.
  - Remove duplicate fields and keep single source of truth.
  - Ensure evidence paths are gate‑scoped.
- **Evidence:** `evidence/phase0/yaml_conventions_lint.json`

## TSK‑P0‑058 — CI toolchain pinning
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** TSK‑P0‑057
- **Touches:** `.github/workflows/invariants.yml`
- **Invariant:** NEW INV‑079 (CI toolchain pinned)
- **Work:**
  - Install pinned PyYAML and ripgrep in CI.
  - Remove fallback branches in CI scripts where possible.
- **Evidence:** `evidence/phase0/ci_toolchain.json`

## TSK‑P0‑051 — Control planes + drift check
- **Owner:** ARCHITECT
- **Depends on:** TSK‑P0‑058
- **Touches:** `docs/control_planes/CONTROL_PLANES.yml`, `scripts/audit/verify_control_planes_drift.sh`
- **Invariant:** INV‑072 (Control‑plane drift prevented)
- **Work:**
  - Define gates with `gate_id`, `plane`, `script`, `evidence`.
  - Implement drift checker (fail‑closed).
- **Evidence:** `evidence/phase0/control_planes_drift.json`

## TSK‑P0‑052 — Security plane expansion
- **Owner:** SECURITY_GUARDIAN
- **Depends on:** TSK‑P0‑051
- **Touches:** `scripts/security/*.sh`, `scripts/audit/run_security_fast_checks.sh`
- **Invariant:** INV‑073 (Security control‑plane baseline enforced)
- **Work:**
  - Secrets scan, .NET dependency audit, secure config lint, insecure pattern lint.
- **Evidence:**
  - `security_secrets_scan.json`
  - `security_dotnet_deps_audit.json`
  - `security_secure_config_lint.json`
  - `security_insecure_patterns.json`

## TSK‑P0‑060 — Contract semantics (PASS/SKIPPED)
- **Owner:** ARCHITECT
- **Depends on:** TSK‑P0‑051
- **Touches:** `docs/PHASE0/phase0_contract.yml`, `scripts/audit/verify_phase0_contract_evidence_status.sh`
- **Invariant:** NEW INV‑080 (Contract evidence semantics enforced)
- **Work:**
  - Contract rows reference gate IDs (not evidence paths).
  - Enforce: completed ⇒ PASS, not completed ⇒ SKIPPED or PASS.
- **Evidence:** `evidence/phase0/phase0_contract_evidence_status.json`

## TSK‑P0‑053 — Compliance mapping expansion
- **Owner:** COMPLIANCE_MAPPER
- **Depends on:** TSK‑P0‑051
- **Touches:** `docs/security/SECURITY_MANIFEST.yml`, `docs/architecture/COMPLIANCE_MAP.md`
- **Invariant:** INV‑074 (Compliance mapping maintained)
- **Work:**
  - Add PCI DSS, NIST, OWASP, ISO‑20022, ISO‑27001/27002.

## TSK‑P0‑054 — Compliance verifier + CI wiring
- **Owner:** COMPLIANCE_MAPPER
- **Depends on:** TSK‑P0‑053
- **Touches:** `scripts/audit/verify_compliance_manifest.sh`, `.github/workflows/invariants.yml`
- **Invariant:** INV‑075 (Compliance manifest verified)
- **Evidence:** `evidence/phase0/compliance_manifest_verify.json`

## TSK‑P0‑061 — Pre‑CI / CI ordering alignment
- **Owner:** ARCHITECT
- **Depends on:** TSK‑P0‑060
- **Touches:** `scripts/dev/pre_ci.sh`, `.github/workflows/invariants.yml`
- **Invariant:** NEW INV‑081 (Execution order enforced)
- **Work:**
  - Ensure ordering: YAML lint → control‑plane drift → plane checks → evidence schema validate → contract check.
- **Evidence:** `evidence/phase0/ci_order.json`
