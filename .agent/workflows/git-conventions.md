---
description: mandatory branch naming and commit message conventions — commits MUST include a Phase or Wave identifier
---

# Git Conventions Workflow

This workflow defines the **mandatory** branch naming and commit message rules for the Symphony repository. All AI agents and contributors MUST follow these conventions. A commit that does not include a Phase name or Wave name **MUST be rejected**.

---

## 1. Pre-Commit Gate (MANDATORY)

Before creating any commit, verify the following:

1. A **Phase Name** or **Wave Name** has been explicitly provided or identified.
2. The approved **Task.md** for the current phase/wave exists and has been reviewed.

> **FAIL CONDITION**: If neither a Phase Name nor a Wave Name can be determined, the commit MUST NOT proceed. The agent MUST stop and ask the user for the Phase or Wave identifier before continuing.

```
# Pseudocode — agent MUST enforce this logic
if phase_name is EMPTY and wave_name is EMPTY:
    STOP
    ASK USER: "No Phase or Wave name has been provided. Please specify one before I can commit."
    DO NOT PROCEED
```

---

## 2. Branch Naming Convention

### Format
```
[category]/[phase-or-wave-key]-[name-kebab-case]
```

### Rules
| Component | Description | Examples |
|-----------|-------------|----------|
| `category` | Work category prefix | `security`, `feat`, `fix`, `ops`, `infra` |
| `phase-or-wave-key` | Phase key (e.g. `0.2`) or Wave key (e.g. `wave-1`) | `0.1`, `0.2`, `wave-1`, `wave-3` |
| `name-kebab-case` | Phase/Wave name in kebab-case | `containment`, `emergency-code-fixes` |

### Examples
```bash
# Security remediation phases
security/0.1-containment
security/0.2-emergency-code-fixes
security/0.3-hardening

# Operational waves
ops/wave-1-stability-gate
ops/wave-2-exit-gate

# Feature work tied to a phase
feat/1.0-pilot-onboarding
```

### Prohibited
- Branches without a phase or wave key: ~~`security/fix-signing`~~
- Generic names: ~~`fix/stuff`~~, ~~`update`~~

---

## 3. Commit Message Convention

### Format
```
Phase [Phase Key]: [Phase Name]
  — OR —
Wave [Wave Key]: [Wave Name]

[Contents of approved Task.md]
```

### Header Line
- **MUST** start with `Phase [key]:` or `Wave [key]:`
- **MUST** include the human-readable Phase/Wave Name after the colon
- Maximum 72 characters

### Body
- The body of the commit message is the contents of the **approved final Task.md** for that phase/wave
- Task items should be listed with their completion status
- Include a blank line between the header and body

### Examples

```
Phase 0.2: Emergency Code Fixes

# Security Remediation Tasks — Phase 0.2

- [x] R-001: Fail hard on missing signing keys
  - [x] Remove literal "dev-signing-key" fallbacks
  - [x] Add signing_key_present to /health
  - [x] Return 503 with SIGNING_CAPABILITY_MISSING
  - [x] Verification PASS, schema validation PASS

- [x] R-002: Tenant allowlist deny-all default
  - [x] Extract AuthorizeTenantScope as centralized method
  - [x] Return 503 when unconfigured, 403 for unknown tenants
  - [x] Verification PASS, schema validation PASS
```

```
Wave 1: Stability Gate

- [x] TSK-OPS-WAVE1-001: Connection pool tuning
- [x] TSK-OPS-WAVE1-002: Health check endpoint
```

---

## 4. Staging Rules

Only stage files relevant to the current Phase/Wave:
- Modified source files
- New/updated verification scripts
- Evidence artifacts and schemas
- Task metadata (`tasks/R-XXX/meta.yml`, docs)

Do **NOT** stage unrelated files from other phases or general workspace changes.

---

## 5. Post-Commit Checklist

After committing:
1. Verify the commit message header matches `Phase X.Y:` or `Wave X:` format
2. Verify the branch name matches `[category]/[key]-[name]` format
3. Confirm the Task.md contents appear in the commit body

```bash
# Quick verification
git log -1 --format="%s" | grep -E "^(Phase|Wave) [0-9]"
```
