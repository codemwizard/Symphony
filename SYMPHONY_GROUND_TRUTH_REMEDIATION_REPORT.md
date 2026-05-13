# Symphony Ground-Truth Remediation Report

Constitutional-Status: ADVISORY
Authority-Rank: 5
Phase-Scope: GLOBAL — applies to Phase 3 entry preparation and structural remediation
Effective-Date: 2026-05-12
Method: Direct migration-by-migration and source-file inspection against diagnostic claims

---

## Purpose

This report reconciles three prior analytical layers — the architectural diagnosis, its
accuracy verdict, and the Phase 3 task pack assessment — against what the codebase
actually contains. It then produces a sequenced, actionable remediation plan grounded
in real file paths, real schema states, and real wiring gaps.

Prior analyses that were right, partly right, or wrong are all noted. The remediation
plan does not repeat what already exists. It starts from where the codebase actually is.

---

## Part 1: What the Codebase Actually Contains

### 1.1 The Ed25519 Situation — Resolved, Not Blocked

The original diagnosis stated:
> "The `wave8_cryptographic_enforcement` function literally raises `P7809 — Ed25519
> verification primitive not available` as a hard-fail on every insert."

**This was true as of migration 0182, but was superseded by migrations 0187 and 0190.**

The actual current state (tip of history at migration 0204):

- **0182** — Restored the hard-fail posture (`P7809: Ed25519 verification primitive not available`). This was the state the diagnosis observed.
- **0187** — Integrated `ed25519_verify()` via the `wave8_crypto` extension. The function now performs actual cryptographic signature verification. However, 0187 dropped replay prevention (nonce validation) and weakened context binding to optional guards.
- **0190** — Full restoration. This is the authoritative current state. The function now enforces all six domains in this order:
  1. Signature presence validation
  2. Signer resolution (`resolve_authoritative_signer`)
  3. Key lifecycle (is_active, valid_until, superseded_by → ERRCODE P7813)
  4. Scope authorization (P7810)
  5. Timestamp integrity — canonical payload `occurred_at` vs persisted (P7811)
  6. Replay prevention — nonce uniqueness insert into `wave8_attestation_nonces` (P7812)
  7. Context binding — mandatory presence of entity_id, execution_id, policy_decision_id, interpretation_version_id in canonical payload (P7814)
  8. Ed25519 signature verification via `ed25519_verify()` (P7809)

**Conclusion:** The Ed25519 gap is closed at the DB trigger layer. The diagnosis that "every piece of Phase 3 work depending on the cryptographic substrate is depending on something that is not verifying anything" is no longer accurate as of migration 0190.

**Residual question:** Does `ed25519_verify()` actually exist as a callable PostgreSQL function? Migration 0187 references `wave8_crypto` extension. The extension itself must be installed in the runtime environment. This has not been verified by direct inspection and remains the single open operational risk in the cryptographic layer. If the extension is absent, the function call fails at runtime rather than at schema load time, and the hard-fail posture effectively returns. **This must be verified before Phase 3 opens.**

---

### 1.2 The Lifecycle Infrastructure — Dormant Scaffolding Confirmed

The accuracy verdict was correct on this point. Migration 0066 creates:

| Table | Purpose | Status |
|-------|---------|--------|
| `canonicalization_registry` | Tracks canon versions with `deprecated_at` | Seeded with `canon-v1` |
| `canonicalization_archive_snapshots` | Snapshot path + sha256 per version | **Empty — no application writes** |
| `proof_pack_batches` | Merkle roots over batched evidence | **Empty — no application writes** |
| `proof_pack_batch_leaves` | Individual leaves with merkle proofs | **Empty — no application writes** |
| `anchor_backfill_jobs` | Replay jobs by `replay_day` | **Empty — no application writes** |
| `archive_verification_runs` | Audit runs with `years_covered` | **Empty — no application writes** |

These tables are structurally correct. The epoch sealing concept is architecturally present. The gap is entirely operational: no application code calls these tables, no CI process triggers them, no task owns them.

The `proof_pack_batches` table with Merkle roots IS the epoch checkpoint mechanism the diagnosis said was missing. It is not missing. It is dormant.

---

### 1.3 The evidence_nodes Table — Confirmed Plain Adjacency List

Migration 0100 (`gf_evidence_lineage.sql`) confirms the analysis exactly:

```sql
CREATE TABLE public.evidence_nodes (
    evidence_node_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    project_id UUID NOT NULL,
    monitoring_record_id UUID,
    node_type TEXT NOT NULL,
    node_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL
);
```

No `data_class`, no `retention_class`, no `tier`, no `replay_critical`, no `archived`. The six constitutional data classes defined in `DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md` (Authority-Rank 9) describe exactly what these columns should encode. The doctrine is comprehensive. The schema has zero materialisation of it.

**This is the highest-priority single schema gap.** Every Phase 3 capability (typed dependency graph, recursive legitimacy engine, replay reconstruction) operates on `evidence_nodes`. Without lifecycle metadata on nodes, the Phase 3 engine cannot:
- Determine whether a node is permanent evidentiary data or operational runtime data
- Apply retention-appropriate replay rules
- Scope CI verifiers to only active constitutional nodes
- Partition archival from active enforcement surfaces

---

### 1.4 The `retention_class` Concept — Domain-Scoped, Not Universal

Migration 0044 (`kyc_retention_policy_hook.sql`) confirms that `retention_class` exists as a concept — implemented for KYC AML obligations (ZM / FIC_AML_CUSTOMER_ID / 10 years). It was never generalised to a platform-wide registry. The six constitutional data classes in the doctrine document have never been materialised into a machine-queryable structure.

---

### 1.5 The PII Vault — Nullification Model, Not Cryptographic Key-Deletion

Migration 0029 implements a nullification model: the `protected_payload JSONB` field is set to NULL on purge. The record structure remains intact; the content is gone.

The diagnosis described the correct long-term target: "PII stored under an encryption key, the key is deleted on erasure (GDPR), the ciphertext remains (BoZ)." That model provides stronger replay continuity because no structural mutation occurs. However, the nullification model is constitutionally sufficient for current regulatory obligations. The cryptographic key-deletion model is Phase 6 work (ZDPA erasure controls). This does not need to be solved in Phase 3.

---

### 1.6 The Invariant Registry — In Schema, Not Wired to Phase 3

Migration 0163 creates `invariant_registry` with `invariant_id`, `verifier_type`, `severity`, `execution_layer`, `is_blocking`, `checksum`, and `superseded_by`. The Phase 3 invariants (INV-301 through INV-310) are defined in `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` at `status: roadmap`. Neither the invariants nor their verifier scripts appear in the `invariant_registry` table. The table and the doctrine are disconnected.

---

### 1.7 The TamperEvidentChain — Operational but File-Based

`TamperEvidentChain.cs` implements a SHA-256 hash chain over NDJSON log files. Each record contains `chain_record` with `current_hash`, `previous_hash`, `payload_hash`, `domain`, `generated_at_utc`, and `commit_boundary`. This is used for evidence link dispatch logs, submission logs, revoked tokens, and exception logs.

This is a well-implemented file-based tamper-evident log. It is NOT connected to the DB-layer `proof_pack_batches` Merkle tree infrastructure. Two hash chain systems exist in parallel with no bridge between them.

---

## Part 2: What Was Right, Partly Right, and Wrong

### Confirmed Right

| Claim | Evidence |
|-------|---------|
| `evidence_nodes` is a plain adjacency list with no lifecycle semantics | Migration 0100 confirmed |
| Lifecycle tables exist but are dormant (0066) | All six tables in 0066 confirmed empty |
| The governance explosion is a lifecycle symptom | 822 task directories, no archival mechanism |
| Policy/code separation needed | Constitutional docs are prose MD; no machine-queryable IR |
| Task archival necessary | CI traverses all 822 task directories on every run |
| The `retention_class` concept is domain-scoped, not universal | 0044 seeds one KYC row only |

### Confirmed Partly Right

| Claim | Correction |
|-------|-----------|
| "Ed25519 hard-fails on every insert" | Was true at 0182; resolved at 0187/0190 |
| "No epoch boundary exists" | `proof_pack_batches` in 0066 IS an epoch checkpoint; it is dormant not absent |
| "Adding lifecycle columns is three lines of SQL" | Adding columns is trivial; wiring them to the constitutional data classes requires a typed registry |

### Confirmed Wrong

| Claim | Reality |
|-------|---------|
| "There is no `retention_class`" | Exists in `kyc_retention_policy` (0044); domain-scoped |
| "Wave 8 cryptographic enforcement is a placeholder" | Migration 0190 is a complete implementation with 8 enforcement domains |
| OPA/Rego as peer model | Correctly rejected; XBRL name-drop is flavouring not precision |

---

## Part 3: The Real Gap Map

Having established ground truth, the actual gaps are:

### Gap 1 — `evidence_nodes` Has No Data Class (CRITICAL)

Every Phase 3 capability (typed dependency graph INV-302, recursive legitimacy engine INV-303, replay reconstruction P3-001) operates on `evidence_nodes`. Without knowing the data class of a node, the legitimacy engine cannot apply the correct retention-aware replay rules. The fix is a `data_class` column constrained to the six constitutional classes, with a backfill migration and a companion typed YAML registry.

### Gap 2 — The Epoch Sealing Process Does Not Exist (HIGH)

The schema (0066) is complete. `proof_pack_batches` is structurally correct as an epoch checkpoint. No application or CI code populates it. Phase 3 adds replay-aware legitimacy chain records that accumulate O(all decisions). Without epoch sealing, the replay burden grows unbounded from the first Phase 3 legitimacy evaluation.

### Gap 3 — The Constitutional Data Classes Are Uncompiled (HIGH)

`DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md` (Authority-Rank 9) defines six data classes in comprehensive prose. They have never been extracted into a machine-queryable YAML registry. Without a compiled registry, the Phase 3 legitimacy engine cannot enforce retention-class-aware admissibility rules at runtime.

### Gap 4 — The Two Hash Chain Systems Are Disconnected (MEDIUM)

`TamperEvidentChain.cs` (application layer, file-based) and `proof_pack_batches` (DB layer, Merkle tree) are two independent evidence structures. External verifier independence (P3-I4) cannot be certified until an auditor can traverse from an application-layer submission hash to a DB-layer Merkle proof.

### Gap 5 — The Invariant Registry Is Not Seeded with Phase 3 Invariants (HIGH)

INV-301 through INV-310 exist in the doctrine. The `invariant_registry` table exists in the schema. They are not connected. Phase 3 cannot claim mechanical invariant enforcement until the rows exist in the table with verifier scripts wired to them.

### Gap 6 — The `wave8_crypto` Extension Operational Status Is Unverified (CRITICAL)

Migration 0190 calls `ed25519_verify()`. If the `wave8_crypto` extension is absent in the runtime environment, the function fails at runtime without the correct error code. This is a pre-Phase-3 entry blocker: the Opening Act's declaration that "Wave 8 cryptographic enforcement is fully operational" depends on this being true.

---

## Part 4: Sequenced Remediation Plan

These six actions are sequentially ordered. Each depends on the previous. None requires rewriting existing infrastructure. All activate or connect what already exists.

---

### Action 1: Verify the `wave8_crypto` Extension

**Task ID:** TSK-P3-PRE-001
**Classification:** Pre-Phase-3 entry blocker. Must complete before any Phase 3 work begins.

Confirm `ed25519_verify()` is callable in all environments:

```sql
SELECT ed25519_verify(
  '\x' || encode(gen_random_bytes(32), 'hex'),
  '\x' || encode(gen_random_bytes(64), 'hex'),
  '\x' || encode(gen_random_bytes(32), 'hex')
);
-- Expected: returns FALSE (bad signature), not a function-not-found error
```

Add a CI gate `scripts/audit/verify_ed25519_available.sh` that runs this check before the migration suite. Document the result in `evidence/phase3/wave8_crypto_operational_status.json`.

**Blocks:** All Phase 3 tasks. Phase 3 opening is constitutionally invalid if this fails.

---

### Action 2: Add `data_class` to `evidence_nodes`

**Task ID:** TSK-P3-W1-DB-007
**Classification:** Phase 3 foundation migration. Required before Wave 1 tasks begin.

Migration `0205_evidence_nodes_data_class.sql`:

```sql
CREATE TYPE public.constitutional_data_class AS ENUM (
    'identity',       -- §3.1: Conditionally deletable; tombstoned on erasure
    'evidentiary',    -- §3.2: Immutable; no deletion; permanent replay obligation
    'provenance',     -- §3.3: Immutable; chain must remain intact
    'replay',         -- §3.4: Immutable; required for constitutional reconstruction
    'regulator',      -- §3.5: Per-regulator mandatory retention; no Symphony deletion
    'operational'     -- §3.6: Permitted deletion; no replay obligation
);

