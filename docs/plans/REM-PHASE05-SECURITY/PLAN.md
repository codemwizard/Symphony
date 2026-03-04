# Phase 0.5 Security Remediation Plan

## Objective
Implement Phase 0.5 security remediation tasks (R-018 through R-022) to enhance security posture and CI integration.

## Tasks

### R-018: Policy scope + enforcement mapping reform
**Goal**: Make security policies language-agnostic and create enforcement mapping contract.

**Implementation**:
- Create SECURITY_ENFORCEMENT_MAP.yml with C# and Python coverage
- Update security policies to explicitly include language scope
- Create verification scripts for policy compliance

### R-019: Lint scope expansion + real SQL injection lint
**Goal**: Expand lint coverage to include application-layer SQL injection detection.

**Implementation**:
- Rename misleading lint_sql_injection.sh
- Create lint_app_sql_injection.sh for C# and Python
- Create fixture suite for testing

### R-020: Semgrep expansion (Python + C#)
**Goal**: Expand Semgrep rules to cover both C# and Python security patterns.

**Implementation**:
- Add Python SQL injection rules
- Add C# string interpolation rules
- Expand hardcoded secrets detection
- Create verification scripts

### R-021: CI gate - parameterization enforcement
**Goal**: Ensure CI security scan includes all required tools and is fail-closed.

**Implementation**:
- Update security_scan job in invariants.yml
- Add lint_app_sql_injection and Semgrep execution
- Ensure fail-closed behavior
- Create suppression auditing

### R-022: Security tooling coverage contract
**Goal**: Create contract enforcing language-present => scanned rules.

**Implementation**:
- Create SECURITY_SCAN_SCOPE.yml contract
- Create validation scripts
- Enforce coverage requirements

## Success Criteria
- All tasks completed with verification scripts
- Evidence artifacts generated per DOD
- CI integration working
- Language-agnostic policies implemented

## Timeline
- **Start**: 2026-03-04
- **Completion**: 2026-03-04
- **Review**: Pending PR creation
