# Troubleshooting: PRECI.AGENT.CONFORMANCE

**Failure signature:** `PRECI.AGENT.CONFORMANCE`
**Gate:** `pre_ci.verify_agent_conformance`
**Owner:** governance
**DRD level:** L2

## What this means

Agent conformance verification failed. An agent prompt file is missing required
headers, references, or approval metadata has an invalid format.

## Expected failure output

```
CONFORMANCE FAIL
- CONFORMANCE_018_PROMPT_HASH_INVALID ai_prompt_hash must be a SHA256 hex string ...
- CONFORMANCE_002_PROMPT_HEADERS_MISSING Missing header 'Stop Conditions' in AGENTS.md
```

## Diagnostic steps

1. **Run the conformance check directly to see the exact failure codes:**
   ```bash
   scripts/audit/verify_agent_conformance.sh
   ```

2. **Common failure codes and fixes:**

   | Code | Meaning | Fix |
   |---|---|---|
   | `CONFORMANCE_002_PROMPT_HEADERS_MISSING` | Required `##` section missing from agent prompt | Add the missing section |
   | `CONFORMANCE_003_ROLE_INVALID` | `Role:` line missing or not in canonical list | Check `CANONICAL_ROLES` in the script |
   | `CONFORMANCE_004_CANONICAL_REFERENCE_MISSING` | A canonical doc not referenced in prompt | Add reference to the doc |
   | `CONFORMANCE_008_APPROVAL_METADATA_INVALID` | `approval_metadata.json` missing a field | Add the missing field |
   | `CONFORMANCE_018_PROMPT_HASH_INVALID` | `ai_prompt_hash` is not a valid SHA256 | Generate a real hash (see below) |
   | `CONFORMANCE_020_BRANCH_MAIN_FORBIDDEN` | Running on main branch | Switch to a feature branch |

3. **For hash errors (`CONFORMANCE_018`):** The `ai_prompt_hash` field in
   `evidence/phase1/approval_metadata.json` must be a real 64-character lowercase
   SHA256 hex string. Branch names, session IDs, and placeholder strings are rejected.
   Generate a valid hash:
   ```bash
   echo -n "your-prompt-content" | sha256sum | cut -d' ' -f1
   ```

4. **Required sections in agent prompt files:**
   `Role`, `Scope`, `Non-Negotiables`, `Stop Conditions`,
   `Verification Commands`, `Evidence Outputs`, `Canonical References`

## Clearing the DRD lockout

```bash
# Step 1 ΓÇö create the casefile
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug agent-conformance \
  --failure-signature PRECI.AGENT.CONFORMANCE \
  --origin-gate-id pre_ci.verify_agent_conformance \
  --repro-command "scripts/dev/pre_ci.sh"

# Step 2 ΓÇö document root cause in PLAN.md

# Step 3 ΓÇö remove lockout
rm .toolchain/pre_ci_debug/drd_lockout.env

# Step 4 ΓÇö re-run
scripts/dev/pre_ci.sh
```