ALTER TABLE public.evidence_nodes
    ADD COLUMN data_class public.constitutional_data_class NOT NULL DEFAULT 'operational';

-- Prevent downgrade: once classified as evidentiary or provenance, cannot be lowered
CREATE OR REPLACE FUNCTION public.enforce_data_class_monotonicity()
RETURNS TRIGGER LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    IF OLD.data_class = 'evidentiary' AND NEW.data_class <> 'evidentiary' THEN
        RAISE EXCEPTION 'Evidentiary data class cannot be downgraded'
            USING ERRCODE = 'P3101';
    END IF;
    IF OLD.data_class = 'provenance' AND NEW.data_class NOT IN ('evidentiary', 'provenance') THEN
        RAISE EXCEPTION 'Provenance data class cannot be downgraded below provenance'
            USING ERRCODE = 'P3101';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enforce_data_class_monotonicity
    BEFORE UPDATE ON public.evidence_nodes
    FOR EACH ROW EXECUTE FUNCTION public.enforce_data_class_monotonicity();
```

Companion YAML (`docs/constitutional/data_class_registry.yml`) materialises the six classes as a machine-readable registry with `deletion_permission`, `replay_obligation`, `redaction_permission`, and `retention_floor` typed fields for each class.

**Blocks:** TSK-P3-W1-DB-001 (Canonical Dependency Node Schema) and all Wave 1–10 tasks.

---

### Action 3: Seed INV-301 through INV-310 into the Invariant Registry

**Task ID:** TSK-P3-GOV-002
**Classification:** Phase 3 foundation. Required before any verifier task can be claimed.

Migration `0206_phase3_invariant_registry_seed.sql` inserts all 10 Phase 3 invariants into `invariant_registry` with `is_blocking = FALSE` (roadmap status). The `checksum` field holds a placeholder that must be replaced with the SHA-256 of the actual verifier script on promotion. Promotion to `is_blocking = TRUE` requires human authorization per the invariant register protocol.

**Blocks:** TSK-P3-CI-006 (per-invariant verifier suite — requires rows to exist).

---

### Action 4: Activate the Epoch Sealing Process

**Task ID:** TSK-P3-W8-SEAL-001
**Classification:** Phase 3 operational infrastructure. Required before Phase 3 exit.

The `proof_pack_batches` and `proof_pack_batch_leaves` tables in migration 0066 are structurally complete. A new command handler `EpochSealingCommand.cs` in the LedgerApi Commands layer is needed to:

1. Accept a batch of `evidence_node_id` values (or a time range)
2. Compute SHA-256 hashes of canonical node payloads
3. Build a Merkle tree from the hashes
4. Write one row to `proof_pack_batches` (merkle_root, leaf_count, canonicalization_version)
5. Write one row per leaf to `proof_pack_batch_leaves`

A Tier 4 CI gate at Phase 3 exit verifies that at least one `proof_pack_batches` row exists for each Phase 3 legitimacy chain batch and that `archive_verification_runs` has at least one PASS row.

**Blocks:** TSK-P3-W10-CERT-005 (exit gate orchestrator).

---

### Action 5: Connect the Application Hash Chain to the DB Merkle System

**Task ID:** TSK-P3-W8-ARCH-001
**Classification:** Phase 3 architectural bridge. Required before external verifier certification.

The `TamperEvidentChain.cs` application-layer chain and `proof_pack_batches` must be connected. Each `EvidenceLinkSubmissionLog` entry has a `chain_record.current_hash`. On epoch seal, these become the `leaf_hash` values in `proof_pack_batch_leaves`, with `artifact_id` referencing the `instruction_id`. This enables the complete external verifier workflow:

1. Regulator receives a `proof_pack_batches` Merkle root
2. Regulator receives `proof_pack_batch_leaves` for specific leaves
3. Regulator independently recomputes SHA-256 of canonical payload from NDJSON log
4. Regulator verifies leaf hash against the Merkle proof
5. Regulator independently reconstructs constitutional state

Without this bridge, external verifier independence (P3-I4) cannot be certified.

**Blocks:** TSK-P3-W10-CERT-004 (external verifier independence certification).

---

### Action 6: Build the Constitutional Compilation Pipeline

**Task ID:** TSK-P3-GOV-001
**Classification:** Phase 3 governance infrastructure. Required before verifier tasks begin.

Script `scripts/constitutional/compile_phase3_constraints.py` reads the PHASE3_INVARIANT_REGISTER.md, phase3_contract.yml, all TSK-P3-*/meta.yml files, and the data_class_registry.yml, then produces `evidence/phase3/constitutional_constraint_manifest.json` validating that every INV-3xx has an implementing task, verifier script path, CI tier assignment, and at least one negative test. It fails CI if any invariant has a broken link in this chain.

This script becomes a Tier 1 CI gate (runs on every commit). It is the difference between "we wrote down the constraints" and "we can mechanically verify the constraints are consistently wired."

**Blocks:** All TSK-P3-CI-* verifier tasks.

---

## Part 5: The Corrected Sequencing Diagram

```
Phase 3 Entry Blockers (complete before any Phase 3 implementation task):

  TSK-P3-PRE-001: wave8_crypto extension verification
    └─ TSK-P3-GOV-002: Invariant registry seeding (migration 0206)
         └─ TSK-P3-W1-DB-007: evidence_nodes data_class column (migration 0205)
              ├─ TSK-P3-GOV-001: Constitutional compilation pipeline
              │    └─ All TSK-P3-CI-* verifier tasks (unblocked once pipeline exists)
              └─ TSK-P3-W1-DB-001 and all Wave 1–10 implementation tasks
                   └─ TSK-P3-W8-SEAL-001: Epoch checkpoint activation
                        └─ TSK-P3-W8-ARCH-001: Application chain to DB Merkle bridge
                             └─ TSK-P3-W10-CERT-004: External verifier independence certification
                                  └─ TSK-P3-W10-CERT-005: Constitutional exit gate orchestrator
