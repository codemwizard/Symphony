# CONSTITUTIONAL GRAPH

**Source:** Direct migration inspection, 0001–0204  
**Purpose:** Node classification and edge topology for DAG synthesis

---

## NODE REGISTRY

| Node | Type | Authority Class | Enforcement Density | Active | Dormant | Deferred | Scaffolded | Shadow Authority | Runtime Authoritative | CI Authoritative | Replacement Forbidden | Convergence Required |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `deny_outbox_attempts_mutation` | trigger | Append-Only Enforcement | ABSOLUTE | ✓ | | | | | ✓ | | ✓ | |
| `enforce_instruction_reversal_source` | trigger | Business Rule Enforcement | ABSOLUTE | ✓ | | | | | ✓ | | | |
| `deny_final_instruction_mutation` | trigger | Finality Enforcement | ABSOLUTE | ✓ | | | | | ✓ | | ✓ | |
| `deny_state_transitions_mutation` | trigger | Append-Only Enforcement | ABSOLUTE | ✓ | | | | | ✓ | | ✓ | |
| `invariant_registry_append_only` | trigger | Append-Only Enforcement | ABSOLUTE | ✓ | | | | | ✓ | | ✓ | |
| `enforce_transition_state_rules` | trigger | State Machine Enforcement | HARD | ✓ | | | | | ✓ | | ✓ | |
| `enforce_transition_authority` | trigger | Authority Enforcement | HARD | ✓ | | | | | ✓ | | ✓ | |
| `enforce_transition_signature` (0141/0148) | trigger | Signing Enforcement | **SOFT** (presence only; crypto stub) | ✓ | | | | | **Partial** | | | ✓ |
| `enforce_execution_binding` | trigger | Execution Binding Enforcement | HARD | ✓ | | | | | ✓ | | ✓ | |
| `update_current_state` | trigger | State Projection | ABSOLUTE | ✓ | | | | | ✓ | | | |
| `add_signature_placeholder_posture` (0153) | trigger | Marker Injection | DECLARATIVE | ✓ | | | | | ✓ | | | |
| `wave8_cryptographic_enforcement` (0190 tip) | trigger | Cryptographic Signing Enforcement | **CONDITIONAL** (depends on `ed25519_verify()` extension) | **CONDITIONAL** | | | | | **CONDITIONAL** | | ✓ | |
| `validate_attestation_gate` (0171) | trigger | Attestation Kill Switch | HARD | ✓ | | | | | ✓ | | ✓ | |
| `enforce_attestation_freshness` (0170) | trigger | Attestation Freshness | HARD | ✓ | | | | | ✓ | | | |
| `enforce_phase1_boundary` (0169) | trigger | Phase Admissibility | HARD | ✓ | | | | | ✓ | | ✓ | |
| `trg_enforce_instruction_hierarchy_verifier` (0050) | trigger | Hierarchy Enforcement | HARD | ✓ | | | | | ✓ | | | |
| `enforce_authority_transition_binding` | SECURITY DEFINER function | Authority Binding | HARD | ✓ | | | | | ✓ | | ✓ | |
| `resolve_authoritative_signer` (0176) | SECURITY DEFINER function | Signer Resolution | ABSOLUTE (fail-closed on ambiguity) | ✓ | | | | | ✓ | | ✓ | |
| `current_tenant_id_or_null` (0059) | SECURITY DEFINER function | Tenant Isolation | ABSOLUTE (returns NULL on invalid) | ✓ | | | | | ✓ | | ✓ | |
| `verify_dispatch_effect_seal` (0062) | SECURITY DEFINER function | Effect Seal Verification | HARD | ✓ | | | | | ✓ | | | |
| `apply_finality_signals` (0062) | SECURITY DEFINER function | Finality Conflict Detection | HARD | ✓ | | | | | ✓ | | | |
| `verify_ed25519_signature` (0141) | SECURITY DEFINER function | Crypto Primitive | **RHETORICAL** (returns true unconditionally) | | | | | ✓ (shadow — appears authoritative) | **NO** | | | ✓ |
| `wave8_signer_resolution` table | registry | Signer Authority Registry | HARD | ✓ | | | | | ✓ | | ✓ | |
| `public_keys_registry` table (0165) | registry | Public Key Registry | DECLARATIVE | | ✓ | | ✓ | | **NO** | | | ✓ |
| `delegated_signing_grants` table (0166) | registry | Actor Authorization Registry | DECLARATIVE | | ✓ | | ✓ | | **NO** | | | ✓ |
| `invariant_registry` table (0163) | registry | Invariant Declaration | DECLARATIVE | | ✓ | | ✓ | | **NO** (no reader) | ✓ (append-only CI-gated) | ✓ | ✓ |
| `policy_versions` table (0005) | registry | Policy Authority | HARD | ✓ | | | | | ✓ | | ✓ | |
| `policy_decisions` table (0134) | registry | Policy Decision Registry | HARD | ✓ | | | | | ✓ | | ✓ | |
| `state_rules` table (0135) | registry | State Machine Rules | HARD | ✓ | | | | | ✓ | | ✓ | |
| `interpretation_packs` table (0116) | registry | Interpretation Authority | HARD | ✓ | | | | | ✓ | | ✓ | |
| `execution_records` table (0118) | registry | Execution Evidence | HARD | ✓ | | | | | ✓ | | ✓ | |
| `revoked_client_certs` / `revoked_tokens` (0012) | registry | Credential Revocation | ABSOLUTE (append-only, BEFORE UPDATE/DELETE blocks) | ✓ | | | | | ✓ | | ✓ | |
| `wave8_attestation_nonces` (0183) | replay system | Nonce Registry | CONDITIONAL (asset_batches path only) | ✓ | | | | | **CONDITIONAL** | | | |
| `instruction_effect_seals` (0062) | registry | Effect Seal Store | HARD | ✓ | | | | | ✓ | | | |
| `orphaned_attestation_landing_zone` (0062) | registry | Orphan Landing Zone | HARD | ✓ | | | | | ✓ | | | |
| `signing_audit_log` (0065) | evidence system | Signing Audit Trail | DECLARATIVE | | ✓ | | ✓ | | **NO** | | | ✓ |
| `evidence_packs` (0023) | evidence system | Evidence Authority | DECLARATIVE | | ✓ | | ✓ | | **NO** | | | ✓ |
| `historical_verification_runs` (0065) | evidence system | Historical Verification | DECLARATIVE | | ✓ | | | | **NO** | | | |
| `archive_verification_runs` (0066) | evidence system | Archive Verification | DECLARATIVE | | ✓ | | | | **NO** | | | |
| `resign_sweeps` (0065) | evidence system | Re-signing Workflow | DECLARATIVE | | ✓ | | | | **NO** | | | |
| CI `mechanical_invariants` job | CI gate | Structural Admissibility | HARD | ✓ | | | | | | ✓ | | |
| CI `db_verify_invariants` job (PG18) | CI gate | Migration Admissibility | HARD | ✓ | | | | | | ✓ | | |
| CI `security_scan` job | CI gate | Security Admissibility | HARD | ✓ | | | | | | ✓ | | |
| CI `phase0_evidence_gate` | CI gate | Evidence Admissibility | HARD | ✓ | | | | | | ✓ | | |
| CI `phase2_entry_gate` (GF branch-gated) | CI gate | Phase Admissibility | CONDITIONAL | ✓ | | | | | | CONDITIONAL | | |
| CI `codex_invariants_review` | CI gate | Advisory Review | SOFT | ✓ | | | | | | ADVISORY | | |
| Migration sequence 0001–0204 | migration authority | Constitutional Record | ABSOLUTE (tip wins) | ✓ | | | | | ✓ | ✓ | | |
| `_migration_guards` / `_migration_fingerprints` (0095) | migration authority | Idempotency Guard | HARD | ✓ (0095 only) | | | | | ✓ | | | |
| `state_transitions` table (0137) | runtime write path | Append-Only State Record | ABSOLUTE | ✓ | | | | | ✓ | | ✓ | |
| `state_current` table (0138) | runtime write path | Current State Projection | HARD | ✓ | | | | | ✓ | | | |
| `asset_batches` table (wave8 write path) | runtime write path | Asset Authority Write Path | CONDITIONAL (crypto gate conditional) | ✓ | | | | | CONDITIONAL | | | |
| `payment_outbox_pending` / `payment_outbox_attempts` | runtime write path | Outbox Write Path | ABSOLUTE (append-only) | ✓ | | | | | ✓ | | | |
| `instruction_settlement_finality` (0028) | runtime write path | Settlement Finality Record | ABSOLUTE | ✓ | | | | | ✓ | | ✓ | |
| RLS RESTRICTIVE policies (0059/0095/0204) | application authority layer | Tenant Isolation Enforcement | HARD | ✓ | | | | | ✓ | | ✓ | |
| `canonicalization_registry` (0065) | canonicalization layer | Canonicalization Version Authority | DECLARATIVE | | ✓ | | ✓ | | **NO** | | | ✓ |
| `wave8_signer_resolution.superseded_by` chain | supersession chain | Key Lifecycle Authority | HARD | ✓ | | | | | ✓ | | ✓ | |
| `invariant_registry.superseded_by` chain (0163/0164) | supersession chain | Invariant Supersession | HARD (append-only + unique index) | ✓ | | | | | ✓ (topology only; no reader) | | ✓ | |
| Phase boundary markers — `monitoring_records.phase` (0169) | phase boundary | Phase Admissibility Enforcement | HARD | ✓ | | | | | ✓ | | | |
| `signing_authorization_matrix` (0065) | governance substrate | Signing Authorization | DECLARATIVE | | ✓ | | ✓ | | **NO** (no runtime reader) | | | ✓ |

