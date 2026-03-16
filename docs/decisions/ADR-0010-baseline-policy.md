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
- 2026-03-12: Baseline refreshed after adding migration 0073_int_004_ack_gap_controls.sql (AWAITING_EXECUTION acknowledgement-gap escalation, supervisor recovery controls, and append-only interrupt audit trail).
- 2026-03-12: Baseline refreshed again after wiring `guard_settlement_requires_acknowledgement()` into `instruction_settlement_finality` settlement inserts via `trg_enforce_settlement_acknowledgement`, preserving the `0073_int_004_ack_gap_controls.sql` cutoff while closing the runtime enforcement gap.
- 2026-03-16: Baseline regenerated after Wave 1 security hardening adding billable clients conflict target uniqueness (0074) and supplier registry persistance/RLS (0075).
