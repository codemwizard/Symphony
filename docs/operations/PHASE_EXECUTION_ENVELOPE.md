
```markdown
# PHASE_EXECUTION_ENVELOPE.md
# Root Control Artifact — All AI Agents Must Read This First

<!--
  MANDATORY PRE-READ FOR ALL AGENTS.
  Before generating any architecture, specification, task, plan, migration,
  verifier, or evidence artifact: read this document in full.
  
  Nothing you produce is admissible if it contradicts this envelope.
  If a task meta.yml contradicts this envelope, the envelope wins.
  If a model's training data suggests a different approach, the envelope wins.
  If a prior conversation assumed different scope, the envelope wins.
  
  This is not guidance. It is the execution contract.
-->

---

## SECTION 1 — CRITICAL STATUS CONFLICT (READ THIS FIRST)

A material conflict exists between two authoritative sources in this repository.
Every agent must understand it before acting.

### The Conflict

**Source A — Individual task meta.yml `status` fields:**

| Task | meta.yml status |
|------|----------------|
| TSK-P2-W8-DB-006 | `completed` |
| TSK-P2-W8-DB-007b | `completed` |
| TSK-P2-W8-DB-007c | `completed` |
| TSK-P2-W8-DB-009 | `completed` |
| TSK-P2-W8-SEC-002 | `completed` |

**Source B — `docs/governance/WAVE8_TASK_STATUS_MATRIX.md` (dated 2026-04-29, status: Authoritative):**

| Task | Matrix classification |
|------|----------------------|
| TSK-P2-W8-DB-006 | `Planned — Not started` |
| TSK-P2-W8-DB-007b | `Planned — Not started` |
| TSK-P2-W8-DB-007c | `Planned — Not started` |
| TSK-P2-W8-DB-009 | `Planned — Not started` |
| TSK-P2-W8-SEC-002 | `Planned — Not started` |

### Resolution

**`WAVE8_TASK_STATUS_MATRIX.md` is the authoritative governance truth for Wave 8 task status.**

The matrix's own stated classification criteria are:
> "Tasks are classified based on evidence-backed completion status, not inherited
> status text or planning claims."

The meta.yml `status` field is a planning field, not a closure certification.
A task is True-Complete only when it satisfies all nine criteria in
`WAVE8_CLOSURE_RUBRIC.md`. Writing `status: completed` in meta.yml does not
satisfy the closure rubric.

**Operative rule for all agents:**
> Treat every W8 task as its matrix classification, not its meta.yml status field.
> No W8 task other than SEC-002 (pending full rubric verification) may be
> treated as closed. GOV-001 is In Progress. All others are Planned.

---

## SECTION 2 — Current Lifecycle Phase

| Field | Value |
|-------|-------|
| **Lifecycle phase key** | `2` |
| **Phase name** | Internal Ledger Truth |
| **Phase status** | RATIFIED (governance artifacts converged 2026-05-03) |
| **Ratification artifact** | `approvals/2026-05-03/PHASE2-RATIFICATION.md` |
| **Machine contract** | `docs/PHASE2/phase2_contract.yml` |
| **Human contract** | `docs/PHASE2/PHASE2_CONTRACT.md` |
| **Policy guard** | `docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md` |
| **Contract verifier** | `scripts/audit/verify_phase2_contract.sh` |
| **Evidence namespace** | `evidence/phase2/**` |
| **Gate flag** | `RUN_PHASE2_GATES=1` |

**What ratification means and does NOT mean:**
- MEANS: Phase-2 governance artifacts are now in admissible constitutional form.
- MEANS: Phase-2 execution is the only legal execution surface.
- DOES NOT MEAN: Phase-2 runtime implementation (Wave 8) is complete.
- DOES NOT MEAN: Phase-2 can be closed. Closeout is a separate future act.
- DOES NOT MEAN: Phase-3 is open or near-open.

---

## SECTION 3 — Current Wave

| Field | Value |
|-------|-------|
| **Active wave** | **Wave 8** |
| **Wave semantics** | Sub-division of Phase-2. NOT a phase boundary. |
| **Authoritative boundary table** | `asset_batches` |
| **Wave governance ADR** | `docs/governance/WAVE8_GOVERNANCE_REMEDIATION_ADR.md` |
| **Closure rubric** | `docs/governance/WAVE8_CLOSURE_RUBRIC.md` |
| **Evidence admissibility policy** | `docs/governance/WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md` |
| **False completion catalog** | `docs/governance/WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md` |
| **Task status matrix** | `docs/governance/WAVE8_TASK_STATUS_MATRIX.md` |
| **Migration head truth table** | `docs/governance/WAVE8_MIGRATION_HEAD_TRUTH_TABLE.md` |

### Authoritative Wave 8 Task Status (from WAVE8_TASK_STATUS_MATRIX.md)

| Task | Domain | Matrix Status | Blocker |
|------|--------|--------------|---------|
| TSK-P2-W8-GOV-001 | Governance truth | **In Progress** | None — this runs first |
| TSK-P2-W8-ARCH-001 | Canonicalization contract | Planned | GOV-001 |
| TSK-P2-W8-ARCH-002 | Transition hash contract | Planned | ARCH-001 |
| TSK-P2-W8-ARCH-003 | Ed25519 signing contract | Planned | ARCH-001, ARCH-002 |
| TSK-P2-W8-ARCH-004 | Key lifecycle contract | Planned | ARCH-002, ARCH-003 |
| TSK-P2-W8-ARCH-005 | Dispatcher topology contract | Planned | ARCH-002, ARCH-003, ARCH-004 |
| TSK-P2-W8-ARCH-006 | Key management governance | Planned | ARCH-002, ARCH-003, ARCH-004, ARCH-005 |
| TSK-P2-W8-SEC-000 | Runtime/provider/evidence fidelity | Planned | ARCH-003, ARCH-006 |
| TSK-P2-W8-SEC-001 | .NET Ed25519 primitive | Planned | ARCH-003, ARCH-006, SEC-000 |
| TSK-P2-W8-SEC-002 | PostgreSQL Ed25519 extension | Planned | SEC-001 |
| TSK-P2-W8-DB-001 | Dispatcher topology migration | Planned | ARCH-005 |
| TSK-P2-W8-DB-002 | Placeholder cleanup | Planned | DB-001, ARCH-002, ARCH-003 |
| TSK-P2-W8-DB-003 | Canonical payload enforcement | Planned | ARCH-001, DB-001, DB-002 |
| TSK-P2-W8-DB-004 | Attestation hash enforcement | Planned | ARCH-002, DB-003 |
| TSK-P2-W8-DB-005 | Signer resolution surface | Planned | ARCH-003, ARCH-005 |
| TSK-P2-W8-DB-006 | Cryptographic enforcement wiring | Planned | DB-004, DB-005, SEC-001 |
| TSK-P2-W8-DB-007a | Scope enforcement | Planned | DB-006 |
| TSK-P2-W8-DB-007b | Timestamp integrity | Planned | DB-006 |
| TSK-P2-W8-DB-007c | Replay prevention | Planned | DB-006 |
| TSK-P2-W8-DB-008 | Non-crypto boundary enforcement | Planned | DB-006, DB-007a, DB-007b, DB-007c |
| TSK-P2-W8-DB-009 | Context binding / anti-transplant | Planned | DB-004, DB-006, DB-007a, DB-007b, DB-007c |
| TSK-P2-W8-QA-001 | Three-surface determinism vectors | Planned | DB-004, DB-006 |
| TSK-P2-W8-QA-002 | Full behavioral rejection matrix | Planned | DB-006–009, QA-001 |
| TSK-P2-W8-DB-007 | **SUPERSEDED** | Non-Executable | Replaced by 007a/007b/007c |
| TSK-P2-REG-001 through REG-004 | Regulatory extensions | **Scaffold** | No implementation evidence |

**Currently runnable (zero unsatisfied dependencies):**
`TSK-P2-W8-GOV-001` — and only this task.

---

## SECTION 4 — Current Phase Objective

Phase-2 establishes the **Internal Ledger Truth** foundation:

1. Deterministic internal posting-set model with event taxonomy.
2. Deterministic ledger proofs that are idempotent and tenant-safe.
3. State machine enforcement via trigger layer.
4. Data authority level enforcement via ENUM and triggers.
5. Phase-1 C# output marked non-authoritative.

**Wave 8 specific objective within Phase-2:**
Implement cryptographic attestation, transition-hash signing, context-binding
anti-transplant protection, and key-management governance — all enforced at the
`asset_batches` boundary via fail-closed PostgreSQL triggers. Every closure claim
must satisfy all nine criteria in `WAVE8_CLOSURE_RUBRIC.md`. The wave objective
is NOT complete until `TSK-P2-W8-QA-002` reaches True-Complete status.

---

## SECTION 5 — Explicit Allowed Capabilities

Only the following are permitted. Default answer for anything not listed is NO.

### 5.1 Schema and Migration Work

- Create new forward-only migrations under `schema/migrations/` when:
  - Targeting the `asset_batches` authoritative boundary.
  - Assigned to an active Wave 8 DB task whose dependencies are satisfied per §3.
  - A Stage A approval artifact exists **before** the first edit.
  - `schema/migrations/MIGRATION_HEAD` is updated in the same commit.
  - Migration is numbered sequentially after `0190` (the current head).
- Read existing migrations `0172`–`0190` for context.
- Never edit any migration numbered `0190` or below — forward-only rule.

### 5.2 Verifier Script Creation

- Create verifier scripts under `scripts/db/**`, `scripts/audit/**`,
  `scripts/security/**`, `scripts/agent/**` for active Wave 8 tasks.
- All database verifier scripts must use `$DATABASE_URL` — no hard-coded
  connection strings.
- All verifiers must produce deterministic pass/fail at `asset_batches`, not
  advisory output.
- Verifier script must exist and be executable before evidence is emitted.

### 5.3 Evidence Emission

- Emit evidence JSON to `evidence/phase2/**` only.
- Evidence must be generated by the verifier script — never hand-authored.
- Required fields for all Wave 8 evidence:
  `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`,
  `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`.
- Evidence emitted without all nine required fields is inadmissible.

### 5.4 Task and Plan Document Updates

- Create or update `tasks/TSK-P2-W8-*/meta.yml` only for active Wave 8 tasks.
- Create or update `docs/plans/phase2/TSK-P2-W8-*/PLAN.md` and `EXEC_LOG.md`.
- EXEC_LOG.md is append-only — never delete or modify existing entries.
- Update `docs/governance/WAVE8_TASK_STATUS_MATRIX.md` to True-Complete
  **only** when all nine rubric criteria are satisfied.

### 5.5 Governance Document Updates

- Update `docs/invariants/INVARIANTS_MANIFEST.yml` to append new Phase-2
  INV IDs only. Never modify ratified entries (INV-156 through INV-177).
- Update `docs/governance/WAVE8_TASK_STATUS_MATRIX.md` for status changes.
- Create governance repair artifacts under active TSK-P2-W8-GOV-001 scope.

### 5.6 Approval Artifacts

- Create Stage A approval artifacts under `approvals/YYYY-MM-DD/` before
  editing any regulated surface. Required regulated surfaces include:
  - `schema/migrations/**`
  - `scripts/db/**`
  - `scripts/security/**`
  - `scripts/dev/pre_ci.sh`
  - `.github/workflows/**`
- All approval artifacts must conform to `docs/operations/approval_metadata.schema.json`.

### 5.7 Source Extension Build

- Create or modify `src/db/extensions/wave8_crypto/**` for SEC-002 scope only.
- Build must target PostgreSQL 18 with PGXS and link against libsodium.

---

## SECTION 6 — Explicit Forbidden Capabilities

These are absolute prohibitions. They cannot be overridden by any task, agent,
model, or prior conversation.

### 6.1 Phase Boundary Violations

- `phase: '3'` or `phase: '4'` must not appear in any task meta.yml, branch name,
  commit message, approval artifact, evidence file, or documentation file.
- Do not create `docs/PHASE3/PHASE3_CONTRACT.md`.
- Do not create `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md`.
- Do not create `scripts/audit/verify_phase3_contract.sh`.
- Do not create any Phase-3 or Phase-4 opening approval artifact.
- Do not write to `evidence/phase3/**` or `evidence/phase4/**`.
- Do not use language: "Phase-3 ready", "Phase-2 complete", "Phase-4 aligned",
  "Phase done", "Phase ready" in any task field or document.

### 6.2 False Completion

- Do not mark any W8 task as True-Complete in the status matrix unless all nine
  rubric criteria in `WAVE8_CLOSURE_RUBRIC.md` are satisfied.
- Do not write `status: completed` in a task meta.yml to claim closure. That
  field alone does not satisfy the rubric. Rubric satisfaction is the closure gate.
- Do not generate or accept evidence files that were hand-authored without running
  the declared verifier script.

### 6.3 Ten Inadmissible Proof Patterns

The following proof forms are banned by `WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md`
and `WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md`. Using any of them makes the
evidence inadmissible and the task non-closeable:

| # | Pattern | Plain description |
|---|---------|------------------|
| 1 | Detached function proof | Checking a function exists without proving it fires in the `asset_batches` path |
| 2 | Grep proof | Searching source code for patterns instead of observing runtime behavior |
| 3 | Reflection-only surface proof | Using type inspection instead of actual invocation (especially SEC-000/001) |
| 4 | Toy-crypto proof | Sign/verify on arbitrary bytes without Wave 8-shaped contract payloads |
| 5 | Garbage-payload matrix fraud | Rejection matrix using inputs that fail for wrong reasons |
| 6 | Fake crypto behind real trigger | Trigger fires but crypto verification is a stub or dead code |
| 7 | Superuser-only success | Verification passes only as PostgreSQL superuser |
| 8 | Mirrored-vector fraud | Test vectors generated from the implementation being tested |
| 9 | Wrapper-only branch markers | Branch markers from wrapper, not the production SQLSTATE path |
| 10 | Advisory-only enforcement | Enforcement that warns but does not fail-close the write |

### 6.4 Contract Contamination

- Do not add rows to `docs/PHASE2/phase2_contract.yml` with `invariant_id`
  matching `^TSK-`.
- Do not add rows with `verifier` containing `run_task.sh`.
- Do not modify INV-156, INV-157, INV-158, INV-175, INV-176, or INV-177.

### 6.5 Migration Edits

- Never modify any migration numbered `0190` or below. Forward-only rule is
  absolute. Applied migrations are immutable.

### 6.6 Execution History Falsification

- Do not backdate any approval artifact.
- Do not claim the 2026-05-03 ratification proves Wave 8 is complete.
- Do not reclassify a task as True-Complete without full rubric evidence.
- Do not claim Phase-2 closeout has been triggered — it has not.

### 6.7 Role Boundary Violations

- DB_FOUNDATION agents do not edit `docs/operations/**`.
- ARCHITECT agents do not edit `schema/migrations/**`.
- SECURITY_GUARDIAN agents do not edit `docs/PHASE2/phase2_contract.yml`
  directly without a governed task.
- Tasks spanning multiple agent role boundaries must be split.

### 6.8 Out-of-Scope Work

- No new product features.
- No new external API integrations.
- No new cross-tenant data-sharing constructs.
- No architectural redesign outside the current wave task graph.

---

## SECTION 7 — Required Evidence Classes

### 7.1 Baseline (all tasks)

```
task_id          string   exact task ID from meta.yml
git_sha          string   current commit SHA at time of verification
timestamp_utc    string   ISO-8601 UTC
status           string   "pass" | "fail"
checks           array    list of check names with pass/fail result
```

### 7.2 Wave 8 Closure Fields (all W8 tasks — extends 7.1)

```
observed_paths   array    file paths inspected during verification
observed_hashes  object   {path: sha256_hex} for each observed path
command_outputs  object   {command_string: stdout/stderr} for each command run
execution_trace  array    ordered list of execution steps taken
```

### 7.3 Database Task Fields (DB_SCHEMA blast radius — extends 7.2)

```
migration_applied      string    migration number applied
boundary_table         string    must be "asset_batches"
negative_test_passed   boolean   true only if PostgreSQL rejected the invalid write
positive_test_passed   boolean   true only if PostgreSQL accepted the valid write
sqlstate_codes_used    array     registered SQLSTATE codes for each failure branch
```

### 7.4 Security Task Fields (SEC-000 specifically — extends 7.2)

```
sdk_image_digest_expected    string
sdk_image_digest_observed    string
runtime_image_digest_expected string
runtime_image_digest_observed string
dotnet_info                  string
openssl_version              string
api_invocation_proof         object
sign_verify_results          object
```

Evidence missing any required field for its class is inadmissible.
Evidence namespace: `evidence/phase2/**` only.

---

## SECTION 8 — Closure Rules

### 8.1 Wave 8 Task True-Complete (all nine must be satisfied)

A task is True-Complete only when:

1. All deliverables in `PLAN.md` exist at declared paths with declared filenames.
2. Task-specific verifier exists, is executable, and exits 0.
3. Evidence file exists with all required fields for its class (§7.1 + §7.2 minimum).
4. For DB tasks: boundary enforcement proven by PostgreSQL accepting/rejecting at `asset_batches` — not advisory, not detached.
5. For regulated surfaces: Stage A approval artifact exists **before** the first edit.
6. EXEC_LOG.md is append-only with all required remediation trace markers present.
7. No inadmissible proof pattern (§6.3) is used anywhere in the verifier or evidence.
8. Single enforcement domain: task covers exactly one domain; if a second domain emerged during implementation the task was split.
9. `WAVE8_TASK_STATUS_MATRIX.md` updated to True-Complete.

### 8.2 Wave 8 Wave-Level Closure (not yet triggered)

Wave 8 is complete when TSK-P2-W8-QA-002 reaches True-Complete. QA-002 depends
on DB-006, DB-007a, DB-007b, DB-007c, DB-008, DB-009, and QA-001.
**Current Wave 8 completion: 0 of 22 tasks True-Complete** (per WAVE8_TASK_STATUS_MATRIX.md).

### 8.3 Phase-2 Closeout (not yet triggered — requires Wave 8 wave-level closure first)

Phase-2 closes when:

1. All `required: true` rows in `docs/PHASE2/phase2_contract.yml` are `status: implemented`.
2. `RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh` exits 0.
3. All `deferred_to_phase3` rows (currently zero) are explicitly staged.
4. A Phase-2 closeout approval artifact is created.

**Current Phase-2 closeout status: NOT TRIGGERED.**

---

## SECTION 9 — Inherited Constraints

These carry forward from prior phases. No Phase-2 task may relax them.

### From Phase-0

- No runtime DDL on production paths. Schema changes only in `schema/migrations/**`.
- Forward-only migrations. Never edit applied migrations.
- `SECURITY DEFINER` functions must set `search_path = pg_catalog, public` explicitly.
- Runtime roles operate under revoke-first model — no CREATE privilege at runtime.
- Outbox attempts are append-only.

### From Phase-1

- `verify_phase1_contract.sh` must pass with `RUN_PHASE1_GATES=1` before any Phase-2 closeout claim.
- Phase-1 invariants (INV-001 through INV-155) are inherited as `phase1_prerequisite` rows.
- No weakening of any Phase-0 or Phase-1 gate.
- No direct pushes to `main` — feature branches and PRs only.

### Universal

- All verification commands use `$DATABASE_URL`. No hard-coded connection strings.
- Evidence generated by scripts, not hand-authored.
- Approval artifacts for regulated surfaces created before the first edit.
- EXEC_LOG.md files are append-only forever.

---

## SECTION 10 — Active DRDs

DRD = Debug Remediation Document (per `AGENT_ENTRYPOINT.md` §Pre-Step 1).

**`.agent/rejection_context.md` does not currently exist.**
No formal DRD lockout is in force at envelope creation time.

**Open governance repair work (active):**

| Scope | Task | Status | Effect |
|-------|------|--------|--------|
| Wave 8 governance truth reconciliation | TSK-P2-W8-GOV-001 | In Progress | All other W8 tasks blocked until this completes |
| PREAUTH-007-19 remediation sub-tasks | TSK-P2-PREAUTH-007-19-R1 through R5 | Planned | Not on Wave 8 critical path |

**If a new DRD is raised during Wave 8 execution**, register it at
`.agent/rejection_context.md` with fields: `DRD_STATUS`, `TASK_ID`,
`FAILURE_SIGNATURE`, `REPRO_COMMAND`, `DRD_SCAFFOLD_CMD`.

---

## SECTION 11 — Known Drifted Artifacts

These exist in the repo but are not authoritative for their named domain.
Do not read them as current truth.

| Artifact | Drift | Authoritative replacement |
|----------|-------|--------------------------|
| `tasks/TSK-P2-W8-DB-006/meta.yml` `status: completed` | Contradicts WAVE8_TASK_STATUS_MATRIX.md which classifies this task as Planned/Not-started | WAVE8_TASK_STATUS_MATRIX.md |
| `tasks/TSK-P2-W8-DB-007b/meta.yml` `status: completed` | Same conflict | WAVE8_TASK_STATUS_MATRIX.md |
| `tasks/TSK-P2-W8-DB-007c/meta.yml` `status: completed` | Same conflict | WAVE8_TASK_STATUS_MATRIX.md |
| `tasks/TSK-P2-W8-DB-009/meta.yml` `status: completed` | Same conflict | WAVE8_TASK_STATUS_MATRIX.md |
| `tasks/TSK-P2-W8-SEC-002/meta.yml` `status: completed` | Same conflict — SEC-002 closure requires full rubric evidence including binary build on PostgreSQL 18 | WAVE8_TASK_STATUS_MATRIX.md |
| `docs/PHASE2/phase2_contract.yml` file-level `status: "planned"` | File-level field is a stub artifact from early planning; row-level statuses are authoritative | Row-level `status` fields for INV-156 through INV-177 |
| Any evidence JSON under `evidence/phase2/tsk_p2_w8_*.json` that was emitted without a passing verifier run | Evidence files exist for all 23 W8 tasks but many tasks are Planned/Not-started per the matrix — those evidence files are pre-generated and inadmissible for closure claims | Re-run the declared verifier and regenerate when the task is actually implemented |

---

## SECTION 12 — Known Inadmissible Artifacts

These patterns or files are explicitly rejected as evidence of delivery claims.

| Pattern / File | Why Inadmissible |
|----------------|-----------------|
| Any of the ten banned proof patterns (§6.3) | Documented in WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md and WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md |
| `evidence/phase2/tsk_p2_w8_*.json` files for tasks classified Planned in the status matrix | Evidence generated before implementation is not admissible for closure. Must be regenerated after True-Complete implementation. |
| `scripts/security/probes/w8_ed25519_environment_fidelity/Wave8Ed25519Probe.csproj` | File declared in SEC-000 deliverables but does not exist on disk. The evidence file for SEC-000 is therefore inadmissible for closure. |
| `scripts/db/verify_w8_crypto_boundary_enforcement.sql` | Declared in DB-006 deliverables but does not exist on disk. DB-006 rubric criterion 1 (deliverable completeness) is not met. |
| Any task meta.yml `status: completed` for a task the matrix classifies as Planned | meta.yml status field is not a rubric-satisfying closure claim |
| Any evidence under `evidence/phase3/**` or `evidence/phase4/**` | Namespaces not open; writing to them is inadmissible |
| Contract rows in `phase2_contract.yml` with `invariant_id` matching `^TSK-` | Task-ID schema violation; rejected by `verify_phase2_contract.sh` |
| Verifier references containing `run_task.sh` | Task-runner is not a verifier |

---

## SECTION 13 — Current Authoritative Execution Surface

### 13.1 The One Runnable Task Right Now

```
TSK-P2-W8-GOV-001  ← Complete this. It blocks everything else.
```

All 22 remaining Wave 8 tasks are gated on GOV-001 directly or transitively.
No other Wave 8 task may be executed until GOV-001 reaches True-Complete.

### 13.2 Dependency Chain After GOV-001

```
GOV-001
  └─→ ARCH-001 (canonicalization contract)
        └─→ ARCH-002 (transition hash contract)
              └─→ ARCH-003 (Ed25519 signing contract) ─┐
              └─→ ARCH-004 (key lifecycle)              │
              └─→ ARCH-005 (dispatcher topology) ─┐    │
              └─→ ARCH-006 (key mgmt governance) ──┤    │
                    └─→ SEC-000 ←─────────────────┘────┘
                          └─→ SEC-001
                                └─→ SEC-002
                                      └─→ DB-006 ←── DB-004 ←── DB-003 ←── DB-001/002
                                            ├─→ DB-007a
                                            ├─→ DB-007b
                                            ├─→ DB-007c
                                            └─→ DB-008, DB-009 ──→ QA-001 ──→ QA-002
```

### 13.3 Writable Surfaces Right Now

| Surface | Allowed operation | Condition |
|---------|-----------------|-----------|
| `tasks/TSK-P2-W8-GOV-001/**` | Implement and update | Active task |
| `docs/governance/**` | Update under GOV-001 scope | GOV-001 In Progress |
| `docs/plans/phase2/TSK-P2-W8-GOV-001/**` | PLAN.md, EXEC_LOG.md updates | Active task |
| `evidence/phase2/tsk_p2_w8_gov_001.json` | Emit via verifier | After verifier passes |
| `approvals/YYYY-MM-DD/` | Stage A artifacts for regulated edits | Before touching regulated surfaces |
| `docs/invariants/INVARIANTS_MANIFEST.yml` | Append only — no modification of existing entries | Under GOV-CONV tasks |
| `docs/PHASE2/**` | Under GOV-CONV task scope only | Per GOV-CONV task graph |

### 13.4 Non-Executable Surfaces Right Now

| Surface | Reason |
|---------|--------|
| Any TSK-P2-W8-ARCH-*, SEC-*, DB-*, QA-* task | GOV-001 not yet True-Complete |
| `schema/migrations/0191+` | No DB task is currently runnable |
| `evidence/phase3/**`, `evidence/phase4/**` | Phase-3/4 not open |
| `docs/PHASE3/**` (implementation content) | Phase-3 not open |
| Applied migrations `0001`–`0190` | Forward-only rule; immutable |
| `tasks/TSK-P2-W8-DB-007/**` | Superseded; non-executable |
| `TSK-P2-REG-001` through `TSK-P2-REG-004` | Scaffold only; no implementation evidence base |
| `.github/workflows/**` | Requires Stage A approval before any edit |
| `scripts/dev/pre_ci.sh` | Requires Stage A approval before any edit |

---

## SECTION 14 — Document Precedence Chain

When any source contradicts this envelope, apply this order (1 = highest):

1. **This file** (`PHASE_EXECUTION_ENVELOPE.md`) — root control artifact
2. `docs/operations/AI_AGENT_OPERATION_MANUAL.md` — apex agent behavior authority
3. `docs/operations/PHASE_LIFECYCLE.md` — lifecycle taxonomy authority
4. `docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md` — Phase-2 policy guard
5. `docs/governance/WAVE8_TASK_STATUS_MATRIX.md` — authoritative W8 task status
6. `docs/governance/WAVE8_CLOSURE_RUBRIC.md` — W8 closure criteria
7. `docs/governance/WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md` — admissibility rules
8. `docs/PHASE2/phase2_contract.yml` — machine contract (row-level fields)
9. `approvals/2026-05-03/PHASE2-RATIFICATION.md` — ratification record
10. Individual `tasks/TSK-P2-W8-*/meta.yml` — task-level planning fields

**A task meta.yml `status` field never overrides the WAVE8_TASK_STATUS_MATRIX.md.**

---

## SECTION 15 — Agent Operating Rules

### Before starting any session

1. Read this file in full.
2. Check §10 for active DRDs. If `.agent/rejection_context.md` exists, resolve
   it before any implementation work.
3. Confirm the task you are about to run is in §13.2 and its dependencies are
   satisfied per the matrix.
4. Confirm the surfaces you will touch are in §13.3, not §13.4.

### Before writing any file

1. Check §6 — is this operation forbidden?
2. If touching a regulated surface, create Stage A approval artifact first.
3. Confirm evidence will satisfy §7 for its class.

### Before claiming a task complete

1. Satisfy all nine rubric criteria in §8.1.
2. Confirm no inadmissible proof pattern from §6.3 was used.
3. Confirm evidence contains all fields required by §7 for its class.
4. Update `WAVE8_TASK_STATUS_MATRIX.md` to True-Complete.
5. Do not change `meta.yml status` to `completed` as a substitute for rubric satisfaction.

### When uncertain whether an action is permitted

Default answer: **NO**.
Consult §5 (allowed) then §6 (forbidden).
If still uncertain, stop and ask the human operator.

### For architecture or design work

Do not ask: *"What is the best architecture for Symphony?"*
Ask instead: *"What is the next admissible capability increment inside the
current Wave 8 boundary that does not violate Phase-2 contract invariants?"*

### For task generation

Do not split a TDD into tickets.
Generate tasks from: phase contract delta → wave boundary → evidence-bearing
task pack. Every task must answer: what contract clause does this satisfy,
what evidence proves it, what makes it inadmissible?

---

## SECTION 16 — Envelope Maintenance

This document is maintained by the **human operator only**.

An AI agent may **not** autonomously update this envelope to expand its own
permissions. Any change to §5 (allowed) or §6 (forbidden) requires a human
decision and a corresponding approval artifact.

Update this envelope when:

- GOV-001 reaches True-Complete (update §3 task table, §13.1, §13.2).
- A new task reaches True-Complete (update §3 table, §13.2).
- A new DRD is opened or closed (update §10).
- A drifted artifact is corrected (update §11).
- A new inadmissible artifact pattern is discovered (update §12).
- Phase-2 closeout is triggered (major update across all sections).
- A new wave begins within Phase-2 (full envelope revision).

---

*Envelope created: 2026-05-04*  
*Phase confirmed from: `approvals/2026-05-03/PHASE2-RATIFICATION.md`*  
*Wave status confirmed from: `docs/governance/WAVE8_TASK_STATUS_MATRIX.md`*  
*Task deliverables confirmed from: direct file system verification of all 23 `tasks/TSK-P2-W8-*/meta.yml` files*  
*Migration head confirmed from: `schema/migrations/0190_wave8_cryptographic_enforcement_full_restore.sql`*  
*Current phase: `2` — Internal Ledger Truth*  
*Current wave: Wave 8*  
*Next required action: Complete TSK-P2-W8-GOV-001 to True-Complete standard before any other W8 task begins*
```