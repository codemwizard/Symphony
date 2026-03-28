# Symphony Enforcement Package v1 ΓÇö README

## What this is
A staged set of enforcement changes for the Symphony repository, organized so
they can be reviewed, held, and applied independently. Nothing in this directory
affects the live repo until you copy files to their target paths.

## Architecture: 5 enforcement layers

```
Layer 1 ΓÇö Git enforcement       (.githooks/pre-push)
Layer 2 ΓÇö Conformance hardening (verify_agent_conformance.sh patch)
Layer 3 ΓÇö DRD mechanical lockout (pre_ci_debug_contract.sh + pre_ci.sh + run_task.sh)
Layer 4 ΓÇö Knowledge base        (failure_signatures.yml + build_failure_index.sh + troubleshooting/)
Layer 5 ΓÇö Agent context         (prompt_template.md + AGENT_ENTRYPOINT.md)
```

Each layer closes a specific failure mode:

| Layer | Failure mode closed |
|---|---|
| 1 | Constraint violation ΓÇö agent pushes to main |
| 2 | Trust corruption ΓÇö fake approval hashes accepted |
| 3 | Goal drift under pressure ΓÇö 16-iteration DRD loop |
| 4 | Hallucination under ambiguity ΓÇö no prior knowledge available |
| 5 | Context decay ΓÇö rules forgotten mid-session |

## What is already live in the repo

Layers 1, 3, and 5 were written directly during the session:
- `.githooks/pre-push` ΓÇö rewrote with main block + force-push block
- `scripts/audit/pre_ci_debug_contract.sh` ΓÇö added DRD lockout writer + checker
- `scripts/dev/pre_ci.sh` ΓÇö added DRD lockout gate at startup
- `scripts/agent/run_task.sh` ΓÇö added rejection context with DRD state
- `AGENT_ENTRYPOINT.md` ΓÇö added Pre-Step with DRD lockout awareness

## What still needs to be applied

### Layer 2 (manual patch)
File: `layer-2-conformance-hardening/verify_agent_conformance.PATCH.md`
Open `scripts/audit/verify_agent_conformance.sh` and apply the find/replace
shown in the patch file. Takes about 5 minutes.

### Layer 4 (new files ΓÇö copy to repo)
```bash
# Copy failure registry
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/failure_signatures.yml \
   docs/operations/failure_signatures.yml

# Copy index builder
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/build_failure_index.sh \
   scripts/audit/build_failure_index.sh
chmod +x scripts/audit/build_failure_index.sh

# Copy troubleshooting docs
mkdir -p docs/troubleshooting
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/troubleshooting/* \
   docs/troubleshooting/

# Run the index builder to generate docs/operations/failure_index.md
bash scripts/audit/build_failure_index.sh
```

### Layer 5 (new file ΓÇö copy to repo)
```bash
cp _staging/symphony-enforcement-v1/layer-5-agent-context/prompt_template.md \
   .agent/prompt_template.md
```

## One-time activation steps
```bash
# Wire git hooks
git config core.hooksPath .githooks
chmod +x .githooks/pre-push .githooks/pre-commit

# Clear the current DRD lockout (ONLY after creating remediation casefile)
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug phase1-db-verifiers \
  --failure-signature PRECI.DB.ENVIRONMENT \
  --origin-gate-id pre_ci.phase1_db_verifiers \
  --repro-command "scripts/dev/pre_ci.sh"
# Then: document root cause in generated PLAN.md, then:
rm .toolchain/pre_ci_debug/drd_lockout.env
```

## What the knowledge base adds (Layer 4)

The failure registry and index builder convert your existing remediation casefiles
into a searchable knowledge base. This closes the "hallucination under ambiguity"
gap: instead of inventing what to do when a failure occurs, agents and humans can
look up prior incidents with the same signature and see what worked.

This mirrors Google SRE postmortem culture ΓÇö your casefiles already have the right
structure (failure_signature, repro_command, EXEC_LOG, final_status). The registry
and index builder add the discovery layer on top.

The `build_failure_index.sh` script produces `docs/operations/failure_index.md`,
which groups all prior incidents by failure signature and links each to its playbook.
The prompt template (Layer 5) tells agents to check this index before guessing.

## Still needed (not in this package)

- `.github/CODEOWNERS` ΓÇö protects workflow files from agent modification
- GitHub branch protection settings ΓÇö server-side main branch lock
- These require GitHub UI access and cannot be applied via file copy.
  See the full threat model in the conversation history for exact settings.

## Directory structure
```
_staging/symphony-enforcement-v1/
Γö£ΓöÇΓöÇ MANIFEST.md                         ΓÇö apply status and instructions
Γö£ΓöÇΓöÇ README.md                           ΓÇö this file
Γö£ΓöÇΓöÇ layer-1-git-enforcement/
Γöé   ΓööΓöÇΓöÇ pre-push.sh                     ΓÇö canonical snapshot (already in repo)
Γö£ΓöÇΓöÇ layer-2-conformance-hardening/
Γöé   ΓööΓöÇΓöÇ verify_agent_conformance.PATCH.md  ΓÇö manual patch instructions
Γö£ΓöÇΓöÇ layer-3-drd-lockout/
Γöé   ΓööΓöÇΓöÇ README.md                       ΓÇö explains what was written to repo
Γö£ΓöÇΓöÇ layer-4-knowledge-base/
Γöé   Γö£ΓöÇΓöÇ failure_signatures.yml          ΓÇö copy to docs/operations/
Γöé   Γö£ΓöÇΓöÇ build_failure_index.sh          ΓÇö copy to scripts/audit/
Γöé   ΓööΓöÇΓöÇ troubleshooting/
Γöé       ΓööΓöÇΓöÇ preci-db-environment.md     ΓÇö copy to docs/troubleshooting/
ΓööΓöÇΓöÇ layer-5-agent-context/
    ΓööΓöÇΓöÇ prompt_template.md              ΓÇö copy to .agent/
```
