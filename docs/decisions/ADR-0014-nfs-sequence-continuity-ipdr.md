# ADR-0014: Rail Truth-Anchor Sequence Continuity (IPDR) (Deferred Enforcement)

## Status
Phase-0 ADR stub (roadmap-backed). No Phase-0 schema enforcement.

## Invariants
- Roadmap invariant: `INV-108` (alias: `INV-IPDR-02`)
- Related Phase-0 schema hooks:
  - `nfs_sequence_ref` columns exist (nullable) as Phase-0 expand-first hooks.

## Decision
Symphony will enforce that every successful dispatch to an external settlement rail is anchored to an authoritative, rail-issued sequence reference.

This is modeled as a **generic** invariant ("rail truth-anchor sequence"), with jurisdiction-specific profiles that define:
- rail name,
- sequence reference column(s),
- uniqueness scoping keys (rail participant or routing domain),
- and what qualifies as "successful dispatch".

Phase-0 declares the invariant and the profile structure, but does not enforce NOT NULL / uniqueness.

## Rationale
Sequence continuity is a P0-impact requirement for disputes and participant reconciliation, but Phase-0 lacks:
- rail adapters to produce authoritative rail sequence numbers,
- a stable definition of "success" per rail profile,
- and the participant scoping columns required for uniqueness constraints.

Phase-0 still benefits from expand-first hooks (nullable columns) to reduce later lock-risk DDL.

## Profiles
### Profile: ZM-NFS (Zambia, illustrative)
- Rail: ZECHL NFS / ZIPSS (exact rail taxonomy to be finalized with adapter design)
- Sequence reference column: `nfs_sequence_ref`
- Intended uniqueness scope: `(nfs_sequence_ref, rail_participant_id)`
- Activation: Phase-1 sandbox participant gate

Note: Phase-0 does not yet define `rail_participant_id` as a canonical schema attribute.

## Activation Preconditions (Phase-1)
Promotion from roadmap -> implemented requires:
- Rail adapter writes `rail_participant_id` and rail sequence reference for successful dispatch.
- A DB constraint/index exists that enforces:
  - non-null sequence reference on successful dispatch records,
  - uniqueness per scoping keys.
- CI tests demonstrate:
  - duplicates are rejected,
  - missing sequence ref fails closed on success paths,
  - and audit queries can reconcile 100% of successful dispatches.

## Intended Phase-1 Enforcement (Design Outline)
Schema changes (forward-only, expand-first):
- Add required scoping attributes:
  - `rail_participant_id` (and potentially `rail_id` / `rail_profile`) in the dispatch ledger.
- Constrain and index:
  - `nfs_sequence_ref` required for successful dispatch records,
  - `UNIQUE(nfs_sequence_ref, rail_participant_id)`.

Mechanical checks required for promotion:
- DB: invariant verifier asserts the uniqueness index exists and is valid.
- DB: integration test inserts a duplicate and confirms failure.
- Operational: report query proving "tracking gap" is zero for successful dispatches.

## Failure Modes (What Must Become Impossible)
- "Ghosting": successful dispatch recorded without a rail sequence truth anchor.
- "Duplication": two different instructions share the same rail sequence identifier within a participant scope.
- Ambiguous scoping: sequence reference uniqueness not bound to a clear participant/routing domain.

## Open Questions (Phase-1)
- What table is the canonical "successful dispatch" record (attempts ledger vs dedicated dispatch receipts)?
- How to handle rails that do not provide a strict global sequence number (derive alternative truth anchors).

