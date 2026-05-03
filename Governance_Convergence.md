Let me read all the reference files first, then the uploaded document.Now let me read the TSK-P1-240 reference task and the uploaded implementation plan:Now let me read the uploaded implementation plan:Now I have all the context I need. Let me read the uploaded implementation plan:Let me also read the truncated middle section:I now have a complete picture of everything. Let me synthesize the corrected implementation plan and all task packs inline.

---

# Governance Convergence Implementation Plan (Corrected + Final)

## Corrections Applied (from end-of-document review)

Three hard corrections have been applied to the original plan before generating tasks:

1. **Track 1 renamed**: "Evidence audit" → **"Phase-2 Constitutional Reconciliation"** — the work happened; the problem is contract admissibility, not discovery.
2. **Track 4 renamed**: "Phase-2 Opening" → **"Phase-2 Constitutional Ratification"** — execution preceded governance; the artifact is retroactive normalization, not a normal phase opening.
3. **Track 5 strengthened**: Claim admissibility script must enforce **semantic admissibility** (capability laundering, future-phase language in present-phase tasks, "Phase complete" overclaims), not just numeric phase validity.

---

## Corrected Tracks Summary

| Track | Corrected Title | Prerequisite |
|-------|----------------|-------------|
| 1 | Phase-2 Constitutional Reconciliation | None (discovery read-only then writes) |
| 2 | Phase-2 Contract Verifier Script | Track 1 complete |
| 3 | Phase-2 Human Contract + Policy Guard | Track 1 complete (can parallel Track 2) |
| 4 | Phase-2 Constitutional Ratification Artifact | Tracks 1, 2, 3 complete |
| 5 | Claim Admissibility Enforcement (Semantic) | Independent — start immediately |
| 6 | Phase-3 / Phase-4 Non-Claimable Scaffolding | Independent — start immediately |

---

## Task Decomposition

Following TASK_CREATION_PROCESS.md mandatory 7-step sequence, TSK-P1-240 pattern, WAVE5 lessons learned, and TASK_AUTHORING_STANDARD_v2 quality bars. Each task has exactly **one primary objective**, explicit anti-drift boundaries, ID-tagged work items and acceptance criteria, negative tests, and proof guarantees/limitations.

**Phase key used:** `'2'` (all tasks are Phase-2 governance work)  
**Task ID series:** `TSK-P2-GOV-CONV-001` through `TSK-P2-GOV-CONV-010`

---

# TASK 1 of 10

## `tasks/TSK-P2-GOV-CONV-001/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-001
title: >-
  Map all executed Phase-2 evidence files and task meta.yml records to invariant
  IDs and produce a reconciliation manifest
owner_role: INVARIANTS_CURATOR
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  The phase2_contract.yml has 12 rows while the repo contains ~90 executed Phase-2
  evidence files spanning waves 3–8. The contract and execution are completely
  disconnected. Before any contract row can be written or any verifier script can
  run, a complete and authoritative mapping must exist that enumerates every executed
  Phase-2 task, its evidence file path, its verifier script path, and the INV ID
  it should carry. This task produces that mapping as a single structured artifact.
  It does not write to any governance file — it only reads and maps.

anti_patterns:
  - >-
    Reading only evidence/phase2/ without cross-referencing tasks/TSK-P2-*/meta.yml —
    evidence files may exist for tasks whose meta.yml records a different scope.
  - >-
    Assigning INV IDs in this task — ID assignment is Track 1 Step 2 (TSK-P2-GOV-CONV-002).
    This task only maps what exists and flags what is missing.
  - >-
    Writing any contract row, policy doc, or verifier script — this task is read-only
    except for the reconciliation manifest output file.

out_of_scope:
  - Assigning or registering INV IDs in INVARIANTS_MANIFEST.yml
  - Writing or modifying phase2_contract.yml
  - Creating any verifier script
  - Patching any task meta.yml
  - Any write to docs/PHASE2/, docs/operations/, or docs/invariants/

stop_conditions:
  - >-
    STOP if any task meta.yml in tasks/TSK-P2-*/ cannot be read — log the unreadable
    path and continue; do not skip the file silently.
  - >-
    STOP if the output manifest has fewer than 80 rows — this signals a scan failure,
    not an absence of work.
  - >-
    STOP if any evidence file referenced in a meta.yml does not exist on disk — record
    as status: evidence_missing in the manifest row, do not silently omit.

proof_guarantees:
  - >-
    The reconciliation manifest at evidence/phase2/gov_conv_001_reconciliation_manifest.json
    enumerates every task whose task_id matches TSK-P2-* found in tasks/.
  - >-
    Every manifest row records: task_id, evidence_paths (declared in meta.yml),
    evidence_exists (boolean per path), verifier_paths (declared in verification field),
    verifier_exists (boolean per path), assigned_inv_ids (from meta.yml invariants field).
  - >-
    The verification script exits non-zero if the manifest row count is below the
    minimum threshold.

proof_limitations:
  - >-
    Does not validate evidence file schema — only checks file existence.
  - >-
    Does not validate verifier script correctness — only checks file existence.
  - >-
    Does not determine which INV IDs are correct — only records what is declared
    in each meta.yml.
  - >-
    Manual review of the manifest is required before TSK-P2-GOV-CONV-002 can proceed.

depends_on:
  - TSK-P2-PREAUTH-007-19
blocks:
  - TSK-P2-GOV-CONV-002

touches:
  - scripts/audit/verify_gov_conv_001.sh
  - evidence/phase2/gov_conv_001_reconciliation_manifest.json
  - tasks/TSK-P2-GOV-CONV-001/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-001/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-001/EXEC_LOG.md

deliverable_files:
  - scripts/audit/verify_gov_conv_001.sh
  - evidence/phase2/gov_conv_001_reconciliation_manifest.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-001/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-001/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-001

work:
  - >-
    [ID gov_conv_001_w01] Write scripts/audit/verify_gov_conv_001.sh: scan all
    tasks/TSK-P2-*/meta.yml files, for each record task_id, declared evidence paths,
    declared verifier paths, declared invariants field values; check file existence
    for each declared path; write the structured result to
    evidence/phase2/gov_conv_001_reconciliation_manifest.json and exit non-zero if
    row count < 80 or if any required field is missing from a manifest row.
  - >-
    [ID gov_conv_001_w02] Run the script against the live repo and confirm the
    manifest is produced with the correct minimum row count. Record the command run
    and the row count in EXEC_LOG.md.
  - >-
    [ID gov_conv_001_w03] Manually inspect the manifest for any task cluster
    (PREAUTH-005, PREAUTH-006, PREAUTH-007, REG, SEC, W5-fix, W6-rem, W8) and
    confirm no cluster is entirely absent. Log the cluster check result in
    EXEC_LOG.md.
  - >-
    [ID gov_conv_001_w04] Annotate the manifest with a summary_counts section:
    total_tasks, evidence_complete (all paths exist), evidence_partial (some missing),
    evidence_absent (all missing), verifier_complete, verifier_partial, verifier_absent,
    inv_id_present (meta.yml invariants field non-empty), inv_id_absent.

acceptance_criteria:
  - >-
    [ID gov_conv_001_w01] scripts/audit/verify_gov_conv_001.sh exists, is executable,
    uses DATABASE_URL for any db calls (none expected here), exits 0 on success
    and non-zero when row count < 80.
  - >-
    [ID gov_conv_001_w02] evidence/phase2/gov_conv_001_reconciliation_manifest.json
    exists and contains at minimum 80 rows with all required fields per row.
  - >-
    [ID gov_conv_001_w03] EXEC_LOG.md records the cluster check and confirms no
    cluster is entirely absent from the manifest.
  - >-
    [ID gov_conv_001_w04] Manifest contains a summary_counts section with all
    six count fields populated with non-negative integers.

negative_tests:
  - id: TSK-P2-GOV-CONV-001-N1
    description: >-
      Run verify_gov_conv_001.sh against a fixture directory containing only 5
      mock TSK-P2-* task directories. The script must exit non-zero because row
      count is below the 80-row minimum threshold. This proves the script enforces
      the minimum and cannot be silently satisfied by a partial scan.
    required: true
  - id: TSK-P2-GOV-CONV-001-N2
    description: >-
      Introduce a mock task meta.yml that declares an evidence path that does not
      exist. The manifest row for that task must record evidence_exists: false for
      that path. The script must not skip the path or mark it true.
    required: true

verification:
  - >-
    # [ID gov_conv_001_w01] [ID gov_conv_001_w02] [ID gov_conv_001_w03] [ID gov_conv_001_w04]
    bash scripts/audit/verify_gov_conv_001.sh > evidence/phase2/gov_conv_001_reconciliation_manifest.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-001
    --evidence evidence/phase2/gov_conv_001_reconciliation_manifest.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_001_reconciliation_manifest.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - rows
      - summary_counts
      - total_tasks
      - evidence_complete
      - verifier_complete
      - inv_id_absent

failure_modes:
  - >-
    Script scans evidence/phase2/ directory instead of tasks/TSK-P2-*/meta.yml
    as the source of truth — manifest will miss tasks whose evidence files are
    absent => CRITICAL_FAIL
  - >-
    Row count threshold not enforced — a partial scan producing 10 rows exits 0
    and is accepted as complete => CRITICAL_FAIL
  - >-
    Evidence file missing from output => FAIL
  - >-
    summary_counts absent from manifest — downstream tasks cannot determine
    scope of remediation needed => FAIL
  - >-
    Script connects to DB without using DATABASE_URL => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md
  - docs/invariants/INVARIANTS_MANIFEST.yml

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-001/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-001/EXEC_LOG.md
notes: >-
  This is a read-only discovery task. The only file it writes to the repo is the
  reconciliation manifest under evidence/phase2/ and the verifier script under
  scripts/audit/. It does not touch any governance document. It is the prerequisite
  for all subsequent Track 1 tasks. The 80-row minimum is a conservative lower bound
  based on the ~90 evidence files observed; lower values signal a scan defect.
client: codex_cli
assigned_agent: invariants_curator
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-001/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-001
# Phase-2 Constitutional Reconciliation: Evidence & Task Scan

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-001.SCAN_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Produce a complete reconciliation manifest that enumerates every TSK-P2-* task,
its evidence file existence status, its verifier script existence status, and the
INV IDs declared in its meta.yml. This manifest is the authoritative input for
INV ID assignment (TSK-P2-GOV-CONV-002) and contract rewriting (TSK-P2-GOV-CONV-003).

Done when: evidence/phase2/gov_conv_001_reconciliation_manifest.json exists with
>=80 rows, all required fields per row, summary_counts populated, and both negative
tests pass.

## Architectural Context

phase2_contract.yml was written early in Phase-2 planning and was never updated as
execution progressed through Waves 3–8. The contract has 12 rows; the repo has ~90
Phase-2 evidence files. Before any contract row can be authoritatively written,
a precise map of what actually executed must exist. This task creates that map by
reading task meta.yml files as the source of truth, not evidence files (which may
be absent even when the task executed and declared them).

## Pre-conditions

- tasks/TSK-P2-*/ directories are readable
- scripts/audit/ directory exists and is writable
- evidence/phase2/ directory exists and is writable
- DATABASE_URL is set (for pre_ci.sh; not needed by the scan script itself)

## Files to Change

- scripts/audit/verify_gov_conv_001.sh (CREATE)
- evidence/phase2/gov_conv_001_reconciliation_manifest.json (EMIT via script)

## out_of_scope

- Assigning INV IDs
- Writing to phase2_contract.yml
- Modifying any task meta.yml
- Any write to docs/PHASE2/, docs/operations/, docs/invariants/

## stop_conditions

- Row count in manifest < 80 => STOP, diagnose scan defect
- Any required manifest row field absent => STOP
- Script exits non-zero on legitimate full scan => STOP

## proof_guarantees

- Manifest enumerates every TSK-P2-* task found in tasks/
- Every row records evidence_exists and verifier_exists boolean per declared path
- Script exits non-zero when row count < 80

## proof_limitations

- Does not validate evidence file schema content
- Does not validate verifier correctness
- Does not assign or confirm correct INV IDs

## Implementation Steps

### Step 1 — Write verify_gov_conv_001.sh [ID gov_conv_001_w01]

What: Create scripts/audit/verify_gov_conv_001.sh
How:
  - Use `find tasks/ -name "meta.yml" -path "*/TSK-P2-*/meta.yml"` to enumerate
  - For each meta.yml, parse with yq or python3 yaml to extract:
      task_id, evidence (paths), verification (commands), invariants
  - For each declared evidence path: test -f <path> => evidence_exists true/false
  - For each declared verification command: extract script paths; test -f <path>
  - Build JSON row per task
  - Compute summary_counts
  - Write full JSON to stdout (caller redirects to manifest file)
  - Exit non-zero if row_count < 80
Done when: Script file exists, is executable, exits 0 on full scan, exits 1 on
fixture with 5 tasks.

### Step 2 — Run script and validate output [ID gov_conv_001_w02]

What: Execute the script against the live repo
How:
  bash scripts/audit/verify_gov_conv_001.sh > evidence/phase2/gov_conv_001_reconciliation_manifest.json
Done when: File exists with correct structure; row count >= 80. Record in EXEC_LOG.md.

### Step 3 — Cluster check [ID gov_conv_001_w03]

What: Manually confirm no task cluster is entirely absent
How: grep the manifest for at least one row per cluster: PREAUTH-005, PREAUTH-006,
PREAUTH-007, REG, SEC, W5, W6, W8
Done when: All clusters represented; logged in EXEC_LOG.md.

### Step 4 — Annotate summary_counts [ID gov_conv_001_w04]

What: Confirm summary_counts section is correct and complete
How: Inspect manifest JSON; counts must be non-negative integers; no placeholder
values.
Done when: All six count fields are integers; logged in EXEC_LOG.md.

