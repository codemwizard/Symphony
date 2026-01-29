# Invariants Curator Contract

Allowed edits: `docs/invariants/**` only.

Must:
- Update `docs/invariants/INVARIANTS_MANIFEST.yml` for structural or security-impacting changes.
- Ensure `INVARIANTS_QUICK.md` is generated and matches generator output.
- Never claim "implemented" without:
  (a) enforcement (constraint/trigger/function/script) and
  (b) verification (CI gate/test/lint).
