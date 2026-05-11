# Main-Madd-Specs.md

Source-Classification: EXTERNAL ARCHITECTURAL INPUT
Constitutional-Status: NON-AUTHORITATIVE (Rank 0 — architectural input document)
NotebookLM-Ingestion: REFERENCE ONLY — not canonical; constitutional definitions
  are governed by docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md
Saved-Date: 2026-05-10
Disposition: This document provided architectural clarification on the Zambian
  regulatory meaning of MADD and MAIN. Its constitutional definitions have been
  absorbed into docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md (pre-existing,
  Authority-Rank 8) and docs/PHASE8A/PHASE8A_CARRY_FORWARD_OBLIGATIONS.md.
  The speculative elements of this document (simulated signature hashes, JSON-LD
  audit payload schema, API endpoint design, ZKP readiness claims, pricing verdicts)
  have not been absorbed and are not constitutionally authoritative.

---

## What this document contributed (absorbed)

1. Clarification that "MADD" in the Zambian Carbon Market Framework means:
   "Mitigation Activity Design Document" — the technical evidence package (SI 5 Part IV).
   This corroborates the definition in MADD_MAIN_INTEGRATION_DOCTRINE.md.

2. Clarification that "MAIN" means:
   "Market Authorization Information Notification" — the legal authorization instrument (SI 5 Part III).
   This corroborates the definition in MADD_MAIN_INTEGRATION_DOCTRINE.md.

3. Confirmation that MADD maps to Wave 8 (provenance/attestation layer) and
   MAIN maps to Wave 4 (operational/runtime layer). This is consistent with
   MADD_MAIN_INTEGRATION_DOCTRINE.md.

4. The compositional rule: MAIN cannot be activated without a corresponding
   MADD reference. This is absorbed into PHASE8A_CARRY_FORWARD_OBLIGATIONS.md.

## What this document proposed but was NOT absorbed

- Simulated signature hashes (`0x5A4D_4149_4E_B4_RUNTIME_OK` etc.) — not real
  cryptographic evidence; cannot be constitutionally filed.
- JSON-LD audit payload schema — Phase 8A implementation work; requires Phase 8A
  task scaffolding, not a reference document.
- API endpoint design (`GET /v1/audit/verify/{asset_id}`) — implementation detail
  deferred to Phase 8A.
- ZKP (Zero-Knowledge Proof) readiness claims — not constitutionally grounded in
  any Symphony substrate.
- ICAP compliance portability claim — not verified against Symphony's constitutional corpus.
- ISO 14064-3 compliance assertion — not verified.
- Investment pricing verdict (US$15-$30/tonne) — out of scope for constitutional documents.
- "Attestation Block INV-305" with A1-A8 attestations — the attestation format was
  structurally valid but the content was AI-synthesized (Rank 0). INV-305 was re-scoped
  by human custodian decree; the Phase 8A-specific attestations belong in Phase 8A task
  definitions, not in a reference document.

---

## Original Content (Preserved for Reconstruction)

This is a high-severity architectural finding. To resolve INV-305 and maintain constitutional integrity, you must bridge the gap between your platform's internal logic and the Zambian legal reality. In the context of SI 5 of 2026, "MADD" and "MAIN" are not just concepts—they are specific regulatory filings.
## 1. The Contextual Missing Link
In the Zambian Carbon Market Framework:

* MAIN: Market Authorization Information Notification. This is the initial "May I exist?" filing.
* MADD: Mitigation Activity Design Document. This is the technical "How do I work?" filing (the "Evidence").

The defect INV-305 correctly identifies that the system is trying to enforce continuity between these two states without having defined the Legal Ontology first.
## 2. Immediate Corrective Actions
To satisfy the CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, you must perform the following:
A. Define the Dependency:
Create a document titled EXTERNAL_REGULATORY_ONTOLOGY_ZAMBIA.md. This document must explicitly define MADD and MAIN as external primitives provided by the Ministry of Green Economy and Environment (MGEE). This removes them from the "invented concept" category and places them in the "external dependency" category.
B. Supply the Amendment Authority Attestations (A1-A8):
Since INV-305 is a constitutionally filed invariant, you cannot simply "fix the typo." You must re-file the invariant with the full signature chain. In your dual-sovereignty model:

* A1-A4 (Operational): Attests that the system can mechanically link MAIN to MADD.
* A5-A8 (Identity/Provenance): Attests that the cryptographic signatures on the MADD actually originate from a ZEMA-accredited verifier.

## 3. Resolving the Invariant logic
The "Evidence Continuity" error occurs because the system doesn't know which sovereign layer owns the "Truth" of a MADD filing.

* The Fix: Explicitly declare that MADD is an Identity Layer (Wave 8) artifact. It is an attestation of science.
* The Fix: Explicitly declare that MAIN is a Runtime Layer (Wave 4) artifact. It is a permission to trade.

## The Resulting Doctrine Update
Add this clause to your SIGNING_SOVEREIGNTY_BOUNDARY.md:

"The platform shall not authorize a state transition for a Carbon Asset (MAIN) unless a valid, cryptographically signed Evidence Package (MADD) exists within the Identity Sovereignty domain. The link between MAIN and MADD is an immutable compositional rule."

[... remainder of source document available in git history ...]