## Verification

```bash
bash scripts/audit/verify_gov_conv_001.sh > evidence/phase2/gov_conv_001_reconciliation_manifest.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-001 --evidence evidence/phase2/gov_conv_001_reconciliation_manifest.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

evidence/phase2/gov_conv_001_reconciliation_manifest.json must include:
task_id, git_sha, timestamp_utc, status, checks, rows (array), summary_counts,
total_tasks, evidence_complete, verifier_complete, inv_id_absent

## Rollback

Delete evidence/phase2/gov_conv_001_reconciliation_manifest.json and
scripts/audit/verify_gov_conv_001.sh. No governance documents are modified by
this task; rollback has no contract impact.

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| yq not available in environment | Script fails to parse YAML | Use python3 -c "import yaml" as fallback parser |
| tasks/TSK-P2-*/ has unexpected subdirectory structure | Find command misses files | Use -maxdepth 3 and test with known task IDs |
| Row count just under 80 due to naming variance | False negative | Set threshold via env var MIN_ROWS=80 with override documented |
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-001/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-001
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-001.SCAN_FAIL
origin_task_id: TSK-P2-GOV-CONV-001

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 2 of 10

## `tasks/TSK-P2-GOV-CONV-002/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-002
title: >-
  Register new INV IDs (INV-159 onward) in INVARIANTS_MANIFEST.yml for all
  executed Phase-2 task clusters not yet carrying invariant IDs
owner_role: INVARIANTS_CURATOR
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  The reconciliation manifest produced by TSK-P2-GOV-CONV-001 identifies which
  TSK-P2 task clusters do not yet have invariant IDs registered in
  INVARIANTS_MANIFEST.yml. The Phase-2 contract requires every contract row to
  carry a real INV ID. This task registers the missing IDs starting from INV-159,
  covering the PREAUTH-005 series, PREAUTH-006A/B/C series, PREAUTH-007 series,
  REG series, SEC series, W5-fix, W6-rem, and W8 arch/db/sec/qa clusters. INV IDs
  must be registered before phase2_contract.yml can be authoritatively rewritten.

anti_patterns:
  - >-
    Inventing INV IDs without consulting the manifest from TSK-P2-GOV-CONV-001 —
    IDs must be grounded in actual executed work, not assumed work.
  - >-
    Registering IDs with vague invariant names (e.g., "Phase-2 work complete") —
    each ID must name a specific, mechanically verifiable behavioral guarantee.
  - >-
    Modifying phase2_contract.yml in this task — contract rewriting is TSK-P2-GOV-CONV-003.

out_of_scope:
  - Writing or modifying phase2_contract.yml
  - Creating any verifier script
  - Patching any task meta.yml
  - Registering Phase-3 or Phase-4 invariants

stop_conditions:
  - >-
    STOP if the reconciliation manifest from TSK-P2-GOV-CONV-001 does not exist —
    do not invent INV IDs without the manifest as ground truth.
  - >-
    STOP if any proposed INV ID conflicts with an existing entry in
    INVARIANTS_MANIFEST.yml — check for gaps before assigning.
  - >-
    STOP if an invariant description cannot name a specific verifier script path —
    a roadmap entry is acceptable only if explicitly marked status: roadmap.

proof_guarantees:
  - >-
    INVARIANTS_MANIFEST.yml contains a new entry for every Phase-2 task cluster
    identified as inv_id_absent in the gov_conv_001 manifest.
  - >-
    Every new entry carries a non-empty description, a status (implemented or roadmap),
    and a verifier path (or explicit roadmap marker if no verifier exists).
  - >-
    The verification script confirms IDs INV-159 onward are syntactically present
    in the manifest file.

proof_limitations:
  - >-
    Does not validate that verifier scripts at declared paths actually function
    correctly — existence check only.
  - >-
    Does not guarantee the verifier scripts were ever run — that is the evidence
    check in TSK-P2-GOV-CONV-003.

depends_on:
  - TSK-P2-GOV-CONV-001
blocks:
  - TSK-P2-GOV-CONV-003

touches:
  - docs/invariants/INVARIANTS_MANIFEST.yml
  - scripts/audit/verify_gov_conv_002.sh
  - evidence/phase2/gov_conv_002_inv_registration.json
  - tasks/TSK-P2-GOV-CONV-002/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-002/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-002/EXEC_LOG.md

deliverable_files:
  - scripts/audit/verify_gov_conv_002.sh
  - evidence/phase2/gov_conv_002_inv_registration.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-002/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-002/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-002

work:
  - >-
    [ID gov_conv_002_w01] Read evidence/phase2/gov_conv_001_reconciliation_manifest.json
    and extract all rows where inv_id_absent is true. Group by task cluster
    (PREAUTH-005, 006, 007, REG, SEC, W5, W6, W8). Log cluster grouping in EXEC_LOG.md.
  - >-
    [ID gov_conv_002_w02] For each cluster, draft a single INV ID entry with:
    invariant_id (INV-159 onward, sequential), cluster name, behavioral description
    (what guarantee does this cluster provide at the system level), status
    (implemented if verifier exists, roadmap if not), verifier path (if exists).
    Append all entries to docs/invariants/INVARIANTS_MANIFEST.yml.
  - >-
    [ID gov_conv_002_w03] Write scripts/audit/verify_gov_conv_002.sh that reads
    INVARIANTS_MANIFEST.yml and confirms all INV IDs from INV-159 onward are
    present as valid entries with non-empty description fields. Exits non-zero
    if any expected ID is missing or has an empty description.
  - >-
    [ID gov_conv_002_w04] Run verify_gov_conv_002.sh and emit
    evidence/phase2/gov_conv_002_inv_registration.json recording: ids_registered,
    ids_implemented, ids_roadmap, manifest_path, git_sha.

acceptance_criteria:
  - >-
    [ID gov_conv_002_w01] EXEC_LOG.md records the cluster grouping with at least
    6 distinct clusters identified (PREAUTH-005/006/007, REG, SEC, W8 minimum).
  - >-
    [ID gov_conv_002_w02] INVARIANTS_MANIFEST.yml contains at least 6 new INV ID
    entries starting from INV-159, each with a non-empty behavioral description
    and a declared status.
  - >-
    [ID gov_conv_002_w03] verify_gov_conv_002.sh exists, is executable, and exits
    non-zero when a known expected ID is removed from the manifest in a test fixture.
  - >-
    [ID gov_conv_002_w04] evidence/phase2/gov_conv_002_inv_registration.json exists
    with ids_registered >= 6 and all required fields.

negative_tests:
  - id: TSK-P2-GOV-CONV-002-N1
    description: >-
      Remove one newly registered INV ID from a fixture copy of INVARIANTS_MANIFEST.yml
      and run verify_gov_conv_002.sh against it. The script must exit non-zero.
      This proves the verifier detects missing IDs and cannot be silently satisfied
      by a partial manifest.
    required: true
  - id: TSK-P2-GOV-CONV-002-N2
    description: >-
      Attempt to register an INV ID with an empty description field.
      verify_gov_conv_002.sh must exit non-zero on a manifest containing an entry
      with description: "". This proves the quality bar on description content
      is enforced mechanically, not by convention.
    required: true

verification:
  - >-
    # [ID gov_conv_002_w03] [ID gov_conv_002_w04]
    bash scripts/audit/verify_gov_conv_002.sh > evidence/phase2/gov_conv_002_inv_registration.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-002
    --evidence evidence/phase2/gov_conv_002_inv_registration.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_002_inv_registration.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - ids_registered
      - ids_implemented
      - ids_roadmap
      - manifest_path

failure_modes:
  - >-
    INV IDs registered without reading gov_conv_001 manifest — IDs may not
    correspond to actual executed work => CRITICAL_FAIL
  - >-
    ID assigned with empty or vague description ("Phase-2 work") — contract row
    cannot reference a non-specific invariant => FAIL
  - >-
    verify_gov_conv_002.sh exits 0 on a fixture with fewer IDs than registered —
    fake PASS pattern => CRITICAL_FAIL
  - >-
    Evidence file missing => FAIL
  - >-
    phase2_contract.yml modified in this task => BLOCKED (out of scope)

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - docs/invariants/INVARIANTS_MANIFEST.yml
  - evidence/phase2/gov_conv_001_reconciliation_manifest.json

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-002/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-002/EXEC_LOG.md
notes: >-
  INV ID numbering starts at INV-159. INV-156/157/158 already exist for ledger
  internals. Do not renumber existing IDs. Use sequential assignment within this
  task only. The exact number of new IDs depends on the cluster count in the
  gov_conv_001 manifest. The minimum of 6 in acceptance criteria is a floor, not
  a ceiling.
client: codex_cli
assigned_agent: invariants_curator
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-002/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-002
# Phase-2 Constitutional Reconciliation: INV ID Registration

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-002.INV_REGISTRATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Register INV IDs INV-159 onward in INVARIANTS_MANIFEST.yml for every Phase-2
task cluster identified as missing invariant IDs in the TSK-P2-GOV-CONV-001
manifest. Done when: >=6 new INV entries exist with non-empty behavioral descriptions,
verify_gov_conv_002.sh exists and passes, and evidence JSON is emitted.

## Architectural Context

The Phase-2 contract requires invariant-centric rows (not task-ID rows). Before
phase2_contract.yml can be rewritten with correct rows, the INV IDs those rows
will reference must be registered in INVARIANTS_MANIFEST.yml. This task does
that registration. The gov_conv_001 manifest is the input; INVARIANTS_MANIFEST.yml
is the output.

## Pre-conditions

- evidence/phase2/gov_conv_001_reconciliation_manifest.json exists (TSK-P2-GOV-CONV-001 complete)
- docs/invariants/INVARIANTS_MANIFEST.yml is readable and writable
- INV-158 is the current last registered ID (verify before assigning INV-159)

## Files to Change

- docs/invariants/INVARIANTS_MANIFEST.yml (MODIFY — append new entries)
- scripts/audit/verify_gov_conv_002.sh (CREATE)
- evidence/phase2/gov_conv_002_inv_registration.json (EMIT via script)

## out_of_scope

- Modifying phase2_contract.yml
- Creating verifier scripts for the invariants themselves
- Registering Phase-3 or Phase-4 invariants

## stop_conditions

- gov_conv_001 manifest does not exist => STOP
- Proposed ID conflicts with existing entry => STOP, resolve gap first
- Invariant description cannot name a specific behavioral guarantee => do not register; mark roadmap

## proof_guarantees

- INVARIANTS_MANIFEST.yml contains >=6 new INV entries starting at INV-159
- Each entry has non-empty description and declared status
- verify_gov_conv_002.sh exits non-zero on manifest missing an expected ID

## proof_limitations

- Does not verify verifier scripts function correctly
- Does not guarantee evidence files exist for implemented invariants

## Implementation Steps

### Step 1 — Extract absent-ID clusters [ID gov_conv_002_w01]

Read gov_conv_001_reconciliation_manifest.json. Filter rows where inv_id_absent
or inv_ids field is empty. Group by task cluster prefix.
Done when: cluster list recorded in EXEC_LOG.md.

### Step 2 — Draft and append INV entries [ID gov_conv_002_w02]

For each cluster, write one INVARIANTS_MANIFEST.yml entry:
```yaml
- invariant_id: INV-159
  cluster: PREAUTH-005
  description: >-
    All Phase-2 PREAUTH-005 state-machine enforcement tasks have been executed
    and produce verifiable evidence under evidence/phase2/. Verifier:
    scripts/audit/verify_tsk_p2_preauth_005_*.sh
  status: implemented  # or roadmap if verifier absent
  phase: '2'
```
Repeat sequentially through all clusters. Append to end of INVARIANTS_MANIFEST.yml.
Done when: All cluster entries appended; file parseable with python3 -c "import yaml; yaml.safe_load(open('docs/invariants/INVARIANTS_MANIFEST.yml'))".

### Step 3 — Write verify_gov_conv_002.sh [ID gov_conv_002_w03]

Script reads INVARIANTS_MANIFEST.yml, finds all entries with invariant_id matching
INV-1[5-9][0-9] or INV-[2-9][0-9][0-9], checks each has non-empty description,
counts total. Exits 1 if count < 6 or any description is empty.
Done when: Script executable; exits 1 on fixture with 5 entries; exits 0 on full manifest.

### Step 4 — Run and emit evidence [ID gov_conv_002_w04]

bash scripts/audit/verify_gov_conv_002.sh > evidence/phase2/gov_conv_002_inv_registration.json
Done when: evidence file exists with required fields.

## Verification

```bash
bash scripts/audit/verify_gov_conv_002.sh > evidence/phase2/gov_conv_002_inv_registration.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-002 --evidence evidence/phase2/gov_conv_002_inv_registration.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

evidence/phase2/gov_conv_002_inv_registration.json must include:
task_id, git_sha, timestamp_utc, status, checks, ids_registered, ids_implemented,
ids_roadmap, manifest_path

## Rollback

Revert the appended entries from INVARIANTS_MANIFEST.yml (they are at the end of
the file; revert to the line before INV-159 was added). Delete verify_gov_conv_002.sh
and the evidence file.

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| INV-158 is not the last existing ID | Numbering conflict | Read manifest end before assigning INV-159 |
| Cluster grouping is ambiguous | Some tasks map to two clusters | Assign to the more specific cluster; note in EXEC_LOG.md |
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-002/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-002
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-002.INV_REGISTRATION_FAIL
origin_task_id: TSK-P2-GOV-CONV-002

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 3 of 10

## `tasks/TSK-P2-GOV-CONV-003/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-003
title: >-
  Rewrite phase2_contract.yml replacing all task-ID rows and stub rows with
  invariant-bearing, evidence-backed contract rows for all executed Phase-2 work
