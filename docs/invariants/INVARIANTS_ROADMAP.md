# Invariants Roadmap

These invariants are **planned** (`roadmap`). They may have partial evidence (e.g., migrations landed) but are not yet verified end-to-end.

_Generated mechanically from `docs/invariants/INVARIANTS_MANIFEST.yml`._

| ID | Aliases | Severity | Title | Owners | Verification (manifest) | Evidence links |
|---|---|---|---|---|---|---|
| INV-009 | I-SEC-05 | P1 | SECURITY DEFINER functions must avoid dynamic SQL and user-controlled identifiers | team-platform | TODO: add linter or allowlist-based review; no mechanical check found | [`scripts/db/ci_invariant_gate.sql L87-L91`](../../scripts/db/ci_invariant_gate.sql#L87-L91)<br>[`scripts/db/lint_search_path.sh L2-L6`](../../scripts/db/lint_search_path.sh#L2-L6)<br>[`scripts/db/verify_invariants.sh L32-L36`](../../scripts/db/verify_invariants.sh#L32-L36) |
| INV-039 |  | P1 | Fail-closed under DB exhaustion | team-platform | TODO: define and wire fail-closed verification |  |
| INV-048 | I-ZECHL-01 | P1 | Proxy/Alias resolution required before dispatch | team-platform | scripts/audit/verify_proxy_resolution_invariant.sh |  |
| INV-116 | INV-IPDR-02 | P0 | Rail truth-anchor sequence continuity (generic; jurisdiction profiles e.g. ZM-NFS) | team-db, team-platform | Phase-1 activation: require non-null rail sequence ref on success + uniqueness scoped to (rail_sequence_ref, rail_participant_id); add DB constraints/indexes and CI integration tests. Phase-0 is declarative only. |  |
