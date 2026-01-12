## Security Policy Consumption

This repository consumes security policy from:

**Repository:** `org-security-policies`
**URL:** `https://github.com/codemwizard/org-security-policies.git`

### Policy Governance Rules

The policy is:
- **Read-only** — No modifications in this repository
- **Version-pinned** — Locked via `.policy.lock` file
- **Immutable authority** — Updated only via approved policy change process

### Prohibited Actions

❌ Direct submodule updates (`git submodule update --remote`)
❌ Manual edits to `.policies/` directory
❌ Bypassing CI policy version verification

### Approved Update Process

1. Policy change is made in `org-security-policies` repository
2. Change is reviewed and approved by Security Authority
3. Symphony repository is updated via approved PR that updates `.policy.lock`
4. CI verifies lock matches submodule

### Audit Trail

All policy consumption is:
- Cryptographically verifiable via commit hash
- CI-enforced on every build
- Logged in build artifacts
