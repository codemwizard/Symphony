# Security, Optimization, and Traceability Deep Audit (2026-03-14)

## Scope and approach

This audit was run as a multi-pass review (simulating specialist sub-agents by layer):

1. **Security pass** — API authn/authz, token handling, data leakage vectors, error handling.
2. **Optimization pass** — duplicate logic, dead paths, unnecessary coupling, fallback drift.
3. **Traceability pass** — UI action/link → API route → handler → data store/DB function.

Primary reviewed surfaces:
- `src/supervisory-dashboard/index.html`
- `src/supervisory-dashboard/legacy.html`
- `services/supervisor_api/server.py`
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
- `services/ledger-api/dotnet/src/LedgerApi/ReadModels/SupervisoryRevealReadModelHandler.cs`
- `services/ledger-api/dotnet/src/LedgerApi/Commands/EvidenceLinkHandlers.cs`
- `schema/migrations/0051_hier_006_supervisor_access_modes.sql`
- `schema/migrations/0058_hier_011_supervisor_access_mechanisms.sql`

---

## 1) Security analysis

### Critical

1. **Supervisor admin API lacks application-layer authn/authz checks (partially mitigated by network boundary).**
   - `services/supervisor_api/server.py` routes (`/v1/admin/supervisor/audit-token`, `/approve/*`, `/audit-records`) are directly callable from handler dispatch without any API key, tenant scope check, or role check in Python layer.
   - However, the R-000 containment task enforced a strict localhost-only bind posture (`verify_supervisor_bind_localhost.sh`).
   - Risk: any caller with *local network reach* to the node can mint/revoke audit tokens and approve supervisor queue items. This should still have application-layer defense-in-depth.
   - Evidence: `do_POST`, `do_DELETE`, `do_GET` branch directly into privileged handlers and handlers do not verify caller identity.

### High

2. **Audit token accepted via URL query parameter (`?token=`).**
   - `handle_audit_records` reads token from query string.
   - Risk: token leaks into proxy/access logs, browser history, and referrer chains.

3. **UI wiring verifier indicates policy drift: pilot-demo instruction generate route is not admin-guarded.**
   - `scripts/audit/verify_task_ui_wire_004.sh` expects admin guard for `/pilot-demo/api/instruction-files/generate` and currently fails with `pilot_demo_generate_route_not_admin_guarded`.
   - In `Program.cs`, this route currently uses `AuthorizeEvidenceRead(httpContext)`.
   - Risk: privilege boundary erosion on a write-capable action, even in pilot-demo profile.

### Medium

4. **Unhandled malformed JSON and integer coercion in supervisor API can induce 500s (DoS/noisy failure mode).**
   - `_read_json` directly `json.loads(...)` and `ttl_seconds = int(...)` without error handling.
   - Risk: request-triggered server errors and unstable behavior under malformed inputs.

5. **Error detail reflection from DB exceptions.**
   - `handle_approve` returns DB exception text in JSON (`"detail": msg`) on unknown failure.
   - Risk: internal schema/function behavior leakage.

### Low

6. **Single-thread `HTTPServer` runtime choice can amplify head-of-line blocking.**
   - `HTTPServer(("127.0.0.1", port), Handler)` with no threading model.
   - Risk: low-throughput / easy local saturation under bursty traffic.

---

## 2) Optimization analysis

### High-value optimization opportunities

1. **Adapter fallback patterns are heavily duplicated across multiple methods.**
   - `getProgrammeSummary`, `getTimeline`, `getExceptionLog`, `getEvidenceCompleteness`, `getInstructionDetail`, `exportProgrammeReport` all repeat identical STATIC_DEMO / HYBRID fallback skeletons.
   - Opportunity: centralize with a generic wrapper (e.g., `withModeFallback(fetcher, fallbackKey, options)`) to reduce bug surface and keep fallback semantics consistent.

2. **Legacy UI shell duplicates current dashboard semantics but diverges behavior.**
   - `legacy.html` still contains button handlers that only trigger `alert(...)`, while `index.html` has actual adapter-backed flows.
   - Opportunity: deprecate or hard-gate legacy shell to avoid maintenance drag and accidental usage.

3. **Read model recomputation is repeated for reveal/detail paths and includes repeated linear scans.**
   - In `SupervisoryRevealReadModelHandler.cs`, proof/timeline assembly repeatedly filters arrays (`Where(...).ToArray()`, `LastOrDefault(...)`) per instruction/proof.
   - Opportunity: pre-index submissions/exceptions by instruction and artifact type once per request.

### Medium/low optimization opportunities

4. **UI uses large inline script and inline `onclick` handlers across many nodes.**
   - Opportunity: event delegation + modular JS organization improves parse time and testability.

5. **Compatibility alias nodes create extra DOM and traceability complexity.**
   - Hidden compatibility IDs (`export-trigger`, `raw-artifact-drilldown`) exist without active wiring in `index.html`.
   - Opportunity: remove once compatibility verifier strategy is updated.

---

## 3) End-to-end traceability analysis (UI → API → domain/data)

## 3.1 Trace map (actionable controls)

