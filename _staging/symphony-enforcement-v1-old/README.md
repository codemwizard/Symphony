# Symphony Enforcement Package v1 — README

## What this is
A staged set of enforcement changes for the Symphony repository, organized so
they can be reviewed, held, and applied independently. Nothing in this directory
affects the live repo until you copy files to their target paths.

## Architecture: 5 enforcement layers

```
Layer 1 — Git enforcement       (.githooks/pre-push)
Layer 2 — Conformance hardening (verify_agent_conformance.sh patch)
Layer 3 — DRD mechanical lockout (pre_ci_debug_contract.sh + pre_ci.sh + run_task.sh)
Layer 4 — Knowledge base        (failure_signatures.yml + build_failure_index.sh + troubleshooting/)
Layer 5 — Agent context         (prompt_template.md + AGENT_ENTRYPOINT.md)
```

Each layer closes a specific failure mode:

| Layer | Failure mode closed |
|---|---|
| 1 | Constraint violation — agent pushes to main |
| 2 | Trust corruption — fake approval hashes accepted |
| 3 | Goal drift under pressure — 16-iteration DRD loop |
| 4 | Hallucination under ambiguity — no prior knowledge available |
| 5 | Context decay — rules forgotten mid-session |

## What is already live in the repo

Layers 1, 3, and 5 were written directly during the session:
- `.githooks/pre-push` — rewrote with main block + force-push block
- `scripts/audit/pre_ci_debug_contract.sh` — added DRD lockout writer + checker
- `scripts/dev/pre_ci.sh` — added DRD lockout gate at startup
- `scripts/agent/run_task.sh` — added rejection context with DRD state
- `AGENT_ENTRYPOINT.md` — added Pre-Step with DRD lockout awareness

## What still needs to be applied

### Layer 2 (manual patch)
File: `layer-2-conformance-hardening/verify_agent_conformance.PATCH.md`
Open `scripts/audit/verify_agent_conformance.sh` and apply the find/replace
shown in the patch file. Takes about 5 minutes.

### Layer 4 (new files — copy to repo)
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

### Layer 5 (new file — copy to repo)
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

This mirrors Google SRE postmortem culture — your casefiles already have the right
structure (failure_signature, repro_command, EXEC_LOG, final_status). The registry
and index builder add the discovery layer on top.

The `build_failure_index.sh` script produces `docs/operations/failure_index.md`,
which groups all prior incidents by failure signature and links each to its playbook.
The prompt template (Layer 5) tells agents to check this index before guessing.

## Still needed (not in this package)

- `.github/CODEOWNERS` — protects workflow files from agent modification
- GitHub branch protection settings — server-side main branch lock
- These require GitHub UI access and cannot be applied via file copy.
  See the full threat model in the conversation history for exact settings.

## Directory structure
```
_staging/symphony-enforcement-v1/
├── MANIFEST.md                         — apply status and instructions
├── README.md                           — this file
├── layer-1-git-enforcement/
│   └── pre-push.sh                     — canonical snapshot (already in repo)
├── layer-2-conformance-hardening/
│   └── verify_agent_conformance.PATCH.md  — manual patch instructions
├── layer-3-drd-lockout/
│   └── README.md                       — explains what was written to repo
├── layer-4-knowledge-base/
│   ├── failure_signatures.yml          — copy to docs/operations/
│   ├── build_failure_index.sh          — copy to scripts/audit/
│   └── troubleshooting/
│       └── preci-db-environment.md     — copy to docs/troubleshooting/
└── layer-5-agent-context/
    └── prompt_template.md              — copy to .agent/
```
