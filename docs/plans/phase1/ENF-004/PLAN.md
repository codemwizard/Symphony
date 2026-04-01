# PLAN: ENF-004 — Update AGENT_ENTRYPOINT.md and prompt_template.md

Status: planned
Phase: 1
Task: ENF-004
Agent: ARCHITECT

---

## Mission

Replace `AGENT_ENTRYPOINT.md` and `.agent/prompt_template.md` with the
versions from the staging package that reference:
- `verify_drd_casefile.sh --clear` instead of raw rm
- The evidence ack gate (exit 51) and retry hard-block (exit 50)
- The rule: never use raw rm to clear lockout or evidence gate files

---

## Constraints

- Apply only after ENF-002 and ENF-003A evidence both show PASS.
- This is a file replacement — no patch script. Use `cp` directly.
- Do not edit the staging files before copying.
- Do not touch any script in `scripts/audit/` or `scripts/agent/`.

---

## Prerequisites

- ENF-002 evidence shows PASS (`verify_drd_casefile.sh` installed and patch applied).
- ENF-003A evidence shows PASS (evidence ack gate in `run_task.sh`).

---

## Step 1 — Confirm prerequisites

```bash
test -f evidence/phase1/enf_002_verify_drd_casefile.json && \
  python3 -c "import json; d=json.load(open('evidence/phase1/enf_002_verify_drd_casefile.json')); assert d['status']=='PASS'" && \
  echo "ENF-002 PASS confirmed"

test -f evidence/phase1/enf_003a_run_task_evidence_ack_gate.json && \
  python3 -c "import json; d=json.load(open('evidence/phase1/enf_003a_run_task_evidence_ack_gate.json')); assert d['status']=='PASS'" && \
  echo "ENF-003A PASS confirmed"
```

---

## Step 2 — Replace AGENT_ENTRYPOINT.md

```bash
cp symphony-enforcement-v2/enf-004-agent-entrypoint-docs/AGENT_ENTRYPOINT.md \
   AGENT_ENTRYPOINT.md
```

---

## Step 3 — Replace prompt_template.md

```bash
cp symphony-enforcement-v2/enf-004-agent-entrypoint-docs/prompt_template.md \
   .agent/prompt_template.md
```

---

## Step 4 — Confirm content

```bash
grep 'evidence_ack' AGENT_ENTRYPOINT.md
grep 'verify_drd_casefile.sh --clear' AGENT_ENTRYPOINT.md
grep 'evidence_ack' .agent/prompt_template.md
grep 'verify_drd_casefile.sh --clear' .agent/prompt_template.md
```

All four greps must return matches.

---

## Step 5 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_004.sh` that runs all four grep checks
and emits `evidence/phase1/enf_004_agent_entrypoint_docs.json`.

```bash
bash scripts/audit/verify_enf_004.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_004.sh
python3 scripts/audit/validate_evidence.py --task ENF-004 --evidence evidence/phase1/enf_004_agent_entrypoint_docs.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_004_agent_entrypoint_docs.json`

---

## Approval references

`AGENT_ENTRYPOINT.md` and `.agent/prompt_template.md` are in the Architect
allowed path. Standard Architect approval applies. No governance scripts are
modified by this task.