owner_role: INVARIANTS_CURATOR
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  docs/PHASE2/phase2_contract.yml currently has 12 rows: 3 correctly marked
  implemented (INV-156/157/158), and 9 rows using task-ID schema (TSK-P2-PREAUTH-
  005-00 through 005-08) which violates the contract schema and will be rejected
  by verify_phase2_contract.sh. Additionally, all executed work beyond these 12 rows
  is entirely absent from the contract. This task rewrites the contract to: remove
  task-ID rows, keep INV-156/157/158 intact, and add invariant-bearing rows for
  every executed Phase-2 cluster using the INV IDs registered in TSK-P2-GOV-CONV-002.
  No row may be marked implemented unless its evidence file exists and its verifier
  script exists.

anti_patterns:
  - >-
    Marking a row implemented when either the verifier script or the evidence file
    does not exist on disk — status must be planned if either is absent.
  - >-
    Adding rows for Phase-3 or future work — only executed Phase-2 work is admissible.
  - >-
    Inventing row counts without reading the gov_conv_001 manifest — the manifest
    is the source of truth for what executed.
  - >-
    Modifying INV-156, INV-157, or INV-158 rows — these are already correct and
    must not be altered.

out_of_scope:
  - Creating verify_phase2_contract.sh (that is TSK-P2-GOV-CONV-004)
  - Registering new INV IDs (that was TSK-P2-GOV-CONV-002)
  - Writing PHASE2_CONTRACT.md (that is TSK-P2-GOV-CONV-005)
  - Any modification to task meta.yml files

stop_conditions:
  - >-
    STOP if INV IDs from TSK-P2-GOV-CONV-002 are not yet registered in
    INVARIANTS_MANIFEST.yml — do not write contract rows without valid INV IDs.
  - >-
    STOP if any row is written with invariant_id matching ^TSK- — task-ID schema
    is prohibited in the contract.
  - >-
    STOP if a row is marked implemented but test -f <evidence_path> returns false —
    downgrade to planned.

proof_guarantees:
  - >-
    phase2_contract.yml contains zero rows with invariant_id matching ^TSK-.
  - >-
    phase2_contract.yml contains zero rows with verifier field containing run_task.sh.
  - >-
    INV-156, INV-157, INV-158 rows are present and unmodified.
  - >-
    All new rows carry an INV ID registered in INVARIANTS_MANIFEST.yml.
  - >-
    No row marked implemented has a non-existent evidence_path on disk.

proof_limitations:
  - >-
    Does not validate evidence file schema content — only file existence.
  - >-
    verify_phase2_contract.sh does not yet exist in this task; full contract
    validation happens in TSK-P2-GOV-CONV-004.

depends_on:
  - TSK-P2-GOV-CONV-002
blocks:
  - TSK-P2-GOV-CONV-004
  - TSK-P2-GOV-CONV-005

touches:
  - docs/PHASE2/phase2_contract.yml
  - scripts/audit/verify_gov_conv_003.sh
  - evidence/phase2/gov_conv_003_contract_rewrite.json
  - tasks/TSK-P2-GOV-CONV-003/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-003/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-003/EXEC_LOG.md

deliverable_files:
  - scripts/audit/verify_gov_conv_003.sh
  - evidence/phase2/gov_conv_003_contract_rewrite.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-003/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-003/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-003

work:
  - >-
    [ID gov_conv_003_w01] Read gov_conv_001 manifest and gov_conv_002 evidence.
    Build the authoritative list of: (a) rows to keep (INV-156/157/158), (b) rows
    to remove (all ^TSK- rows), (c) rows to add (one per Phase-2 INV ID from
    TSK-P2-GOV-CONV-002). Log this list in EXEC_LOG.md before touching the YAML.
  - >-
    [ID gov_conv_003_w02] Create a backup of the current phase2_contract.yml as
    phase2_contract.yml.bak in the same directory. Confirm the backup exists before
    making any modification.
  - >-
    [ID gov_conv_003_w03] Rewrite phase2_contract.yml: remove all rows with
    invariant_id matching ^TSK-, keep INV-156/157/158 unmodified, append new
    invariant-bearing rows. Each new row must include: invariant_id, description
    (1 sentence), status (implemented or planned), required (true/false),
    gate_id, verifier (script path or null), evidence_path (or null).
  - >-
    [ID gov_conv_003_w04] Write scripts/audit/verify_gov_conv_003.sh that reads
    phase2_contract.yml and: asserts zero rows with invariant_id matching ^TSK-,
    asserts zero rows with verifier containing run_task.sh, asserts INV-156/157/158
    present, asserts each implemented row's evidence_path exists on disk. Exits
    non-zero on any failure.
  - >-
    [ID gov_conv_003_w05] Run verify_gov_conv_003.sh and emit
    evidence/phase2/gov_conv_003_contract_rewrite.json with: rows_total,
    rows_implemented, rows_planned, rows_removed, task_id_rows_found (must be 0).

acceptance_criteria:
  - >-
    [ID gov_conv_003_w01] EXEC_LOG.md records the pre-rewrite list: rows kept,
    rows removed, rows added.
  - >-
    [ID gov_conv_003_w02] phase2_contract.yml.bak exists before the first write
    to phase2_contract.yml.
  - >-
    [ID gov_conv_003_w03] phase2_contract.yml contains zero rows where invariant_id
    starts with TSK- as verified by grep "^  invariant_id: TSK-" phase2_contract.yml
    returning no matches.
  - >-
    [ID gov_conv_003_w04] verify_gov_conv_003.sh exits non-zero when a task-ID
    row is injected into a fixture copy of the contract.
  - >-
    [ID gov_conv_003_w05] evidence/phase2/gov_conv_003_contract_rewrite.json
    exists with task_id_rows_found: 0.

negative_tests:
  - id: TSK-P2-GOV-CONV-003-N1
    description: >-
      Inject a row with invariant_id: TSK-P2-TEST-999 into a fixture copy of
      phase2_contract.yml. Run verify_gov_conv_003.sh against it. It must exit
      non-zero. This proves the script enforces the no-task-ID-row constraint
      and cannot be satisfied by a contract that still contains task-ID rows.
    required: true
  - id: TSK-P2-GOV-CONV-003-N2
    description: >-
      Mark a row as status: implemented but point its evidence_path to a file that
      does not exist. Run verify_gov_conv_003.sh. It must exit non-zero. This proves
      the script enforces evidence existence for implemented rows.
    required: true

verification:
  - >-
    # [ID gov_conv_003_w04] [ID gov_conv_003_w05]
    bash scripts/audit/verify_gov_conv_003.sh > evidence/phase2/gov_conv_003_contract_rewrite.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-003
    --evidence evidence/phase2/gov_conv_003_contract_rewrite.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_003_contract_rewrite.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - rows_total
      - rows_implemented
      - rows_planned
      - rows_removed
      - task_id_rows_found

failure_modes:
  - >-
    Task-ID row survives the rewrite — contract remains schema-non-compliant and
    verify_phase2_contract.sh will reject it => CRITICAL_FAIL
  - >-
    INV-156/157/158 are modified or removed — regression in already-validated
    contract rows => CRITICAL_FAIL
  - >-
    Row marked implemented without evidence file existing => FAIL
  - >-
    No backup created before rewrite — recovery impossible if YAML is corrupted => FAIL
  - >-
    Evidence file missing => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - evidence/phase2/gov_conv_001_reconciliation_manifest.json
  - evidence/phase2/gov_conv_002_inv_registration.json
  - docs/PHASE2/phase2_contract.yml

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-003/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-003/EXEC_LOG.md
notes: >-
  The backup (.bak) file is incidental churn and must be removed before commit per
  EVIDENCE_CHURN_CLEANUP_POLICY.md. Its purpose is safety during the rewrite session
  only. The deliverable is the rewritten phase2_contract.yml, not the backup.
client: codex_cli
assigned_agent: invariants_curator
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-003/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-003
# Phase-2 Constitutional Reconciliation: Contract Rewrite

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-003.CONTRACT_REWRITE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Rewrite docs/PHASE2/phase2_contract.yml to contain zero task-ID rows, intact
INV-156/157/158 rows, and correct invariant-bearing rows for all executed
Phase-2 work. Done when: verify_gov_conv_003.sh passes with task_id_rows_found: 0
and evidence JSON emitted.

## Architectural Context

The contract is currently a 12-row stub from early Phase-2 planning. Nine rows
use task-ID schema (^TSK-) which verify_phase2_contract.sh will reject. The
contract must be reconciled to the execution reality established by Tracks 1–2
(TSK-P2-GOV-CONV-001 and -002) before the aggregator verifier can run.

## Pre-conditions

- evidence/phase2/gov_conv_001_reconciliation_manifest.json exists
- evidence/phase2/gov_conv_002_inv_registration.json exists
- docs/invariants/INVARIANTS_MANIFEST.yml contains INV-159 onward entries
- docs/PHASE2/phase2_contract.yml is readable and writable

## Files to Change

- docs/PHASE2/phase2_contract.yml (REWRITE)
- scripts/audit/verify_gov_conv_003.sh (CREATE)
- evidence/phase2/gov_conv_003_contract_rewrite.json (EMIT via script)

## out_of_scope

- Creating verify_phase2_contract.sh (TSK-P2-GOV-CONV-004)
- Writing PHASE2_CONTRACT.md (TSK-P2-GOV-CONV-005)
- Modifying task meta.yml files
- Adding Phase-3 rows

## stop_conditions

- TSK-P2-GOV-CONV-002 incomplete => STOP
- Any row written with ^TSK- invariant_id => STOP immediately
- Implemented row with non-existent evidence_path => downgrade to planned, not STOP

## proof_guarantees

- Zero ^TSK- rows in contract
- Zero run_task.sh verifier references in contract
- INV-156/157/158 intact
- All implemented rows have existing evidence_path

## proof_limitations

- Does not validate evidence file content schema
- verify_phase2_contract.sh validation (schema-level) happens in TSK-P2-GOV-CONV-004

## Implementation Steps

### Step 1 — Build rewrite plan [ID gov_conv_003_w01]

Read manifests from TSK-P2-GOV-CONV-001 and -002. List: keep rows, remove rows,
add rows. Record in EXEC_LOG.md.

### Step 2 — Backup [ID gov_conv_003_w02]

cp docs/PHASE2/phase2_contract.yml docs/PHASE2/phase2_contract.yml.bak
Verify backup exists before proceeding.

### Step 3 — Rewrite contract [ID gov_conv_003_w03]

Remove ^TSK- rows. Keep INV-156/157/158 unmodified.
Add new rows using format:
```yaml
- invariant_id: INV-159
  description: "PREAUTH-005 state-machine enforcement tasks executed with evidence."
  status: implemented
  required: true
  gate_id: PHASE2_GATE
  verifier: scripts/audit/verify_tsk_p2_preauth_005_cluster.sh
  evidence_path: evidence/phase2/tsk_p2_preauth_005_cluster.json
```
Verify YAML parses cleanly after write.

### Step 4 — Write verifier [ID gov_conv_003_w04]

Create scripts/audit/verify_gov_conv_003.sh with checks described in work item 04.

### Step 5 — Run and emit evidence [ID gov_conv_003_w05]

bash scripts/audit/verify_gov_conv_003.sh > evidence/phase2/gov_conv_003_contract_rewrite.json

## Verification

```bash
bash scripts/audit/verify_gov_conv_003.sh > evidence/phase2/gov_conv_003_contract_rewrite.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-003 --evidence evidence/phase2/gov_conv_003_contract_rewrite.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Rollback

Restore from phase2_contract.yml.bak:
cp docs/PHASE2/phase2_contract.yml.bak docs/PHASE2/phase2_contract.yml
Delete verify_gov_conv_003.sh and evidence file.

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| YAML corruption during rewrite | Contract unparseable | Always validate with python3 yaml.safe_load after write |
| Evidence path in contract points to wrong phase dir | verify_phase2_contract.sh rejects row | Check all paths start with evidence/phase2/ |
| Row count is unexpectedly large | PR diff is hard to review | Group rows by cluster with YAML comments |
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-003/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-003
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-003.CONTRACT_REWRITE_FAIL
origin_task_id: TSK-P2-GOV-CONV-003

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 4 of 10

## `tasks/TSK-P2-GOV-CONV-004/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-004
title: >-
  Create verify_phase2_contract.sh — the Phase-2 contract aggregator gate script
  modelled on verify_phase1_contract.sh
owner_role: SECURITY_GUARDIAN
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: CI_GATES

intent: >-
  No script currently aggregates Phase-2 contract row validation. Individual task
  verifiers exist per task (verify_tsk_p2_preauth_*.sh), but nothing ties them
  to the contract under RUN_PHASE2_GATES=1. Without this script, Phase-2 has no
  contract-level gate. This task creates verify_phase2_contract.sh modelled
  exactly on verify_phase1_contract.sh, wires it into CI in non-enforcing mode,
  and emits evidence proving its schema enforcement behavior.

anti_patterns:
  - >-
    Implementing a soft verifier that exits 0 even when rows fail validation —
    the script must be fail-closed on every check when RUN_PHASE2_GATES=1.
  - >-
    Wiring into CI in enforcing mode (RUN_PHASE2_GATES=1) before Phase-2 ratification
    is complete — non-enforcing mode is correct until Track 4 closes.
  - >-
    Accepting a row where verifier field contains run_task.sh — this is a schema
    violation that must cause a hard exit.

out_of_scope:
  - Rewriting phase2_contract.yml (TSK-P2-GOV-CONV-003)
  - Creating PHASE2_CONTRACT.md (TSK-P2-GOV-CONV-005)
  - Switching CI to enforcing mode (deferred until Track 4)

stop_conditions:
  - >-
    STOP if phase2_contract.yml still contains ^TSK- rows — the script cannot
    validly enforce a schema-contaminated contract.
  - >-
    STOP if RUN_PHASE2_GATES=1 is set in CI before the ratification artifact
    exists — non-enforcing default only.

