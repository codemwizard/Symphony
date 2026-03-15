# Symphony Demo Key and Rotation Policy

Status: Demo-specific operator policy for the host-based run
Scope: host-based Phase-1 demo execution on the current local server

## 1. Purpose
This document turns the existing repo security posture into an operator-executable demo policy.

It does not replace canonical security documents. It applies their rules to the demo run.

Canonical references:
- `docs/security/KEY_MANAGEMENT_POLICY.md`
- `docs/security/TLS_DEPLOYMENT_GUIDE.md`
- `docs/security/AUTH_IDENTITY_BOUNDARY.md`
- `docs/operations/KEY_ROTATION_SOP.md`
- `scripts/infra/verify_tsk_p1_inf_006.sh`

## 2. Identity Separation
The following identities are distinct and must not be conflated operationally or in incident response:
- client/read identity
- admin/operator identity
- service/mesh identity
- evidence-signing identity

Demo implication:
- `SYMPHONY_UI_API_KEY` is not an admin identity
- `ADMIN_API_KEY` is not a browser identity
- OpenBao-backed signing identity is not the same as API auth identity

## 3. Current Demo Contract
Current host-demo contract on this branch:
- `SYMPHONY_UI_API_KEY == INGRESS_API_KEY`

This is a **current demo contract**, not permanent architecture doctrine.

Required rule:
- if the two values differ, the host-based demo run fails closed before startup

## 4. Tenant Allowlist Policy
`SYMPHONY_KNOWN_TENANTS` is mandatory and deny-by-default.

Rules:
- empty or missing allowlist is invalid for the demo run
- wildcard behavior is not permitted
- `SYMPHONY_UI_TENANT_ID` must be present in the allowlist

Pass condition:
- allowlist is configured and the chosen UI tenant is present

Fail condition:
- allowlist missing, empty, or tenant absent

Operator action:
- stop the run before app start

## 5. Admin Key Handling
`ADMIN_API_KEY` is server-side only.

It must never appear in:
- browser JavaScript
- UI/bootstrap payloads
- rendered HTML
- screenshots
- operator notes copied into the run bundle
- plain-text logs where avoidable
- run-bundle env snapshots

Required exposure checks:
- logs
- run bundle artifacts
- rendered HTML responses
- UI/bootstrap payloads when applicable

## 6. OpenBao Mode Resolution
The canonical full-demo mode requires OpenBao-backed signing posture.

### 6.1 Full Demo / Signoff
Allowed only if all of the following are true:
- OpenBao is reachable
- INF-006 verifier passes
- OpenBao is not in dev-mode or equivalent insecure posture
- required audit/smoke posture is satisfied
- required TLS posture can be positively described

If any of the above cannot be proven, the host is **not approved for full-demo sign-off**.

### 6.2 Rehearsal-Only / Non-Signoff
Allowed when host execution is needed for rehearsal but the stronger OpenBao-backed signoff posture cannot be proven.

Rules:
- must be labeled `rehearsal-only` or `non-signoff`
- must never be represented as full-demo readiness
- may not be used to claim full OpenBao/TLS signoff posture

## 7. OpenBao Verification Requirements
For full-demo signoff, operator verification must include:
- `/v1/sys/health` posture
- INF-006 verifier pass
- AppRole smoke availability
- audit device configured
- dev-mode or equivalent insecure posture absent

Current repo-backed commands:
```bash
bash scripts/infra/verify_tsk_p1_inf_006.sh
bash scripts/security/openbao_smoke_test.sh
bash scripts/audit/verify_openbao_not_dev.sh
```

## 8. OpenBao TLS Posture
For full-demo signoff, TLS posture must be positively described.

Required capture set:
- TLS enabled status
- subject
- issuer
- serial
- SHA-256 fingerprint
- validity window

If the current host cannot provide this truth, the run remains rehearsal-only.

This is deliberate fail-closed behavior.

## 9. Evidence Signing Policy
Evidence-signing posture for full-demo mode:
- INF-006 must pass before the run is declared signoff-ready
- no live signing-key rotation during the visible demo
- evidence-signing identity remains separate from client and admin identities

The current INF-006 implementation truth on this repo uses OpenBao-backed HMAC-SHA256 proof with key-id sidecars.

## 10. Read/Admin Key Rotation
Mandatory rule:
- rotate demo read/admin keys per demo event or immediately upon suspected exposure

This closeout is treated as the demo key rotation closeout step.

Required closeout fields in the run summary:
- whether rotation was required
- whether rotation was completed
- whether a waiver was used
- operator note for any waiver

If rotation is required and neither completed nor explicitly waived, signoff closeout fails.

## 11. Secret Material in Evidence
Run bundles and operator tooling must never store:
- raw API keys
- raw admin keys
- raw OpenBao root token
- reusable unsalted secret digests

Allowed:
- presence/absence indicators
- run-scoped HMAC fingerprints
- metadata such as key role, scope, and whether rotation occurred

## 12. Failure Rules
Fail closed for full-demo signoff when:
- OpenBao truth is ambiguous
- INF-006 fails
- dev-mode posture is present
- admin key appears in browser/bootstrap/rendered HTML
- allowlist is missing or tenant is absent
- required post-demo rotation is neither completed nor waived
