# PHASE8A_CARRY_FORWARD_OBLIGATIONS.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-8A
Depends-On:
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md
  - docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md

Effective-Date: 2026-05-10

---

## Purpose

This document registers the carry-forward obligations assigned to Phase 8A
(Sovereign Authorization Layer) as determined by the Phase 3 capability boundary
rewrite (2026-05-10) and the canonical phase assignment derived from
Symphony-Phase-Specification-Document_v1.md.

It also registers the MADD/MAIN constitutional definitions as Phase 8A
implementation prerequisites, sourced from the MADD_MAIN_INTEGRATION_DOCTRINE.md
and clarified by the Main-Madd-Specs.md architectural input.

---

## CF-3: Sovereign Authorization Schema (MADD/MAIN Integration)

**Origin:** docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md, §3
**Assigned to Phase 8A by:** docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md §Carry-Forward Obligations
**Determination date:** 2026-05-10

### Description

Expanding into Article 6 sovereign contexts requires a specialized authorization
schema linking Market Authorization (MAIN) to Mitigation Activity Design Documents
(MADD). This schema is currently deferred and must be implemented in Phase 8A before
sovereign credit issuance can occur.

### Phase Specification Basis

Symphony-Phase-Specification-Document_v1.md §Phase 8A — Sovereign Authorization Layer:

> "Builds: Machine-readable host-country authorization request packs, LoA
> ingestion/recording workflows, corresponding adjustment bindings, and
> first-transfer proof attachments."
> "Exit Criteria: Functional authorization packs and immutable LoA ingestions
> that classify credits correctly."

The MAIN authorization is the "permission to exist" in the market (host-country
authorization). The MADD is the "scientific truth" attestation that backs it.
The Phase 8A authorization schema must formally link these two instruments.

### Constitutional Doctrine Reference

The full constitutional doctrine governing MADD and MAIN integration is defined
in docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md (Authority-Rank 8, ROOT
interpretation authority). That document is the authoritative source for all
MADD/MAIN constitutional definitions. Phase 8A implementation must be governed
by that doctrine.

Key constitutional mapping (from MADD_MAIN_INTEGRATION_DOCTRINE.md and
corroborated by Main-Madd-Specs.md):

| Instrument | Zambian Legal Source | Symphony Sovereign Layer | Constitutional Role |
|---|---|---|---|
| MAIN (Market Authorization Information Notification) | SI 5 of 2026, Part III | Wave 4 — Operational/Runtime | Execution Authority — permission to trade |
| MADD (Mitigation Activity Design Document) | SI 5 of 2026, Part IV | Wave 8 — Provenance/Cryptographic | Attestation Provenance — scientific truth |

**Critical sovereignty rule (MADD_MAIN_INTEGRATION_DOCTRINE.md):**
- MADD is a Wave 8 (Identity/Provenance) artifact: a signed attestation by a
  ZEMA-accredited verifier.
- MAIN is a Wave 4 (Runtime/Operational) artifact: a permission instrument issued
  by MGEE.
- These are constitutionally orthogonal and must never be collapsed into a single
  authority surface.
- The platform shall not authorize an asset issuance (MAIN activation) unless a
  valid, cryptographically signed MADD exists within the provenance sovereignty
  domain. This link is immutable and compositional.

### Escalation Trigger (unchanged from Phase 2 filing)

Becomes an immediate blocker if sovereign credit issuance is attempted without
the Phase 8A authorization schema being implemented.

### Phase 8A Entry Conditions

CF-3 must be addressed as a formal Phase 8A task pack. Phase 8A entry conditions:

1. Phase 3 (Constraint and Legitimacy Engine) is complete — required per
   Symphony-Phase-Specification-Document_v1.md §Critical Cross-Phase Dependencies:
   "Phase 3 must precede Phase 8A."
2. Phase 5 (Adapter Refactor) is complete — required for multi-artifact outputs.
3. Phase 6 VVB Portal is complete — required for independent VVB checks per
   Article 6 requirements.
4. Domain-canonical policy review of the MADD/MAIN schema is complete.
5. Stage A approval metadata is produced before schema modifications begin.

