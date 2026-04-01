# Symphony Enforcement Package v2 — Implementation Plan

Status: planned
Phase: 1
Author: ARCHITECT

---

## Mission

Apply the five enforcement upgrades from `symphony-enforcement-v2/` to harden
the agent toolchain against two recurring failure modes:

1. Agents retrying without reading their failure artifacts → solved by ENF-003A + ENF-003B
2. Lockout cleared with raw `rm` instead of a verified casefile → solved by ENF-001 + ENF-002

All staging artefacts are in `symphony-enforcement-v2/`. Every apply script is
idempotent. Each task produces verifier-backed evidence before it is marked done.

---

## Source staging directory

```
symphony-enforcement-v2/
  MANIFEST.md
  gitattributes/.gitattributes
  enf-001-run-task-drd-gate/apply.sh
  enf-002-verify-drd-casefile/verify_drd_casefile.sh
  enf-002-verify-drd-casefile/apply_patch.sh
  enf-003-evidence-ack-gate/apply_patch.sh
  enf-003-evidence-ack-gate/reset_evidence_gate.sh
  enf-004-agent-entrypoint-docs/AGENT_ENTRYPOINT.md
  enf-004-agent-entrypoint-docs/prompt_template.md
```

---

## Task decomposition

The MANIFEST defines ENF-000 through ENF-004. ENF-003 from the MANIFEST is
split into ENF-003A and ENF-003B here because the two deliverables belong to
different agent surfaces: `scripts/agent/run_task.sh` (Architect) and
`scripts/audit/reset_evidence_gate.sh` (Security Guardian). Per
`docs/operations/TASK_CREATION_PROCESS.md` §3: touches spanning multiple
agent surfaces must be separate tasks.

| Task | Agent | Governance file? | Source |
|---|---|---|---|
| ENF-000 | ARCHITECT | No | gitattributes/.gitattributes |
| ENF-001 | ARCHITECT | Yes — run_task.sh | enf-001-run-task-drd-gate/apply.sh |
| ENF-002 | SECURITY_GUARDIAN | No | enf-002-verify-drd-casefile/* |
| ENF-003A | ARCHITECT | Yes — run_task.sh | enf-003-evidence-ack-gate/apply_patch.sh |
| ENF-003B | SECURITY_GUARDIAN | No | enf-003-evidence-ack-gate/reset_evidence_gate.sh |
| ENF-004 | ARCHITECT | No | enf-004-agent-entrypoint-docs/* |

---

## DAG

```
ENF-000 ──────────────────────────────────────────────────────┐
ENF-001 ─────────────────────────────┬──────────────────────┐ │
ENF-002 ────────────────┬────────────┼──────────────────── ENF-004
ENF-003A (needs ENF-001)┘            │                       │
ENF-003B (independent)───────────────┘                       │
                                                              └─ all parallel to ENF-004
```

Simplified serial-safe execution order: ENF-000 → ENF-001 → ENF-002 → ENF-003A → ENF-003B → ENF-004

ENF-004 must come last because AGENT_ENTRYPOINT.md and prompt_template.md reference
`verify_drd_casefile.sh --clear` (created by ENF-002) and the evidence_ack gate
(created by ENF-003A).

---

## Approval note for governance files

`scripts/agent/run_task.sh` is listed in the SYSTEM INVARIANTS as a governance
file. ENF-001 and ENF-003A modify it. Both tasks require explicit human approval
before implementation starts. Apply scripts are idempotent and use Python-based
insertion with an anchor check — they will skip if already applied.

---

## Verification sequence (after all tasks applied)

```bash
# ENF-000
bash scripts/audit/verify_enf_000.sh

# ENF-001
bash scripts/audit/verify_enf_001.sh

# ENF-002
bash scripts/audit/verify_enf_002.sh

# ENF-003A
bash scripts/audit/verify_enf_003a.sh

# ENF-003B
bash scripts/audit/verify_enf_003b.sh

# ENF-004
bash scripts/audit/verify_enf_004.sh

# Full gate
bash scripts/dev/pre_ci.sh
```

---

## Constraints

- Apply scripts must be run from repo root.
- ENF-003A apply_patch.sh checks that ENF-001 is already applied — run in order.
- Do not apply any task on `main`. Work on feature branch `task/ENF-ENFORCEMENT-V2`.
- Evidence artifacts must be emitted before any task is marked completed.
