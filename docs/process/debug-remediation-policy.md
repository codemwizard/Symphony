# Debug and Remediation Documentation Policy (Mirror)

Canonical source: `.agent/policies/debug-remediation-policy.md`  
Last synchronized from canonical: 2026-02-24

If this document conflicts with canonical policy, the `.agent` policy governs.

## Summary
Symphony uses severity-based DRD documentation to avoid non-converging debug loops while preventing process overhead for trivial fixes.

## Severity
- L0: no DRD required.
- L1: DRD Lite required.
- L2: DRD Full required.
- L3: DRD Full + prevention tracking.

## Key Rules
- Initial implementation blockers are in scope.
- Two-strike non-convergence triggers mandatory DRD Full and fail-first triage.
- Gates that read committed diff state require commit-state discipline before rerun.
- Advisory-first enforcement; declarative severity input; promote later by metrics.

## Templates
- `docs/remediation/templates/drd-lite-template.md`
- `docs/remediation/templates/drd-full-template.md`
