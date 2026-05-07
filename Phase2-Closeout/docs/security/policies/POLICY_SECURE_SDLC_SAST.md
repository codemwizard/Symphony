# Secure SDLC & SAST Readiness Policy (Phase-0 Stub)

## Purpose
This policy establishes secure development lifecycle requirements for Symphony, including baseline SAST readiness.
In Phase-0, enforcement is **readiness + evidence emission** (tool presence, configuration presence, and policy linkage),
not full vulnerability remediation SLAs.

## Secure SDLC Minimum Controls
- code review is mandatory for regulated surfaces (schema/, scripts/, infra/, src/, workflows/)
- changes must pass all control-plane gates (Security, Integrity, Governance) in pre-CI and CI
- exceptions must be documented via ADR and are time-bound

## SAST Readiness (Phase-0)
At minimum, Symphony must demonstrate:
- a configured SAST toolchain exists (Semgrep and/or native .NET analyzers)
- dependency vulnerability checks exist for .NET packages
- evidence is emitted on every run, including versions and scope scanned

Recommended baseline tools for .NET:
- `dotnet list package --vulnerable` (dependency vulnerability signal)
- Roslyn analyzers (compiler-level rules)
- Semgrep (repo-scoped policy rules for migrations/scripts and lightweight C# rules)

## Evidence Expectations
Each CI run must generate evidence including:
- tool version(s)
- scope scanned (paths, file counts)
- git SHA
- status (PASS/FAIL/SKIPPED)

## References
- `docs/security/THREE_PILLARS_SECURITY.md`
- `docs/control_planes/CONTROL_PLANES.yml`