proof_guarantees:
  - >-
    verify_phase2_contract.sh reads docs/PHASE2/phase2_contract.yml and validates
    all required fields per row.
  - >-
    Script rejects any row where invariant_id matches ^TSK-.
  - >-
    Script rejects any row where verifier contains run_task.sh.
  - >-
    When RUN_PHASE2_GATES=1: validates each implemented+required=true row's
    evidence file exists and is schema-valid.
  - >-
    Script emits evidence/phase2/phase2_contract_status.json on success.
  - >-
    CI calls the script in non-enforcing mode (RUN_PHASE2_GATES=0 default).

proof_limitations:
  - >-
    Does not validate evidence file content beyond schema existence check.
  - >-
    Non-enforcing mode means CI passes even if rows would fail in enforcing mode.

depends_on:
  - TSK-P2-GOV-CONV-003
blocks:
  - TSK-P2-GOV-CONV-007

touches:
  - scripts/audit/verify_phase2_contract.sh
  - .github/workflows/ci.yml
  - scripts/dev/pre_ci.sh
  - evidence/phase2/phase2_contract_status.json
  - tasks/TSK-P2-GOV-CONV-004/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-004/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-004/EXEC_LOG.md

deliverable_files:
  - scripts/audit/verify_phase2_contract.sh
  - evidence/phase2/phase2_contract_status.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-004/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-004/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-004