---

## GRAPH EDGES

| Source | Edge Type | Target | Enforcement Status | Sovereignty Weight |
|---|---|---|---|---|
| `migration sequence` | overrides | all prior SECURITY DEFINER bodies | ABSOLUTE — CREATE OR REPLACE | Highest |
| `enforce_transition_state_rules` | enforces | `state_transitions` INSERT | HARD — BEFORE INSERT trigger | High |
| `enforce_transition_authority` | enforces | `state_transitions` INSERT | HARD — BEFORE INSERT trigger | High |
| `enforce_transition_signature` | declares | `state_transitions` INSERT (signature presence only) | SOFT — crypto call absent | Medium (theater boundary) |
| `enforce_execution_binding` | enforces | `state_transitions` INSERT | HARD — BEFORE INSERT trigger | High |
| `deny_state_transitions_mutation` | forbids_replacement_of | `state_transitions` rows | ABSOLUTE — BEFORE UPDATE/DELETE | Highest |
| `update_current_state` | enforces | `state_current` projection | ABSOLUTE — AFTER INSERT | High |
| `wave8_cryptographic_enforcement` | conditionally_authoritative_to | `asset_batches` INSERT | CONDITIONAL — extension dependency | High (conditional) |
| `validate_attestation_gate` | gates | `asset_batches` INSERT | HARD | High |
| `enforce_attestation_freshness` | constrains | `asset_batches` INSERT | HARD | High |
| `resolve_authoritative_signer` | enforces | signer identity resolution | ABSOLUTE (fail-closed) | Highest |
| `wave8_signer_resolution` | gates | `resolve_authoritative_signer` | HARD | High |
| `public_keys_registry` | declares | actor public key storage | DECLARATIVE | Low (scaffolded) |
| `delegated_signing_grants` | declares | actor signing authorization | DECLARATIVE | Low (scaffolded) |
| `public_keys_registry` | converges_to | `wave8_signer_resolution` | NOT YET WIRED | Critical convergence |
| `delegated_signing_grants` | converges_to | `wave8_cryptographic_enforcement` | NOT YET WIRED | Critical convergence |
| `invariant_registry` | declares | invariant authority | DECLARATIVE | Low (no reader) |
| `invariant_registry` | converges_to | CI enforcement scripts | NOT YET WIRED | Required convergence |
| `validate_attestation_gate` | depends_on | `invariant_registry` (live snapshot) | HARD — reads invariant_registry for snapshot hash | High |
| `current_tenant_id_or_null` | enforces | RLS RESTRICTIVE policies | ABSOLUTE (NULL-fail-closed) | Highest |
| RLS RESTRICTIVE policies | constrains | all `tenant_id` tables | HARD | High |
| `app.bypass_rls` predicate (partial, pre-0204) | bypasses | RLS isolation (3 tables) | **REMOVED** in 0204 | Was: Critical bypass |
| `verify_ed25519_signature` | shadows | `enforce_transition_signature` (appears crypto but returns true) | RHETORICAL | Shadow authority |
| `add_signature_placeholder_posture` | declares | transition_hash placeholder state | DECLARATIVE (marker only) | Low |
| `policy_decisions` | constrains | `state_transitions.policy_decision_id` | HARD — FK + trigger | High |
| `execution_records` | constrains | `state_transitions.execution_id` | HARD — FK + trigger | High |
| `interpretation_packs` | constrains | `execution_records.interpretation_version_id` | HARD — NOT NULL after 0159 | High |
| `state_rules` | constrains | `enforce_transition_state_rules` lookup | HARD | High |
| `wave8_attestation_nonces` | enforces | nonce uniqueness (asset_batches path) | HARD (PRIMARY KEY) | High |
| `signing_audit_log` | declares | signing evidence | DECLARATIVE (no writer active) | Low |
| `canonicalization_registry` | declares | canonicalization versioning | DECLARATIVE (no reader wired) | Low |
| `wave8_signer_resolution.superseded_by` | supersedes | prior key version | HARD (FK + lifecycle check) | High |
| `invariant_registry.superseded_by` | supersedes | prior invariant declaration | HARD (append-only + unique index) | Medium (no runtime reader) |
| CI `mechanical_invariants` | gates | merge to main | HARD — required pass | CI sovereign |
| CI `db_verify_invariants` | gates | merge to main | HARD — required pass | CI sovereign |
| CI `phase0_evidence_gate` | gates | merge to main | HARD — required pass | CI sovereign |
| CI `codex_invariants_review` | declares | advisory review | SOFT | Advisory only |
| `enforce_phase1_boundary` | enforces | `monitoring_records.data_authority` | HARD | High |
| `_migration_guards` | constrains | migration 0095 re-run | HARD (0095 only) | Medium |
| `instruction_effect_seals` | constrains | dispatch via `verify_dispatch_effect_seal` | HARD | High |
| `deny_final_instruction_mutation` | forbids_replacement_of | `instruction_settlement_finality` rows | ABSOLUTE | Highest |