```

---

## Part 6: What Requires No Action

| Item | Status | Phase |
|------|--------|-------|
| Ed25519 verification | Complete (0190) — only needs operational confirmation (Action 1) | Phase 2 closed |
| PII vault cryptographic model | Current nullification model is compliant; key-deletion is an enhancement | Phase 6 (ZDPA) |
| TamperEvidentChain implementation | Well-implemented; needs connection to Merkle system (Action 5) | Phase 3 |
| `kyc_retention_policy` domain extension | Sufficient for current KYC obligations | Phase 4 (BoZ) |
| OPA/Rego policy engine | Not needed; YAML registry + C# executor is correct pattern | Phase 5 (Adapter) |
| Bazel/action graph parallelism | Not needed; archival + tiered CI is the correct intervention | Operations |

---

## Part 7: Summary of Actionable Tasks

| Priority | Task ID | Description | Artifact |
|----------|---------|-------------|----------|
| CRITICAL | TSK-P3-PRE-001 | wave8_crypto operational verification | `scripts/audit/verify_ed25519_available.sh` |
| CRITICAL | TSK-P3-GOV-002 | INV-301–310 invariant registry seeding | Migration 0206 |
| CRITICAL | TSK-P3-W1-DB-007 | evidence_nodes data_class column | Migration 0205 |
| HIGH | TSK-P3-GOV-001 | Constitutional compilation pipeline | `scripts/constitutional/compile_phase3_constraints.py` |
| HIGH | TSK-P3-W8-SEAL-001 | Epoch checkpoint activation | `EpochSealingCommand.cs` + CI gate |
| HIGH | TSK-P3-W8-ARCH-001 | Application chain to DB Merkle bridge | Application layer change |
| HIGH | data_class_registry.yml | Machine-readable constitutional data classes | `docs/constitutional/data_class_registry.yml` |

These 7 actions, added to the 116-task plan, constitute the complete ground-truth remediation set. They are not new work. They are the activation and connection of infrastructure that already exists.

---

## Final Statement

Symphony does not need to start over. It does not need new technology. It needs:

1. **One operational confirmation** — that `ed25519_verify()` is callable (Action 1).
2. **One schema column** — `data_class` on `evidence_nodes` (Action 2).
3. **One migration** — seeding the invariant registry (Action 3).
4. **One process** — populating the dormant epoch checkpoint tables (Action 4).
5. **One bridge** — connecting the application hash chain to the DB Merkle system (Action 5).
6. **One script** — the constitutional compilation pipeline (Action 6).

The foundation is sound. The cryptographic layer is complete, not placeholder. The lifecycle doctrine is comprehensive, not absent. The epoch infrastructure exists, not missing. The gap is entirely in wiring: doctrine to schema, schema to application layer, application layer to DB checkpoint, checkpoint to external verifier. Close these six wiring gaps and Phase 3 begins on solid ground.