work:
  - >-
    [ID gov_conv_004_w01] Read scripts/audit/verify_phase1_contract.sh fully to
    understand its structure: how it reads the YAML, validates rows, checks evidence
    file existence, enforces gate flag, emits evidence JSON. Log the key structural
    patterns in EXEC_LOG.md before writing Phase-2 equivalent.
  - >-
    [ID gov_conv_004_w02] Create scripts/audit/verify_phase2_contract.sh with
    these exact behaviors: reads docs/PHASE2/phase2_contract.yml; validates required
    fields per row (invariant_id, status, required, gate_id, verifier, evidence_path);
    rejects ^TSK- invariant_id rows (exit 1); rejects verifier containing run_task.sh
    (exit 1); when RUN_PHASE2_GATES=1 validates each implemented+required:true row's
    evidence_path exists and passes schema; enforces evidence namespace
    evidence/phase2/** for Phase-2 rows; emits evidence/phase2/phase2_contract_status.json;
    exits 0 on PASS, non-zero on FAIL. All psql calls (if any) use $DATABASE_URL.
  - >-
    [ID gov_conv_004_w03] Wire verify_phase2_contract.sh into CI alongside
    verify_phase1_contract.sh. Default: RUN_PHASE2_GATES=0 (non-enforcing).
    Add to pre_ci.sh in the fast-checks tier.
  - >-
    [ID gov_conv_004_w04] Run the script with RUN_PHASE2_GATES=0 against the
    rewritten phase2_contract.yml and confirm it exits 0 and emits the evidence file.

acceptance_criteria:
  - >-
    [ID gov_conv_004_w01] EXEC_LOG.md records the structural patterns from
    verify_phase1_contract.sh before any Phase-2 equivalent is written.
  - >-
    [ID gov_conv_004_w02] verify_phase2_contract.sh exists, is executable, exits
    1 on a fixture contract containing a ^TSK- row, exits 1 on a fixture containing
    run_task.sh as verifier.
  - >-
    [ID gov_conv_004_w03] CI workflow file contains a call to verify_phase2_contract.sh;
    pre_ci.sh calls it in fast-checks tier. Default RUN_PHASE2_GATES value is 0.
  - >-
    [ID gov_conv_004_w04] evidence/phase2/phase2_contract_status.json exists after
    script run with all required fields populated.

negative_tests:
  - id: TSK-P2-GOV-CONV-004-N1
    description: >-
      Create a fixture phase2_contract.yml with one row where invariant_id is
      TSK-P2-PREAUTH-005-01. Run verify_phase2_contract.sh against it. The script
      must exit non-zero. This proves the task-ID row rejection is enforced and
      not bypassed by a soft check.
    required: true
  - id: TSK-P2-GOV-CONV-004-N2
    description: >-
      Create a fixture with an implemented+required:true row whose evidence_path
      points to a non-existent file. Run the script with RUN_PHASE2_GATES=1. It
      must exit non-zero. This proves the enforcing-mode evidence check works.
    required: true

verification:
  - >-
    # [ID gov_conv_004_w02] [ID gov_conv_004_w04]
    RUN_PHASE2_GATES=0 bash scripts/audit/verify_phase2_contract.sh > evidence/phase2/phase2_contract_status.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-004
    --evidence evidence/phase2/phase2_contract_status.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/phase2_contract_status.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - rows_validated
      - rows_passed
      - rows_failed
      - enforcing_mode
      - task_id_rows_rejected

failure_modes:
  - >-
    Script exits 0 on a contract with ^TSK- rows — fake PASS pattern; the
    gate is useless => CRITICAL_FAIL
  - >-
    CI wired in enforcing mode before ratification artifact exists — blocks
    all CI before Track 4 complete => BLOCKED
  - >-
    psql commands in script do not use DATABASE_URL — script fails in ephemeral CI
    environments => FAIL
  - >-
    Evidence file missing => FAIL
  - >-
    Script not added to pre_ci.sh — gate exists but is not run locally => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md
  - scripts/audit/verify_phase1_contract.sh
  - docs/PHASE2/phase2_contract.yml

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-004/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-004/EXEC_LOG.md
notes: >-
  This task uses blast_radius: CI_GATES because it modifies .github/workflows/ci.yml
  and scripts/dev/pre_ci.sh. These are regulated surfaces. Approval artifacts for
  these files must be created before editing them per REGULATED_SURFACE_PATHS.yml.
  Non-enforcing mode (RUN_PHASE2_GATES=0) is the correct default until the
  Phase-2 ratification artifact (TSK-P2-GOV-CONV-007) is complete.
client: codex_cli
assigned_agent: security_guardian
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-004/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-004
# Phase-2 Contract Verifier: verify_phase2_contract.sh

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-004.VERIFIER_CREATE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create scripts/audit/verify_phase2_contract.sh that validates phase2_contract.yml
rows, rejects task-ID rows and run_task.sh verifiers, enforces evidence existence
in gate mode, and emits evidence JSON. Wire into CI in non-enforcing mode.
Done when: both negative tests pass and evidence JSON is emitted.

## Architectural Context

Phase-2 has individual task verifiers but no contract-level aggregator. The pattern
from verify_phase1_contract.sh is the exact template. The Phase-2 equivalent must
be fail-closed on the same schema violations: ^TSK- row IDs and run_task.sh verifiers.
It must run in non-enforcing mode by default until TSK-P2-GOV-CONV-007 creates the
ratification artifact.

## Pre-conditions

- docs/PHASE2/phase2_contract.yml has been rewritten by TSK-P2-GOV-CONV-003
  (zero ^TSK- rows confirmed)
- scripts/audit/verify_phase1_contract.sh is readable (template)
- .github/workflows/ci.yml is readable

## Regulated Surface Compliance

This task touches .github/workflows/ci.yml and scripts/dev/pre_ci.sh which are
regulated surfaces. Stage A approval artifact must be created BEFORE editing
these files. Do not edit these files without prior approval metadata.

## Files to Change

- scripts/audit/verify_phase2_contract.sh (CREATE)
- .github/workflows/ci.yml (MODIFY — add gate call in non-enforcing mode)
- scripts/dev/pre_ci.sh (MODIFY — add to fast-checks tier)
- evidence/phase2/phase2_contract_status.json (EMIT via script)

## out_of_scope

- Switching to enforcing mode (deferred to TSK-P2-GOV-CONV-007)
- Modifying phase2_contract.yml content
- Creating PHASE2_CONTRACT.md

## stop_conditions

- phase2_contract.yml still contains ^TSK- rows => STOP
- CI wired to RUN_PHASE2_GATES=1 before ratification artifact exists => STOP

## proof_guarantees

- Script rejects ^TSK- invariant_id rows
- Script rejects run_task.sh verifier references
- Script emits evidence JSON on success
- CI calls script with RUN_PHASE2_GATES=0

## proof_limitations

- Non-enforcing mode means CI does not fail on row validation failures
- Does not validate evidence content schema

## Implementation Steps

### Step 1 — Read Phase-1 template [ID gov_conv_004_w01]

cat scripts/audit/verify_phase1_contract.sh — note YAML parsing method, row
iteration pattern, gate flag check, evidence emission format. Log in EXEC_LOG.md.

### Step 2 — Create verify_phase2_contract.sh [ID gov_conv_004_w02]

Model on Phase-1 equivalent. Change contract path to docs/PHASE2/phase2_contract.yml.
Change evidence path to evidence/phase2/phase2_contract_status.json.
Change gate flag to RUN_PHASE2_GATES. Add the two schema violation checks:
grep for ^TSK- IDs and run_task.sh verifiers.

### Step 3 — Wire into CI and pre_ci.sh [ID gov_conv_004_w03]

Create Stage A approval artifact first.
Add to .github/workflows/ci.yml with RUN_PHASE2_GATES=0.
Add to scripts/dev/pre_ci.sh fast-checks section.

### Step 4 — Run and validate [ID gov_conv_004_w04]

RUN_PHASE2_GATES=0 bash scripts/audit/verify_phase2_contract.sh > evidence/phase2/phase2_contract_status.json
Confirm exit 0. Confirm evidence file populated.

## Verification

```bash
RUN_PHASE2_GATES=0 bash scripts/audit/verify_phase2_contract.sh > evidence/phase2/phase2_contract_status.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-004 --evidence evidence/phase2/phase2_contract_status.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Rollback

Delete scripts/audit/verify_phase2_contract.sh. Revert .github/workflows/ci.yml
and scripts/dev/pre_ci.sh changes. Delete evidence file.

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| YAML parser not available in bash | Script cannot read contract | Use python3 as YAML parser in the bash script |
| CI wired with wrong default gate value | Blocks CI before ratification | Grep ci.yml for RUN_PHASE2_GATES and confirm =0 before PR |
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-004/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-004
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-004.VERIFIER_CREATE_FAIL
origin_task_id: TSK-P2-GOV-CONV-004

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 5 of 10

## `tasks/TSK-P2-GOV-CONV-005/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-005
title: >-
  Create docs/PHASE2/PHASE2_CONTRACT.md — the human-readable Phase-2 contract
  narrative modelled on PHASE1_CONTRACT.md
owner_role: ARCHITECT
status: planned
priority: NORMAL
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  PHASE2_CONTRACT.md does not exist. It is a required artifact for Phase-2 to be
  constitutionally admissible and is listed as a dependency of the Phase-2 ratification
  artifact (TSK-P2-GOV-CONV-007). This document provides the human-readable narrative
  that explains the Phase-2 contract schema, status semantics, evidence namespace
  conventions, gate flag, and the authoritative role of phase2_contract.yml. It must
  not redefine or weaken any machine row in the YAML — the YAML is authoritative.

anti_patterns:
  - >-
    Redefining row semantics in the markdown that conflict with phase2_contract.yml —
    the YAML is authoritative; this document explains it.
  - >-
    Creating AGENTIC_SDLC_PHASE2_POLICY.md in this task — that is TSK-P2-GOV-CONV-006.
  - >-
    Adding implementation details about Phase-3 or Phase-4 — this document is
    scoped to Phase-2 contract semantics only.

out_of_scope:
  - Creating AGENTIC_SDLC_PHASE2_POLICY.md
  - Modifying phase2_contract.yml
  - Creating the ratification artifact
  - Defining Phase-3 or Phase-4 semantics

stop_conditions:
  - >-
    STOP if the document would redefine any row field meaning in a way that
    contradicts the YAML schema — document must be subordinate to the YAML.
  - >-
    STOP if the document does not explicitly state that phase2_contract.yml is
    the machine source of truth.

proof_guarantees:
  - >-
    docs/PHASE2/PHASE2_CONTRACT.md exists with all required sections listed
    in acceptance_criteria.
  - >-
    The document explicitly states phase2_contract.yml is the machine source of truth.
  - >-
    The document documents status semantics for Phase-2 and the gate flag.

proof_limitations:
  - >-
    Document correctness is confirmed by human review only; no automated schema
    check for markdown content.
  - >-
    Does not enforce the semantics it describes — that is the verifier script's job.

depends_on:
  - TSK-P2-GOV-CONV-003
blocks:
  - TSK-P2-GOV-CONV-007

touches:
  - docs/PHASE2/PHASE2_CONTRACT.md
  - scripts/audit/verify_gov_conv_005.sh
  - evidence/phase2/gov_conv_005_contract_md.json
  - tasks/TSK-P2-GOV-CONV-005/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-005/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-005/EXEC_LOG.md

deliverable_files:
  - docs/PHASE2/PHASE2_CONTRACT.md
  - scripts/audit/verify_gov_conv_005.sh
  - evidence/phase2/gov_conv_005_contract_md.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-005/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-005/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-005

work:
  - >-
    [ID gov_conv_005_w01] Read docs/PHASE1/PHASE1_CONTRACT.md fully. Identify all
    sections. Map each section to its Phase-2 equivalent. Log the section map in
    EXEC_LOG.md before writing any content.
  - >-
    [ID gov_conv_005_w02] Write docs/PHASE2/PHASE2_CONTRACT.md with these required
    sections: (1) Phase name and key, (2) machine source of truth statement
    (phase2_contract.yml is authoritative), (3) contract row schema explanation,
    (4) status semantics (phase1_prerequisite / planned / implemented /
    deferred_to_phase3), (5) evidence namespace conventions (evidence/phase2/**),
    (6) gate flag (RUN_PHASE2_GATES) and verifier reference, (7) what this document
    does NOT define (YAML rows are not redefined here).
  - >-
    [ID gov_conv_005_w03] Write scripts/audit/verify_gov_conv_005.sh that checks:
    file exists, contains the phrase "phase2_contract.yml" (machine source of truth
    reference), contains "RUN_PHASE2_GATES" (gate flag reference), contains
    "evidence/phase2" (namespace reference), and is non-empty. Exits non-zero if
    any check fails.
  - >-
    [ID gov_conv_005_w04] Run verify_gov_conv_005.sh and emit
    evidence/phase2/gov_conv_005_contract_md.json.

acceptance_criteria:
  - >-
    [ID gov_conv_005_w01] EXEC_LOG.md records the section map from PHASE1_CONTRACT.md
    to Phase-2 equivalent before writing begins.
  - >-
    [ID gov_conv_005_w02] docs/PHASE2/PHASE2_CONTRACT.md exists and contains all
    seven required sections as confirmed by grep checks in the verifier script.
  - >-
    [ID gov_conv_005_w03] verify_gov_conv_005.sh exits non-zero when the phrase
    "phase2_contract.yml" is removed from a fixture copy of the document.
  - >-
    [ID gov_conv_005_w04] evidence/phase2/gov_conv_005_contract_md.json exists
    with all required fields.

negative_tests:
  - id: TSK-P2-GOV-CONV-005-N1
    description: >-
      Remove the phrase "phase2_contract.yml" from a fixture copy of
      PHASE2_CONTRACT.md. Run verify_gov_conv_005.sh against it. The script must
      exit non-zero. This proves the machine-source-of-truth reference is enforced
      as a required section, not optional prose.
    required: true

verification:
  - >-
    # [ID gov_conv_005_w03] [ID gov_conv_005_w04]
    bash scripts/audit/verify_gov_conv_005.sh > evidence/phase2/gov_conv_005_contract_md.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-005
    --evidence evidence/phase2/gov_conv_005_contract_md.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_005_contract_md.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - file_exists
      - machine_source_reference_found
      - gate_flag_reference_found
      - namespace_reference_found

failure_modes:
  - >-
    Document redefines row field semantics in a way that contradicts the YAML —
    governance confusion between human and machine source of truth => FAIL
  - >-
    Section "machine source of truth" absent — downstream ratification artifact
    cannot reference the correct authority document => FAIL
  - >-
    Evidence file missing => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/PHASE1/PHASE1_CONTRACT.md
  - docs/PHASE2/phase2_contract.yml
  - docs/operations/PHASE_LIFECYCLE.md

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-005/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-005/EXEC_LOG.md
notes: >-
  This task can run in parallel with TSK-P2-GOV-CONV-004. Both depend on
  TSK-P2-GOV-CONV-003. The markdown document must be brief — the YAML is
  authoritative. Three to five pages maximum.
client: codex_cli
assigned_agent: architect
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-005/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-005
# Phase-2 Human Contract: PHASE2_CONTRACT.md

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-005.CONTRACT_MD_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create docs/PHASE2/PHASE2_CONTRACT.md with all seven required sections, explicitly
stating phase2_contract.yml as the machine source of truth. Done when:
verify_gov_conv_005.sh passes and evidence JSON is emitted.

## Architectural Context

PHASE2_CONTRACT.md is a required artifact for Phase-2 ratification. It is the
human-readable companion to the machine contract YAML. It does not redefine the YAML;
it explains it. The pattern is docs/PHASE1/PHASE1_CONTRACT.md.

## Pre-conditions

- docs/PHASE1/PHASE1_CONTRACT.md is readable (template)
- docs/PHASE2/phase2_contract.yml has been rewritten (TSK-P2-GOV-CONV-003)
- docs/PHASE2/ directory exists

## Files to Change

- docs/PHASE2/PHASE2_CONTRACT.md (CREATE)
- scripts/audit/verify_gov_conv_005.sh (CREATE)
- evidence/phase2/gov_conv_005_contract_md.json (EMIT via script)

## Required Sections in PHASE2_CONTRACT.md

1. Phase name and key (Phase-2: Pre-Authorization Assurance)
2. Machine source of truth statement
3. Contract row schema explanation
4. Status semantics
5. Evidence namespace conventions
6. Gate flag and verifier reference
7. What this document does NOT define

## Verification

```bash
bash scripts/audit/verify_gov_conv_005.sh > evidence/phase2/gov_conv_005_contract_md.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-005 --evidence evidence/phase2/gov_conv_005_contract_md.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Rollback

Delete docs/PHASE2/PHASE2_CONTRACT.md, scripts/audit/verify_gov_conv_005.sh,
and evidence file. No contract YAML is modified.
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-005/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-005
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-005.CONTRACT_MD_FAIL
origin_task_id: TSK-P2-GOV-CONV-005

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 6 of 10

## `tasks/TSK-P2-GOV-CONV-006/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-006
title: >-
  Create docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md — the Phase-2 equivalent
  of AGENTIC_SDLC_PHASE1_POLICY.md
owner_role: ARCHITECT
status: planned
priority: NORMAL
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  AGENTIC_SDLC_PHASE2_POLICY.md does not exist. It is a required artifact for
  Phase-2 ratification and must define: what was blocked in Phase-1 that is now
  permitted in Phase-2 (policy rotation), what remains blocked in Phase-2, Phase-2
  specific non-negotiables (GF entry gate separation, schema compliance on new
  contract rows), role model, stop conditions including Phase-2-specific ones,
  and definition of done for Phase-2 adoption. This is a docs/operations/ file
  and is a regulated surface — approval is required before editing.

anti_patterns:
  - >-
    Copying Phase-1 policy verbatim — Phase-2 has different permitted surfaces
    and non-negotiables that must be explicitly stated.
  - >-
    Permitting large-scale autonomous adaptation or cross-domain federation in
    Phase-2 — these remain blocked.
  - >-
    Creating Phase-3 policy in this task — Phase-3 policy cannot exist until
    Phase-2 ratification is complete.

out_of_scope:
  - Creating PHASE3 or PHASE4 policy documents
  - Modifying phase2_contract.yml
  - Defining Phase-3 implementation surfaces

stop_conditions:
  - >-
    STOP if the document would permit large-scale autonomous adaptation — this
    remains blocked in Phase-2.
  - >-
    STOP if the document does not explicitly state Phase-2-specific stop conditions
    (schema-non-compliant contract row, missing INV ID for new invariant).

proof_guarantees:
  - >-
    docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md exists with all required
    sections verified by the verifier script.
  - >-
    Document explicitly lists what is newly permitted in Phase-2 vs Phase-1.
  - >-
    Document explicitly lists what remains blocked in Phase-2.
  - >-
    Document contains Phase-2-specific stop conditions.

proof_limitations:
  - >-
    Policy correctness is confirmed by human review only; verifier only checks
    structural completeness, not policy intent.

depends_on:
  - TSK-P2-GOV-CONV-003
blocks:
  - TSK-P2-GOV-CONV-007

touches:
  - docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md
  - scripts/audit/verify_gov_conv_006.sh
  - evidence/phase2/gov_conv_006_phase2_policy.json
  - tasks/TSK-P2-GOV-CONV-006/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-006/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-006/EXEC_LOG.md

deliverable_files:
  - docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md
  - scripts/audit/verify_gov_conv_006.sh
  - evidence/phase2/gov_conv_006_phase2_policy.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-006/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-006/EXEC_LOG.md

regulated_surface_compliance:
  enabled: true
  approval_workflow: stage_a_stage_b
  stage_a_required_before_edit: true
  regulated_paths:
    - docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md

invariants:
  - INV-GOV-CONV-006

work:
  - >-
    [ID gov_conv_006_w01] Create Stage A approval artifact before editing
    docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md. Validate against
    approval_metadata.schema.json. Record in EXEC_LOG.md.
  - >-
    [ID gov_conv_006_w02] Read AGENTIC_SDLC_PHASE1_POLICY.md fully. Log each
    section title and whether it carries over to Phase-2 or requires modification.
  - >-
    [ID gov_conv_006_w03] Write AGENTIC_SDLC_PHASE2_POLICY.md with required sections:
    (1) scope guard changes from Phase-1 (newly permitted: policy rotation,
    AI-review artifact governance, approved API expansion); (2) what remains blocked
    (large-scale autonomous adaptation, cross-domain federation); (3) Phase-2
    non-negotiables (GF entry gate separation, schema compliance on new rows);
    (4) role model (same three roles; advisory MCP read-only); (5) stop conditions
    including Phase-2-specific: schema-non-compliant contract row, missing INV ID
    for new invariant; (6) definition of done for Phase-2 adoption.
  - >-
    [ID gov_conv_006_w04] Write verify_gov_conv_006.sh checking: file exists,
    contains "newly permitted" section, contains "remains blocked" section,
    contains "stop conditions" section, contains "schema-non-compliant" keyword.
    Emit evidence JSON. Exits non-zero if any check fails.

acceptance_criteria:
  - >-
    [ID gov_conv_006_w01] Stage A approval artifact exists and validates before
    any edit to AGENTIC_SDLC_PHASE2_POLICY.md. EXEC_LOG.md records the artifact path.
  - >-
    [ID gov_conv_006_w02] EXEC_LOG.md records the section-by-section Phase-1→Phase-2
    mapping before writing begins.
  - >-
    [ID gov_conv_006_w03] AGENTIC_SDLC_PHASE2_POLICY.md contains all six required
    sections as confirmed by the verifier script.
  - >-
    [ID gov_conv_006_w04] verify_gov_conv_006.sh exits non-zero when "schema-non-compliant"
    is removed from a fixture copy.

negative_tests:
  - id: TSK-P2-GOV-CONV-006-N1
    description: >-
      Remove the "schema-non-compliant" keyword from a fixture copy of
      AGENTIC_SDLC_PHASE2_POLICY.md. Run verify_gov_conv_006.sh. It must exit
      non-zero. This proves Phase-2-specific stop conditions are structurally
      required, not optional prose.
    required: true

verification:
  - >-
    # [ID gov_conv_006_w04]
    bash scripts/audit/verify_gov_conv_006.sh > evidence/phase2/gov_conv_006_phase2_policy.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-006
    --evidence evidence/phase2/gov_conv_006_phase2_policy.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_006_phase2_policy.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - file_exists
      - newly_permitted_section_found
      - remains_blocked_section_found
      - stop_conditions_section_found
      - phase2_specific_stop_condition_found

failure_modes:
  - >-
    Phase-2 policy permits large-scale autonomous adaptation — regression beyond
    Phase-2 authority boundary => CRITICAL_FAIL
  - >-
    Stage A approval artifact not created before editing regulated surface => BLOCKED
  - >-
    Phase-2-specific stop conditions absent — future agents have no enforcement
    signal for schema-non-compliant rows => FAIL
  - >-
    Evidence file missing => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md
  - docs/operations/PHASE_LIFECYCLE.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-006/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-006/EXEC_LOG.md
notes: >-
  This task can run in parallel with TSK-P2-GOV-CONV-004 and TSK-P2-GOV-CONV-005.
  All three depend on TSK-P2-GOV-CONV-003. The regulated surface compliance section
  is active because docs/operations/ is a regulated path.
client: codex_cli
assigned_agent: architect
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-006/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-006
# Phase-2 Policy Guard: AGENTIC_SDLC_PHASE2_POLICY.md

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-006.POLICY_CREATE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md with six required sections
defining Phase-2 permitted surfaces, blocked surfaces, non-negotiables, stop
conditions, role model, and definition of done. Done when: verify_gov_conv_006.sh
passes and evidence JSON is emitted.

## Regulated Surface Compliance (CRITICAL)

docs/operations/ is a regulated surface. Stage A approval artifact MUST be created
BEFORE editing any file in this directory.

## Pre-conditions

- Stage A approval artifact created and validated
- docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md is readable (template)
- TSK-P2-GOV-CONV-003 complete (contract rewritten)

## Verification

```bash
bash scripts/audit/verify_gov_conv_006.sh > evidence/phase2/gov_conv_006_phase2_policy.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-006 --evidence evidence/phase2/gov_conv_006_phase2_policy.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Rollback

Delete docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md, scripts/audit/verify_gov_conv_006.sh,
and evidence file. No contract YAML modified.
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-006/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-006
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-006.POLICY_CREATE_FAIL
origin_task_id: TSK-P2-GOV-CONV-006

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 7 of 10

## `tasks/TSK-P2-GOV-CONV-007/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-007
title: >-
  Create Phase-2 Constitutional Ratification Artifact — PHASE2-RATIFICATION.md
  and sidecar JSON — retroactively normalizing executed Phase-2 into admissible
  constitutional form
owner_role: ARCHITECT
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  Phase-2 execution is real (~90 evidence artifacts, Waves 3-8 executed, active
  TSK-P2 task graph). Phase-2 constitutional authority is incomplete. This is not
  a normal phase opening — Phase-2 already executed before constitutional opening
  was formalized. The artifact created by this task is therefore a RETROACTIVE
  CONSTITUTIONAL RATIFICATION artifact, not a normal opening artifact. It must
  explicitly state: (a) execution began before constitutional formalization,
  (b) this artifact ratifies existing execution into canonical governance form,
  (c) it does not claim Phase-2 began at this approval date, (d) it claims Phase-2
  becomes constitutionally admissible at this approval date, (e) prior execution
  remains historical and is now reconciled, not reclassified.

anti_patterns:
  - >-
    Writing this as a normal phase opening artifact — execution predated
    constitutional opening; writing a normal opening artifact falsifies history.
  - >-
    Creating this artifact before Tracks 1-3 are complete — the entry threshold
    checklist must be fully satisfied before ratification.
  - >-
    Backdating the ratification to the earliest evidence timestamp — the ratification
    date is the date the artifact is created, not the date execution began.
  - >-
    Claiming this artifact proves Phase-2 work was always constitutionally governed —
    it does not; it reconciles authority to execution without rewriting history.

out_of_scope:
  - Switching CI to enforcing mode (that is a post-ratification operational decision)
  - Modifying any executed task meta.yml
  - Defining Phase-3 implementation surfaces
  - Creating Phase-3/4 opening artifacts

stop_conditions:
  - >-
    STOP if verify_phase1_contract.sh does not pass with RUN_PHASE1_GATES=1 —
    Phase-1 must be fully satisfied before Phase-2 can be ratified.
  - >-
    STOP if phase2_contract.yml still contains ^TSK- rows (TSK-P2-GOV-CONV-003
    incomplete).
  - >-
    STOP if verify_phase2_contract.sh does not exist or does not pass with
    RUN_PHASE2_GATES=0 (TSK-P2-GOV-CONV-004 incomplete).
  - >-
    STOP if PHASE2_CONTRACT.md does not exist (TSK-P2-GOV-CONV-005 incomplete).
  - >-
    STOP if AGENTIC_SDLC_PHASE2_POLICY.md does not exist (TSK-P2-GOV-CONV-006
    incomplete).
  - >-
    STOP if the artifact does not explicitly use the word "ratification" and
    explicitly state that execution preceded constitutional formalization.

proof_guarantees:
  - >-
    approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md exists with all five required
    explicit statements about retroactive normalization.
  - >-
    Sidecar JSON exists and validates against approval_metadata.schema.json.
  - >-
    Entry threshold checklist in the artifact is fully checked (all five prerequisite
    artifacts confirmed present).
  - >-
    The artifact does not claim Phase-2 began at the ratification date.

proof_limitations:
  - >-
    Does not switch CI to enforcing mode — that is a separate operational decision.
  - >-
    Human review of the artifact content is required; no automated check can
    validate constitutional intent.

depends_on:
  - TSK-P2-GOV-CONV-004
  - TSK-P2-GOV-CONV-005
  - TSK-P2-GOV-CONV-006

touches:
  - approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md
  - approvals/YYYY-MM-DD/PHASE2-RATIFICATION.approval.json
  - scripts/audit/verify_gov_conv_007.sh
  - evidence/phase2/gov_conv_007_ratification.json
  - tasks/TSK-P2-GOV-CONV-007/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-007/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-007/EXEC_LOG.md

deliverable_files:
  - approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md
  - approvals/YYYY-MM-DD/PHASE2-RATIFICATION.approval.json
  - scripts/audit/verify_gov_conv_007.sh
  - evidence/phase2/gov_conv_007_ratification.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-007/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-007/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-007

work:
  - >-
    [ID gov_conv_007_w01] Verify the entry threshold checklist mechanically before
    creating any artifact: (a) RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh exits 0,
    (b) grep "^  invariant_id: TSK-" docs/PHASE2/phase2_contract.yml returns no matches,
    (c) test -f scripts/audit/verify_phase2_contract.sh exits 0, (d) RUN_PHASE2_GATES=0
    bash scripts/audit/verify_phase2_contract.sh exits 0, (e) test -f
    docs/PHASE2/PHASE2_CONTRACT.md exits 0, (f) test -f
    docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md exits 0. Record all six check
    results in EXEC_LOG.md. Do not proceed until all six pass.
  - >-
    [ID gov_conv_007_w02] Determine today's date (YYYY-MM-DD) and the current git
    commit SHA. Create approvals/YYYY-MM-DD/ directory if it does not exist.
  - >-
    [ID gov_conv_007_w03] Write approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md with
    these explicit required sections: (1) Header declaring this is a RETROACTIVE
    CONSTITUTIONAL RATIFICATION, not a normal phase opening; (2) Statement that
    Phase-2 execution began before constitutional formalization was complete;
    (3) Entry threshold checklist (all six items checked); (4) Reference to all
    five required artifacts (phase2_contract.yml, PHASE2_CONTRACT.md,
    AGENTIC_SDLC_PHASE2_POLICY.md, verify_phase2_contract.sh, INV registrations);
    (5) Statement that Phase-2 becomes constitutionally admissible at this date
    without retroactively claiming governance existed before it did; (6) Architecture
    owner signature and date; (7) Commit SHA.
  - >-
    [ID gov_conv_007_w04] Write approvals/YYYY-MM-DD/PHASE2-RATIFICATION.approval.json
    conforming to approval_metadata.schema.json. Validate with the schema validator.
  - >-
    [ID gov_conv_007_w05] Write verify_gov_conv_007.sh that checks: PHASE2-RATIFICATION.md
    exists, contains "RETROACTIVE" keyword, contains "ratification" keyword, contains
    "entry threshold" section, sidecar JSON exists and is valid JSON. Emit
    evidence/phase2/gov_conv_007_ratification.json.

acceptance_criteria:
  - >-
    [ID gov_conv_007_w01] EXEC_LOG.md records all six threshold check results before
    any artifact is created. All six must show PASS.
  - >-
    [ID gov_conv_007_w02] Approval directory for today's date exists.
  - >-
    [ID gov_conv_007_w03] PHASE2-RATIFICATION.md contains the word "RETROACTIVE" in
    its header and does not contain the phrase "Phase-2 begins" or "phase opens" —
    it is a ratification, not an opening.
  - >-
    [ID gov_conv_007_w04] PHASE2-RATIFICATION.approval.json validates successfully
    against approval_metadata.schema.json.
  - >-
    [ID gov_conv_007_w05] verify_gov_conv_007.sh exits non-zero when "RETROACTIVE"
    is removed from a fixture copy of the ratification document.

negative_tests:
  - id: TSK-P2-GOV-CONV-007-N1
    description: >-
      Remove the word "RETROACTIVE" from a fixture copy of PHASE2-RATIFICATION.md.
      Run verify_gov_conv_007.sh. It must exit non-zero. This proves the retroactive
      framing is structurally enforced, preventing the document from being written
      as a normal phase opening that would falsify history.
    required: true
  - id: TSK-P2-GOV-CONV-007-N2
    description: >-
      Attempt to create the ratification artifact with one of the six threshold
      checks still failing (simulate by using a fixture directory where
      PHASE2_CONTRACT.md is absent). Verify the implementation sequence in
      gov_conv_007_w01 prevents proceeding. EXEC_LOG.md must record the failed check.
    required: true

verification:
  - >-
    # [ID gov_conv_007_w05]
    bash scripts/audit/verify_gov_conv_007.sh > evidence/phase2/gov_conv_007_ratification.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-007
    --evidence evidence/phase2/gov_conv_007_ratification.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_007_ratification.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - ratification_md_exists
      - retroactive_keyword_found
      - threshold_checklist_complete
      - sidecar_json_valid

failure_modes:
  - >-
    Artifact written as a normal phase opening without retroactive framing —
    falsifies governance history => CRITICAL_FAIL
  - >-
    Artifact created before all six threshold checks pass — ratification without
    prerequisites is constitutionally void => CRITICAL_FAIL
  - >-
    Sidecar JSON does not validate against approval_metadata.schema.json — artifact
    is not admissible => FAIL
  - >-
    Evidence file missing => FAIL
  - >-
    "RETROACTIVE" keyword absent from header => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/PHASE_LIFECYCLE.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md
  - docs/operations/approval_metadata.schema.json

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-007/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-007/EXEC_LOG.md
notes: >-
  The YYYY-MM-DD in the file path must be replaced with the actual date when the
  artifact is created. The touches list reflects this with a placeholder. The
  touches field must be updated to the actual date path when the task is implemented.
  This task is the apex of Tracks 1-3 and the hardest governance gate in the entire
  convergence program. It cannot be rushed. The six threshold checks in w01 are
  mandatory pre-conditions, not suggestions.
client: codex_cli
assigned_agent: architect
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-007/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-007
# Phase-2 Constitutional Ratification Artifact

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-007.RATIFICATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create PHASE2-RATIFICATION.md (retroactive constitutional ratification, not normal
phase opening) and sidecar JSON. Done when: both negative tests pass, all six
threshold checks confirmed in EXEC_LOG.md, and evidence JSON emitted.

## CRITICAL: This is not a normal phase opening

Phase-2 execution preceded constitutional formalization. This artifact is a
RETROACTIVE RATIFICATION. It must use that language explicitly. Writing it as
a normal "phase opens today" artifact would falsify history. The artifact claims
Phase-2 becomes constitutionally admissible at this date. It does not claim
Phase-2 began here.

## Pre-conditions (all six must PASS before any file is created)

1. RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh exits 0
2. phase2_contract.yml contains zero ^TSK- rows
3. verify_phase2_contract.sh exists and passes with RUN_PHASE2_GATES=0
4. docs/PHASE2/PHASE2_CONTRACT.md exists
5. docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md exists
6. INV registrations from TSK-P2-GOV-CONV-002 exist in INVARIANTS_MANIFEST.yml

## Files to Change

- approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md (CREATE)
- approvals/YYYY-MM-DD/PHASE2-RATIFICATION.approval.json (CREATE)
- scripts/audit/verify_gov_conv_007.sh (CREATE)
- evidence/phase2/gov_conv_007_ratification.json (EMIT via script)

## Verification

```bash
bash scripts/audit/verify_gov_conv_007.sh > evidence/phase2/gov_conv_007_ratification.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-007 --evidence evidence/phase2/gov_conv_007_ratification.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Rollback

Delete PHASE2-RATIFICATION.md and sidecar JSON. This is a governance act — rollback
requires human decision, not just file deletion. Log the rollback rationale in
EXEC_LOG.md.
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-007/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-007
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-007.RATIFICATION_FAIL
origin_task_id: TSK-P2-GOV-CONV-007

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 8 of 10

## `tasks/TSK-P2-GOV-CONV-008/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-008
title: >-
  Create verify_phase_claim_admissibility.sh enforcing semantic admissibility of
  lifecycle phase claims in task metadata — blocking numeric overclaims AND
  capability laundering
owner_role: SECURITY_GUARDIAN
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: CI_GATES

intent: >-
  Section 2F of PHASE_LIFECYCLE.md defines admissibility rules in prose but nothing
  enforces them at CI. A task can reference phase: '2' in metadata while using
  future-phase capability language (semantic laundering), claim "Phase complete"
  without a ratification artifact, or reference phase: '3' with no opening artifact.
  All three patterns must be mechanically blocked. This task creates a CI-enforced
  lint script covering BOTH numeric admissibility (invalid phase numbers, phases
  without opening artifacts) AND semantic admissibility (capability laundering in
  task title/intent/notes fields, phase-completion overclaims without authority,
  wave-as-phase misuse). The three corrections from the implementation plan review
  are encoded here: numeric + semantic enforcement, not just numeric.

anti_patterns:
  - >-
    Implementing only numeric phase validation (phase in {0,1,2,3,4}) without
    semantic content scanning — this is the exact gap the plan review identified
    as insufficient; people will just lie with better wording.
  - >-
    Writing a soft linter that exits 0 on violations and only prints warnings —
    this must be fail-closed on every blocked pattern.
  - >-
    Hard-coding specific task IDs into the lint patterns — the script must match
    semantic patterns, not specific task names.

out_of_scope:
  - Modifying any task meta.yml to fix violations found (that is TSK-P2-GOV-CONV-009)
  - Creating ratification artifacts
  - Switching CI to enforcing phase-2 contract mode

stop_conditions:
  - >-
    STOP if the script would exit non-zero on any currently passing task without
    a legitimate violation — false positives must be fixed before wiring into CI.
  - >-
    STOP if any semantic pattern check produces match on fewer than 3 distinct
    character sequences — patterns must be specific enough to avoid false positives.

proof_guarantees:
  - >-
    Script rejects task meta.yml files with phase: '3' or phase: '4'.
  - >-
    Script rejects task meta.yml files with phase: '2' where
    approvals/*/PHASE2-RATIFICATION.md does not exist (post-ratification only).
  - >-
    Script rejects task meta.yml files containing any of the blocked semantic
    patterns in title, intent, or notes fields: "Phase complete", "Phase ready",
    "Phase done", "Phase aligned", "Phase 3 ready", "Phase 4 aligned",
    "Phase 2 complete", and any phase: '2' task claiming capability surfaces
    that belong to Phase-3 (cross-domain federation, large-scale autonomous
    adaptation).
  - >-
    Script rejects tasks where phase field value looks like a wave identifier
    (e.g., 'W8', 'wave5').
  - >-
    Script emits evidence/phase2/phase_claim_admissibility.json on completion.
  - >-
    Script is wired into pre_ci.sh fast-checks tier (no DB required).

