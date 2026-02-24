# Debug and Remediation Documentation Policy (DRD)

## Canonical Source
This file is the canonical source for DRD requirements.

## Purpose
Standardize how agents document blockers, non-converging debug loops, and remediation so recovery is deterministic and auditable.

## Scope
Applies to initial implementation blockers, debugging, and remediation. Not limited to post-implementation fixes.

## Severity Model
- `L0` Trivial: one-pass local fix; no DRD required.
- `L1` Local blocker: DRD Lite required.
- `L2` Non-converging or multi-gate failure: DRD Full required.
- `L3` Cross-task/systemic issue: DRD Full + prevention tracking required.

## Non-Bureaucracy Rule
DRD is not required for L0 trivial fixes. Over-reporting trivial issues is misuse.

## Mandatory Triggers
Use DRD Lite or Full when any trigger applies:
- Blocked > 15 minutes.
- More than 2 failed attempts.
- Multi-gate CI/pre_ci/pre-push failure chain.
- Governance/compliance/baseline/invariants/security remediation scope.
- Material push/merge delay (>30 minutes).

## Two-Strike Non-Convergence Rule
After 2 full reruns/retries without convergence, or if first blocker changes between reruns, the agent must:
1. Stop blind reruns.
2. Open/update DRD Full.
3. Switch to first-fail artifact triage.

## Triage Protocol (Fail-First)
1. Capture earliest failing artifact/signal.
2. Patch only that breach.
3. Run targeted verification for that breach.
4. Advance only after explicit PASS/FAIL outcome.

## Commit-State Discipline
If a gate evaluates committed diff state, ensure required fixes are staged/committed before rerunning that gate.

## Template Use
- Lite template: `docs/remediation/templates/drd-lite-template.md`
- Full template: `docs/remediation/templates/drd-full-template.md`

## Required Metadata (Lite and Full)
- Template type
- Incident class
- Severity
- Status
- Owner
- Task/branch
- First failing signal/artifact
- Verification outcomes

## Full Template Required Sections
- Timeline
- Root causes
- Contributing factors
- Decision points
- Prevention actions with owner, enforcement, metric, status, target date

## Enforcement Rollout
- Advisory first; no day-1 hard fail.
- Initial declarative input: severity marked by author in PR/task process.
- Enforcement promotion only after adoption/false-positive thresholds are met.
