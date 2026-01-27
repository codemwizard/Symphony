# Invariants Implementation & Verification Process

This document defines how Symphony enforces invariants (P0/P1 contracts) using a two-phase system:

1. **Mechanical enforcement** (CI + deterministic scripts): authoritative source of "implemented"
2. **AI/manual assistance** (Codex): secondary enforcement + helps author doc/manifest updates, always human-reviewed

Key rule: **If CI can't fail, the invariant is not implemented** (it remains roadmap).

## Repository locations

### Invariants documentation

* Registry (source of truth):
  `docs/invariants/Invariants_Manifest.yml` 
* Implemented narrative (human-readable):
  `docs/invariants/Invariants_Implemented.md` 
* Roadmap narrative (human-readable):
  `docs/invariants/Invariants_Roadmap.md` 
* Quick reference (generated; do not hand-edit):
  `docs/invariants/Invariants_Quick.md` 
* Exceptions (escape hatch; timeboxed):
  `docs/invariants/exceptions/exception_template.md` 

### Scripts

**Cheap / no-DB**

* `scripts/audit/…` 

**DB / requires Postgres**

* `scripts/db/…` 
* `schema/migrations/0001…0005…` 

## Source of truth and generation rules

### Source of truth

`docs/invariants/Invariants_Manifest.yml` is the **authoritative registry**. It contains:

* invariants that are **implemented** (mechanically provable)
* invariants that are **roadmap** (known requirements, not yet proven)

### Generated output

`docs/invariants/Invariants_Quick.md` is **generated from the manifest**, and must be treated as derived:

* It must only include `status: implemented` 
* It must be reproducible and deterministic
* CI must fail if generated output differs from committed `Invariants_Quick.md` 

### Why "roadmap" can exist in the manifest

Because the manifest is a **machine-readable registry**, not a machine-generated file. It's intentionally the place where you track:

* what exists and is enforced now (**implemented**), and
* what is planned but not yet enforced (**roadmap**)

The enforcement rule is:

* `implemented` invariants must have **real verification references** (lint/gate/test).
* if verification is missing or unproven, the invariant stays `roadmap`.

## Phase I — Mechanical enforcement (cheap gates)

This is the "fail fast" layer and should run on every PR before expensive DB checks.

### Fast checks wrapper (recommended)

**Script:** `scripts/audit/run_invariants_fast_checks.sh` 

This wrapper should run:

* shell syntax checks (`bash -n`) for audit scripts
* python compilation checks (`python3 -m py_compile`) for audit python
* detector unit tests (`scripts/audit/tests/...`)
* manifest validation (schema + uniqueness + required fields)
* docs ↔ manifest consistency (prevents drift)
* regenerate `Invariants_Quick.md` and fail if it changes
* validate exception templates if present

### Change rule gate (Rule 1)

**Script:** `scripts/audit/enforce_change_rule.sh` 

Goal: if a PR contains structural/security changes that likely impact invariants, then the PR must include either:

* updates to the manifest and/or docs (meaningful), OR
* a valid timeboxed exception

Meaningful doc update rule (recommended):

* doc diffs must include invariant IDs/aliases (ex: `INV-###` or approved alias tags), not blank-line churn.

### Promotion gate (Roadmap → Implemented)

**Script:** `scripts/audit/enforce_invariant_promotion.sh` 

Goal: prevent "paper promotion." Promotion is only allowed when:

* invariant is marked `status: implemented` 
* verification field is populated with real hooks (not TODO)
* required metadata exists (owners, severity, aliases, evidence links)

### Exception handling (escape hatch)

**Template:** `docs/invariants/exceptions/exception_template.md` 
**Validator script:** `scripts/audit/verify_exception_template.sh` 
**Optional helper:** `scripts/audit/record_invariants_exception.sh` 

Rules:

* exception must include expiry + follow-up ticket
* exception must be committed (audit trail)
* exception bypass should be visible/loud in CI output
* (recommended) scheduled workflow audits expired exceptions

## Phase II — DB verification (expensive, authoritative)

This phase runs only when needed (schema/migration/DB invariants touched) because it requires Postgres.

### DB verification entrypoint

**Script:** `scripts/db/verify_invariants.sh` 

This is the single authoritative DB verification command and typically runs:

* migrations: `scripts/db/migrate.sh` 
* lints:

  * `scripts/db/lint_migrations.sh` 
  * `scripts/db/lint_search_path.sh` 
* SQL gate:

  * `scripts/db/ci_invariant_gate.sql` 

**Rule:** implemented DB invariants must be provable by the above (CI fails if broken).

### Current implemented foundation scope: migrations 0001–0005

For this phase, the invariants should map to enforcement/verification in:

* `schema/migrations/0001…0005…` 
* `scripts/db/ci_invariant_gate.sql` 
* `scripts/db/lint_*` 
* role/privilege posture (no runtime DDL, hardened SECURITY DEFINER search_path, etc.)

## AI assistance (Codex) — how it is used safely

Codex is a **secondary enforcement and authoring assistant**. It must never be the authority.

### When Codex runs

Codex should run only if the detector says "likely invariant-affecting," e.g.:

* migration/DDL changes
* GRANT/REVOKE, role changes, SECURITY DEFINER changes
* invariant gates/lints modified

### What Codex is allowed to do

* propose or author updates **only** under:

  * `docs/invariants/` (manifest + narrative docs)
  * `docs/invariants/exceptions/` (exception proposal only)
* output a structured summary:

  * classification (true change / false positive / unclear)
  * confidence score
  * which invariants were affected (IDs + aliases)
  * recommended edits

### What Codex must never do

* edit `docs/invariants/Invariants_Quick.md` directly
* edit migrations, db scripts, code, CI gates, or bypass checks
* auto-merge

Human reviewers must approve anything Codex proposes.

## Script execution permissions (chmod)

### Must be executable (shell)

Run once (or ensure executable bit is committed):

```bash
chmod +x scripts/audit/*.sh scripts/db/*.sh
```

### Python scripts

Executable bit is optional if invoked via `python3 …`.
If you want direct execution:

```bash
chmod +x scripts/audit/*.py scripts/audit/generate_invariants_quick
```

## Local "before CI" checklist

### Always run (cheap)

```bash
scripts/audit/run_invariants_fast_checks.sh
scripts/audit/enforce_change_rule.sh
scripts/audit/enforce_invariant_promotion.sh
```

### Run when DB is available / relevant changes

```bash
scripts/db/verify_invariants.sh
```

## Developer workflow: adding and implementing an invariant

1. Add a new invariant entry to `docs/invariants/Invariants_Manifest.yml` 

   * start with `status: roadmap` 
   * include aliases (required)
   * include owner + severity
2. Write/update narrative in `Invariants_Roadmap.md` 
3. Implement enforcement (migrations/constraints/functions/roles/lints/etc)
4. Implement verification (CI gate/lint/test must fail if violated)
5. Promote in manifest to `status: implemented` only when step 4 is true
6. Ensure QUICK regenerates cleanly and matches committed file

## Notes on reducing CI cost

* Always run "cheap" checks first.
* Only run DB verification when detectors or paths indicate it's necessary.
* QUICK generation is cheap and should be required (drift prevention).

## CI execution contract: exact commands, conditionals, and artifacts

This repository uses a single GitHub Actions workflow: **`.github/workflows/invariants.yml`** (name: *Invariants (Mechanical + Codex + DB Verify)*). It runs in four modes:

* **pull_request** (main): full mechanical + optional Codex + DB verify
* **push** (main): mechanical + DB verify (Codex only runs on PRs)
* **schedule** (daily): exception audit only
* **workflow_dispatch**: exception audit only