proof_limitations:
  - >-
    Cannot detect all possible capability laundering phrasings — covers documented
    blocked patterns only; novel phrasings require future pattern additions.
  - >-
    Does not validate intent field semantic correctness — only pattern matching
    against blocked strings.
  - >-
    Phase: '2' check for ratification artifact only activates after
    PHASE2-RATIFICATION.md is created; before that, the check is skipped gracefully.

depends_on: []
blocks:
  - TSK-P2-GOV-CONV-009

touches:
  - scripts/audit/verify_phase_claim_admissibility.sh
  - scripts/dev/pre_ci.sh
  - .github/workflows/ci.yml
  - evidence/phase2/phase_claim_admissibility.json
  - tasks/TSK-P2-GOV-CONV-008/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-008/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-008/EXEC_LOG.md

deliverable_files:
  - scripts/audit/verify_phase_claim_admissibility.sh
  - evidence/phase2/phase_claim_admissibility.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-008/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-008/EXEC_LOG.md

regulated_surface_compliance:
  enabled: true
  approval_workflow: stage_a_stage_b
  stage_a_required_before_edit: true
  regulated_paths:
    - scripts/dev/pre_ci.sh
    - .github/workflows/ci.yml

invariants:
  - INV-GOV-CONV-008

work:
  - >-
    [ID gov_conv_008_w01] Create Stage A approval artifact before editing
    pre_ci.sh or ci.yml. Validate against approval_metadata.schema.json.
    Record in EXEC_LOG.md.
  - >-
    [ID gov_conv_008_w02] Write scripts/audit/verify_phase_claim_admissibility.sh
    with two check tiers:
    TIER 1 — Numeric admissibility: (a) phase field must be in {0, 1, 2, 3, 4};
    (b) if phase is 3 or 4, exit 1 with error phase_not_open; (c) if phase is 2
    and approvals/*/PHASE2-RATIFICATION.md exists, check task for blocking semantic
    patterns (if ratification file does not exist yet, skip phase: '2' check
    gracefully); (d) reject any phase value matching wave pattern ([Ww][0-9]+).
    TIER 2 — Semantic admissibility: scan title, intent, and notes fields of each
    meta.yml for these blocked strings: "Phase complete", "Phase ready", "Phase done",
    "Phase aligned", "Phase 3 ready", "Phase 4 aligned", "Phase 2 complete",
    "cross-domain federation" (in phase 2 tasks), "large-scale autonomous adaptation"
    (in phase 2 tasks). Exit 1 with pattern name on any match. Emit
    evidence/phase2/phase_claim_admissibility.json with counts of tasks scanned,
    violations found, violation details.
  - >-
    [ID gov_conv_008_w03] Wire into pre_ci.sh fast-checks tier (before any DB
    check). Wire into CI workflow.
  - >-
    [ID gov_conv_008_w04] Run the script against the current task set. Record the
    result in EXEC_LOG.md. If any existing task violates, record violation details
    in EXEC_LOG.md — do NOT patch tasks in this task (that is TSK-P2-GOV-CONV-009).

acceptance_criteria:
  - >-
    [ID gov_conv_008_w01] Stage A approval artifact exists and validates before
    editing pre_ci.sh or ci.yml.
  - >-
    [ID gov_conv_008_w02] Script exits non-zero when given a fixture meta.yml with
    phase: '3'. Script exits non-zero when given a fixture with "Phase complete"
    in the intent field. Script exits non-zero when given a fixture with phase: 'W8'.
  - >-
    [ID gov_conv_008_w03] pre_ci.sh contains a call to verify_phase_claim_admissibility.sh
    before any database check line.
  - >-
    [ID gov_conv_008_w04] evidence/phase2/phase_claim_admissibility.json exists
    with tasks_scanned >= 80 and all required fields populated.

negative_tests:
  - id: TSK-P2-GOV-CONV-008-N1
    description: >-
      Create a fixture meta.yml with phase: '3'. Run verify_phase_claim_admissibility.sh.
      It must exit non-zero with error phase_not_open. This proves numeric
      admissibility enforcement is active for unopened phases.
    required: true
  - id: TSK-P2-GOV-CONV-008-N2
    description: >-
      Create a fixture meta.yml with phase: '2' and intent field containing the
      string "Phase 2 complete". Run the script. It must exit non-zero identifying
      the semantic violation. This proves semantic admissibility enforcement catches
      capability overclaims, not just numeric phase errors.
    required: true
  - id: TSK-P2-GOV-CONV-008-N3
    description: >-
      Create a fixture meta.yml with phase: 'W8'. Run the script. It must exit
      non-zero with a wave-as-phase rejection. This proves wave identifiers are
      rejected as phase values.
    required: true

verification:
  - >-
    # [ID gov_conv_008_w02] [ID gov_conv_008_w04]
    bash scripts/audit/verify_phase_claim_admissibility.sh > evidence/phase2/phase_claim_admissibility.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-008
    --evidence evidence/phase2/phase_claim_admissibility.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/phase_claim_admissibility.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - tasks_scanned
      - numeric_violations
      - semantic_violations
      - violation_details

failure_modes:
  - >-
    Script validates phase numbers only, not semantic content — capability
    laundering via better wording passes undetected => CRITICAL_FAIL
  - >-
    Script exits 0 on phase: '3' task — unopened phase access unblocked => CRITICAL_FAIL
  - >-
    Stage A approval not created before editing regulated surfaces => BLOCKED
  - >-
    tasks_scanned < 80 in evidence — partial scan; violations may be missed => FAIL
  - >-
    Script not wired into pre_ci.sh before DB checks — defeats the fast-check tier
    purpose => FAIL
  - >-
    Evidence file missing => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/PHASE_LIFECYCLE.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-008/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-008/EXEC_LOG.md
notes: >-
  This task is independent and can start immediately. It has no prerequisite tasks.
  Three negative tests are required because the script has three distinct check
  tiers (numeric, semantic, wave-pattern). The TIER 2 semantic check for phase: '2'
  tasks is graceful before PHASE2-RATIFICATION.md exists — it skips the ratification
  check but still enforces the blocked semantic pattern list. This prevents the
  script from breaking during TSK-P2-GOV-CONV-007 execution.
client: codex_cli
assigned_agent: security_guardian
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-008/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-008
# Claim Admissibility Enforcement: verify_phase_claim_admissibility.sh

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-008.ADMISSIBILITY_CREATE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create a fail-closed lint script enforcing both numeric and semantic phase claim
admissibility across all task meta.yml files. Wire into pre_ci.sh fast-checks tier
and CI. Done when: all three negative tests pass and evidence JSON emitted.

## CRITICAL: Semantic enforcement is not optional

The plan review identified that numeric-only enforcement is insufficient — people
will just use better wording. The semantic tier must detect: capability laundering
phrases, phase completion overclaims, and wave-as-phase misuse.

## Pre-conditions (independent task — no prerequisite tasks)

- scripts/audit/ directory is writable
- scripts/dev/pre_ci.sh is writable (with Stage A approval)
- .github/workflows/ci.yml is writable (with Stage A approval)

## Regulated Surface Compliance

Stage A approval MUST be created before editing pre_ci.sh or ci.yml.

## Files to Change

- scripts/audit/verify_phase_claim_admissibility.sh (CREATE)
- scripts/dev/pre_ci.sh (MODIFY — add to fast-checks tier)
- .github/workflows/ci.yml (MODIFY — add to CI)
- evidence/phase2/phase_claim_admissibility.json (EMIT via script)

## Blocked Semantic Patterns

Tier 1 (numeric): phase not in {0,1,2,3,4}, phase matching [Ww][0-9]+
Tier 2 (semantic in title/intent/notes):
  - "Phase complete"
  - "Phase ready"
  - "Phase done"
  - "Phase aligned"
  - "Phase 3 ready"
  - "Phase 4 aligned"
  - "Phase 2 complete"
  - "cross-domain federation" (in phase: '2' tasks)
  - "large-scale autonomous adaptation" (in phase: '2' tasks)

## Verification

```bash
bash scripts/audit/verify_phase_claim_admissibility.sh > evidence/phase2/phase_claim_admissibility.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-008 --evidence evidence/phase2/phase_claim_admissibility.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Rollback

Delete scripts/audit/verify_phase_claim_admissibility.sh. Revert pre_ci.sh and
ci.yml changes. Delete evidence file.
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-008/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-008
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-008.ADMISSIBILITY_CREATE_FAIL
origin_task_id: TSK-P2-GOV-CONV-008

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 9 of 10

## `tasks/TSK-P2-GOV-CONV-009/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-009
title: >-
  Run admissibility sweep against all existing TSK-P2-* task metadata and patch
  any semantic violations found by verify_phase_claim_admissibility.sh
owner_role: INVARIANTS_CURATOR
status: planned
priority: NORMAL
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  After verify_phase_claim_admissibility.sh exists (TSK-P2-GOV-CONV-008), it must
  be run against all ~90 existing TSK-P2-* task meta.yml files. Any task whose
  title, intent, or notes field contains a blocked semantic pattern must be patched.
  The ~90 TSK-P2 tasks should mostly pass since they correctly declare phase: '2'.
  However, any that use blocked phrases (Phase complete, Phase ready, etc.) in
  intent or notes must be corrected. This task is narrow: only patch violations
  found by the script; do not re-author task intent or scope.

anti_patterns:
  - >-
    Patching task intent to change its technical scope — only remove blocked
    semantic phrases; do not change what the task actually does.
  - >-
    Patching tasks preemptively without running the script first — only patch what
    the script actually flags.
  - >-
    Modifying TSK-P1-* tasks — scope is TSK-P2-* only.

out_of_scope:
  - Re-authoring task technical scope or work items
  - Patching TSK-P1-* or TSK-P0-* tasks
  - Creating new verifier scripts

stop_conditions:
  - >-
    STOP if verify_phase_claim_admissibility.sh does not exist (TSK-P2-GOV-CONV-008
    incomplete) — do not run sweep without the script.
  - >-
    STOP if a patch would change a task's work items or acceptance criteria —
    only intent/title/notes field text is in scope for semantic patches.

proof_guarantees:
  - >-
    verify_phase_claim_admissibility.sh exits 0 against all TSK-P2-* task meta.yml
    files after patches are applied.
  - >-
    Evidence JSON records tasks_scanned, violations_found, violations_patched.

proof_limitations:
  - >-
    Only catches violations in the blocked pattern list from TSK-P2-GOV-CONV-008.
    Novel phrasings not in the list are not detected.
  - >-
    Does not re-run semantic correctness of task intent beyond removing blocked phrases.

depends_on:
  - TSK-P2-GOV-CONV-008
blocks: []

touches:
  - tasks/TSK-P2-*/meta.yml
  - scripts/audit/verify_gov_conv_009.sh
  - evidence/phase2/gov_conv_009_admissibility_sweep.json
  - tasks/TSK-P2-GOV-CONV-009/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-009/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-009/EXEC_LOG.md

