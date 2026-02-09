# Invariants Roadmap

These invariants are **planned** (`roadmap`). They may have partial evidence (e.g., migrations landed) but are not yet verified end-to-end.

_Generated mechanically from `docs/invariants/INVARIANTS_MANIFEST.yml`._

| ID | Aliases | Severity | Title | Owners | Verification (manifest) | Evidence links |
|---|---|---|---|---|---|---|
| INV-009 | I-SEC-05 | P1 | SECURITY DEFINER functions must avoid dynamic SQL and user-controlled identifiers | team-platform | TODO: add linter or allowlist-based review; no mechanical check found | [`scripts/db/ci_invariant_gate.sql L87-L91`](../../scripts/db/ci_invariant_gate.sql#L87-L91)<br>[`scripts/db/lint_search_path.sh L2-L6`](../../scripts/db/lint_search_path.sh#L2-L6)<br>[`scripts/db/verify_invariants.sh L32-L36`](../../scripts/db/verify_invariants.sh#L32-L36) |
| INV-039 |  | P1 | Fail-closed under DB exhaustion | team-platform | TODO: define and wire fail-closed verification |  |
| INV-048 | I-ZECHL-01 | P1 | Proxy/Alias resolution required before dispatch | team-platform | scripts/audit/verify_proxy_resolution_invariant.sh |  |
| INV-111 |  | P0 | BoZ observability role exists + provably read-only (DB structural) | team-db, team-platform | Phase-0/1 activation: forward-only migration defining boz_auditor role; catalog verifier proves read-only posture; CI DB job emits evidence. |  |
| INV-112 |  | P0 | ZDPA PII leakage prevention lint (fail-closed on regulated payload surfaces) | team-security, team-platform | Phase-0 activation: implement scripts/audit/lint_pii_leakage_payloads.sh (fail-closed, deterministic) + tests; emit evidence in CI/pre-CI. |  |
| INV-113 |  | P0 | Hybrid anchor-sync schema hooks present (Phase-0 structural readiness) | team-db, team-platform | Phase-0 activation: catalog verifier checks structural anchor hooks on evidence packs; Phase-1 adds operational queue semantics. |  |
| INV-114 | INV-BOZ-04 | P0 | Payment finality / instruction irrevocability (reversal-only via ISO 20022 camt.056) | team-db, team-platform | Phase-1 activation: enforce finality state machine + camt.056 reversal workflow; add mechanical DB constraints/triggers and CI tests. Phase-0 is declarative only. |  |
| INV-115 | INV-ZDPA-01 | P0 | PII decoupling + right-to-be-forgotten survivability (evidence remains valid after PII purge) | team-security, team-db, team-platform | Phase-1/2 activation: tokenization/vault tables + retention hooks + evidence signing over identity_hash; add mechanical purge tests and signature verification. Phase-0 is declarative only. |  |
| INV-116 | INV-IPDR-02 | P0 | Rail truth-anchor sequence continuity (generic; jurisdiction profiles e.g. ZM-NFS) | team-db, team-platform | Phase-1 activation: require non-null rail sequence ref on success + uniqueness scoped to (rail_sequence_ref, rail_participant_id); add DB constraints/indexes and CI integration tests. Phase-0 is declarative only. |  |