| UI control | UI call site | API route called | Backend route present | Handler/data layer | DB touchpoint | Status |
|---|---|---|---|---|---|---|
| Export Pack (`#exportBtn`) | `triggerExport()` | `POST /v1/supervisory/programmes/{programId}/export` | Yes | `Program.cs` export route executes `generate_programme_reporting_pack.sh` and reads evidence artifacts | File-system evidence; no direct SQL here | **Wired, but script-coupled** |
| Timeline row click | `openDrill(ref)` | `GET /v1/supervisory/instructions/{instructionId}/detail` (when non-STATIC mode) | Yes | `SupervisoryInstructionDetailReadModelHandler.Handle` | Reads projections/submissions via `SupervisoryProofModel` | **Wired** |
| Dashboard hydrate | `hydrateDashboard()` | `GET /v1/supervisory/programmes/{programId}/reveal` | Yes | `SupervisoryRevealReadModelHandler.Handle` | Reads submission logs + projection store | **Wired** |
| Supplier policy check | `adapter.getSupplierPolicy()` | `GET /v1/programs/{programId}/suppliers/{supplierId}/policy` | Yes | `ProgramSupplierPolicyReadHandler.Handle` from `Program.cs` | Policy lookup path | **Wired** |
| Evidence link issue | `adapter.issueEvidenceLink()` | `POST /pilot-demo/api/evidence-links/issue` | Yes | `EvidenceLinkIssueHandler.HandleAsync` | No direct DB in handler; logs dispatch artifact | **Wired** |
| Instruction file generate | `adapter.generateInstructionFile()` | `POST /pilot-demo/api/instruction-files/generate` | Yes | `SignedInstructionFileHandler.GenerateAsync` | Writes/reads signed file artifacts | **Wired with auth-policy mismatch (see Security #3)** |
| Verify instruction file ref | `adapter.verifyInstructionFile()` | `POST /v1/instruction-files/verify-ref` | Yes | `SignedInstructionFileHandler.VerifyAsync` | Reads evidence file by sanitized ref | **Wired** |
| Pilot success tab | `loadPilotSuccessPanel()` | `GET /pilot-demo/api/pilot-success` | Yes | `PilotSuccessCriteriaReadModelHandler.Handle` | Reads evidence JSON files | **Wired** |

## 3.2 Supervisor admin API trace

| Caller | Endpoint | Python service function | SQL/function invoked | Contract alignment | Status |
|---|---|---|---|---|---|
| Admin client | `POST /v1/admin/supervisor/audit-token` | `handle_create_audit_token` | `INSERT public.supervisor_audit_tokens(...)` | Uses expected table/columns | **Wired** |
| Admin client | `DELETE /v1/admin/supervisor/audit-token/{token_id}` | `handle_revoke_audit_token` | `UPDATE public.supervisor_audit_tokens SET revoked_at ...` | Uses UUID cast; consistent | **Wired** |
| Admin client | `GET /v1/admin/supervisor/audit-records?token=...` | `handle_audit_records` | `SELECT ... supervisor_audit_tokens`, then `SELECT ... supervisor_audit_member_device_events` | Signature/column usage aligned | **Wired (token-in-query risk)** |
| Admin client | `POST /v1/admin/supervisor/approve/{instruction_id}` | `handle_approve` | `SELECT public.decide_supervisor_approval(%s,'APPROVED',%s,%s)` | Matches SQL function signature | **Wired** |

## 3.3 Signature and type checks

- `decide_supervisor_approval` signature in migration (`TEXT, TEXT, TEXT, TEXT DEFAULT NULL`) matches Python call argument count and order.
- UI fetch payload keys align with route request DTO expectations for:
  - evidence-link issue (`tenant_id`, `instruction_id`, `program_id`, `submitter_*`, optional geo/TTL)
  - instruction file generate (`tenant_id`, `program_id`, `instruction_id`, `supplier_id`, `amount_minor`, etc.)
  - verify-ref (`instruction_file_ref`)

## 3.4 Traceability gaps discovered

1. **Compatibility alias controls in `index.html` are inert in the current shell.**
   - Hidden IDs `#export-trigger` and `#raw-artifact-drilldown` exist, but real active control is `#exportBtn`; there is no active click wiring for alias IDs in `index.html`.

2. **`legacy.html` has action controls that call local alerts only (no API wiring).**
   - This can cause confusion for operators or test automation expecting real back-end interaction.

---

## Prioritized remediation backlog (task-artifact ready)

## P0 (Critical / High)

- [ ] **SEC-P0-01:** Add mandatory authn/authz middleware/checks to `services/supervisor_api/server.py` for all `/v1/admin/supervisor/*` routes (API key + role + tenant scope + audit logging).
- [ ] **SEC-P0-02:** Move audit token transport from query param to `Authorization: Bearer` (or dedicated header) and reject query tokens.
- [ ] **SEC-P0-03:** Resolve pilot-demo generate-route authorization mismatch (`AuthorizeAdminTenantOnboarding` vs `AuthorizeEvidenceRead`) and re-pass `verify_task_ui_wire_004.sh`.

## P1 (Medium)

- [ ] **SEC-P1-01:** Harden JSON/body parsing in supervisor API with deterministic 4xx responses; remove exception detail reflection.
- [ ] **TRC-P1-01:** Reconcile compatibility alias strategy (`export-trigger`, `raw-artifact-drilldown`) with actual active controls; remove or actively wire aliases.
- [ ] **TRC-P1-02:** Add automated UI control inventory test that validates every clickable control maps to a known function and route contract.

## P2 (Optimization)

- [ ] **OPT-P2-01:** Refactor adapter fallback logic into one reusable helper to remove duplication and fallback drift.
- [ ] **OPT-P2-02:** Deprecate `legacy.html` behind explicit non-prod path banner/guard.
- [ ] **OPT-P2-03:** Pre-index reveal input arrays in `SupervisoryProofModel` to reduce repeated scans.

---

## Command log

*(Stale local-environment failure logs from 2026-03-14 have been removed. Verifier parity relies on the CI pipeline.)*