deliverable_files:
  - scripts/audit/verify_gov_conv_009.sh
  - evidence/phase2/gov_conv_009_admissibility_sweep.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-009/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-009/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-009

work:
  - >-
    [ID gov_conv_009_w01] Run verify_phase_claim_admissibility.sh against all
    TSK-P2-* meta.yml files and capture violations. Record each violation by task_id,
    field (title/intent/notes), and matched pattern in EXEC_LOG.md. Do not patch yet.
  - >-
    [ID gov_conv_009_w02] For each violation: remove or rephrase the blocked semantic
    string in the affected field. Do not modify work, acceptance_criteria,
    verification, or evidence fields. Record each patch in EXEC_LOG.md with before
    and after text.
  - >-
    [ID gov_conv_009_w03] Re-run verify_phase_claim_admissibility.sh after all patches.
    Confirm exit 0. Record in EXEC_LOG.md.
  - >-
    [ID gov_conv_009_w04] Write verify_gov_conv_009.sh that runs
    verify_phase_claim_admissibility.sh and confirms exit 0, then emits
    evidence/phase2/gov_conv_009_admissibility_sweep.json with tasks_scanned,
    violations_found (pre-patch), violations_patched, violations_remaining (must be 0).

acceptance_criteria:
  - >-
    [ID gov_conv_009_w01] EXEC_LOG.md records all violations found before any patch
    is applied, with task_id and field for each.
  - >-
    [ID gov_conv_009_w02] EXEC_LOG.md records before/after text for each patched field.
    No work, acceptance_criteria, verification, or evidence field is modified.
  - >-
    [ID gov_conv_009_w03] verify_phase_claim_admissibility.sh exits 0 against all
    TSK-P2-* tasks after patches.
  - >-
    [ID gov_conv_009_w04] evidence/phase2/gov_conv_009_admissibility_sweep.json
    exists with violations_remaining: 0.

negative_tests:
  - id: TSK-P2-GOV-CONV-009-N1
    description: >-
      After patching, re-introduce a blocked phrase into one of the patched tasks
      in a fixture copy. Run verify_gov_conv_009.sh against the fixture. It must
      exit non-zero with violations_remaining > 0. This proves the sweep is not a
      one-time pass but a repeatable gate.
    required: true

verification:
  - >-
    # [ID gov_conv_009_w04]
    bash scripts/audit/verify_gov_conv_009.sh > evidence/phase2/gov_conv_009_admissibility_sweep.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-009
    --evidence evidence/phase2/gov_conv_009_admissibility_sweep.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_009_admissibility_sweep.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - tasks_scanned
      - violations_found
      - violations_patched
      - violations_remaining

failure_modes:
  - >-
    Patch changes work items or acceptance criteria — modifies task scope beyond
    semantic cleanup => BLOCKED
  - >-
    violations_remaining > 0 in evidence — sweep incomplete => FAIL
  - >-
    verify_phase_claim_admissibility.sh not run before patching — patches are
    speculative, not evidence-driven => FAIL
  - >-
    Evidence file missing => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - evidence/phase2/phase_claim_admissibility.json

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-009/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-009/EXEC_LOG.md
notes: >-
  Expected result is zero or very few violations in TSK-P2-* tasks since they are
  correctly phase-scoped. The task still runs to confirm this mechanically. If zero
  violations are found, violations_found: 0 and violations_patched: 0 in evidence
  is the correct and complete result.
client: codex_cli
assigned_agent: invariants_curator
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-009/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-009
# Admissibility Sweep: Patch Existing TSK-P2 Semantic Violations

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-009.SWEEP_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Run verify_phase_claim_admissibility.sh against all TSK-P2-* meta.yml files,
patch any violations in title/intent/notes fields only, confirm exit 0 post-patch.
Done when: violations_remaining: 0 in evidence JSON.

## Verification

```bash
bash scripts/audit/verify_gov_conv_009.sh > evidence/phase2/gov_conv_009_admissibility_sweep.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-009 --evidence evidence/phase2/gov_conv_009_admissibility_sweep.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-009/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-009
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-009.SWEEP_FAIL
origin_task_id: TSK-P2-GOV-CONV-009

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# TASK 10 of 10

## `tasks/TSK-P2-GOV-CONV-010/meta.yml`

```yaml
schema_version: 1
phase: '2'
task_id: TSK-P2-GOV-CONV-010
title: >-
  Create docs/PHASE3/ and docs/PHASE4/ stub scaffolding — non-claimable, no
  implementation semantics, no runnable surfaces
