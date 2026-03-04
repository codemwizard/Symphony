# Security Remediation Task List (Ordered)

**Source of Truth:** [SECURITY_REMEDIATION_DOD.yml](file:///home/mwiza/workspace/Symphony/docs/contracts/SECURITY_REMEDIATION_DOD.yml)
**Enforcement:** [AI_AGENT_OPERATION_MANUAL.md](file:///home/mwiza/workspace/Symphony/docs/operations/AI_AGENT_OPERATION_MANUAL.md)

---

## Phase 0.1 — Containment

### TASK ID: R-000
**Title:** Contain supervisor_api + admin bypass
**Owner Role:** SECURITY_GUARDIAN
**Depends On:** none
**Touches:** `services/ledger-api/dotnet/src/LedgerApi/Program.cs`, `scripts/audit/verify_supervisor_bind_localhost.sh`, `scripts/security/lint_insecure_patterns.sh`
**Invariant(s):** NEW SEC-001 (Admin bind localhost), NEW SEC-002 (Admin auth required)
**Work:**
- Add regression gate `scripts/audit/verify_supervisor_bind_localhost.sh` to ensure bind remains 127.0.0.1.
- Remove `x-admin-claim` header bypass in `Program.cs`.
- Require and enforce `ADMIN_API_KEY` for all admin endpoints.
**Acceptance Criteria:**
- `verify_supervisor_bind_localhost.sh` passes.
- Semgrep rejects `x-admin-claim` header trust patterns.
- `test_admin_endpoints_require_key.sh` passes.
**Verification Commands:**
- `bash scripts/audit/verify_supervisor_bind_localhost.sh`
- `semgrep --config security/semgrep --severity ERROR --error`
- `bash scripts/audit/test_admin_endpoints_require_key.sh`
**Evidence Artifact(s):**
- `evidence/security_remediation/r_000_containment.json`
**Notes:**
- Registry in `tasks/R-000/meta.yml` required.

---

## Phase 0.2 — Emergency Code Fixes

### TASK ID: R-001
**Title:** Fail hard on missing signing keys
**Owner Role:** SECURITY_GUARDIAN
**Depends On:** R-000
**Touches:** `services/ledger-api/dotnet/src/LedgerApi/Program.cs`, `scripts/security/scan_secrets.sh`
**Invariant(s):** NEW SEC-003 (Fail-closed on missing secrets)
**Work:**
- Replace `?? "dev-signing-key"` fallbacks with `?? throw` exceptions.
- Ensure all signing key literals are removed from the repo.
**Acceptance Criteria:**
- `scan_secrets.sh` finds no dev keys.
- Semgrep structural gate rejects `?? "literal"` fallback patterns.
- `test_missing_signing_key_fails_closed.sh` passes.
**Evidence Artifact(s):**
- `evidence/security_remediation/r_001_signing_keys.json`

### TASK ID: R-002
**Title:** Tenant allowlist deny-all default
**Owner Role:** SECURITY_GUARDIAN
**Depends On:** R-000
**Touches:** `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
**Invariant(s):** NEW SEC-004 (Tenant allowlist default-deny)
**Work:**
- Ensure unconfigured `SYMPHONY_KNOWN_TENANTS` results in rejecting all tenant-scoped requests.
**Acceptance Criteria:**
- `test_tenant_allowlist_deny_all.sh` passes.
**Evidence Artifact(s):**
- `evidence/security_remediation/r_002_tenant_allowlist.json`

---

## Phase 0.5 — Enforcement Repair

[...See docs/contracts/SECURITY_REMEDIATION_DOD.yml for detailed Phase 0.5 through Phase 5 task definitions...]