All jobs run on `ubuntu-latest`.

### Job 1 — Phase I: Mechanical gates (`mechanical_invariants`)

**Conditionals**

* Skips most steps when `github.event_name == 'schedule'`.
* The "Rule 1" gate only runs when `structural_change == true` (detector output).

**Command lines CI runs (in order)**

1. **Checkout**

```bash
# actions/checkout@v4 with fetch-depth: 0
```

2. **Setup Python**

```bash
# actions/setup-python@v5 python-version: 3.11
```

3. **Unit tests for detector** (not on schedule)

```bash
python3 -m pip install --upgrade pip
python3 -m pip install pytest
pytest -q scripts/audit/tests/test_detect_structural_sql_changes.py
```

4. **Compute PR diff + structural detection** (not on schedule)
   Creates the canonical PR diff and runs the detector.

```bash
mkdir -p /tmp/invariants_ai

# PR:
RANGE="${{ github.event.pull_request.base.sha }}...${{ github.event.pull_request.head.sha }}"
# Push:
# RANGE="${{ github.event.before }}...${{ github.sha }}"

git diff --no-color --no-ext-diff --unified=0 "$RANGE" > /tmp/invariants_ai/pr.diff
python3 scripts/audit/detect_structural_changes.py \
  --diff-file /tmp/invariants_ai/pr.diff \
  --out /tmp/invariants_ai/detect.json
```

5. **Rule 1: enforce doc/manifest or exception**
   Only if `structural_change == 'true'` (and not schedule).

```bash
chmod +x scripts/audit/*.sh || true
BASE_REF="origin/main" HEAD_REF="HEAD" scripts/audit/enforce_change_rule.sh
```

6. **Promotion gate** (not on schedule)

```bash
chmod +x scripts/audit/enforce_invariant_promotion.sh
scripts/audit/enforce_invariant_promotion.sh
```

7. **Validate exception templates** (not on schedule)

```bash
chmod +x scripts/audit/verify_exception_template.sh
scripts/audit/verify_exception_template.sh
```

8. **Generate QUICK and ensure committed output matches** (not on schedule)

```bash
chmod +x scripts/audit/generate_invariants_quick
scripts/audit/generate_invariants_quick
git diff --exit-code docs/invariants/INVARIANTS_QUICK.md
```

**Artifacts produced by Job 1**
Uploaded as **`invariants-detector`**:

* `/tmp/invariants_ai/pr.diff` (unified diff used for detection + Codex)
* `/tmp/invariants_ai/detect.json` (detector output; includes `structural_change`, `confidence_hint`, matches, summary)

### Job 2 — Phase II: Codex authoring (`codex_invariants_review`)

**Why it runs**

* This job is *only* for **PRs**.
* It runs *only if* Job 1 detected a structural change.

**Conditional (the key part)**

```yaml
if: >
  github.event_name == 'pull_request' &&
  always() &&
  needs.mechanical_invariants.outputs.structural_change == 'true'
```

* `github.event_name == 'pull_request'`: Codex is not invoked on pushes to main.
* `always()`: run even if Job 1 had failures (so you still get Codex analysis + artifacts to help fix).
* `needs...structural_change == 'true'`: do not spend money/time on Codex unless a structural change was detected.

**Command lines CI runs**

1. **Checkout PR merge ref**

```bash
# actions/checkout@v5
# ref: refs/pull/<PR_NUMBER>/merge
```

2. **Fetch base + head refs**

```bash
git fetch --no-tags origin \
  ${{ github.event.pull_request.base.ref }} \
  +refs/pull/${{ github.event.pull_request.number }}/head
```

3. **Prepare diff for Codex**

```bash
mkdir -p /tmp/invariants_ai
git diff --no-color --no-ext-diff --unified=0 \
  "${{ github.event.pull_request.base.sha }}...${{ github.event.pull_request.head.sha }}" \
  > /tmp/invariants_ai/pr.diff
```