owner_role: ARCHITECT
status: planned
priority: LOW
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

intent: >-
  docs/PHASE3/ and docs/PHASE4/ do not exist. Their absence creates undocumented
  drift risk: agents may attempt to create Phase-3 artifacts in ad-hoc locations.
  Stub scaffolding explicitly marks both phases as non-claimable, documents the
  required artifacts for opening, and links to PHASE_LIFECYCLE.md as the authority.
  This task must not create PHASE3_CONTRACT.md, AGENTIC_SDLC_PHASE3_POLICY.md,
  or any implementation artifact — those are required artifacts for opening, and
  creating them now would falsely imply Phase-3 is closer to opening than it is.

anti_patterns:
  - >-
    Creating PHASE3_CONTRACT.md or AGENTIC_SDLC_PHASE3_POLICY.md — these are opening
    artifacts, not scaffolding artifacts. Creating them now is premature and signals
    false readiness.
  - >-
    Adding any row to phase3_contract.yml other than the stub header — a populated
    contract implies claimable rows.
  - >-
    Creating any runnable verifier script for Phase-3 surfaces — no Phase-3
    implementation exists; a verifier would be decorative.

out_of_scope:
  - Creating PHASE3_CONTRACT.md or AGENTIC_SDLC_PHASE3_POLICY.md
  - Defining Phase-3 implementation tasks or invariants
  - Creating Phase-4 opening artifacts
  - Any modification to Phase-2 documents

stop_conditions:
  - >-
    STOP if the README stub would imply Phase-3 is deliverable or runnable —
    "NOT YET OPEN" must be prominent.
  - >-
    STOP if any file created would be referenced by verify_phase_claim_admissibility.sh
    as evidence of Phase-3 opening — stubs are explicitly not opening artifacts.

proof_guarantees:
  - >-
    docs/PHASE3/README.md exists with "NOT YET OPEN" notice and list of required
    artifacts for opening.
  - >-
    docs/PHASE3/phase3_contract.yml exists as stub with delivery_claimable: false
    and rows: [].
  - >-
    docs/PHASE4/README.md and docs/PHASE4/phase4_contract.yml exist with same pattern.
  - >-
    No PHASE3_CONTRACT.md or AGENTIC_SDLC_PHASE3_POLICY.md is created.

proof_limitations:
  - >-
    Stub existence does not prevent an agent from creating Phase-3 opening artifacts
    in the future — that prevention comes from verify_phase_claim_admissibility.sh.

depends_on: []
blocks: []

touches:
  - docs/PHASE3/README.md
  - docs/PHASE3/phase3_contract.yml
  - docs/PHASE4/README.md
  - docs/PHASE4/phase4_contract.yml
  - scripts/audit/verify_gov_conv_010.sh
  - evidence/phase2/gov_conv_010_scaffolding.json
  - tasks/TSK-P2-GOV-CONV-010/meta.yml
  - docs/plans/phase2/TSK-P2-GOV-CONV-010/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-010/EXEC_LOG.md

deliverable_files:
  - docs/PHASE3/README.md
  - docs/PHASE3/phase3_contract.yml
  - docs/PHASE4/README.md
  - docs/PHASE4/phase4_contract.yml
  - scripts/audit/verify_gov_conv_010.sh
  - evidence/phase2/gov_conv_010_scaffolding.json
  - docs/plans/phase2/TSK-P2-GOV-CONV-010/PLAN.md
  - docs/plans/phase2/TSK-P2-GOV-CONV-010/EXEC_LOG.md

invariants:
  - INV-GOV-CONV-010

work:
  - >-
    [ID gov_conv_010_w01] Create docs/PHASE3/README.md with: Phase-3 definition
    from PHASE_LIFECYCLE.md Section 8, prominent "NOT YET OPEN — Phase-3 has no
    opening artifact" notice, list of required artifacts before Phase-3 is
    delivery-claimable (PHASE3_CONTRACT.md, AGENTIC_SDLC_PHASE3_POLICY.md,
    verify_phase3_contract.sh, approvals/*/PHASE3-OPENING.md), and a link to
    PHASE_LIFECYCLE.md as the authority. Must not contain any implementation
    specification.
  - >-
    [ID gov_conv_010_w02] Create docs/PHASE3/phase3_contract.yml as a stub:
    phase: "3", phase_name: "Scaled Runtime Assurance", status: "not_open",
    delivery_claimable: false, note: "Phase-3 is not open.", rows: []
  - >-
    [ID gov_conv_010_w03] Create docs/PHASE4/README.md and docs/PHASE4/phase4_contract.yml
    with the same pattern as Phase-3 (Phase-4: Autonomous Governance Expansion,
    status: "not_open", delivery_claimable: false, rows: []).
  - >-
    [ID gov_conv_010_w04] Write verify_gov_conv_010.sh that checks all four stub
    files exist, phase3_contract.yml contains delivery_claimable: false and rows
    is empty, phase4_contract.yml same, PHASE3_CONTRACT.md does NOT exist (absence
    check — creating it would be premature), AGENTIC_SDLC_PHASE3_POLICY.md does
    NOT exist. Emit evidence/phase2/gov_conv_010_scaffolding.json.

acceptance_criteria:
  - >-
    [ID gov_conv_010_w01] docs/PHASE3/README.md exists and contains "NOT YET OPEN"
    and at least four required-artifact bullet points.
  - >-
    [ID gov_conv_010_w02] docs/PHASE3/phase3_contract.yml parses as valid YAML with
    delivery_claimable: false and rows count of 0.
  - >-
    [ID gov_conv_010_w03] docs/PHASE4/README.md and docs/PHASE4/phase4_contract.yml
    exist with same structure as Phase-3 equivalents.
  - >-
    [ID gov_conv_010_w04] verify_gov_conv_010.sh exits non-zero if PHASE3_CONTRACT.md
    is created (absence is enforced). Evidence JSON emitted with all required fields.

negative_tests:
  - id: TSK-P2-GOV-CONV-010-N1
    description: >-
      Create a fixture docs/PHASE3/PHASE3_CONTRACT.md file and run
      verify_gov_conv_010.sh. It must exit non-zero because PHASE3_CONTRACT.md
      existing signals premature Phase-3 opening preparation. This proves the
      verifier enforces the absence constraint on premature opening artifacts,
      not just the presence of stubs.
    required: true

verification:
  - >-
    # [ID gov_conv_010_w04]
    bash scripts/audit/verify_gov_conv_010.sh > evidence/phase2/gov_conv_010_scaffolding.json || exit 1
  - >-
    python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-010
    --evidence evidence/phase2/gov_conv_010_scaffolding.json || exit 1
  - >-
    RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1

evidence:
  - path: evidence/phase2/gov_conv_010_scaffolding.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - phase3_readme_exists
      - phase3_contract_stub_valid
      - phase4_readme_exists
      - phase4_contract_stub_valid
      - phase3_opening_artifacts_absent

failure_modes:
  - >-
    PHASE3_CONTRACT.md created in this task — signals false Phase-3 readiness
    and will be rejected by verify_phase_claim_admissibility.sh => CRITICAL_FAIL
  - >-
    phase3_contract.yml rows field is non-empty — signals fabricated Phase-3
    implementation claims => FAIL
  - >-
    "NOT YET OPEN" notice absent from Phase-3/4 README — future agents may
    misread stubs as partial openings => FAIL
  - >-
    Evidence file missing => FAIL

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/PHASE_LIFECYCLE.md
  - docs/PHASE2/PHASE2_CONTRACT.md

implementation_plan: docs/plans/phase2/TSK-P2-GOV-CONV-010/PLAN.md
implementation_log: docs/plans/phase2/TSK-P2-GOV-CONV-010/EXEC_LOG.md
notes: >-
  This task is independent and can start immediately. It is the lowest priority
  in the pack (LOW) because the stubs prevent drift but do not unblock any other
  task. It should run in parallel with TSK-P2-GOV-CONV-008. The unique negative
  test enforces absence rather than presence — the verifier must reject the creation
  of premature opening artifacts, not just confirm the stubs exist.
client: codex_cli
assigned_agent: architect
model: UNASSIGNED
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-010/PLAN.md`

```markdown
# PLAN — TSK-P2-GOV-CONV-010
# Phase-3/4 Non-Claimable Stub Scaffolding

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-010.SCAFFOLDING_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create four stub files (PHASE3/README.md, PHASE3/phase3_contract.yml,
PHASE4/README.md, PHASE4/phase4_contract.yml) marking both phases as not open,
non-claimable, with zero implementation rows. Verifier enforces absence of premature
opening artifacts. Done when: verify_gov_conv_010.sh passes with
phase3_opening_artifacts_absent: true.

## Verification

```bash
bash scripts/audit/verify_gov_conv_010.sh > evidence/phase2/gov_conv_010_scaffolding.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-010 --evidence evidence/phase2/gov_conv_010_scaffolding.json || exit 1
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```
```

---

## `docs/plans/phase2/TSK-P2-GOV-CONV-010/EXEC_LOG.md`

```markdown
# EXEC_LOG — TSK-P2-GOV-CONV-010
# Append-only. Never delete or modify existing entries.

failure_signature: PHASE2.GOV-CONV.TSK-P2-GOV-CONV-010.SCAFFOLDING_FAIL
origin_task_id: TSK-P2-GOV-CONV-010

| # | Timestamp | Action | Result | Notes |
|---|-----------|--------|--------|-------|
```

---

# Human Task Index Registration

The following block should be appended to `docs/tasks/PHASE2_GOVERNANCE_TASKS.md` (create if absent):

```markdown
## Governance Convergence Program — TSK-P2-GOV-CONV Series

| Task ID | Title | Owner | Depends On | Touches | Invariants | Status |
|---------|-------|-------|-----------|---------|------------|--------|
| TSK-P2-GOV-CONV-001 | Phase-2 evidence/task scan → reconciliation manifest | INVARIANTS_CURATOR | TSK-P2-PREAUTH-007-19 | scripts/audit/verify_gov_conv_001.sh, evidence/phase2/gov_conv_001_reconciliation_manifest.json | INV-GOV-CONV-001 | planned |
| TSK-P2-GOV-CONV-002 | Register INV IDs (INV-159+) in INVARIANTS_MANIFEST.yml | INVARIANTS_CURATOR | TSK-P2-GOV-CONV-001 | docs/invariants/INVARIANTS_MANIFEST.yml | INV-GOV-CONV-002 | planned |
| TSK-P2-GOV-CONV-003 | Rewrite phase2_contract.yml (remove TSK- rows, add INV rows) | INVARIANTS_CURATOR | TSK-P2-GOV-CONV-002 | docs/PHASE2/phase2_contract.yml | INV-GOV-CONV-003 | planned |
| TSK-P2-GOV-CONV-004 | Create verify_phase2_contract.sh + wire CI (non-enforcing) | SECURITY_GUARDIAN | TSK-P2-GOV-CONV-003 | scripts/audit/verify_phase2_contract.sh, .github/workflows/ci.yml, scripts/dev/pre_ci.sh | INV-GOV-CONV-004 | planned |
| TSK-P2-GOV-CONV-005 | Create PHASE2_CONTRACT.md | ARCHITECT | TSK-P2-GOV-CONV-003 | docs/PHASE2/PHASE2_CONTRACT.md | INV-GOV-CONV-005 | planned |
| TSK-P2-GOV-CONV-006 | Create AGENTIC_SDLC_PHASE2_POLICY.md | ARCHITECT | TSK-P2-GOV-CONV-003 | docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md | INV-GOV-CONV-006 | planned |
| TSK-P2-GOV-CONV-007 | Create PHASE2-RATIFICATION.md + sidecar JSON | ARCHITECT | TSK-P2-GOV-CONV-004, 005, 006 | approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md, approvals/YYYY-MM-DD/PHASE2-RATIFICATION.approval.json | INV-GOV-CONV-007 | planned |
| TSK-P2-GOV-CONV-008 | Create verify_phase_claim_admissibility.sh (numeric + semantic) | SECURITY_GUARDIAN | none | scripts/audit/verify_phase_claim_admissibility.sh, scripts/dev/pre_ci.sh, .github/workflows/ci.yml | INV-GOV-CONV-008 | planned |
| TSK-P2-GOV-CONV-009 | Admissibility sweep + patch existing TSK-P2-* violations | INVARIANTS_CURATOR | TSK-P2-GOV-CONV-008 | tasks/TSK-P2-*/meta.yml | INV-GOV-CONV-009 | planned |
| TSK-P2-GOV-CONV-010 | Create PHASE3/PHASE4 non-claimable stub scaffolding | ARCHITECT | none | docs/PHASE3/*, docs/PHASE4/* | INV-GOV-CONV-010 | planned |
```

---

# Execution Order Summary

```
TSK-P2-GOV-CONV-001  (critical path: scan)
         ↓
TSK-P2-GOV-CONV-002  (critical path: INV IDs)
         ↓
TSK-P2-GOV-CONV-003  (critical path: contract rewrite)
         ↓
TSK-P2-GOV-CONV-004  ←→ TSK-P2-GOV-CONV-005 ←→ TSK-P2-GOV-CONV-006  (parallel)
                   ↘          ↓               ↙
                    TSK-P2-GOV-CONV-007  (ratification — all three must complete first)

TSK-P2-GOV-CONV-008  (independent — start immediately)
         ↓
TSK-P2-GOV-CONV-009  (depends on 008 only)

TSK-P2-GOV-CONV-010  (independent — start immediately)
```

**Tasks 008 and 010 can be started the moment this task pack is approved — zero prerequisites.**