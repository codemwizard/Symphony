# PLAN — Zambia Regulatory Invariants (Roadmap Declarations + ADR Stubs)

## Task IDs
- TSK-P0-114
- TSK-P0-115
- TSK-P0-116
- TSK-P0-117

## Context
Strategic directive introduces high-stakes requirements for:
- Bank of Zambia payment finality (CII / NPS Act framing).
- Zambia Data Protection Act (ZDPA) erasure survivability for long-term evidence.
- IPDR truth anchors (NFS sequence continuity).

Phase-0 in this repo is explicitly a mechanically defensible foundation without jurisdiction-locked runtime semantics. The correct Phase-0 action is to:
- declare these requirements as **roadmap invariants** (not implemented),
- produce authoritative ADRs that define the model and activation preconditions,
- and add Phase-0 governance documentation that gives auditors line-of-sight.

### Decisions (from owner guidance; binding for this plan)
- Severity axis vs activation axis are distinct:
  - These invariants are **P0 by impact** (regulatory shutdown / legal exposure).
  - Enforcement is **deferred by design** to Phase-1/2 (requires rail adapters + legal workflows).
- IPDR modeling is generic:
  - Base invariant is "Rail truth-anchor sequence" (generic).
  - Zambia instantiation is a profile (e.g., `ZM-NFS`) using `nfs_sequence_ref` and participant scoping.

## Scope (Phase-0 Appropriate)
- Register roadmap invariants in the canonical registry (`docs/invariants/INVARIANTS_MANIFEST.yml`) using numeric IDs with directive IDs captured as aliases:
  - `INV-BOZ-04` Instruction Irrevocability / Payment Finality (alias)
  - `INV-ZDPA-01` PII Decoupling + Right-to-be-Forgotten Survivability (alias)
  - `INV-IPDR-02` NFS Sequence Continuity (alias)
- Update `docs/invariants/INVARIANTS_ROADMAP.md` so coverage checks pass.
- Create authoritative ADR stubs under `docs/decisions/`:
  - Payment finality model and reversal-only transitions (deferred enforcement).
  - ZDPA identity decoupling strategy and evidence survivability (deferred enforcement).
  - NFS sequence continuity/IPDR anchor model (deferred enforcement).
- Create Phase-0 governance stubs clarifying activation preconditions and boundaries.

## Non-Goals
- No DB schema changes for finality state, PII vault, or rail sequence uniqueness in Phase-0.
- No ISO 20022 camt.056 workflow implementation in Phase-0.
- No claim of regulatory certification or legal compliance in Phase-0 (documents are stubs + roadmap).

## Deliverables
- Roadmap invariants registered (status `roadmap`) with explicit Phase-1/2 activation notes.
- ADRs that:
  - define the intended semantics unambiguously,
  - enumerate required schema changes and mechanical verifiers,
  - define auditability and failure modes,
  - and state why enforcement is deferred out of Phase-0.
- Phase-0 doc stubs:
  - Zambia CII/BoZ designation brief (technical posture summary).
  - ZDPA compliance mapping stub (sections-to-controls placeholder).
  - Regulatory activation preconditions (what triggers Phase-1 enforcement).

## Proposed Manifest Entries (Exact Draft, Pending TSK-P0-115)
Manifest schema in this repo requires numeric IDs (`INV-###`). Directive IDs are captured as **aliases**.

Recommended new IDs (next after `INV-105`):
- `INV-114` Payment Finality (alias `INV-BOZ-04`)
- `INV-115` ZDPA Erasure Survivability (alias `INV-ZDPA-01`)
- `INV-116` Rail Truth-Anchor Sequence (alias `INV-IPDR-02`)

Draft entries (Phase-0 = roadmap only; activation described in `verification`):
```yaml
- id: INV-114
  aliases: ["INV-BOZ-04"]
  status: roadmap
  severity: P0
  title: "Payment finality / instruction irrevocability (reversal-only via ISO 20022 camt.056)"
  owners: ["team-db", "team-platform"]
  sla_days: 14
  verification: "Phase-1 activation: enforce finality state machine + camt.056 reversal workflow; add mechanical DB constraints/triggers and CI tests; Phase-0 is declarative only."

- id: INV-115
  aliases: ["INV-ZDPA-01"]
  status: roadmap
  severity: P0
  title: "PII decoupling + right-to-be-forgotten survivability (evidence remains valid after PII purge)"
  owners: ["team-security", "team-db", "team-platform"]
  sla_days: 14
  verification: "Phase-1/2 activation: tokenization/vault tables + retention hooks + evidence signing over identity_hash; add mechanical purge tests and signature verification; Phase-0 is declarative only."

- id: INV-116
  aliases: ["INV-IPDR-02"]
  status: roadmap
  severity: P0
  title: "Rail truth-anchor sequence continuity (generic; jurisdiction profiles e.g. ZM-NFS)"
  owners: ["team-db", "team-platform"]
  sla_days: 14
  verification: "Phase-1 activation: require non-null rail sequence ref on success + uniqueness scoped to (rail_sequence_ref, rail_participant_id); add DB constraints/indexes and CI integration tests; Phase-0 is declarative only."
```

## Task Breakdown
### TSK-P0-114 (ARCHITECT)
- Create plan folder + tasks scaffolding for this cluster.
- Keep Phase-0 boundary explicit: roadmap + ADRs only.

### TSK-P0-115 (INVARIANTS_CURATOR)
- Add new roadmap invariants to `docs/invariants/INVARIANTS_MANIFEST.yml` using the next available numeric IDs.
- Ensure each has:
  - `aliases` including the directive invariant ID (e.g., `INV-BOZ-04`),
  - clear `verification` text (non-placeholder) describing Phase-1 verification intent,
  - owners + severity consistent with business criticality.
- Update `docs/invariants/INVARIANTS_ROADMAP.md` to include the new invariants so `scripts/audit/check_docs_match_manifest.py` coverage remains satisfied.

### TSK-P0-116 (ARCHITECT)
- Create ADR stubs in `docs/decisions/` covering:
  - Finality semantics (no cancel/void except reversal workflow).
  - PII decoupling + retention/erasure survivability requirements.
  - NFS sequence continuity: uniqueness, non-nullability-on-success, participant scoping.
- ADRs must explicitly list the future mechanical checks required to promote roadmap -> implemented.

### TSK-P0-117 (COMPLIANCE_MAPPER)
- Draft Phase-0 Zambia-facing documentation stubs (no claims of compliance):
  - CII designation brief for ZICTA/BoZ.
  - ZDPA compliance map (sections-to-controls placeholder).
  - Regulatory activation preconditions and audit artifacts inventory.

## Gates / Verifiers (Phase-0)
- `scripts/audit/run_invariants_fast_checks.sh`
  - includes `scripts/audit/check_docs_match_manifest.py` coverage checks.

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
