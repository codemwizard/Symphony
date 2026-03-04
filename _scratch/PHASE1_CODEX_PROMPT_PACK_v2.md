# Phase-1 Codex Prompt Pack (Authoritative v2)
<!-- docs/PHASE1/CODEX_PROMPT_PACK.md -->

**Version:** 2026-02-13 rev2 | **Replaces:** v1 (2026-02-13)
**Ground truth source:** `repomix-output.xml` direct read + external assessment cross-checked

> **Global instruction (paste into EVERY Codex thread):**
>
> - Do **NOT** invent new invariant IDs.
> - Do **NOT** change existing gate IDs or remove/relax any Phase-0 required gates.
> - Treat `docs/invariants/INVARIANTS_MANIFEST.yml` and `docs/control_planes/CONTROL_PLANES.yml` as the sole truth holders.
> - Every invariant promoted `roadmap → implemented` requires all ten steps in the **Canonical Promotion Sequence** (Section 2) to be complete. No partial promotions.
> - Evidence files MUST conform to `docs/architecture/evidence_schema.json` (required fields: `check_id`, `timestamp_utc`, `git_sha`, `status ∈ {PASS,FAIL,SKIPPED}`). Phase-1 evidence under `evidence/phase1/` must also pass schema validation.
> - Every task touching a **regulated surface** (schema/migrations/**, scripts/audit/**, scripts/db/**, docs/invariants/**, docs/control_planes/**, evidence/**, .github/workflows/**) must have `docs/plans/phase1/<TASK_ID>/PLAN.md` + `EXEC_LOG.md` and an approval metadata artifact (INV-105, TSK-P1-002 contract).
> - New SQLSTATEs raised by Phase-1 triggers must be registered in `docs/contracts/sqlstate_map.yml` (INV-061). Failing to do so causes `check_sqlstate_map_drift.sh` (INT-G04) to fail.
> - New migrations must follow expand-first discipline: `ADD COLUMN` requires a DEFAULT, no `ADD COLUMN NOT NULL` without default, no `DROP COLUMN`, no `CLEANUP` marker (INV-097). Concurrent indexes require `symphony:no_tx` marker (INV-041/042).
> - New gates added to `CONTROL_PLANES.yml` are checked by `verify_control_planes_drift.sh` (INT-G15). Scripts referenced in CONTROL_PLANES.yml must exist and be executable or the drift gate fails.
> - Always run `scripts/dev/pre_ci.sh` at the end; fix all failures before committing.

---

## 1. Definition of Done — Phase-1

Phase-1 is **complete** when ALL of the following hold:

| Check | Criterion | Enforced By |
|---|---|---|
| INV-114 | `status: implemented` in manifest; all ten promotion steps done | INV-044, INT-G25 |
| INV-115 | `status: implemented` in manifest; all ten promotion steps done | INV-044, INT-G26 |
| INV-116 | `status: implemented` in manifest; all ten promotion steps done | INV-044, INT-G27 |
| INV-111/112/113 | `status: implemented`; docs aligned | INV-044, INT-G01 |
| INV-044 | `check_docs_match_manifest.py` passes (manifest ↔ doc pair in sync) | Auto in ordered checks |
| INV-061 | All Phase-1 SQLSTATEs in `sqlstate_map.yml` | INT-G04 (`check_sqlstate_map_drift.sh`) |
| INV-072 | No CONTROL_PLANES drift | INT-G15 (`verify_control_planes_drift.sh`) |
| INV-077 | Phase-1 evidence passes schema validation | INT-G01 extended to `evidence/phase1/` |
| INV-080 | Phase-1 contract semantics enforced | INT-G28 (`verify_phase1_contract.sh`, new) |
| INV-105 | Every regulated-surface task has plan/exec-log + approval metadata | GOV-G02 |
| TSK-P1-001..004 | All OPEN tasks closed with evidence | evidence/phase1/ |
| Phase-0 gates | No regression; `scripts/dev/pre_ci.sh` exits 0 | All Phase-0 gates |
| INV-039 / INV-048 | Explicitly deferred (not Phase-1 scope); roadmap status unchanged | — |

---

## 2. Canonical Promotion Sequence (All Ten Steps)

Every invariant promoted from `roadmap` → `implemented` requires these ten steps. No step may be skipped. Present this checklist in every invariant task's PLAN.md.

```
[ ] 1. Schema: forward-only migration (expand-first, INV-097 compliant; concurrent indexes use symphony:no_tx)
[ ] 2. Verifier: deterministic script in scripts/db/ or scripts/audit/ (PASS/FAIL/SKIPPED only, no silent success)
[ ] 3. Evidence: conforms to evidence_schema.json (check_id, timestamp_utc, git_sha, status); written to evidence/phase1/<filename>.json
[ ] 4. SQLSTATE: any new error codes registered in docs/contracts/sqlstate_map.yml (INV-061 / INT-G04)
[ ] 5. Control-plane gate: new gate_id declared in CONTROL_PLANES.yml under correct plane (INT for DB/structural; SEC for security; GOV for governance)
[ ] 6. Ordered-check wiring: verifier called from scripts/db/verify_invariants.sh or scripts/audit/run_phase0_ordered_checks.sh (+ pre-flight existence check)
[ ] 7. Evidence schema validation: validate_evidence_schema.sh (INT-G01) must cover evidence/phase1/ path (or a parallel Phase-1 schema validator covers it)
[ ] 8. Remediation-trace compliance: PLAN.md + EXEC_LOG.md with required markers (failure_signature, origin_task_id, verification_commands_run, final_status); approval metadata artifact (INV-105)
[ ] 9. Manifest promotion: INVARIANTS_MANIFEST.yml status → implemented; verification field populated with script + gate + evidence path
[ ] 10. Roadmap/implemented doc update: INVARIANTS_IMPLEMENTED.md entry added; INVARIANTS_ROADMAP.md entry removed; INVARIANTS_QUICK.md regenerated; INV-044 passes
```

---

## 3. Critical Repo Reality

### Invariants status and gap map

| Invariant | Manifest status | Gate wired? | Script exists? | Evidence path | Gap |
|---|---|---|---|---|---|
| INV-111 (BoZ seat) | `roadmap` ← wrong | INT-G23 ✅ | `scripts/db/verify_boz_observability_role.sh` ✅ | `evidence/phase0/boz_observability_role.json` | Manifest + docs only |
| INV-112 (PII lint) | `roadmap` ← wrong | SEC-G17 ✅ | `scripts/audit/lint_pii_leakage_payloads.sh` ✅ | `evidence/phase0/pii_leakage_payloads.json` | Manifest + docs only |
| INV-113 (anchor hooks) | `roadmap` ← wrong | INT-G24 ✅ | `scripts/db/verify_anchor_sync_hooks.sh` ✅ | `evidence/phase0/anchor_sync_hooks.json` | Manifest + docs only |
| INV-114 (finality) | `roadmap` | none | none | none | Full implementation |
| INV-115 (PII decoupling) | `roadmap` | none | none | none | Full implementation |
| INV-116 (rail sequence) | `roadmap` | none | none | none | Full implementation |
| INV-039 (fail-closed DB) | `roadmap` | none | none | none | Deferred; not Phase-1 |
| INV-048 (proxy resolution) | `roadmap` | none | `verify_proxy_resolution_invariant.sh` referenced | none | Deferred; not Phase-1 |

**For INV-111/112/113:** All three promotion steps except #9 and #10 (manifest + docs) are already done. The scripts exist, gates are wired in CONTROL_PLANES.yml and `verify_invariants.sh`, evidence is emitted. The only gap is the manifest status field and doc alignment. P2 below verifies this before promoting.

### Existing schema surface for INV-114/115/116

From **migration 0020**: `ingress_attestations`, `payment_outbox_pending`, `payment_outbox_attempts` all have `nfs_sequence_ref TEXT NULL`, `correlation_id UUID NULL`, `upstream_ref TEXT NULL`, `downstream_ref TEXT NULL`.

From **migration 0023**: `evidence_packs` has `anchor_ref`, `anchor_type`, `anchored_at`, and signature columns (nullable hooks).

**NOT YET EXISTING** (must be added expand-first):
- `instruction_state` / `finalized_at` / `reversal_of_outbox_id` — needed for INV-114
- `pii_vault` table / `pii_purge_requests` table / `pii_token` / `identity_hash` on attestations — needed for INV-115
- `rail_participant_id` / `rail_profile` — needed for INV-116 uniqueness constraint (per ADR-0014)

### Control-plane gate ceiling (do not collide)

| Plane | Owner | Last gate | Next available |
|---|---|---|---|
| security | SECURITY_GUARDIAN | SEC-G17 | SEC-G18 |
| integrity | INVARIANTS_CURATOR | INT-G24 | INT-G25 |
| governance | COMPLIANCE_MAPPER | GOV-G03 | GOV-G04 |

**Phase-1 gate reservations:**
- `INT-G25` → INV-114 (instruction finality verifier)
- `INT-G26` → INV-115 (PII decoupling verifier)
- `INT-G27` → INV-116 (rail sequence verifier)
- `INT-G28` → Phase-1 contract verifier (`verify_phase1_contract.sh`)

### Evidence schema validation scope (gap to fix)

`validate_evidence_schema.sh` (INT-G01) currently scans **only** `evidence/phase0/*.json`. Phase-1 evidence under `evidence/phase1/` is NOT currently schema-validated. This must be fixed in P3 (Phase-1 contract task) by extending the schema validator or adding a parallel Phase-1 validation step.

### Tasks already open (do not duplicate)

| Task | Status | Note |
|---|---|---|
| TSK-P1-001 | OPEN | Agent governance docs |
| TSK-P1-002 | OPEN | Approval metadata harness — **hard prerequisite for P4/P5/P6** |
| TSK-P1-003 | OPEN | `verify_agent_conformance.sh` — script partially implemented; needs closing |
| TSK-P1-004 | OPEN | `VERIFY_AGENT_CONFORMANCE_SPEC.md` |

### Deferred invariants (not Phase-1 scope, must be documented)

- **INV-039** (`roadmap`, severity P1): "Fail-closed under DB exhaustion" — `TODO: define and wire`. Formally out of scope for Phase-1. Acknowledge in Phase-1 contract as deferred.
- **INV-048** (`roadmap`, severity P1): "Proxy/Alias resolution required before dispatch" — verifier stub referenced (`verify_proxy_resolution_invariant.sh`) but not wired. Formally out of scope for Phase-1.

Both must be listed in Phase-1 contract as `deferred_to_phase2`.

---

## 4. Prompt Pack — Ordered Execution

---

### P0 — Truth-Sync Audit (read-only, no code)

> **Purpose:** Confirm the exact repo state before any code is written. Prevents re-implementing what exists.

**Codex prompt:**

```
You are auditing Phase-1 readiness. Read ONLY these files (no implementation):

- docs/invariants/INVARIANTS_MANIFEST.yml
- docs/invariants/INVARIANTS_IMPLEMENTED.md
- docs/invariants/INVARIANTS_ROADMAP.md
- docs/control_planes/CONTROL_PLANES.yml
- scripts/audit/run_phase0_ordered_checks.sh
- scripts/audit/validate_evidence_schema.sh          ← note: scans evidence/phase0/ only
- scripts/db/verify_invariants.sh                    ← check which verifiers are called
- scripts/db/verify_boz_observability_role.sh
- scripts/db/verify_anchor_sync_hooks.sh
- scripts/audit/lint_pii_leakage_payloads.sh
- schema/migrations/ (list filenames; read 0020–0027 contents)
- docs/architecture/evidence_schema.json             ← required evidence fields
- docs/decisions/ADR-0012-payment-finality-model-deferred.md
- docs/decisions/ADR-0013-zdpa-pii-decoupling-strategy.md
- docs/decisions/ADR-0014-nfs-sequence-continuity-ipdr.md
- docs/contracts/sqlstate_map.yml                    ← current SQLSTATE ceiling

Output a table for INV-111 through INV-116 with columns:
  INV-ID | manifest status | gate in CONTROL_PLANES? | gate_id | verifier script? |
  verifier in verify_invariants.sh? | evidence path | IMPLEMENTED.md entry? | ROADMAP.md entry?

Then output:
  - Every mismatch found (e.g. manifest=roadmap but gate wired)
  - Minimum changes needed per invariant (docs-only vs full implementation)
  - Current last gate ID per control plane
  - Schema columns existing for INV-114/115/116 targets; columns MISSING
  - Current max SQLSTATE in sqlstate_map.yml
  - validate_evidence_schema.sh coverage gap (phase0 only vs phase1)

STOP. Do not implement anything. Do not propose code.
```

---

### P1 — Close TSK-P1-001 through TSK-P1-004

> **Purpose:** Complete open agent governance tasks. TSK-P1-002 (approval metadata) is a **hard prerequisite** for all regulated-surface work in P4/P5/P6.

**Plane owner:** INVARIANTS_CURATOR (for evidence/audit wiring) + SECURITY_GUARDIAN (for regulated-surface checks)

**Codex prompt:**

```
Complete TSK-P1-001 through TSK-P1-004.
Reference tasks/TSK-P1-00{1,2,3,4}/meta.yml and docs/plans/phase1/TSK-P1-001_phase1_system_rollout/PLAN.md.

For each task, apply the full ten-step promotion sequence where relevant.
Specifically:
  - Step 8 (remediation trace): create PLAN.md + EXEC_LOG.md with markers:
      failure_signature, origin_task_id, verification_commands_run, final_status
    This is required by INV-105 and caught by verify_remediation_trace.sh (GOV-G02).
  - Step 3 (evidence schema): all evidence JSON under evidence/phase1/ must contain
      check_id, timestamp_utc, git_sha, status ∈ {PASS,FAIL,SKIPPED}
    per docs/architecture/evidence_schema.json.

TSK-P1-001: Canonize agent rule sourcing.
  - Emit evidence/phase1/agent_role_mapping.json (schema-conformant).
  - Update tasks/TSK-P1-001/meta.yml status → "completed".

TSK-P1-002: Implement approval metadata harness.
  - Enhance evidence scripts to include ai_prompt_hash, model_id, approver_id
    when regulated surfaces are touched.
  - Emit evidence/phase1/approval_metadata.json (schema-conformant).
  - Self-bootstrapping: TSK-P1-002's own approval metadata may use a placeholder
    approver; subsequent tasks (P1-003+) must use the real harness.
  - Update tasks/TSK-P1-002/meta.yml status → "completed".

TSK-P1-003: Close verify_agent_conformance.sh.
  NOTE: scripts/audit/verify_agent_conformance.sh partially exists. Read it first.
  Close remaining gaps per TSK-P1-004 spec (if available) and ensure:
  - Script runs deterministically
  - Emits evidence/phase1/agent_conformance_architect.json, evidence/phase1/agent_conformance_implementer.json, and evidence/phase1/agent_conformance_policy_guardian.json (schema-conformant)
  - Wire into scripts/dev/pre_ci.sh
  - Wire into .github/workflows/invariants.yml
  CONTROL_PLANES: no new gate required for this (it is a governance-plane verifier;
  GOV-G02 via verify_remediation_trace.sh handles the trace, not a new gate).
  - Update tasks/TSK-P1-003/meta.yml status → "completed".

TSK-P1-004: Write docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md.
  - Include: failure codes, regulated surface list, evidence output schema,
    approval artifact templates.
  - Emit evidence/phase1/verify_agent_conformance_spec.json (schema-conformant).
  - Update tasks/TSK-P1-004/meta.yml status → "completed".

For TSK-P1-001 and TSK-P1-004 (which touch regulated surfaces):
  - Create docs/plans/phase1/TSK-P1-001.../PLAN.md + EXEC_LOG.md (if not exist).
  - Produce approval metadata artifact.

Run scripts/dev/pre_ci.sh. Fix all failures.
```

---

### P2 — Truth-Sync INV-111 / INV-112 / INV-113

> **Purpose:** Fix the manifest/docs mismatch. These three invariants have all promotion steps already done (gates wired, scripts exist, evidence emitted) except #9 (manifest status) and #10 (doc alignment). Verify mechanically before promoting.

**Plane owner:** INVARIANTS_CURATOR

**Codex prompt:**

```
Truth-sync INV-111, INV-112, INV-113. Read the P0 audit output first.

PRE-CHECK — before changing the manifest, verify each of these mechanically:
  For INV-111 (verify_boz_observability_role.sh / INT-G23):
    1. Script exists and is executable
    2. INT-G23 is declared in docs/control_planes/CONTROL_PLANES.yml
    3. Script is called in scripts/db/verify_invariants.sh
    4. Evidence path evidence/phase0/boz_observability_role.json is emitted when script runs
    5. Evidence file contains check_id, timestamp_utc, git_sha, status fields

  For INV-112 (lint_pii_leakage_payloads.sh / SEC-G17):
    Same five checks.

  For INV-113 (verify_anchor_sync_hooks.sh / INT-G24):
    Same five checks.

  If ANY check fails: stop, fix the gap first, then re-run this audit. Do not promote
  an invariant until ALL five checks pass.

PROMOTE (only after all pre-checks pass):

1. docs/invariants/INVARIANTS_MANIFEST.yml:
   INV-111: status → implemented
     verification: "scripts/db/verify_boz_observability_role.sh; wired via scripts/db/verify_invariants.sh; gate INT-G23; evidence: evidence/phase0/boz_observability_role.json"
   INV-112: status → implemented
     verification: "scripts/audit/lint_pii_leakage_payloads.sh; wired via scripts/audit/run_phase0_ordered_checks.sh; gate SEC-G17; evidence: evidence/phase0/pii_leakage_payloads.json"
   INV-113: status → implemented
     verification: "scripts/db/verify_anchor_sync_hooks.sh; wired via scripts/db/verify_invariants.sh; gate INT-G24; evidence: evidence/phase0/anchor_sync_hooks.json"

2. docs/invariants/INVARIANTS_IMPLEMENTED.md:
   Add entries for INV-111, INV-112, INV-113 in the established format.

3. docs/invariants/INVARIANTS_ROADMAP.md:
   Remove INV-111, INV-112, INV-113 from the roadmap section.

4. Regenerate INVARIANTS_QUICK.md (run scripts/audit/generate_invariants_quick.py if it exists;
   otherwise regenerate from manifest manually following the existing format).

5. Do NOT change CONTROL_PLANES.yml (gates already present and correct).
   Do NOT move evidence paths (phase0 evidence stays under evidence/phase0/).
   Do NOT change verifier scripts (they already work).
   Do NOT update sqlstate_map.yml (no new SQLSTATEs; these are structural checks).

Regulated surfaces touched: docs/invariants/** — requires PLAN.md + EXEC_LOG.md + approval metadata.
  Create: docs/plans/phase1/TSK-P1-005_inv111_112_113_truth_sync/PLAN.md + EXEC_LOG.md

Run scripts/dev/pre_ci.sh. Fix all failures.
Expected to pass: check_docs_match_manifest.py (INV-044) and verify_control_planes_drift.sh (INT-G15).
```

---

### P3 — Phase-1 Contract + Evidence Schema Extension

> **Purpose:** (1) Declare Phase-1 contract formally with enforcement gate. (2) Extend evidence schema validation to cover `evidence/phase1/`. Without these, Phase-1 evidence is undisciplined and INV-080 lacks a Phase-1 analog.

**Plane owner:** INVARIANTS_CURATOR (contract gate) + COMPLIANCE_MAPPER (Phase-1 contract doc)

**Codex prompt:**

```
Create Phase-1 contract infrastructure. This task has two parts.

PART A — Extend evidence schema validation to evidence/phase1/

The existing validate_evidence_schema.sh (INT-G01) scans evidence/phase0/ only.
Phase-1 evidence must also be schema-validated.

Option 1 (preferred): Extend validate_evidence_schema.sh to scan both evidence/phase0/ and
evidence/phase1/, emitting a combined evidence/phase0/evidence_validation.json.
Option 2: Create scripts/audit/validate_phase1_evidence_schema.sh scoped to evidence/phase1/,
wiring it into run_phase0_ordered_checks.sh (no new gate needed if under existing INT-G01 scope;
otherwise add INT-G25-alt).

Whichever option: all evidence/phase1/*.json must conform to docs/architecture/evidence_schema.json.

PART B — Phase-1 contract file + enforcement gate

Create docs/PHASE1/phase1_contract.yml:
  - For INV-114, INV-115, INV-116: each entry has:
      invariant_id, status: pending, evidence_required: false (until verifier wired),
      evidence_paths: [list of what they WILL be, under evidence/phase1/],
      gate_id: reserved (INT-G25 / INT-G26 / INT-G27),
      verifier_script: (what it will be named)
  - For INV-039, INV-048: status: deferred_to_phase2
  - For INV-111, INV-112, INV-113: status: phase0_prerequisites with evidence/phase0/ paths

Create docs/PHASE1/PHASE1_CONTRACT.md:
  - Contract purpose and scope boundary
  - Evidence path convention (evidence/phase1/ for runtime; evidence/phase0/ for structural)
  - Promotion rule (ten-step sequence from CODEX_PROMPT_PACK.md)
  - Phase boundary: Phase-0 gates frozen; Phase-1 adds new gates only
  - Gate ID reservations: INT-G25..INT-G28
  - Deferred invariants: INV-039, INV-048

Create scripts/audit/verify_phase1_contract.sh:
  - Gate ID: INT-G28
  - Plane: integrity (INVARIANTS_CURATOR)
  - Checks:
      1. docs/PHASE1/phase1_contract.yml exists and is valid YAML
      2. All gate_ids referenced in phase1_contract.yml are declared in CONTROL_PLANES.yml
         (or are reserved-not-yet-wired if evidence_required: false)
      3. All evidence_paths with evidence_required: true have the actual file present
      4. All evidence files present pass evidence_schema.json validation
      5. No invariant in phase1_contract.yml has status: pending AND evidence_required: true
         simultaneously (would indicate a wiring gap)
  - Evidence: evidence/phase1/phase1_contract_status.json (schema-conformant)
  - Status: SKIPPED is allowed for evidence_required: false entries; PASS requires all
    evidence_required: true entries to be present and valid

Wire verify_phase1_contract.sh into:
  - scripts/audit/run_phase0_ordered_checks.sh (after INT-G03 verify_phase0_contract.sh)
  - scripts/dev/pre_ci.sh

Add to CONTROL_PLANES.yml under integrity.required_gates:
  - gate_id: INT-G28
    owner: INVARIANTS_CURATOR
    script: scripts/audit/verify_phase1_contract.sh
    evidence: evidence/phase1/phase1_contract_status.json

Run scripts/dev/pre_ci.sh. Fix all failures.
Verify INT-G15 (verify_control_planes_drift.sh) still passes after adding INT-G28.
Create docs/plans/phase1/TSK-P1-006_phase1_contract/PLAN.md + EXEC_LOG.md + approval metadata.
Add tasks/TSK-P1-006/meta.yml.
```

---

### P4 — INV-114: Instruction Finality + Reversal-Only Semantics

> **Purpose:** Payment finality enforcement per ADR-0012. DB-first; reversal as compensating instruction only.

**Plane owner:** INVARIANTS_CURATOR (DB verifier, INT-G25)

**Codex prompt:**

```
Implement INV-114 end-to-end. Apply all ten steps of the Canonical Promotion Sequence.
Read ADR-0012 (docs/decisions/ADR-0012-payment-finality-model-deferred.md) before writing code.
Prerequisite: TSK-P1-002 complete (approval metadata harness); P3 complete (Phase-1 contract).

STEP 1 — Schema (INV-097 compliant; expand-first)

Create schema/migrations/0028_instruction_finality_state.sql:
  - ADD COLUMN IF NOT EXISTS instruction_state TEXT NOT NULL DEFAULT 'PENDING'
    to payment_outbox_pending.
    CHECK (instruction_state IN ('PENDING','SUBMITTED','SETTLED','FINALIZED','REVERSED'))
  - ADD COLUMN IF NOT EXISTS finalized_at TIMESTAMPTZ NULL to payment_outbox_pending.
  - ADD COLUMN IF NOT EXISTS reversal_of_outbox_id UUID NULL
    REFERENCES public.payment_outbox_pending(outbox_id) to payment_outbox_pending.
  - ADD COLUMN IF NOT EXISTS reversal_reason TEXT NULL to payment_outbox_pending.
  - Create trigger trg_deny_finalized_instruction_mutation:
      BEFORE UPDATE OR DELETE ON payment_outbox_pending FOR EACH ROW
      WHEN (OLD.instruction_state = 'FINALIZED')
      RAISE EXCEPTION SQLSTATE 'P7003' MESSAGE 'finality violation'
  - CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_outbox_pending_finalized
      ON payment_outbox_pending(instruction_id) WHERE instruction_state = 'FINALIZED';
  - symphony:no_tx marker required for concurrent index.

STEP 2 — Verifier (scripts/db/verify_instruction_finality_invariant.sh)

  - Gate ID: INT-G25 (integrity plane, INVARIANTS_CURATOR)
  - Evidence: evidence/phase1/instruction_finality_invariant.json
  - Required evidence fields: check_id, timestamp_utc, git_sha, status ∈ {PASS,FAIL,SKIPPED}
    plus: gate_id, invariant_id, checked_objects, errors
  - Checks (all must pass for status=PASS):
    1. instruction_state column exists with correct type + check constraint
    2. finalized_at column exists
    3. Trigger trg_deny_finalized_instruction_mutation exists
    4. Partial index idx_outbox_pending_finalized exists and is valid (not invalid)
    5. reversal_of_outbox_id column exists
  - Emit evidence via python3 json.dumps() + Path.write_text(); never use SKIPPED except
    if DATABASE_URL is unset (integration-unavailable mode).

STEP 3 — SQLSTATE registry (INV-061 / INT-G04)

Add to docs/contracts/sqlstate_map.yml:
  - code: P7003
    name: SYMPHONY_FINALITY_VIOLATION
    meaning: "Attempted mutation of a finalized instruction"
    raised_by: trg_deny_finalized_instruction_mutation
    introduced_in_phase: 1
    invariant: INV-114

Run check_sqlstate_map_drift.sh (INT-G04) to confirm it passes after this addition.

STEP 4 — Control-plane gate

Add to docs/control_planes/CONTROL_PLANES.yml under integrity.required_gates:
  - gate_id: INT-G25
    invariant_id: INV-114
    owner: INVARIANTS_CURATOR
    script: scripts/db/verify_instruction_finality_invariant.sh
    evidence: evidence/phase1/instruction_finality_invariant.json
    mode: both

Run verify_control_planes_drift.sh (INT-G15) to confirm it passes.

STEP 5 — Ordered-check wiring

In scripts/db/verify_invariants.sh:
  - Add existence check in pre-flight block:
      [[ -x "$SCRIPT_DIR/verify_instruction_finality_invariant.sh" ]] || { echo "❌ missing verify_instruction_finality_invariant.sh"; exit 2; }
  - Add execution:
      echo "🔒 Verifying instruction finality invariant (INV-114)..."
      "$SCRIPT_DIR/verify_instruction_finality_invariant.sh"

STEP 6 — Tests (scripts/db/tests/test_instruction_finality.sh)

  - Test 1: transition PENDING → FINALIZED succeeds.
  - Test 2: UPDATE on FINALIZED row raises SQLSTATE P7003.
  - Test 3: DELETE on FINALIZED row raises SQLSTATE P7003.
  - Test 4: reversal instruction created as NEW row with reversal_of_outbox_id set;
    original row remains FINALIZED.
  - Test 5: FINALIZED row visible to boz_auditor role (SELECT only).
  - Emit evidence/phase1/instruction_finality_runtime.json (schema-conformant).

STEP 7 — Evidence schema validation

Confirm validate_evidence_schema.sh (or the Phase-1 extension from P3) covers
evidence/phase1/instruction_finality_invariant.json.
Run it and confirm PASS.

STEP 8 — Remediation trace

Create docs/plans/phase1/TSK-P1-007_inv114_instruction_finality/PLAN.md + EXEC_LOG.md with:
  failure_signature: PHASE1.INV-114.INSTRUCTION_FINALITY
  origin_task_id: TSK-P1-007
  verification_commands_run: [list all scripts run]
  final_status: PASS
Produce approval metadata artifact (requires TSK-P1-002 complete).

STEP 9 — Manifest promotion

docs/invariants/INVARIANTS_MANIFEST.yml: INV-114 → implemented
  verification: "scripts/db/verify_instruction_finality_invariant.sh; tests: scripts/db/tests/test_instruction_finality.sh; gate INT-G25; evidence: evidence/phase1/instruction_finality_invariant.json"

STEP 10 — Doc update

docs/invariants/INVARIANTS_IMPLEMENTED.md: add INV-114 entry.
docs/invariants/INVARIANTS_ROADMAP.md: remove INV-114 entry.
Regenerate INVARIANTS_QUICK.md.
Update docs/PHASE1/phase1_contract.yml: INV-114 status → completed, evidence_required → true.
Add tasks/TSK-P1-007/meta.yml.

FINAL: Run scripts/dev/pre_ci.sh. Fix all failures.
Verify: INV-044 (check_docs_match_manifest.py) passes.
Verify: INT-G04 (check_sqlstate_map_drift.sh) passes.
Verify: INT-G15 (verify_control_planes_drift.sh) passes.
Verify: INT-G28 (verify_phase1_contract.sh) passes.
```

---

### P5 — INV-115: PII Decoupling + Purge Survivability

> **Purpose:** Implement ZDPA PII isolation per ADR-0013. Evidence chain remains valid after PII purge.

**Plane owner:** SECURITY_GUARDIAN (PII surfaces) + INVARIANTS_CURATOR (DB verifier, INT-G26)

**Codex prompt:**

```
Implement INV-115 end-to-end. Apply all ten steps of the Canonical Promotion Sequence.
Read ADR-0013 (docs/decisions/ADR-0013-zdpa-pii-decoupling-strategy.md) before writing code.
Prerequisite: TSK-P1-002 complete; P3 complete.

STEP 1 — Schema (expand-first)

Create schema/migrations/0029_pii_vault_and_purge.sql:
  - CREATE TABLE IF NOT EXISTS public.pii_vault (
      vault_id UUID PRIMARY KEY DEFAULT uuid_v7_or_random(),
      tenant_id TEXT NOT NULL,
      pii_token TEXT NOT NULL UNIQUE,
      identity_hash TEXT NOT NULL,
      raw_nrc TEXT NULL,
      raw_phone TEXT NULL,
      raw_name TEXT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      purged_at TIMESTAMPTZ NULL,
      purge_request_id UUID NULL
    );
  - REVOKE ALL ON TABLE public.pii_vault FROM PUBLIC;
  - CREATE TABLE IF NOT EXISTS public.pii_purge_requests (
      purge_request_id UUID PRIMARY KEY DEFAULT uuid_v7_or_random(),
      tenant_id TEXT NOT NULL,
      requested_by TEXT NOT NULL,
      reason_code TEXT NOT NULL CHECK (reason_code IN ('CUSTOMER_REQUEST','RETENTION_EXPIRY','REGULATORY')),
      status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','IN_PROGRESS','COMPLETED','FAILED')),
      requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      completed_at TIMESTAMPTZ NULL
    );
  - REVOKE ALL ON TABLE public.pii_purge_requests FROM PUBLIC;
  - ADD COLUMN IF NOT EXISTS identity_hash TEXT NULL to ingress_attestations.
  - ADD COLUMN IF NOT EXISTS pii_token TEXT NULL to ingress_attestations.
    (expand-first hooks; NOT NULL enforcement deferred until Phase-1/2 rail adapters exist)
  - Add append-only trigger on pii_purge_requests:
      trg_deny_purge_request_mutation (BEFORE UPDATE/DELETE ON completed records;
      raise SQLSTATE P7004 SYMPHONY_PII_VAULT_VIOLATION).

SEC-G17 compatibility: The new table/column names (pii_vault, pii_token, identity_hash,
raw_nrc, raw_phone, raw_name) may trigger lint_pii_leakage_payloads.sh (SEC-G17).
For columns in schema/migrations/, add symphony:pii_ok markers to affected lines OR
verify that the SEC-G17 scan excludes schema/migrations/ (check PII_LINT_ROOTS env var;
default is "src packages scripts schema" which DOES include schema/).
If SEC-G17 fires on the new migration, add symphony:pii_ok inline markers to the raw_*
column definitions.

STEP 2 — Verifier (scripts/db/verify_pii_decoupling_hooks.sh)

  - Gate ID: INT-G26 (integrity plane, INVARIANTS_CURATOR)
  - Evidence: evidence/phase1/pii_decoupling_invariant.json
  - Required evidence fields: check_id, timestamp_utc, git_sha, status + gate_id, invariant_id, errors
  - Checks:
    1. pii_vault table exists with required columns (vault_id, pii_token, identity_hash, purged_at)
    2. pii_purge_requests table exists with status constraint
    3. REVOKE ALL from PUBLIC on pii_vault (has_table_privilege PUBLIC = false)
    4. identity_hash + pii_token columns exist on ingress_attestations
    5. Append-only trigger exists on pii_purge_requests
  - Do NOT add pii_vault to boz_auditor SELECT grants (pii_vault is out of scope for
    regulator observability; boz_auditor should NOT see raw PII).

STEP 3 — SQLSTATE registry

Add to docs/contracts/sqlstate_map.yml:
  - code: P7004
    name: SYMPHONY_PII_VAULT_VIOLATION
    meaning: "Write or mutation attempted on completed PII purge record"
    raised_by: trg_deny_purge_request_mutation
    introduced_in_phase: 1
    invariant: INV-115

Run INT-G04 to confirm PASS.

STEP 4 — Control-plane gate

Add to CONTROL_PLANES.yml under integrity.required_gates:
  - gate_id: INT-G26
    invariant_id: INV-115
    owner: INVARIANTS_CURATOR
    script: scripts/db/verify_pii_decoupling_hooks.sh
    evidence: evidence/phase1/pii_decoupling_invariant.json
    mode: both

Run INT-G15 to confirm PASS.

STEP 5 — Ordered-check wiring

Add to scripts/db/verify_invariants.sh:
  - Existence check in pre-flight block
  - Execution call for verify_pii_decoupling_hooks.sh

STEP 6 — Tests (scripts/db/tests/test_pii_decoupling.sh)

  - Test 1: insert into pii_vault; pii_token returned.
  - Test 2: identity_hash queryable without raw PII after purge.
  - Test 3: purge transitions PENDING → COMPLETED correctly.
  - Test 4: purge nulls raw_nrc/raw_phone/raw_name; identity_hash + pii_token intact.
  - Test 5: mutation of COMPLETED purge record raises P7004.
  - Test 6: boz_auditor cannot SELECT pii_vault (should get permission denied).
  - Emit evidence/phase1/pii_decoupling_runtime.json (schema-conformant).

STEP 7 — Evidence schema validation

Confirm phase1 evidence schema coverage (from P3) covers pii_decoupling_invariant.json.

STEP 8 — Remediation trace

Create docs/plans/phase1/TSK-P1-008_inv115_pii_decoupling/PLAN.md + EXEC_LOG.md.
Produce approval metadata artifact.

STEP 9 — Manifest promotion

INVARIANTS_MANIFEST.yml: INV-115 → implemented.

STEP 10 — Doc update

INVARIANTS_IMPLEMENTED.md, INVARIANTS_ROADMAP.md, INVARIANTS_QUICK.md.
Update phase1_contract.yml: INV-115 → completed.
Add tasks/TSK-P1-008/meta.yml.

FINAL: Run scripts/dev/pre_ci.sh. Fix all failures.
VERIFY SEC-G17 (lint_pii_leakage_payloads.sh) still exits 0.
VERIFY INT-G04, INT-G15, INT-G28 all pass.
VERIFY INV-044 passes.
```

---

### P6 — INV-116: Rail Truth-Anchor Sequence Continuity

> **Purpose:** Enforce non-null, unique rail sequence reference on every successful dispatch, per ADR-0014.

**Plane owner:** INVARIANTS_CURATOR (DB verifier, INT-G27)

**Codex prompt:**

```
Implement INV-116 end-to-end. Apply all ten steps of the Canonical Promotion Sequence.
Read ADR-0014 (docs/decisions/ADR-0014-nfs-sequence-continuity-ipdr.md) before writing code.
Prerequisite: TSK-P1-002 complete; P3 complete.

CRITICAL: rail_participant_id does NOT exist in any current migration.
nfs_sequence_ref TEXT NULL DOES exist (migration 0020).
Two-migration approach required (expand, then constrain).

STEP 1 — Schema (two migrations)

Migration 0030_rail_participant_id_expand.sql (symphony:no_tx for concurrent indexes):
  - ADD COLUMN IF NOT EXISTS rail_participant_id TEXT NULL to payment_outbox_pending.
  - ADD COLUMN IF NOT EXISTS rail_participant_id TEXT NULL to payment_outbox_attempts.
  - ADD COLUMN IF NOT EXISTS rail_profile TEXT NULL to payment_outbox_pending.
  - ADD COLUMN IF NOT EXISTS rail_profile TEXT NULL to payment_outbox_attempts.
  - CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_outbox_pending_rail_participant
      ON payment_outbox_pending(rail_participant_id) WHERE rail_participant_id IS NOT NULL;

Migration 0031_rail_sequence_uniqueness_enforce.sql (symphony:no_tx):
  - CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS ux_outbox_attempts_rail_sequence
      ON payment_outbox_attempts(nfs_sequence_ref, rail_participant_id)
      WHERE nfs_sequence_ref IS NOT NULL AND rail_participant_id IS NOT NULL
      AND state = 'DISPATCHED';
  - Create trigger trg_require_rail_sequence_on_dispatch:
      BEFORE INSERT OR UPDATE ON payment_outbox_attempts FOR EACH ROW
      WHEN (NEW.state = 'DISPATCHED' AND NEW.nfs_sequence_ref IS NULL AND NEW.rail_participant_id IS NOT NULL)
      RAISE EXCEPTION SQLSTATE 'P7005' MESSAGE 'rail sequence missing on dispatch'

STEP 2 — Verifier (scripts/db/verify_rail_sequence_truth_anchor.sh)

  - Gate ID: INT-G27 (integrity plane, INVARIANTS_CURATOR)
  - Evidence: evidence/phase1/rail_sequence_truth_anchor.json
  - Required evidence fields: check_id, timestamp_utc, git_sha, status + gate_id, invariant_id, errors
  - Checks:
    1. rail_participant_id column exists on payment_outbox_attempts (TEXT)
    2. nfs_sequence_ref column exists on payment_outbox_attempts (already present from mig 0020)
    3. Unique index ux_outbox_attempts_rail_sequence exists and indisvalid = true
    4. Trigger trg_require_rail_sequence_on_dispatch exists
    5. rail_profile column exists (expand-first hook)

STEP 3 — SQLSTATE registry

Add to docs/contracts/sqlstate_map.yml:
  - code: P7005
    name: SYMPHONY_RAIL_SEQUENCE_MISSING
    meaning: "Successful dispatch recorded without rail sequence truth anchor"
    raised_by: trg_require_rail_sequence_on_dispatch
    introduced_in_phase: 1
    invariant: INV-116

Run INT-G04 to confirm PASS.

STEP 4 — Control-plane gate

Add to CONTROL_PLANES.yml under integrity.required_gates:
  - gate_id: INT-G27
    invariant_id: INV-116
    owner: INVARIANTS_CURATOR
    script: scripts/db/verify_rail_sequence_truth_anchor.sh
    evidence: evidence/phase1/rail_sequence_truth_anchor.json
    mode: both

Run INT-G15 to confirm PASS.

STEP 5 — Ordered-check wiring

Add to scripts/db/verify_invariants.sh:
  - Existence check + execution for verify_rail_sequence_truth_anchor.sh.

STEP 6 — Tests (scripts/db/tests/test_rail_sequence_continuity.sh)

  - Test 1: DISPATCHED row with nfs_sequence_ref + rail_participant_id succeeds.
  - Test 2: Duplicate (nfs_sequence_ref, rail_participant_id) on DISPATCHED raises 23505.
  - Test 3: DISPATCHED row with rail_participant_id set but nfs_sequence_ref NULL raises P7005.
  - Test 4: Non-DISPATCHED row without nfs_sequence_ref is allowed (trigger scoped to DISPATCHED).
  - Emit evidence/phase1/rail_sequence_runtime.json (schema-conformant).

STEP 7 — Evidence schema validation: verify phase1 coverage from P3 includes rail_sequence_truth_anchor.json.

STEP 8 — Remediation trace

Create docs/plans/phase1/TSK-P1-009_inv116_rail_sequence/PLAN.md + EXEC_LOG.md.
Produce approval metadata artifact.

STEP 9 — Manifest promotion: INVARIANTS_MANIFEST.yml INV-116 → implemented.

STEP 10 — Doc update

INVARIANTS_IMPLEMENTED.md, INVARIANTS_ROADMAP.md, INVARIANTS_QUICK.md.
Update phase1_contract.yml: INV-116 → completed.
Add tasks/TSK-P1-009/meta.yml.

FINAL: Run scripts/dev/pre_ci.sh. Fix all failures.
VERIFY INT-G04, INT-G15, INT-G28 all pass.
VERIFY INV-044 passes.
```

---

### P7 — Phase-1 Closeout

> **Purpose:** Final validation pass — no gate regressions, no SKIPPED invariants that should be implemented, clean contract, full evidence.

**Plane owner:** COMPLIANCE_MAPPER (governance closeout) + INVARIANTS_CURATOR (drift check)

**Codex prompt:**

```
Phase-1 closeout verification. Do not introduce a Phase-1 ordered runner.
This step validates; it does not implement new functionality.

1. Control-plane completeness (INV-072 / INT-G15)

   Run verify_control_planes_drift.sh. Must PASS.
   Confirm all reserved gate IDs exist in CONTROL_PLANES.yml:
     INT-G25 (INV-114), INT-G26 (INV-115), INT-G27 (INV-116), INT-G28 (Phase-1 contract)
   Confirm all scripts referenced in CONTROL_PLANES.yml exist and are executable.

2. Evidence schema validation (INV-077 / INT-G01)

   Run validate_evidence_schema.sh (extended or parallel from P3).
   ALL files under evidence/phase0/ and evidence/phase1/ must conform to evidence_schema.json.
   No file may have status: FAIL in any evidence that should be PASS.

3. Phase-1 contract status (INV-080 / INT-G28)

   Run verify_phase1_contract.sh. Must PASS.
   All three runtime invariants (INV-114, INV-115, INV-116) must be:
     status: completed, evidence_required: true, evidence files present.
   INV-039 and INV-048 must be: status: deferred_to_phase2.

4. Manifest alignment (INV-044)

   Run check_docs_match_manifest.py. Must PASS.
   All six invariants (INV-111 through INV-116) must be:
     manifest: implemented
     INVARIANTS_IMPLEMENTED.md: entry present
     INVARIANTS_ROADMAP.md: entry absent

5. SQLSTATE registry completeness (INV-061 / INT-G04)

   Run check_sqlstate_map_drift.sh. Must PASS.
   P7003, P7004, P7005 all present with correct fields.

6. Remediation trace (INV-105 / GOV-G02)

   Run verify_remediation_trace.sh. Must PASS.
   Every regulated-surface change in Phase-1 (all ten TSK-P1-00x) must have
   a plan/exec-log in docs/plans/phase1/ with required markers.

7. CI parity (INV-081 / INT-G20)

   Run verify_ci_order.sh. Must PASS.
   Update .github/workflows/invariants.yml to include Phase-1 verifiers as optional
   post-phase0 steps:
     - scripts/db/verify_instruction_finality_invariant.sh
     - scripts/db/verify_pii_decoupling_hooks.sh
     - scripts/db/verify_rail_sequence_truth_anchor.sh
     - scripts/audit/verify_phase1_contract.sh
   These must run in the DB verify job AFTER all Phase-0 gates.
   Do NOT reorder or remove Phase-0 gate execution.

8. Pre-CI parity

   Update scripts/dev/pre_ci.sh to include Phase-1 gates with opt-in flag:
     if [[ "${RUN_PHASE1_GATES:-0}" == "1" ]]; then
       scripts/db/verify_instruction_finality_invariant.sh
       scripts/db/verify_pii_decoupling_hooks.sh
       scripts/db/verify_rail_sequence_truth_anchor.sh
       scripts/audit/verify_phase1_contract.sh
     fi
   Default RUN_PHASE1_GATES=0 to preserve Phase-0 parity.

9. Closeout evidence

   Emit evidence/phase1/phase1_closeout.json:
     {
       "check_id": "PHASE1-CLOSEOUT",
       "timestamp_utc": "<iso8601>",
       "git_sha": "<sha>",
       "status": "PASS",
       "invariants": {
         "INV-111": {"status": "implemented", "gate": "INT-G23"},
         "INV-112": {"status": "implemented", "gate": "SEC-G17"},
         "INV-113": {"status": "implemented", "gate": "INT-G24"},
         "INV-114": {"status": "implemented", "gate": "INT-G25"},
         "INV-115": {"status": "implemented", "gate": "INT-G26"},
         "INV-116": {"status": "implemented", "gate": "INT-G27"}
       },
       "deferred": ["INV-039", "INV-048"]
     }

10. Create docs/plans/phase1/TSK-P1-010_phase1_closeout/PLAN.md + EXEC_LOG.md + approval metadata.
    Add tasks/TSK-P1-010/meta.yml.

Run scripts/dev/pre_ci.sh (default flags). Must exit 0.
Run scripts/dev/pre_ci.sh with RUN_PHASE1_GATES=1. Must exit 0.
```

---

## 5. Corrections From External Assessment

The following critique claims were validated against the actual codebase. Each is assessed and addressed.

### ✅ Valid — incorporated

| Critique claim | Action taken |
|---|---|
| "Promote only after mechanical verification confirmed" | P2 now has explicit five-point pre-check before any manifest change |
| "Evidence schema validation gap (phase1 not covered)" | P3 now requires extending validate_evidence_schema.sh to evidence/phase1/ |
| "Phase-1 contract needs an enforcement gate, not just docs" | P3 adds verify_phase1_contract.sh → INT-G28 |
| "Control-plane drift wiring must be verified after adding gates" | Every Px step now includes explicit "run INT-G15" verification |
| "SQLSTATE registry update required per INV-061" | Steps 3+4 of P4/P5/P6 already had this; now formalized with INT-G04 verification call |
| "Remediation trace compliance per INV-105" | Formalized as Step 8 in Canonical Promotion Sequence with explicit marker list |
| "Ten-step promotion sequence should be canonical and explicit" | Section 2 formalizes this as the governing checklist for all tasks |
| "INV-039 and INV-048 should be formally deferred, not just omitted" | Now explicitly listed in Phase-1 contract (deferred_to_phase2) and in Section 3 gap map |
| "Evidence schema (check_id, timestamp_utc, git_sha, status) must be explicit" | Added to global instruction header and to every verifier step |

### ❌ Invalid — not incorporated (with reasoning)

| Critique claim | Why not adopted |
|---|---|
| "Gate ownership (SECURITY_GUARDIAN etc.) must be assigned per task" | Control-plane plane ownership is already declared in CONTROL_PLANES.yml per plane. Assigning per-task within prompts would duplicate and risk conflicting with the canonical plane ownership model. |
| "INV-111/112/113 gates not sufficient to prove 'implemented'" | The critique misunderstands the repo's implemented criteria. These gates exist, are wired in verify_invariants.sh, and emit evidence — they satisfy the manifest's mechanical verification criterion. P2 adds a mandatory pre-check to confirm this before promoting. |
| "INV-048 has verifier stub; both INV-039 and INV-048 need Phase-1 scope" | INV-048 has a referenced-but-not-wired verifier. Both are P1 severity roadmap items. Inclusion in Phase-1 would expand scope beyond what the three primary business invariants (114/115/116) require. Deferral is the correct decision. |

---

## 6. Evidence Path Reference

| Invariant | Gate | Evidence Path | Phase | Status |
|---|---|---|---|---|
| INV-111 | INT-G23 | `evidence/phase0/boz_observability_role.json` | phase0 | exists |
| INV-112 | SEC-G17 | `evidence/phase0/pii_leakage_payloads.json` | phase0 | exists |
| INV-113 | INT-G24 | `evidence/phase0/anchor_sync_hooks.json` | phase0 | exists |
| INV-114 | INT-G25 | `evidence/phase1/instruction_finality_invariant.json` | phase1 | to create |
| INV-114 | INT-G25 | `evidence/phase1/instruction_finality_runtime.json` | phase1 | to create |
| INV-115 | INT-G26 | `evidence/phase1/pii_decoupling_invariant.json` | phase1 | to create |
| INV-115 | INT-G26 | `evidence/phase1/pii_decoupling_runtime.json` | phase1 | to create |
| INV-116 | INT-G27 | `evidence/phase1/rail_sequence_truth_anchor.json` | phase1 | to create |
| INV-116 | INT-G27 | `evidence/phase1/rail_sequence_runtime.json` | phase1 | to create |
| Contract | INT-G28 | `evidence/phase1/phase1_contract_status.json` | phase1 | to create |
| Closeout | — | `evidence/phase1/phase1_closeout.json` | phase1 | to create |

## 7. New SQLSTATEs to Register

| Code | Name | Raised By | Invariant | Checked By |
|---|---|---|---|---|
| P7003 | SYMPHONY_FINALITY_VIOLATION | `trg_deny_finalized_instruction_mutation` | INV-114 | INT-G04 |
| P7004 | SYMPHONY_PII_VAULT_VIOLATION | `trg_deny_purge_request_mutation` | INV-115 | INT-G04 |
| P7005 | SYMPHONY_RAIL_SEQUENCE_MISSING | `trg_require_rail_sequence_on_dispatch` | INV-116 | INT-G04 |

## 8. New Tasks Summary

| Task ID | Title | Depends On | Regulated surfaces? |
|---|---|---|---|
| TSK-P1-005 | INV-111/112/113 truth-sync | TSK-P1-002 | Yes — docs/invariants/** |
| TSK-P1-006 | Phase-1 contract + evidence schema extension | TSK-P1-001 | Yes — scripts/audit/**, docs/invariants/**, CONTROL_PLANES.yml |
| TSK-P1-007 | INV-114 instruction finality | TSK-P1-002, TSK-P1-006 | Yes — schema/migrations/**, scripts/db/**, CONTROL_PLANES.yml |
| TSK-P1-008 | INV-115 PII decoupling | TSK-P1-002, TSK-P1-006 | Yes — schema/migrations/**, scripts/db/**, CONTROL_PLANES.yml |
| TSK-P1-009 | INV-116 rail sequence | TSK-P1-002, TSK-P1-006 | Yes — schema/migrations/**, scripts/db/**, CONTROL_PLANES.yml |
| TSK-P1-010 | Phase-1 closeout | TSK-P1-007, TSK-P1-008, TSK-P1-009 | Yes — evidence/**, .github/workflows/** |

## 9. Execution Order Summary

```
P0 (audit)        → read-only; confirm current state; no code
P1 (TSK-P1-001..004) → close open governance tasks; enables approval metadata harness
P2 (truth-sync)   → manifest + docs fix for INV-111/112/113; verify mechanically first
P3 (contract)     → Phase-1 contract file + enforcement gate INT-G28 + evidence/phase1/ schema coverage
      ↓ all three may run in parallel once P1 + P3 are done ↓
P4 (INV-114)      → instruction finality; ten-step promotion
P5 (INV-115)      → PII decoupling; ten-step promotion (SEC-G17 compatibility required)
P6 (INV-116)      → rail sequence; two-migration expand-then-constrain; ten-step promotion
      ↓
P7 (closeout)     → CI wiring + full validation + gap report + closeout evidence
```