### Status

DEFERRED. Non-triggered. Non-blocking for Phase 3. Phase 8A is not yet open.
This obligation is registered for Phase 8A planning.

---

## MADD/MAIN Concept Register (Phase 8A Implementation Prerequisites)

The following definitions are sourced from docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md
and corroborated by Main-Madd-Specs.md. They are registered here as Phase 8A
implementation prerequisites so that Phase 8A task generation has an authoritative
reference for MADD and MAIN scope.

### MAIN — Market Authorization Information Notification

- **Regulatory source:** SI 5 of 2026, Ministry of Green Economy and Environment (MGEE)
- **Constitutional classification:** External regulatory instrument; MGEE-sovereign
- **Symphony sovereign layer:** Wave 4 — Operational/Runtime
- **Function:** The formal legal instrument granting "Market Authorization" to a project.
  Serves as the "permission to exist" in the Zambian carbon market.
- **Implementation requirement:** A MAIN cannot be activated in Symphony without a
  corresponding MADD reference. This is a hard compositional rule, not a soft check.
- **Integration boundary:** MAIN records enter Symphony at the Phase 8A authorization
  boundary. They are Wave 4 artifacts once ingested.

### MADD — Mitigation Activity Design Document

- **Regulatory source:** SI 5 of 2026, Part IV, ZEMA-accredited verifier process
- **Constitutional classification:** External evidentiary attestation; ZEMA-sovereign
- **Symphony sovereign layer:** Wave 8 — Provenance/Cryptographic
- **Function:** The technical evidence package detailing the methodology, baseline, and
  expected emission reductions. Serves as the "scientific truth" backing the MAIN.
- **Implementation requirement:** MADD integrity must be cryptographically verifiable
  independently of the MAIN's market status. If the MAIN is revoked, the MADD's
  historical evidentiary standing as a scientific attestation remains.
- **Sovereignty rule:** MADD signatures must originate from a ZEMA-accredited verifier
  key. The Identity/Provenance layer does not trust the Runtime layer to generate
  MADD attestations. These are constitutionally isolated authority surfaces.

### Compositional Integrity Rule (Phase 8A Implementation Constraint)

The relationship between MADD and MAIN is orthogonal but linked:

1. **Runtime gate:** The Wave 4 operational layer must not authorize an asset issuance
   unless the Wave 8 provenance layer holds a valid cryptographic attestation for the
   MADD_ID referenced in the MAIN filing.
2. **Mutation rule:** Any update to the MADD (methodology update) requires new Wave 8
   provenance attestations before the MAIN can resume execution authority.
3. **Independence rule:** MADD validity is independent of MAIN status. MADD revocation
   does not automatically revoke the MAIN, and vice versa. Each operates in its
   constitutional sovereignty domain.
4. **Replay rule:** Both MAIN authorization records and MADD attestation records must
   be permanently replayable from persisted fields without access to MGEE or ZEMA
   operational systems.

### What Phase 8A Must NOT Do

Phase 8A must NOT collapse MADD and MAIN into a single authorization record.
Phase 8A must NOT treat ZEMA accreditation as equivalent to Wave 8 cryptographic
enforcement — they are complementary, not substitutable.
Phase 8A must NOT implement MADD/MAIN integration as a Phase 3, 4, 5, or 6 task.
The constitutional doctrine and carry-forward have both confirmed Phase 8A as the
correct implementation phase.

---

## Note on Phase 8A Cross-Phase Dependencies

Per Symphony-Phase-Specification-Document_v1.md §Critical Cross-Phase Dependencies:

- Phase 3 must precede Phase 8A (legitimacy engine required for national authority acceptance)
- Phase 4 must precede Phase 8B (statutory deductions must calculate before registry reporting)
- Phase 5 must precede all Phase 8 sub-phases (multi-artifact outputs required)
- Phase 6 VVB Portal must precede Phase 8A (Article 6 requirement)

CF-3 resolution in Phase 8A therefore depends on Phases 3, 4, 5, and 6 being complete.
