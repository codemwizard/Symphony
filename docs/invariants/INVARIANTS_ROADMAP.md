# Invariants Roadmap

These invariants are **planned** (`roadmap`). They may have partial evidence (e.g., migrations landed) but are not yet verified end-to-end.

_Generated mechanically from `docs/invariants/INVARIANTS_MANIFEST.yml`._

| ID | Aliases | Severity | Title | Owners | Verification (manifest) | Evidence links |
|---|---|---|---|---|---|---|
| INV-009 | I-SEC-05 | P1 | SECURITY DEFINER functions must avoid dynamic SQL and user-controlled identifiers | team-platform | TODO: add linter or allowlist-based review; no mechanical check found | [`scripts/db/ci_invariant_gate.sql L87-L91`](../../scripts/db/ci_invariant_gate.sql#L87-L91)<br>[`scripts/db/lint_search_path.sh L2-L6`](../../scripts/db/lint_search_path.sh#L2-L6)<br>[`scripts/db/verify_invariants.sh L32-L36`](../../scripts/db/verify_invariants.sh#L32-L36) |
| INV-039 |  | P1 | Fail-closed under DB exhaustion | team-platform | TODO: define and wire fail-closed verification |  |
| INV-048 | I-ZECHL-01 | P1 | Proxy/Alias resolution required before dispatch | team-platform | scripts/audit/verify_proxy_resolution_invariant.sh |  |
| INV-130 | SEC-001, I-SEC-07 | P0 | Admin bind localhost (supervisor_api) | team-security | scripts/audit/verify_supervisor_bind_localhost.sh |  |
| INV-131 | SEC-002, I-SEC-08 | P0 | Admin auth required (supervisor_api) | team-security | scripts/audit/test_admin_endpoints_require_key.sh |  |
| INV-132 | SEC-003, I-SEC-09 | P0 | Fail-closed on missing secrets (signing keys) | team-security | scripts/security/scan_secrets.sh |  |
| INV-133 | SEC-004, I-SEC-10 | P0 | Tenant allowlist default-deny | team-security | scripts/audit/test_tenant_allowlist_deny_all.sh |  |
