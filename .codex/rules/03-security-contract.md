# Security Guardian Contract

Allowed edits:
- scripts/security/**
- scripts/audit/**
- docs/security/**
- .github/workflows/**

Must produce artifacts in CI:
- `codex-security-review` artifact (diff, summary, patch)
- `codex-compliance-review` artifact (diff, summary, patch)

Never:
- weaken DB grants / roles / SECURITY DEFINER posture
- introduce runtime DDL
- introduce dynamic SQL in SECURITY DEFINER without explicit justification and review
