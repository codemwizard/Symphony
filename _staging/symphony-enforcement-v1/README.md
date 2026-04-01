# Symphony Enforcement Package v1 -- README

## What this is
A staged set of enforcement changes for the Symphony repository, organized so
they can be reviewed, held, and applied independently. Nothing in this directory
affects the live repo until you copy files to their target paths.

## Architecture: 5 enforcement layers

```
Layer 1 -- Git enforcement       (.githooks/pre-push)
Layer 2 -- Conformance hardening (verify_agent_conformance.sh patch)
Layer 3 -- DRD mechanical lockout (pre_ci_debug_contract.sh + pre_ci.sh + run_task.sh)
Layer 4 -- Knowledge base        (failure_signatures.yml + build_failure_index.sh + troubleshooting/)
Layer 5 -- Agent context         (prompt_template.md + AGENT_ENTRYPOINT.md)
```

Each layer closes a specific failure mode:

| Layer | Failure mode closed |
|---|---|
| 1 | Constraint violation -- agent pushes to main |
| 2 | Trust corruption -- fake approval hashes accepted |
| 3 | Goal drift under pressure -- 16-iteration DRD loop |
| 4 | Hallucination under ambiguity -- no prior knowledge available |
| 5 | Context decay -- rules forgotten mid-session |

## What is already live in the repo

Layers 1, 3, and 5 were written directly during the session:
- `.githooks/pre-push` -- rewrote with main block + force-push block
- `scripts/audit/pre_ci_debug_contract.sh` -- added DRD lockout writer + checker
- `scripts/dev/pre_ci.sh` -- added DRD lockout gate at startup
- `scripts/agent/run_task.sh` -- added rejection context with DRD state
- `AGENT_ENTRYPOINT.md` -- added Pre-Step with DRD lockout awareness

## What still needs to be applied

### Layer 2 (manual patch)
File: `layer-2-conformance-hardening/verify_agent_conformance.PATCH.md`
Open `scripts/audit/verify_agent_conformance.sh` and apply the find/replace
shown in the patch file. Takes about 5 minutes.

### Layer 4 (new files -- copy to repo)
```bash
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/failure_signatures.yml \
   docs/operations/failure_signatures.yml
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/build_failure_index.sh \
   scripts/audit/build_failure_index.sh
chmod +x scripts/audit/build_failure_index.sh
mkdir -p docs/troubleshooting
cp _staging/symphony-enforcement-v1/layer-4-knowledge-base/troubleshooting/* \
   docs/troubleshooting/
bash scripts/audit/build_failure_index.sh
```

### Layer 5 (new file -- copy to repo)
```bash
cp _staging/symphony-enforcement-v1/layer-5-agent-context/prompt_template.md \
   .agent/prompt_template.md
```

## One-time activation steps
```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-push .githooks/pre-commit
```

## Directory structure
```
_staging/symphony-enforcement-v1/
|-- MANIFEST.md
|-- README.md
|-- layer-1-git-enforcement/
|   `-- pre-push.sh
|-- layer-2-conformance-hardening/
|   `-- verify_agent_conformance.PATCH.md
|-- layer-3-drd-lockout/
|   |-- pre_ci_check_drd_lockout.ENHANCEMENT.sh
|   `-- README.md
|-- layer-4-knowledge-base/
|   |-- failure_signatures.yml
|   |-- build_failure_index.sh
|   |-- validate_failure_registry.sh
|   |-- failure-index.yml
|   `-- troubleshooting/
|       |-- preci-db-environment.md
|       |-- preci-toolchain.md
|       |-- preci-conformance.md
|       |-- preci-change-rule.md
|       |-- preci-governance.md
|       `-- preci-remediation.md
`-- layer-5-agent-context/
    `-- prompt_template.md
```
