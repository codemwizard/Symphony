# ADR-0010: Baseline Governance Policy

## Status
Accepted (Phase-0)

## Context
Schema baseline snapshots are used for drift detection and auditability. Without governance, baselines can be updated without a corresponding migration or rationale, which erodes integrity.

## Decision
Baseline updates are **governed** and **fail-closed**:

1) If `schema/baseline.sql` changes, **at least one migration** must change in the same diff.
2) If `schema/baseline.sql` changes, this ADR **must be updated** with a human-readable note.
3) Baseline generation should use a deterministic, container-based `pg_dump` when possible.

### Governance Note (2026-02-17)
This ADR remains the authoritative governance reference for baseline change checks when integrating branch histories.

## Consequences
- Baseline updates are explicit, auditable, and tied to migrations.
- CI/local checks will fail if governance requirements are not met.

## Baseline Update Log
- 2026-02-05: Baseline regenerated after tenant/client/member migrations (0014–0019).
- 2026-02-07: Baseline regenerated after Phase-0 audit gap closeout migrations (0022–0024).
- 2026-02-09: Baseline regenerated after business foundation delta tightening (0025–0027).
- 2026-02-13: Baseline regenerated after INV-114 instruction finality migration (0028).
- 2026-02-13: Baseline regenerated after INV-115 pii decoupling migration (0029).
- 2026-02-13: Baseline regenerated after follow-up fix migration for pii purge executor (0030).
- 2026-02-13: Baseline regenerated after INV-116 rail sequence truth-anchor migration (0031).
- 2026-02-18: Baseline regenerated after timeout posture + anchor-sync operational restoration migrations (0032, 0033, 0034).
- 2026-02-22: Baseline regenerated after Phase-0 levy structural hook migrations (0035, 0036).
- 2026-02-22: Baseline regenerated after levy calculation records structural hook migration (0037).
- 2026-02-22: Baseline regenerated after levy remittance periods structural hook migration (0038).
- 2026-02-22: Baseline regenerated after KYC provider registry structural hook migration (0039).
- 2026-02-23: Baseline regenerated after KYC structural hook migrations for verification records and outbox hold seam (0042, 0043).
- 2026-02-23: Baseline regenerated after KYC retention policy governance declaration hook migration (0044).
- 2026-02-23: Baseline regenerated after escrow state machine + atomic reservation semantics migration (0045).
- 2026-02-23: Baseline regenerated after escrow ceiling enforcement + cross-tenant protections migration (0046).
- 2026-02-24: Baseline regenerated after hierarchy bridge migration for `programs.program_escrow_id` + `person_roles.member_id` (0047).
- 2026-02-24: Baseline regenerated after member-device distribution + tenant-denorm index posture migration (0048).
- 2026-02-24: Baseline regenerated after member-device event append-only ingress-anchored migration (0049).
- 2026-02-24: Baseline regenerated after hierarchy verification function migration (`verify_instruction_hierarchy`) with deterministic SQLSTATE linkage checks (0050).
- 2026-02-24: Baseline regenerated after supervisor access mode control-plane hardening migration (0051).
- 2026-02-24: Baseline regenerated after risk formula registry + program deterministic tier-default migration (0052).
- 2026-02-25: Baseline regenerated after SIM-swap alert derivation and traceability migrations (`sim_swap_alerts`, event-type expansion, derive function ordering fix) (0053, 0054, 0055).
- 2026-02-25: Baseline regenerated after hierarchy SQLSTATE alignment migration for `verify_instruction_hierarchy()` deterministic mapping conformance (0056).
- 2026-02-25: Baseline regenerated after program migration contract alignment migration for `program_migration_events` and `migrate_person_to_program()` HIER-010 signature semantics (0057).
- 2026-02-25: Baseline regenerated after supervisor-access mechanism migration adding approval queue hold/approval metadata, single-arg supervisor submission path, and self-approval denial semantics in `decide_supervisor_approval()` (0058).
- 2026-02-25: Baseline regenerated after tenant isolation migration applying restrictive + forced RLS posture across tenant-scoped tables with cross-tenant leakage verification coverage (0059).
- 2026-02-26: Baseline regenerated after regulatory incident workflow migration introducing `regulatory_incidents` and append-only `incident_events` for 48-hour BoZ incident report export posture (0060).
- 2026-03-05: Baseline regenerated after Wave-1 hardening inquiry state-machine migration adding `inquiry_state_machine` and fail-closed auto-finalize guard (0061).
- 2026-03-05: Baseline regenerated after Wave-1 hardening runtime control migration adding effect sealing, finality conflict containment, malformed quarantine, circuit-breaker suspension, offline safe mode, and orphan/replay containment primitives (0062).
- 2026-03-05: Baseline regenerated after Wave-2 adjustment governance migration adding adjustment instruction lifecycle, approvals/quorum tables, execution-idempotency and ceiling checks, cooling/freezes gate primitives, and terminal immutability trigger (0063).
- 2026-03-05: Baseline refreshed after adding migration 0064_hard_wave3_reference_strategy_and_registry.sql (Wave-3 reference governance).
- 2026-03-05: Baseline refreshed after adding migration 0065_hard_wave4_signing_controls_and_assurance.sql (Wave-4 signing controls and assurance).
- 2026-03-05: Baseline refreshed after adding migration 0066_hard_wave5_archive_merkle_and_replay.sql (Wave-5 archive merkle anchoring and replay integrity controls).
- 2026-03-05: Baseline refreshed after adding migration 0067_hard_wave5_reference_strategy_rotation_and_allocation_race.sql (Wave-5 reference-strategy policy-rotation continuity, fail-closed length enforcement, and concurrent collision retry hardening).
- 2026-03-05: Baseline refreshed after adding migration 0069_hard_wave6_merkle_and_policy_rotation_guards.sql (Merkle null-expected-hash fail-closed verification and policy-rotation immutability guard hardening).
- 2026-03-09: Baseline refreshed after adding migration 0070_cqrs_projection_roles_and_read_models.sql (Phase-1 CQRS/projection role separation and deterministic projection read-model cutover).
- 2026-03-06: Baseline refreshed after adding migration 0072_hard_wave6_reference_policy_post_deactivation_immutability.sql (post-deactivation policy-row immutability enforcement for previously ACTIVE records).
- 2026-03-21: Baseline regenerated after Wave F onboarding control plane RLS hardening (0077).
- 2026-03-27: Baseline regenerated after scrubbing orphaned Wave 2 configuration components (0085-0094).
- 2026-04-01: Baseline regenerated after Green Finance Wave 1 DB verifier integration (0097-0114).
- 2026-04-15: Baseline regenerated using generate_baseline_snapshot.sh to sync with migration 0115 (supplier_type column added to supplier_registry table).
- 2026-04-17: Baseline regenerated after TSK-OPS-DRD-008 compliance rewrite of migration 0116 (ALTER TABLE with temporal columns on interpretation_packs, resolve_interpretation_pack SECURITY DEFINER function with REVOKE/GRANT posture) and inclusion of migration 0117 (factor_registry).
- 2026-04-18: Baseline regenerated after Wave 3 Phase 2 implementation adding execution_records table with interpretation_version_id FK to bind executions to interpretation packs (migration 0118).
- 2026-04-18: Baseline regenerated from fresh database using migrate.sh to ensure parity with pre_ci verification process and fix schema_migrations consistency (migration 0118 was missing from schema_migrations in main DB).
- 2026-04-18: Baseline regenerated after manually inserting migration 0118 into main database schema_migrations table to fix consistency; baseline now matches both main DB and pre_ci fresh DB verification.
- 2026-04-19: Baseline regenerated after Phase-2 data authority enforcement migrations (0121, 0122).
- 2026-04-19: Baseline regenerated after statutory levy, exchange rate audit, and postgis taxonomy migrations (0123-0130).
- 2026-04-24: Baseline regenerated after Wave 3-5 execution records determinism columns/constraints/triggers (0131-0133), Wave 4 policy decisions and state rules (0134-0136), and Wave 5 state machine layer — state_transitions, state_current, enforcement triggers, and update_current_state function (0137-0144).
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-01 (0145) correcting column name mismatch in enforce_transition_authority() trigger function from decision_id to policy_decision_id.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-02 (0146) adding entity_type TEXT NOT NULL column to state_rules table and updating unique constraint to include entity_type for domain-isolated rule resolution.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-03 (0147) adding FOREIGN KEY constraints for execution_id and policy_decision_id on state_transitions table to enforce DB-level referential integrity.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-04 (0148) adding SECURITY DEFINER and SET search_path = pg_catalog, public to all 6 Wave 5 trigger functions to prevent privilege escalation via search_path manipulation.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-05 (0149) renaming all triggers on state_transitions to use bi_XX_ (BEFORE INSERT), bd_XX_ (BEFORE DELETE), and ai_XX_ (AFTER INSERT) prefixes to guarantee deterministic execution order.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-06 (0150) changing fk_last_transition foreign key on state_current.last_transition_id from ON DELETE CASCADE to ON DELETE RESTRICT to preserve append-only audit history.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-07 (0151) verifying NOT NULL constraint on state_current.current_state. Migration 0138 already created this column as VARCHAR NOT NULL, so this is a verification-only no-op that confirms the constraint exists. No schema changes were made.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-08 (0152) adding explicit GF-prefixed SQLSTATE codes to all RAISE EXCEPTION statements in Wave 5 trigger functions. Function bodies unchanged except for adding USING ERRCODE clauses to enable structured error handling.
- 2026-04-24: Baseline regenerated after Wave 5 Stabilization FIX-09 (0153) adding a BEFORE INSERT trigger that prefixes transition_hash with PLACEHOLDER_PENDING_SIGNING_CONTRACT: to distinguish placeholder hashes from real cryptographic output.
- 2026-04-26: Baseline regenerated after Wave 7-STRICT migrations (0163-0171) adding invariant registry, public keys registry, delegated signing grants, interpretation overlap exclusion constraint (TSK-P2-PREAUTH-007-10), attestation seam schema with correct attestation_source_type enum, version column, and hash format constraints (TSK-P2-PREAUTH-007-12), Phase 1 boundary marker schema with columns and trigger enforcing phase1 rules (TSK-P2-PREAUTH-007-11), attestation anti-replay contract with nonce, unique hash constraint, and freshness trigger (TSK-P2-PREAUTH-007-13), DB kill switch gate with check_invariant_gate function and trigger on asset_batches (TSK-P2-PREAUTH-007-14), and INV-165/INV-167 verifier corrections fixing orthogonal string matching and hardcoded ID=175 bug (TSK-P2-PREAUTH-007-17).