---

## DISCONNECTED GRAPH ISLANDS

The following nodes have **no inbound enforcement edges from any active authority surface**:

1. **`public_keys_registry`** — declared, temporal constraints present, zero readers in enforcement path
2. **`signing_audit_log`** — declared columns exist, zero writers active in migration evidence
3. **`delegated_signing_grants`** — declared, schema present, no trigger or FK from signing paths
4. **`canonicalization_registry`** — declared, no consumer found in migration evidence
5. **`historical_verification_runs`** / `archive_verification_runs` — declared, dormant
6. **`signing_authorization_matrix`** (0065) — declared matrix, no enforcement reader wired

---

## PARALLEL AUTHORITY SYSTEMS (DAG POISONING RISK)

| Domain | System A | System B | Convergence Obligation |
|---|---|---|---|
| Signing authority | `enforce_transition_signature` (state_transitions, presence-only) | `wave8_cryptographic_enforcement` (asset_batches, conditional crypto) | REQUIRED — different trust models on different tables |
| Signer registry | `wave8_signer_resolution` (active, enforced) | `public_keys_registry` (scaffolded, not enforced) | REQUIRED — must converge |
| Replay prevention | `wave8_attestation_nonces` (wave8 path) | `revoked_tokens` (client auth path) | NOT REQUIRED — semantically distinct |
| Canonicalization | `canonical_payload_bytes` (wave8 path) | `transition_hash` (state_transitions path) | REQUIRED — parallel canonical payload models |