4. **Run Codex (GitHub Action)**

* Uses: `openai/codex-action@v1` 
* Prompt file: `.github/codex/prompts/invariants_review.md` 
* Output file: `/tmp/invariants_ai/codex_final_message.md` 

5. **Capture patch from workspace**

```bash
git diff > /tmp/invariants_ai/codex-invariants.patch || true
if [[ ! -s /tmp/invariants_ai/codex-invariants.patch ]]; then
  echo "No changes produced by Codex." > /tmp/invariants_ai/codex-invariants.patch
fi
```

6. **Upload Codex artifacts**
   Uploaded as **`codex-invariants-review`**:

* `/tmp/invariants_ai/pr.diff` 
* `/tmp/invariants_ai/codex_final_message.md` 
* `/tmp/invariants_ai/ai_confidence.json` *(required by prompt contract)*
* `/tmp/invariants_ai/codex_summary.md` *(required by prompt contract)*
* `/tmp/invariants_ai/codex-invariants.patch` 

7. **Comment on PR**

* Posts:

  * classification
  * confidence
  * invariant IDs list
  * rationale
  * recommended_action
  * includes the start of `codex_summary.md` 
* Also points reviewers to the `codex-invariants-review` artifact.

**Expected Codex outputs (contract)**
Your prompt requires Codex to write these files in `/tmp/invariants_ai/`:

* `ai_confidence.json` with keys:

  * `classification`, `confidence`, `invariants[]`, `rationale`, `recommended_action` 
* `codex_summary.md` describing what it saw and what it recommends/changed
* Optional:

  * `ai_patch_meta.json` (if Codex authored changes)

### Job 3 — DB invariant verification (`db_verify_invariants`)

**Why it runs**

* Runs on PRs and pushes (not on schedule).
* Uses a Postgres service container and runs your DB verification entrypoint.

**Conditional**

```yaml
if: always() && github.event_name != 'schedule'
```

* `always()`: still runs even if mechanical gates failed (useful to diagnose real DB failures vs doc gating failures).
* Not on schedule: scheduled runs are reserved for exception audit.

**Command lines CI runs**

1. **Bring up Postgres 18 service** (GitHub Actions `services:`)

2. **Wait for Postgres**

```bash
for i in {1..60}; do
  if pg_isready -h localhost -p 5432 -U symphony -d symphony; then exit 0; fi
  sleep 2
done
exit 1
```

3. **Run DB verify entrypoint**

```bash
chmod +x scripts/db/verify_invariants.sh
DATABASE_URL=postgres://symphony:symphony@localhost:5432/symphony \
SKIP_POLICY_SEED="1" \
scripts/db/verify_invariants.sh
```

**Artifacts**

* This job doesn't currently upload artifacts by default.
* If you want cheap diagnostics, the usual improvement is to tee logs into `/tmp/invariants_ai/db_verify.log` and upload as an artifact on failure.

### Job 4 — Scheduled exception audit (`exception_audit`)

**When it runs**

* Only on `schedule` (daily) or manual `workflow_dispatch`.

**Command lines CI runs**

```bash
chmod +x scripts/audit/verify_exception_template.sh
scripts/audit/verify_exception_template.sh

chmod +x scripts/audit/record_invariants_exception.sh
scripts/audit/record_invariants_exception.sh
```

**Artifacts**

* Not currently uploading artifacts.
* If `record_invariants_exception.sh` produces a report file, you can upload it (recommended) so the audit has an auditable output trail.

## Summary: artifact names you should expect in a PR run

### `invariants-detector` (always on PR/push, even if later steps fail)

* `pr.diff` 
* `detect.json` 

### `codex-invariants-review` (only on PRs AND only when structural change detected)

* `pr.diff` 
* `codex_final_message.md` 
* `ai_confidence.json` 
* `codex_summary.md` 
* `codex-invariants.patch`
