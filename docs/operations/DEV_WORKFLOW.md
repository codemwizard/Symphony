# Developer Workflow (Phase 1 → Phase 2)

This repo uses **mechanical gates first** and treats invariants as “real” only when backed by:
- **enforcement** (constraints/triggers/functions/scripts), and
- **verification** (CI gate/tests/lints).

Your job as a developer is to keep changes **cheap** by catching “structural” issues **before push**.

---

## Quick start (local)

### Prereqs
- Docker (or compatible container runtime)
- `bash`, `python3`, `psql`
- Git

### One command
From repo root:

```bash
scripts/dev/pre_ci.sh
```

This should:
1) start Postgres via compose (dev only)
2) run **fast invariants** checks (no DB)
3) run **fast security** checks (no DB)
4) run DB function tests (and any extra DB tests you wire in)

If this is green, your PR should be green on the first CI run.

---

## Normal development loop

1) Make your changes
2) Run fast checks locally:
   ```bash
   scripts/dev/pre_ci.sh
   ```
3) Commit + push + open PR

---

## When your change is “structural”

A change is considered **structural / invariant-affecting** when it touches things like:
- migrations / DDL / constraints / triggers
- roles, grants, revoke posture
- SECURITY DEFINER patterns / search_path hardening
- “boot critical” schema objects (tables/columns/functions referenced at startup)

The detector is:
- `scripts/audit/detect_structural_changes.py`

### Expected rule
If a structural change is detected, you must ship **one** of:
1) Update `docs/invariants/INVARIANTS_MANIFEST.yml` and relevant docs (include `INV-###` token), **or**
2) Add a timeboxed exception file under `docs/invariants/exceptions/`

This is enforced by:
- `scripts/audit/enforce_change_rule.sh` (CI gate and/or local gate)

---

## Shift-left: run the Invariants Curator before you push (recommended)

### Step 1 — prepare agent inputs (staged diff + detector output)
Stage your changes:

```bash
git add -A
```

Then run:

```bash
scripts/audit/prepare_invariants_curator_inputs.sh
```

This writes:
- `/tmp/invariants_ai/pr.diff`  (your staged diff)
- `/tmp/invariants_ai/detect.json` (what triggered “structural”)

### Step 2 — run the Curator agent in Cursor
In Cursor:
1) Open `.cursor/agents/invariants_curator.md`
2) Run it as an agent prompt
3) Let it propose a patch limited to `docs/invariants/**`

### Step 3 — verify docs are coherent
```bash
scripts/audit/run_invariants_fast_checks.sh
```

This ensures:
- Manifest validates
- Docs ↔ Manifest match
- QUICK regenerated matches generator output

### Step 4 — commit the docs/exception with the code change
```bash
git add docs/invariants
git commit -m "Docs: update invariants for <change>"
git push
```

---

## Exception workflow (when the right invariant work is not ready yet)

Create an exception file under:
`docs/invariants/exceptions/exception_<INV-ID>_<YYYY-MM-DD>.md`

Rules:
- Must have an **expiry date**
- Must have a **follow_up_ticket**
- Must explain why the exception is needed and mitigation in place

Then push it with the code change so CI passes in one run.

---

## Troubleshooting

### CI says “Change rule violated”
Meaning: detector flagged your diff as structural, but you didn’t include:
- manifest/docs updates with `INV-###`, or
- an exception file

Fix: run the Curator flow above and push once.

### Postgres container fails to start (PG 18+)
If you see logs mentioning Postgres 18+ data layout, use the compose file under `infra/docker/` and ensure the volume is mounted at `/var/lib/postgresql` (not `/var/lib/postgresql/data`). Then:

```bash
cd infra/docker
docker compose down -v
docker compose up -d
```

---

## What “done” looks like
- `scripts/dev/pre_ci.sh` passes locally
- PR CI passes on first run
- Structural changes always include docs/exception in the same PR
