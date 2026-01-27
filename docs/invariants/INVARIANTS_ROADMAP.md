# Invariants Roadmap

These invariants are **planned** (`roadmap`). They may have partial evidence (e.g., migrations landed) but are not yet verified end-to-end.

_Generated mechanically from `docs/invariants/INVARIANTS_MANIFEST.yml`._

| ID | Aliases | Severity | Title | Owners | Verification (manifest) | Evidence links |
|---|---|---|---|---|---|---|
| INV-004 | I-MIG-05 | P1 | Baseline snapshot is derived from migrations and must not drift | team-db | TODO: add baseline regeneration + freshness check in CI (no baseline enforcement found in repo snapshot) | [`scripts/db/ci_invariant_gate.sql L1-L5`](../../scripts/db/ci_invariant_gate.sql#L1-L5)<br>[`scripts/db/lint_migrations.sh L1-L5`](../../scripts/db/lint_migrations.sh#L1-L5)<br>[`scripts/db/lint_search_path.sh L12-L16`](../../scripts/db/lint_search_path.sh#L12-L16) |
| INV-009 | I-SEC-05 | P1 | SECURITY DEFINER functions must avoid dynamic SQL and user-controlled identifiers | team-platform | TODO: add linter or allowlist-based review; no mechanical check found | [`scripts/db/ci_invariant_gate.sql L87-L91`](../../scripts/db/ci_invariant_gate.sql#L87-L91)<br>[`scripts/db/lint_search_path.sh L2-L6`](../../scripts/db/lint_search_path.sh#L2-L6)<br>[`scripts/db/verify_invariants.sh L32-L36`](../../scripts/db/verify_invariants.sh#L32-L36) |
