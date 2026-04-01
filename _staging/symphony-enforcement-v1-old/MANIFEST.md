# Symphony Enforcement Package v1 — MANIFEST
# Staging directory — DO NOT apply to repo without reading this file first.
# Apply layers in order. Each layer is independent and additive.
#
# SOURCE OF TRUTH: Everything in this staging directory is the canonical version.
# Do not use shell commands printed in chat sessions — those were workarounds
# for MCP write failures and may be out of date. Always apply from here.

## Current state of all layers

| Layer | Name | Repo status | Action needed |
|---|---|---|---|
| 1 | Git enforcement (pre-push) | ✅ Live | None — already written |
| 2 | Conformance hash validation | ⏳ Pending | Manual patch — see layer-2 |
| 3 | DRD mechanical lockout | ✅ Live | Optional enhancement — see layer-3 |
| 4 | Knowledge base | ⏳ Pending | Apply with copy commands below |
| 5 | Agent context | ⏳ Pending | Apply with copy command below |
| 6 | CODEOWNERS + GitHub settings | ⏳ Pending | Copy + GitHub UI settings |

## Files already live in repo (do not reapply)

- `.githooks/pre-push` — main block + force-push block (Layer 1)
- `scripts/audit/pre_ci_debug_contract.sh` — DRD lockout writer + checker (Layer 3)
- `scripts/dev/pre_ci.sh` — DRD lockout gate at startup (Layer 3)
- `scripts/agent/run_task.sh` — rejection context with DRD state (Layer 3)
- `AGENT_ENTRYPOINT.md` — pre-step with DRD lockout awareness (Layer 5)

## Current DRD lockout state

Your repo is currently LOCKED:
  Signature: PRECI.DB.ENVIRONMENT
  Count: 16 consecutive failures

BEFORE running pre_ci.sh you must (in order):
1. Run: scripts/audit/new_remediation_casefile.sh \
     --phase phase1 --slug phase1-db-verifiers \
     --failure-signature PRECI.DB.ENVIRONMENT \
     --origin-gate-id pre_ci.phase1_db_verifiers \
     --repro-command "scripts/dev/pre_ci.sh"
2. Document root cause in the generated PLAN.md
3. Run: rm .toolchain/pre_ci_debug/drd_lockout.env
4. Diagnose the DB issue using: docs/troubleshooting/preci-db-environment.md
   (available after Layer 4 is applied)

---

## How to apply — full apply script

Run all of the following from the repo root on the Ubuntu server.
The staging directory (_staging/symphony-enforcement-v1/) must be present
in the repo (it is committed alongside the live files).

### Step 1 — Layer 4: Knowledge base

```bash
# Failure signature registry
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/failure_signatures.yml \
   docs/operations/failure_signatures.yml

# Index builder
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/build_failure_index.sh \
   scripts/audit/build_failure_index.sh
chmod +x scripts/audit/build_failure_index.sh

# Registry validator (new — run after editing failure_signatures.yml)
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/validate_failure_registry.sh \
   scripts/audit/validate_failure_registry.sh
chmod +x scripts/audit/validate_failure_registry.sh

# CI workflow for automatic index rebuilds (new)
mkdir -p .github/workflows
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/failure-index.yml \
   .github/workflows/failure-index.yml

# Troubleshooting playbooks (note: target is docs/troubleshooting/, not docs/operations/troubleshooting/)
mkdir -p docs/troubleshooting
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/troubleshooting/* \
   docs/troubleshooting/

# Validate registry before generating index
bash scripts/audit/validate_failure_registry.sh

# Generate the searchable index from existing casefiles
bash scripts/audit/build_failure_index.sh
```

### Step 2 — Layer 5: Agent prompt template

```bash
cp _staging/symphony-enforcement-v1/layer-5-agent-context/prompt_template.md \
   .agent/prompt_template.md
```

### Step 3 — Layer 2: Hash validation patch (manual edit, ~5 minutes)

Open `scripts/audit/verify_agent_conformance.sh`.
Inside `check_approval_metadata()`, find this exact block:

```python
    for field in ["ai_prompt_hash", "model_id"]:
        if not data.get("ai", {}).get(field):
            fail("CONFORMANCE_008_APPROVAL_METADATA_INVALID", f"Approval metadata missing ai.{field}")
```

Replace it with the block in:
  `layer-2-conformance-hardening/verify_agent_conformance.PATCH.md`

`import re` is already present in the file — no additional import needed.

### Step 4 — Layer 3 enhancement (optional, apply after Step 1 is confirmed)

Replace `pre_ci_check_drd_lockout()` in `scripts/audit/pre_ci_debug_contract.sh`
with the version in:
  `layer-3-drd-lockout/pre_ci_check_drd_lockout.ENHANCEMENT.sh`

This adds registry lookup to the lockout message so agents see the playbook
link immediately when blocked. Requires failure_signatures.yml to exist (Step 1).

### Step 5 — CODEOWNERS (requires GitHub UI)

```bash
# Copy template and set your GitHub username
cp _staging/symphony-enforcement-v1/CODEOWNERS.template .github/CODEOWNERS
# Edit .github/CODEOWNERS: replace @your-github-username with real username
```

Then in GitHub → Settings → Branches → Add rule for `main`:
- Require pull request before merging: ON
- Require approvals: 1
- Require review from Code Owners: ON
- Require status checks to pass: ON
- Do not allow bypassing above settings: ON
- Allow force pushes: OFF

### Step 6 — One-time activation (if not already done)

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-push
```

---

## Verification after apply

```bash
# Confirm all new files exist
ls docs/operations/failure_signatures.yml
ls docs/operations/failure_index.md
ls scripts/audit/build_failure_index.sh
ls scripts/audit/validate_failure_registry.sh
ls .github/workflows/failure-index.yml
ls docs/troubleshooting/preci-db-environment.md
ls docs/troubleshooting/preci-toolchain.md
ls docs/troubleshooting/preci-conformance.md
ls docs/troubleshooting/preci-change-rule.md
ls docs/troubleshooting/preci-governance.md
ls docs/troubleshooting/preci-remediation.md
ls .agent/prompt_template.md

# Confirm registry is valid
bash scripts/audit/validate_failure_registry.sh

# Confirm index builder works
bash scripts/audit/build_failure_index.sh
```