---

## EXECUTABLE SUPREMACY ZONES

Zones where `CREATE OR REPLACE` is the effective constitutional authority:

- **`wave8_cryptographic_enforcement`** — rewritten 5+ times; current tip is 0190; no protection against future overwrite
- **`verify_ed25519_signature`** — shadow authority function; overwritten in 0141/0148; returns true unconditionally
- **`store_effect_seal`** (0062) — effect seal hash uses MD5; overwriteable
- **`enforce_transition_signature`** — presence-only logic; crypto call commented out and stable across overwrites

---

## RUNTIME BYPASS VECTORS

1. **`PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix** — all `state_transitions.transition_hash` values currently carry this prefix, meaning no real transition hash has been persisted. The enforcement trigger accepts them unconditionally.
2. **`wave8_crypto` extension absent** — if `ed25519_verify()` does not exist, all `asset_batches` INSERTs fail at runtime (fail-closed behavior, but constitutionally this is a broken path, not a secured one).
3. **`app.bypass_rls` residual** — confirmed removed from 3 tables in 0204; potential residual on other tables requires runtime audit.
4. **`symphony_control` role** — holds `ALL PRIVILEGES` on `payment_outbox_pending` and `participant_outbox_sequences`; INSERT rights on append-only tables. No BYPASSRLS confirmed in migration evidence, but role privilege scope is elevated.
