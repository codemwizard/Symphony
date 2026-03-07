# Invariant ID Management

This document tracks invariant ID declarations and ownership references for governance-critical controls.

## Declared IDs

- `INV-134`
  - Title: SEC-G08 dependency audit gate enforcement
  - Scope: Dependency vulnerability audit must run fail-closed and emit evidence
  - Primary script: `scripts/security/dotnet_dependency_audit.sh`
  - Evidence:
    - `evidence/phase0/security_dotnet_deps_audit.json`
    - `evidence/phase1/dep_audit_gate.json`
