# GreenTech4CE Deployment and Onboarding Hardening Plan

## objective
Convert the current provisional GreenTech4CE demo into a hardened deployment and onboarding system
with one supported runtime architecture:
- PostgreSQL as the durable operational store for ingress and onboarding state.
- OpenBao as the runtime secret source for the hardened profile.
- Server-side onboarding APIs and a website onboarding console for operators.
- One canonical bootstrap path.
- Readiness and verifiers that reject provisional workarounds.

## non_negotiable_hardening_rules
1. No manual workaround may remain in the supported path after the owning task closes.
2. No hardened deployment may depend on file-mode persistence for ingress or supplier policy state.
3. No hardened deployment may trust process environment variables as the runtime source of truth for
   secrets that are in scope for OpenBao integration.
4. No onboarding workflow may depend on SYMPHONY_KNOWN_TENANTS as the live operational tenant registry.
5. No browser code may hold ADMIN_API_KEY or signing-key material.
6. No restart may require operator reseeding of supplier, allowlist, tenant, or programme state.
7. No gate may pass by exercising only a provisional path when a hardened path exists.

## execution_order
1. TSK-P1-211 — repair schema conflict-target defect permanently.
2. TSK-P1-212 — restore db_psql ingress and make it canonical.
3. TSK-P1-214 — persist supplier registry and programme allowlist in PostgreSQL.
4. TSK-P1-215 — integrate runtime secret provider with OpenBao.
5. TSK-P1-216 — separate key domains and prove rotation.
6. TSK-P1-217 — persist onboarding control-plane state.
7. TSK-P1-218 — expose server-side onboarding APIs.
8. TSK-P1-219 — deliver website onboarding console.
9. TSK-P1-220 — build the one-command bootstrap.
10. TSK-P1-221 — rewrite docs, readiness, and gates around the hardened architecture.

## expected_end_state
- An operator can bootstrap the GreenTech4CE demo from a clean checkout with one supported command.
- Runtime secrets come from OpenBao in the hardened profile and readiness fails closed without them.
- Tenants, programmes, supplier registry, and programme allowlists survive restart without replay.
- Operators can onboard clients and suppliers through the website using server-side privileged routes.
- Deployment and onboarding docs stop documenting provisional escape hatches as acceptable behavior.
