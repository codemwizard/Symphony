# Update phase capability boundary

> First read docs/architecture/Symphony-Phase-Specification-Document_v1 so that you get an understanding of what is being built and where it is leading to. It should also help you understand the boundariesof each phase so that you make better decisions when defining the boundaries of task below.
> 1. Review docs/PHASE3/PHASE_CAPABILITY_BOUNDARY.md. Then review the documents in docx/constitutuinal/ and see if there are any that contradict or conflict with it or have relevant information to add to it to further define its scope. Create a full draft version of PHASE_CAPABILITY_BOUNDARY.md but do not overwrite the original. Make sure to flag every change and cite the exact document that you used for the change and why.

<details><summary>2 previous messages</summary>

> I’ll first follow the repo’s agent entrypoint and routing requirements, then read the phase specification and boundary docs before drafting anything. After that I’ll compare the constitutional source set and create a separate draft file with source-cited change flags.
>
> The router has a narrow task-pack workflow, so I’m checking the root execution envelope and any rejection state before deciding how far I can proceed without violating the repo contract. I’m also going to run the local conformance gate because the AGENTS contract makes that a prerequisite for agent work.
</details>

I’m blocked by the repo’s own operating contract before I can draft the new file.

Current blockers:

1. `AGENT_PROMPT_ROUTER.md` does not map this request cleanly to exactly one permitted mode. It is not a normal `IMPLEMENT-TASK` resume because no task ID / task pack was provided.
2. `scripts/audit/verify_agent_conformance.sh` could not run because this environment has no installed WSL distribution, so the required conformance gate did not pass.
3. `docs/operations/PHASE_EXECUTION_ENVELOPE.md` currently says Phase-3 surfaces are not open and flags `docs/PHASE3/**` implementation content as non-executable. A draft Phase-3 boundary document may need an explicit task/approval path before I can write it.

To proceed safely, I need you to either provide the existing task ID that authorizes this documentation work, or explicitly direct me to create/repair the task pack first with the required Phase, acceptance criteria, verifier, and permitted touch paths.

> The AGENT_ENTRYPOINT.md only applies to tasks that are being created for implemtation. This is a purely research task and nothing you are doing is being implemented so how are you blocked

<details><summary>2 previous messages</summary>

> You’re right to challenge that. I treated the router as gating all repo-scoped file creation, but your request is research and drafting against existing source documents, not implementation execution; I should have proceeded under that distinction while still respecting “do not overwrite original” and avoiding implementation claims.
>
> I’ll do the research pass now: read the phase specification, current Phase 3 boundary, then inventory the constitutional documents and produce a separate draft with explicit change flags and citations.
>
> Two requested paths appear to be slightly different in the repo: I found `docs/constitutional/**` rather than `docx/constitutuinal/**`, and the exact phase/boundary filenames are not at the paths given. I’m locating the closest canonical files by name before drafting so the output is anchored to actual repo content.
</details>

The current boundary already has a companion review assessment that identifies several gaps and conflicts. I’m using that as a starting map, then checking the constitutional corpus directly so the draft can cite source documents rather than relying only on the assessment.

> Do not use any prior assessment because they are faulty and will reintroduce noise. Just do your own assessment based on the instructions and documents I have outlined in the docs/constitutional/ and docs/architecture/Symphony-Phase-Specification-document_v1.md.

<details><summary>6 previous messages</summary>

> Understood. I’ll discard the prior assessment entirely and base this pass only on the phase specification, the current Phase 3 boundary, and the documents under `docs/constitutional/`. I’ll use the assessment file only as something to avoid, not as a source.
>
> I’ve got the two anchor documents and the constitutional corpus inventory. Next I’m narrowing the constitutional documents into direct scope drivers, conflict drivers, and no-change references, so the draft can show both what changed and why other constitutional files did not change the boundary.
>
> The main independent findings are clear now: the current boundary is directionally aligned with the phase spec, but it needs tighter constitutional guardrails around authority posture, replay/historical evaluation, regulator non-collapse, task generation, metadata/authority status, and entry-condition wording. I’m drafting a separate full version with a change register and an all-constitutional-doc review appendix.
>
> I’m going to write the draft as a new file under `docs/PHASE3/` and leave the existing boundary untouched. The draft will mark every substantive delta with `CHANGE-CB-*` IDs and include a document-by-document review appendix for the constitutional corpus.
>
> <details><summary>Created 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md` (+789 -0)
>
> </details>
>
> The draft file is created. I’m doing a quick integrity pass now: checking that the file exists, that the change IDs are present, and that the original boundary file was not modified.
</details>

Created the full draft here:

[PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md](./docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md)

I did not overwrite the original. `git status` shows only the new draft file as untracked; the existing [PHASE3_CAPABILITY_BOUNDARY.md](./docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md) is unchanged.

The draft includes:

- A `CHANGE-CB-001` through `CHANGE-CB-015` register.
- Inline change flags throughout the full draft boundary.
- Exact source-document citations for each change and why it was made.
- A document-by-document appendix covering the `docs/constitutional/` corpus.
- A conflict/addition summary based only on the phase spec, current boundary, and constitutional docs, not the prior assessment.

> Compare this attachment to the draft you just made and state:
> 1. What is in the attachment that is immediately of value to the draft you create and can be directly ported to it without conflict
> 2. What is better defined, scoped in the attached document that you think can be infused in or overwrite the draft you created
> 3. What is in direct conflict with the document and need a decision before being added to draft
> 4. What other thoughts you might have
>
> User context
>
> Attachments:
> - ChatGPT-Draft_Canonical_Boundary.md: `C:/Workspace/GitHub/Symphony-Buraucracy/Boundary-Definitions/ChatGPT-Draft_Canonical_Boundary.md`

<details><summary>1 previous message</summary>

> I’ll compare the attached boundary draft against the draft I created, using only non-mutating reads. I’ll focus on portable value, stronger definitions, conflicts requiring a decision, and any structural concerns.
</details>

Yes. I compared the attached `ChatGPT-Draft_Canonical_Boundary.md` against the draft I created at `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md`.

**1. Immediately Valuable And Directly Portable**
These can be ported with little or no conflict:

- The opening framing: “Phase 3 transforms Symphony from cryptographically trustworthy into constitutionally legitimate and replay-reconstructable.” This is concise and stronger than my current purpose wording.
- The ontology separation table: Phase, Wave, Sovereignty Domain, Capability Boundary, Historical Truth, Replay Projection, Legitimacy Evaluation, Operational Exhaust. This is valuable and should be added near my `Constitutional Terminology` section.
- The stronger dependency graph lineage list: evidence lineage, authority lineage, policy lineage, contradiction lineage, admissibility lineage, constitutional failure lineage, replay projection lineage.
- The runtime-only prohibitions: no live memory state, mutable cache state, operational telemetry, implementation scaffolding, or transient execution context as legitimacy sources.
- The policy artifact constraints: version-pinned, replay-addressable, immutable, constitutionally declared policy artifacts only.
- The operational exhaust exclusion: implementation tasks, CI exhaust, debug logs, conversations, telemetry, and temporary coordination artifacts are not constitutional replay lineage.
- The spatial mechanics clarification: Phase 3 provides generalized spatial constraint mechanics only, not jurisdiction-specific environmental legality.
- The compact prohibited-responsibility table. My draft has the same concept, but the attachment’s table is easier to scan.

**2. Better Defined Or Better Scoped Than My Draft**
These are materially stronger than my current draft and should either be infused or partially overwrite sections:

- **Replay boundedness.** The attachment’s distinction between canonical replay lineage and replay acceleration artifacts is better than my draft. It clearly says checkpoints/snapshots/caches are non-authoritative, derivable, discardable, and must produce identical outcomes to canonical replay.
- **Projection isolation.** My draft mostly avoids projection semantics because the constitutional corpus does not define them cleanly. The attachment gives a useful emerging model: projection universes must be isolated, deterministic, replay-visible, and externally reconstructable.
- **Policy ontology.** The “Minimal Policy Ontology” table is useful: Constraint Policy, Authority Policy, Precedence Policy, Contradiction Policy, Replay Policy, Projection Policy. I would port it, but label it “Phase 3 internal policy artifact categories” rather than root ontology.
- **Contradiction outcomes.** The attachment’s list is useful: admissibility blocking, replay-visible supersession, compensating lineage attachment, contradiction quarantine, arbitration escalation. My draft says contradictions must be recorded or blocked, but the attachment gives better outcome categories.
- **Core vs external scope.** The attachment repeatedly states “Phase 3 executes mechanics only; it does not define sovereign policy meaning.” That should be infused throughout my sections on regulator-aware scope, authority scope, and spatial/DNSH.
- **No mutable truth.** My draft has this in prohibited capabilities, but the attachment’s framing is stronger: all legitimacy reconstruction must derive from append-only lineage.

**3. Direct Conflicts Or Decision Points Before Adding**
These should not be ported without a decision:

- **“Replay reconstruction may supersede historical admissibility conclusions” and “invalidate prior legitimacy states.”** This conflicts with the replay and temporal doctrines unless it is rewritten as: replay may append a later finding, contradiction, supersession, or invalidation record, but must not retroactively mutate historical truth.
- **“Distinct replay universes may produce distinct admissibility outcomes.”** Potentially valid, but dangerous. Needs a decision: are “replay universes” approved terminology, or should we use safer language like “bounded replay evaluation contexts”?
- **Projection doctrine.** The attachment treats replay projections as core Phase 3 concepts. My draft intentionally avoids making them first-class doctrine because the constitutional corpus does not define them. Decision needed: define projection now in this boundary, or defer to a separate `LEGITIMACY_AND_PROJECTION_DOCTRINE.md`.
- **Replay acceleration mechanics.** Useful, but may be too implementation-architectural for a capability boundary. Decision needed: keep a short guardrail in the boundary, or move detailed checkpoint/snapshot rules to a later replay architecture doctrine.
- **Sovereign overlay execution runtime.** The attachment mentions future overlay runtimes, syscall restriction, execution hash stability, and resource isolation. This is out of boundary scope unless explicitly marked as future non-Phase-3 doctrine.
- **Entry conditions.** The attachment adds concrete technical conditions like replay lineage persistence, contradiction lineage persistence, and replay reconstruction determinism certification. These are plausible, but stricter and more implementation-specific than my neutral entry-condition list. Needs decision before replacing my current language.
- **“Sovereign policy implementation” / “sovereign policy execution” as Phase 8.** This may be too broad. Some policy evaluation mechanics are Phase 3; external sovereign policy execution is later. Needs careful wording to avoid blocking Phase 3’s internal policy artifact consumption.

**4. Other Thoughts**
The attachment is stronger than my draft on conceptual precision around replay, projection, policy artifacts, and operational exhaust. My draft is stronger on source grounding, authority metadata, constitutional corpus traceability, and regulator/data-retention constraints.

Best path would be a hybrid:

- Keep my draft’s metadata, citations, change register, constitutional source grounding, entry-condition neutrality, and corpus review appendix.
- Port the attachment’s ontology separation, replay boundedness, policy artifact constraints, operational exhaust boundary, and projection-isolation guardrails.
- Rewrite the risky replay/projection language so it cannot imply retroactive mutation of historical truth.
- Do not import the attachment’s final self-assessment text into the document; treat it only as reviewer commentary.

If incorporated, I would add a new change flag like `CHANGE-CB-016 — Replay Projection and Operational Exhaust Boundary`, citing the attachment as advisory input and grounding the accepted parts in `REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`, `TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`, and `NON_INFERENCE_AND_INTERPRETATION_LIMITS.md`.

> For the direct conflicts found, are they mainly because Symphony does not define the partilcular doctrine fully or in part and therefore it is a weakness outside the PHASE3_CAPABILITY_BOUNDARY.md files jurisdiction or are they items that can be authoritatively defined within the document. If outside of it, state which governance documents need to be updated or created if not in any of them. Make sure to fully define the full doctrine or principles that are required to create or update these documents.

<details><summary>1 previous message</summary>

> I’ll verify whether the conflict terms are already defined anywhere in the constitutional corpus before classifying them as boundary-level vs outside-boundary doctrine. I’m checking for “projection,” “replay universe,” overlay execution, supersession/invalidation, and acceleration artifacts specifically.
</details>

Most direct conflicts are not because the attachment is “wrong”; they are because it tries to define doctrines that are only partially defined, or not defined at all, in the current constitutional corpus. `PHASE3_CAPABILITY_BOUNDARY.md` can reference and constrain those concepts, but it should not become the root authority for them.

**Classification**
| Conflict area | Boundary can define? | Better home |
|---|---:|---|
| Retroactive “supersede/invalidate prior legitimacy states” | No, only prohibit or reword | Existing replay/temporal/amendment doctrines |
| Replay projection / projection universe | No, except bounded placeholder | New `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` plus glossary |
| Projection cross-contamination | Partially as prohibition | New projection doctrine; regulator non-collapse update |
| Replay acceleration snapshots/checkpoints | Partially as guardrail | New `PHASE3_REPLAY_ACCELERATION_DOCTRINE.md` or evidentiary doctrine update |
| Sovereign overlay execution runtime | No | New future overlay doctrine, likely Phase 8-facing |
| Technical Phase 3 entry conditions | Partially | Phase 3 opening act, contract, legality matrix |
| Policy artifact ontology | Partially | New or updated policy/authority-lineage doctrine |

**1. Retroactive Supersession / Invalidation**
This is already governed outside the Phase 3 boundary.

The attachment says replay reconstruction may “supersede historical admissibility conclusions” or “invalidate prior legitimacy states.” That conflicts with:

- [TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md](./docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md)
- [REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md](./docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md)
- [EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md](./docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md)
- [CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md](./docs/constitutional/CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md)

Required principle:

> Phase 3 may append a new replay-visible finding, contradiction record, invalidation record, supersession record, or compensating lineage event. It must not retroactively mutate, erase, or reclassify the historical admissibility status that existed at the time of the original event.

So this belongs in the boundary only as a prohibition/rewording. The doctrine is already defined elsewhere.

**2. Replay Projection / Projection Universe**
This is the biggest genuine doctrinal gap. The corpus has snapshots, proof-of-state, replay reconstruction, and admissibility lineage, but it does not fully define “replay projection,” “projection universe,” or “projection isolation.”

This is outside the Phase 3 boundary’s jurisdiction if treated as a first-class constitutional concept.

Create:

[LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md](./docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md)

Core doctrine required:

> A replay projection is a deterministic, derived admissibility interpretation computed exclusively from append-only constitutional lineage under a bounded policy context, authority context, regulator-domain context, and temporal reconstruction point.

Required principles:

- Projection is not canonical truth.
- Projection is derived from canonical lineage.
- Projection is discardable and reproducible.
- Projection cannot introduce facts absent from persisted constitutional artifacts.
- Projection cannot mutate historical lineage.
- Projection cannot retroactively change historical admissibility.
- Distinct projection contexts may produce different present-time evaluative findings only if the underlying historical lineage remains unchanged and the context boundary is explicit.
- Every projection must declare policy lineage, authority lineage, regulator domain, replay time, evaluation time, and source artifact set.
- Projection output must be externally reconstructable without live runtime trust.

Also update:

- [CONSTITUTIONAL_GLOSSARY.md](./docs/constitutional/CONSTITUTIONAL_GLOSSARY.md): add `Replay Projection`, `Projection Context`, `Projection Isolation`.
- [NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md](./docs/constitutional/NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md): add projection terms to ontology drift protected terms.

**3. Projection Cross-Contamination**
This depends on whether projection becomes formal doctrine. If yes, the boundary can prohibit contamination, but the isolation mechanics belong outside it.

Update/create in the projection doctrine:

Required isolation vectors:

- policy lineage isolation;
- authority lineage isolation;
- regulator-domain isolation;
- contradiction lineage isolation;
- failure lineage isolation;
- replay acceleration artifact isolation;
- admissibility cache isolation;
- reconstruction materialization isolation;
- tenant and jurisdiction context isolation.

Required principle:

> No projection artifact, cache, checkpoint, materialized view, or acceleration layer may be shared across sovereignty domains unless the sharing protocol is explicitly declared, replay-visible, regulator-domain-safe, and produces no cross-domain admissibility inference.

Also update:

- [REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md](./docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md), adding projection isolation as a regulator non-collapse mechanism.

**4. Replay Acceleration Snapshots / Checkpoints**
This is partially covered, but not fully. Existing docs mention snapshots, canonicalization archive snapshots, registry snapshot hashes, and temporal proof-of-state. They do not fully define Phase 3 replay acceleration.

Boundary can say: acceleration artifacts are non-authoritative. Full rules should live elsewhere.

Create either:

[PHASE3_REPLAY_ACCELERATION_DOCTRINE.md](./docs/constitutional/PHASE3_REPLAY_ACCELERATION_DOCTRINE.md)

or add a section to [EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md](./docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md).

Required doctrine:

> Replay acceleration artifacts are derived, non-authoritative materializations used to speed replay reconstruction. They are admissible only as acceleration aids, never as independent constitutional truth.

Required principles:

- Must be derivable from canonical lineage.
- Must be discardable without loss of truth.
- Must be cryptographically sealable.
- Must include source artifact hashes.
- Must include reconstruction algorithm/version.
- Must produce identical admissibility outcomes to canonical replay.
- Must not become a mutable truth layer.
- Cache divergence must fail closed to canonical replay.

**5. Sovereign Overlay Execution Runtime**
This is outside `PHASE3_CAPABILITY_BOUNDARY.md`.

The attachment’s syscall restriction, execution hash stability, resource isolation, and overlay runtime language is implementation/runtime doctrine, not Phase 3 capability boundary doctrine. It likely belongs to future phases because Phase 3 consumes externally declared policy artifacts but does not execute sovereign overlays.

Create later:

[SOVEREIGN_OVERLAY_EXECUTION_DOCTRINE.md](./docs/constitutional/SOVEREIGN_OVERLAY_EXECUTION_DOCTRINE.md)

Required doctrine:

> A sovereign overlay execution runtime is an isolated execution surface for regulator-specific, jurisdiction-specific, or methodology-specific policy semantics that must remain outside the Phase 3 legitimacy core.

Required principles:

- Overlay execution is not Phase 3 core legitimacy mechanics.
- Overlay outputs must be versioned, signed or otherwise provenance-bound, replay-addressable, and externally verifiable.
- Overlay execution must declare regulator domain, policy version, input artifact set, output artifact set, and execution environment hash.
- Overlay runtimes must not share mutable state across regulator domains.
- Overlay execution cannot override canonical historical truth.
- Overlay output is an input to Phase 3 legitimacy evaluation only when constitutionally admitted.

Likely also update:

- [MADD_MAIN_INTEGRATION_DOCTRINE.md](./docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md)
- [REGULATORY_SOVEREIGNTY_BOUNDARY_MAP.md](./docs/constitutional/REGULATORY_SOVEREIGNTY_BOUNDARY_MAP.md)
- Phase 8 docs when created.

**6. Entry Conditions**
The boundary may define Phase 3 entry conditions, but it cannot certify that they are satisfied, and it cannot define Wave 8 or Phase 2 completion truth.

So the boundary can say:

> Phase 3 requires replay lineage persistence, contradiction lineage persistence, deterministic reconstruction verification, and Phase 3 invariant/contract artifacts.

But satisfaction belongs in:

- [PHASE3_OPENING_ACT.md](./docs/PHASE3/PHASE3_OPENING_ACT.md)
- [phase3_contract.yml](./docs/PHASE3/phase3_contract.yml)
- [PHASE_CAPABILITY_LEGALITY_MATRIX.md](./docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md)
- [CONSTITUTIONAL_HISTORY_RECORD.md](./docs/constitutional/CONSTITUTIONAL_HISTORY_RECORD.md)

Required principle:

> A Phase 3 boundary defines what must be true for Phase 3 to be legal. The opening act and constitutional history record establish whether those conditions are actually satisfied.

**7. Policy Artifact Ontology**
This can be partially defined in the boundary as “Phase 3 consumes these categories,” but not as root ontology.

The attachment’s policy categories are useful, but they need stronger grounding.

Create:

[POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md](./docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md)

or add to an existing authority/provenance doctrine.

Required doctrine:

> A policy artifact is a versioned, replay-addressable constitutional input that defines constraints, authority scope, precedence, contradiction classification, replay reconstruction, or projection rules without itself becoming an operational runtime authority unless separately activated.

Required categories:

- Constraint Policy: defines admissibility constraints.
- Authority Policy: defines scope, delegation, revocation, and authority binding.
- Precedence Policy: defines conflict ordering within a declared domain.
- Contradiction Policy: defines contradiction classes and outcomes.
- Replay Policy: defines reconstruction semantics.
- Projection Policy: defines projection context and derivation rules.

Required prohibitions:

- No mutable runtime-generated policy state.
- No policy artifact without version identity.
- No policy artifact without effective time.
- No policy artifact without authority source.
- No policy artifact that collapses regulator domains.
- No policy artifact that retroactively changes historical admissibility.

**Bottom Line**
The Phase 3 boundary can authoritatively define Phase 3 scope, exclusions, and guardrails. It should not become the root doctrine for projection, replay acceleration, overlay execution, or policy artifact ontology.

I would handle it this way:

- Put short, enforceable guardrails in `PHASE3_CAPABILITY_BOUNDARY.md`.
- Create `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` before adopting projection-universe language.
- Create or update replay acceleration doctrine before adopting checkpoint/snapshot mechanics.
- Defer sovereign overlay runtime doctrine to a later phase-facing document.
- Keep retroactive invalidation strictly prohibited under existing replay and temporal doctrines.

> What can be taken from the following that is relevant to what we are doing:
> ## 1. The Cryptographic Attestation Chain: From Entry to Act
> Symphony handles credit issuance not as a mutable database row, but as an Atomic Transition bound by multi-party consensus.
>
> * Binding to Methodology Invariants: Every issuance requires a set of Ed25519 signatures from independent authority domains (e.g., ZEMA, BoZ, Verra) [verify_tsk_p2_reg_003_05.sh]. These parties do not sign arbitrary JSON; they sign a Canonical Payload governed by docs/contracts/ED25519_SIGNING_CONTRACT.md [ED25519_SIGNING_CONTRACT.md].
> * The Transition Hash: The payload includes a transition_hash (SHA-256), which is derived from exactly eight immutable fields (including policy_decision_id and execution_id) [TRANSITION_HASH_CONTRACT.md]. This binds the signature to the Methodology Invariant that authorized the transition [TRANSITION_HASH_CONTRACT.md].
> * JCS (RFC 8785) Parity: By using the JSON Canonicalization Scheme [ED25519_SIGNING_CONTRACT.md], Symphony ensures that the byte-level representation of the "Act" is stable across all platforms and eras, preventing "signature malleability" or whitespace-induced drift.
>
> ## 2. Hardware-Level Sovereignty: The Constitutional Zone
> Symphony guarantees silicon-level integrity through a strict separation of powers between the software host and the hardware root of trust.
>
> * TPM 2.0 / Silicon Anchoring: Per ADR-0015, evidence is anchored to Runtime Invocation Trust. This requires hardware-rooted attestation (vTPM, AWS Nitro Enclave, or Azure SNP) to be included in the transition record. This proves that the environment was in a "known-good" state at the microsecond of signing.
> * Sovereign VPC Posture: Defined in docs/security/SOVEREIGN_VPC_POSTURE.md, the architecture enforces a total boundary between the Control Plane and the Data Plane. Regulated data stores never leave the customer-controlled VPC, and the HSM boundary ensures that signing keys are constitutionally and physically separate from the runtime code that requests the signature.
>
> ## 3. The Deterministic Replay Engine: 2035 Reconstitution
> The architecture is designed for "Auditability in Perpetuity," ensuring a regulator in 2035 can verify a 2026 issuance using only the RFC-standard primitives.
>
> * Artifact-Alone Verification: Because the Evidence Merkle Tree is built from canonical artifacts (JCS + SHA256 + Ed25519), the 2035 regulator does not need a single line of Symphony's 2026 runtime. They only need the publicly available RFCs for JSON Canonicalization and EdDSA [ED25519_SIGNING_CONTRACT.md].
> * Projection Registry: The system maintains an immutable record of all state transitions. The Projection Registry defines how these transitions are materialised into read-models. In 2035, the "truth" is reconstituted by replaying the Merkle-anchored event log through a set of deterministic projection rules, ensuring that the ledger state is always a derived—not authoritative—value.
>
> ## 4. Spatial Invariant Gates: The Coordinate-Level Constitution
> Symphony prevents greenwashing and double-counting by moving spatial constraints from the application layer into Atomic DB Invariants.
>
> * PostGIS DNSH Gates: Per INV-1571 and migration 0129_enforce_dns_harm_trigger.sql, the system implements the enforce_dns_harm() trigger [INVARIANTS_MANIFEST.yml, 0129_enforce_dns_harm_trigger.sql]. Using PostGIS spatial functions (e.g., ST_Intersects), the database enforces Do No Significant Harm (DNSH) compliance at the transaction boundary [0129_enforce_dns_harm_trigger.sql].
> * Silicon-Enforced Legality: If a project boundary is updated to intersect a protected area dataset, the database raises a GF057 SQLSTATE exception and rolls back the entire transaction [0129_enforce_dns_harm_trigger.sql]. This prevents "Greenwashing" by ensuring that a project cannot even exist in the ledger if its coordinates violate spatial invariants that are legally binding across jurisdictions [0129_enforce_dns_harm_trigger.sql].
> * Anti-Double-Counting: The spatial engine ensures coordinate-level uniqueness and exclusion, preventing the same physical hectare from being tokenized twice across different registries or methodologies.
>
> ------------------------------
> How would you like to advance this architectural blueprint? I can assist by:
>
> * Drafting the definitive docs/security/SOVEREIGN_VPC_POSTURE.md specification to map the network isolation boundaries.
> * Fleshing out the ADR-0015 trust attestation schema for vTPM and AWS Nitro Enclave payload inclusion.
> * Expanding the deterministic projection engine rules to formally document the 2035 reconstitution logic.

<details><summary>2 previous messages</summary>

> I’ll ground this against the repo before accepting any of it, because several phrases sound architecturally plausible but may overstate what the current constitutional corpus authorizes. I’m checking whether the cited contracts, ADR, security doc, invariant, and migration actually exist and what they say.
>
> The cited artifacts mostly exist, but some claims are stronger than the repo evidence supports. I’m reading the core contracts and spatial/VPC files now so the useful parts can be separated from overclaims.
</details>

The useful material is real, but it needs to be translated into constitutional boundary language and stripped of overclaims.

**Immediately Useful**
1. **Canonical payload and transition hash framing**
   - Portable into Phase 3 as grounding for dependency/authority lineage.
   - The repo confirms:
     - `ED25519_SIGNING_CONTRACT.md` requires JCS RFC 8785 canonical bytes, Ed25519, persisted fields, replay from persisted artifacts.
     - `TRANSITION_HASH_CONTRACT.md` derives `transition_hash` from exactly 8 fields: `project_id`, `entity_type`, `entity_id`, `from_state`, `to_state`, `execution_id`, `interpretation_version_id`, `policy_decision_id`.
   - Use in the draft as: Phase 3 legitimacy evaluation must treat transition hashes and canonical signatures as replayable provenance inputs, not mutable runtime assertions.

2. **Artifact-alone verification**
   - Strongly relevant to the replay/projection doctrine gap.
   - Portable principle: Phase 3 findings must be reconstructable from persisted canonical artifacts and open cryptographic/canonicalization standards, without trusting the live Symphony runtime.

3. **Projection registry idea, with caution**
   - Relevant, but the wording must be changed.
   - Good concept: derived read/legitimacy state is not authoritative truth; truth is append-only lineage plus deterministic reconstruction rules.
   - Do not call existing CQRS projections “the truth.” Use this as support for a future `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`.

4. **Spatial invariant gates**
   - Repo confirms `0129_enforce_dns_harm_trigger.sql` implements `enforce_dns_harm()` with PostGIS `ST_Intersects` and SQLSTATE `GF057`.
   - Portable into Phase 3 as a precedent: spatial/DNSH constraints already belong at mechanical enforcement boundaries, not advisory application logic.
   - Use carefully: Phase 3 can generalize spatial constraint mechanics, not sovereign environmental meaning.

**Better Defined Than Current Draft**
- The phrase “derived, not authoritative” for projections is valuable and should be infused into the projection section.
- “Artifact-alone verification” is stronger than my current “external verifier independence” wording.
- The canonical payload explanation gives a concrete example of how dependency legitimacy should bind to persisted, deterministic inputs.
- Spatial constraints as “coordinate-level constitution” is rhetorically useful, but should be rewritten as “spatial constraint primitives are mechanically enforceable and replay-visible.”

**Conflicts / Overclaims**
1. **“Multi-party consensus”**
   - The cited contracts prove deterministic signing and verification, not necessarily consensus semantics.
   - Add only if a separate consensus/threshold-signature doctrine exists.

2. **“Every issuance requires signatures from ZEMA, BoZ, Verra”**
   - Too strong as stated. `ED25519_SIGNING_CONTRACT.md` defines signing mechanics and key-scope checks, not that every issuance always needs those exact parties.
   - Reword as: “Phase 3 may evaluate whether required authority-domain signatures exist for the decision type.”

3. **TPM / Nitro / SNP claims**
   - `SOVEREIGN_VPC_POSTURE.md` exists, but it explicitly says Phase 0 is documentation/mechanical presence only and runtime enforcement/attestation transport are Phase 1+.
   - Do not port the claim that hardware-rooted attestation is already required in transition records unless ADR-0015 or another ratified doc states that exact requirement.

4. **“Known-good state at the microsecond of signing”**
   - Overclaim. Not supported by the VPC doc I read.
   - If needed, this belongs in a future runtime invocation trust/attestation doctrine, not Phase 3 boundary.

5. **“Silicon-enforced legality”**
   - Misleading for DNSH. The enforcement shown is DB/PostGIS trigger enforcement, not silicon enforcement.
   - Reword as “DB-enforced spatial legality gate.”

6. **Anti-double-counting via spatial engine**
   - The DNSH trigger checks protected-area intersection. It does not, by itself, prove hectare uniqueness across registries/methodologies.
   - This needs separate spatial uniqueness/exclusion doctrine or verifier evidence before inclusion.

**What To Take Into The Draft**
Add a new section or change flag along these lines:

> Phase 3 legitimacy evaluation must consume cryptographically and canonically bound transition artifacts as replayable inputs. Transition hashes, Ed25519 signatures, canonical payload bytes, policy decision references, and execution identifiers are provenance inputs to legitimacy evaluation. Phase 3 must not recompute legitimacy from mutable runtime state where canonical persisted artifacts exist.

And for projection:

> Any Phase 3 projection or reconstructed legitimacy state is derived, non-authoritative, discardable, and reproducible from append-only canonical lineage. Projection outputs may accelerate review but must not replace canonical replay.

And for spatial:

> Existing DNSH PostGIS enforcement is a precedent for Phase 3 spatial constraint mechanics. Phase 3 may generalize mechanical spatial constraint evaluation, but must not define jurisdiction-specific environmental legality or cross-registry double-counting semantics unless those are supplied by authorized later-phase or regulator doctrine.

**Governance Documents Potentially Needed**
- `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`: define projection, projection context, projection registry, derived/non-authoritative status.
- `RUNTIME_INVOCATION_TRUST_ATTESTATION_DOCTRINE.md`: define TPM/Nitro/SNP/vTPM claims, if hardware attestation is intended.
- `SPATIAL_CONSTRAINT_AND_DOUBLE_COUNTING_DOCTRINE.md`: define coordinate uniqueness, exclusion, registry/methodology overlap semantics, and how DNSH differs from anti-double-counting.

<details><summary>1 previous message</summary>

> Context compaction
>
> Source: automatic
> Status: completed
</details>

Yes. There is enough material to draft the **projection universe language** and the adjacent doctrine needed to make Phase 3 task scoping much cleaner.

The key point is that the boundary document can authoritatively define **Phase 3 mechanics**, but it should not pretend to define sovereign policy meaning. So the language should separate:

1. **Historical truth**
   Append-only canonical facts, artifacts, signatures, policy decision references, authority references, transition hashes, timestamps, and evidentiary lineage.

2. **Replay reconstruction**
   Deterministic recomputation from historical truth under declared replay rules.

3. **Projection universe**
   A bounded interpretive context used to derive admissibility or legitimacy views from the same historical record, using explicit policy, authority, temporal, regulator, jurisdictional, and contradiction-lineage inputs.

4. **Legitimacy/admissibility result**
   A derived output, not canonical truth. It may be replay-visible, superseded, quarantined, or contradicted, but it must not mutate the historical record.

5. **Operational exhaust**
   Caches, snapshots, read models, runtime memory, telemetry, indexes, and acceleration artifacts. These may help performance but must be discardable and reconstructable.

What can now be drafted into the Phase 3 boundary:

- A formal definition of **Projection Universe**.
- Rules for **projection isolation**.
- Rules for **cross-universe non-contamination**.
- A distinction between **historical invalidation claims** and **later replay-visible legitimacy findings**.
- A rule that **Phase 3 does not define sovereign policy meaning**, only the mechanics by which sovereign/regulator/domain policy artifacts are versioned, applied, replayed, and bounded.
- A list of policy artifact classes Phase 3 may consume: constraint, authority, precedence, contradiction, replay, and projection policies.
- A clear prohibition against using mutable runtime state, caches, implementation scaffolding, or live service behavior as legitimacy authority.
- A stronger treatment of spatial gates as **mechanical invariant enforcement**, not full environmental/legal sovereignty unless supplied by regulator or later-phase doctrine.

The one thing I would not overclaim inside `PHASE3_CAPABILITY_BOUNDARY.md` is the full root doctrine for projection universes. The boundary can define the Phase 3 usage and constraints, but the durable constitutional home should likely be a new doctrine such as:

`LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`

Then `PHASE3_CAPABILITY_BOUNDARY.md` can cite and apply that doctrine. If that new doctrine does not exist yet, the Phase 3 boundary can include an interim “Phase 3 Projection Universe Doctrine” section, clearly marked as boundary-scoped until promoted into constitutional doctrine.

So the answer is: **yes, enough material exists to write the full Phase 3 boundary language now**, but the strongest version should also flag that Symphony needs a standalone projection/replay legitimacy doctrine to prevent the boundary document from carrying too much constitutional weight by itself.

> That universal doctrine document and any other similar documents required by PHASE3_CAPABILITY_BOUNDARY.md for reference are what I was refering to. We can't move forward with a self-contained PHASE3_CAPABILITY_BOUNDARY.md that will have agents making up doctrines as they create tasks because there is no authoritative guidance outside the PHASE3_CAPABILITY_BOUNDARY.md. That is why I had asked you to state all the documents needed that are currently available or need creating to fulfill the obligations of PHASE3_CAPABILITY_BOUNDARY.md in guiding all tasking in Phase 3. Acknowledge that you understand what I've said. This is vital for the next plan implementation

Understood.

You are not asking for a self-contained `PHASE3_CAPABILITY_BOUNDARY.md` that invents doctrine locally. You want the Phase 3 boundary to be a **scoping and routing document** that depends on a complete set of authoritative constitutional/governance doctrines outside itself.

The required work is therefore to identify:

1. Which existing doctrine documents already provide authoritative guidance for Phase 3 task scoping.
2. Which missing doctrine documents must be created before Phase 3 task generation can be safe.
3. Which obligations in `PHASE3_CAPABILITY_BOUNDARY.md` must reference those documents instead of defining doctrine ad hoc.
4. Where the current corpus is weak enough that agents would otherwise fill gaps themselves during task creation.

I also understand the core risk: if the Phase 3 boundary document is treated as the only authority, agents will improvise doctrines around projection universes, replay legitimacy, policy artifacts, spatial constraints, regulator separation, and historical truth. That would create noise and inconsistent Phase 3 tasks.

For the next plan implementation, I will treat the deliverable as a **doctrine dependency map plus required document set**, not merely a revised capability boundary draft.

> Great. That's very accurate understanding.
> Tell me how implementing Phase capability boundaries will improve task creation compared to the way they are created using AGENT_ENTRYPOINT.mc.
> Also state how we will make sure that:
> 1. We don't over complicate the process
> 2. If the following is what you have in mind or if it is too complicated and need to be simplified
>
> A strong `PHASE3_CAPABILITY_BOUNDARY.md` should **not attempt to define Phase 3 doctrine itself**. Its constitutional role is to act as a **routing and scoping control document** that tells task-generation agents:
>
> 1. What Phase 3 is authorized to build.
> 2. What Phase 3 is prohibited from building.
> 3. Which external governing documents must be consulted for each task category.
> 4. Which doctrine gaps block task creation until resolved.
>
> In other words:
>
> > **The capability boundary is not the source of truth. It is the map to the sources of truth.**
>
> ---
>
> # Constitutional Purpose of PHASE3_CAPABILITY_BOUNDARY.md
>
> The correct constitutional purpose is:
>
> > To constrain and direct all Phase 3 task generation by binding each authorized capability to its governing doctrines and by preventing agents from inventing policy, legitimacy, or sovereignty rules locally.
>
> This avoids a common failure mode where an agent sees “build legitimacy engine” and starts improvising:
>
> * authority semantics,
> * policy models,
> * replay rules,
> * regulator precedence,
> * DNSH logic,
> * temporal validity,
> * admissibility criteria.
>
> Those rules must already exist in constitutional doctrine.
>
> ---
>
> # Design Principle: Boundary as Doctrine Dependency Router
>
> The capability boundary should contain only four kinds of information:
>
> ---
>
> ## 1. Authorized Capability Domains
>
> Defines what constitutional capability categories Phase 3 may implement.
>
> Example:
>
> * Typed Dependency Graph
> * Recursive Legitimacy Engine
> * Contradiction Detection
> * Authority Scope Engine
> * Regulator Arbitration
> * Conflict-of-Interest Enforcement
> * Spatial Legality & DNSH
> * Replay Reconstruction
> * Failure Composition
> * Verifier & CI Enforcement
>
> ---
>
> ## 2. Governing Doctrine References
>
> Each capability must list the documents that define its behavior.
>
> Example:
>
> |                  Capability | Governing Documents                                                                                                 |
> | --------------------------: | :------------------------------------------------------------------------------------------------------------------ |
> | Recursive Legitimacy Engine | `SYSTEM_SOVEREIGNTY_MODEL.md`, `TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`, `REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md` |
> |       Regulator Arbitration | `REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md`                                                                    |
> |            Spatial Legality | `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`                                                                          |
> |         Failure Composition | `TASK_GENERATION_CONSTITUTION.md`                                                                                   |
>
> ---
>
> ## 3. Prohibited Capability Domains
>
> Explicitly identifies what belongs to other phases.
>
> Examples:
>
> * methodology execution (Phase 5),
> * tax deductions (Phase 4),
> * PII erasure controls (Phase 6),
> * MAIN/MADD authorization (Phase 8A),
> * registry integrations (Phase 8B).
>
> ---
>
> ## 4. Doctrine Gaps and Blocking Conditions
>
> Lists missing documents that must be created before task generation.
>
> Example:
>
> | Missing Doctrine                             | Blocks |
> | -------------------------------------------- | ------ |
> | `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md` | Wave 4 |
> | `CONTRADICTION_CLASSIFICATION_DOCTRINE.md`   | Wave 3 |
> | `FAILURE_COMPOSITION_TAXONOMY.md`            | Wave 9 |
>
> ---
>
> # Recommended Document Structure
>
> ```text
> PHASE3_CAPABILITY_BOUNDARY.md
> ├── Constitutional Purpose
> ├── Phase Scope Summary
> ├── Authorized Capability Domains
> ├── Capability-to-Doctrine Mapping
> ├── Prohibited Capability Domains
> ├── Required Doctrine Inventory
> ├── Missing Doctrine and Blocking Conditions
> ├── Task Generation Rules
> └── Constitutional Exit Conditions
> ```
>
> ---
>
> # Capability-to-Doctrine Mapping (Core Section)
>
> This is the heart of the document.
>
> ## Example Table
>
> | Capability Domain       | Governing Documents                              | Tasks May Define            | Tasks Must Not Define      |
> | ----------------------- | ------------------------------------------------ | --------------------------- | -------------------------- |
> | Typed Dependency Graph  | `SYSTEM_SOVEREIGNTY_MODEL.md`                    | schemas, indexes, traversal | legitimacy semantics       |
> | Recursive Legitimacy    | `TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`       | evaluation runtime          | temporal rules             |
> | Contradiction Detection | `CONTRADICTION_CLASSIFICATION_DOCTRINE.md`       | detection logic             | contradiction definitions  |
> | Authority Scope         | `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`     | validation logic            | authority semantics        |
> | Regulator Arbitration   | `REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md` | veto runtime                | regulator precedence rules |
> | Spatial Legality        | `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`       | geospatial checks           | statutory interpretations  |
> | Failure Composition     | `FAILURE_COMPOSITION_TAXONOMY.md`                | structured outputs          | failure categories         |
> | Replay Reconstruction   | `REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`         | replay runtime              | historical truth doctrine  |
>
> This table prevents local doctrine invention.
>
> ---
>
> # Required Governing Documents for Phase 3
>
> ## Foundational Doctrines
>
> * `SYSTEM_SOVEREIGNTY_MODEL.md`
> * `TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`
> * `REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`
> * `REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md`
> * `DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md`
> * `TASK_GENERATION_CONSTITUTION.md`
> * `PHASE_CAPABILITY_LEGALITY_MATRIX.md`
>
> ## Phase 3-Specific Doctrines
>
> * `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`
> * `CONTRADICTION_CLASSIFICATION_DOCTRINE.md`
> * `FAILURE_COMPOSITION_TAXONOMY.md`
> * `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`
> * `CROSS_SYSTEM_EVIDENCE_CONTINUITY_DOCTRINE.md`
> * `DWELL_TIME_FORENSIC_DOCTRINE.md`
> * `VERIFIER_INDEPENDENCE_AND_DUAL_IDENTITY_DOCTRINE.md`
>
> ---
>
> # Missing Doctrine Detection
>
> Your boundary should explicitly state:
>
> > If a capability requires doctrine that does not exist, task generation for that capability is constitutionally blocked.
>
> This prevents agents from inventing policy.
>
> ---
>
> # Task Generation Rule
>
> Include a binding rule such as:
>
> > Every generated Phase 3 task must cite at least one governing doctrine. Tasks that introduce behavioral semantics not explicitly grounded in referenced doctrines are constitutionally invalid.
>
> This single rule dramatically improves task quality.
>
> ---
>
> # Anti-Improvisation Rule
>
> Add:
>
> > Agents may implement doctrine, but may not define doctrine.
>
> This is the most important sentence in the document.
>
> ---
>
> # Prohibited Capability Routing
>
> The boundary should route out-of-scope work to the correct phase.
>
> |                    Capability | Assigned Phase |
> | ----------------------------: | :------------- |
> |   Methodology Adapter Runtime | Phase 5        |
> |          Statutory Deductions | Phase 4        |
> |         ZDPA Erasure Controls | Phase 6        |
> |       MAIN/MADD Authorization | Phase 8A       |
> | External Registry Integration | Phase 8B       |
>
> ---
>
> # Doctrine Dependency Matrix
>
> A useful visualization is:
>
> ```text
> Phase 3 Capability Boundary
>         ↓
> Capability Domain
>         ↓
> Required Governing Doctrine
>         ↓
> Implementation Tasks
>         ↓
> Verifier Tasks
>         ↓
> CI Enforcement
> ```
>
> Tasks are generated only after doctrine exists.
>
> ---
>
> # Constitutional Benefits
>
> This design delivers:
>
> * deterministic task generation,
> * elimination of doctrinal improvisation,
> * consistent architectural decisions,
> * phase contamination prevention,
> * explicit dependency management,
> * and auditability of why each task exists.
>
> ---
>
> # Example Constitutional Statement
>
> Use language like:
>
> > This document is a constitutional routing instrument. It does not define legitimacy, authority, replay, contradiction, or sovereignty semantics. Those semantics are exclusively defined in the governing doctrines referenced herein. Its sole purpose is to constrain Phase 3 implementation to authorized capability domains and to direct task generation to the controlling constitutional authorities.
>
> ---
>
> # Recommended Governance Sequence
>
> 1. Establish governing doctrines.
> 2. Create capability boundary as doctrine router.
> 3. Create invariant register.
> 4. Create phase contract.
> 5. Generate task plan.
> 6. Generate implementation tasks.
> 7. Build verifier suite.
>
> This ordering prevents doctrine from being invented during task creation.
>
> ---
>
> # Final Design Principle
>
> > **PHASE3_CAPABILITY_BOUNDARY.md should function as a constitutional import map, not a doctrinal specification.**
>
> Its role is to answer:
>
> * What may Phase 3 build?
> * What may it not build?
> * Which documents define each capability?
> * Which missing documents block task creation?
>
> When designed this way, task generation becomes rule-driven rather than improvisational, and every task is traceable to explicit constitutional authority.

Yes, this is the right direction. I would simplify the operating model slightly, but the core concept is correct:

> `AGENT_ENTRYPOINT.md` routes the agent.
> `PHASE3_CAPABILITY_BOUNDARY.md` routes the work.

That distinction matters.

**How Phase Capability Boundaries Improve Task Creation**

`AGENT_ENTRYPOINT.md` is mainly an agent-governance entrypoint. It helps determine things like mode, role, workflow, conformance expectations, and whether the agent is allowed to proceed. That is useful, but it does not give enough Phase 3-specific architectural control to generate good implementation tasks.

A Phase capability boundary improves task creation because it answers the questions an implementation-task generator actually needs:

- Is this capability authorized in Phase 3?
- Is this capability prohibited because it belongs to another phase?
- Which doctrine defines the semantics?
- What may the task implement versus what must already be defined elsewhere?
- Is task creation blocked because the governing doctrine does not exist yet?

So instead of an agent seeing “build recursive legitimacy engine” and inventing authority/replay/contradiction rules, the boundary forces the task to say:

- capability: recursive legitimacy evaluation
- governing doctrine: replay, historical truth, temporal validity, projection doctrine
- task may define: runtime evaluation mechanics
- task must not define: legitimacy meaning or sovereign policy semantics
- blocker: missing doctrine if projection rules are not yet authoritative

That makes task creation more deterministic, auditable, and phase-contained.

**Avoiding Overcomplication**

The process should stay simple by making the boundary document a routing matrix, not a giant theory document.

I would keep it to five recurring controls:

1. **Capability**
   What Phase 3 may build.

2. **Doctrine**
   Which authoritative documents control the behavior.

3. **Allowed Task Surface**
   What implementation tasks may define.

4. **Forbidden Task Surface**
   What implementation tasks must not define.

5. **Blocker**
   Which missing doctrine prevents task creation.

That is enough. We do not need every task-generation agent to read a long narrative and infer rules. The goal should be a table-driven boundary that leaves little room for interpretation.

**On Your Proposed Structure**

Your structure is sound. I would keep the principle, but compress the document so it does not become another doctrine layer.

The most important sentence is exactly right:

> Agents may implement doctrine, but may not define doctrine.

I would also keep this framing:

> The capability boundary is not the source of truth. It is the map to the sources of truth.

That should become the controlling design principle.

Where I would simplify:

- Do not put too much doctrinal explanation inside `PHASE3_CAPABILITY_BOUNDARY.md`.
- Do not make the boundary restate every doctrine.
- Do not make agents interpret prose when a matrix can decide the routing.
- Do not create more doctrine documents than necessary just because a category exists.

The better shape is:

```text
PHASE3_CAPABILITY_BOUNDARY.md
├── Constitutional Purpose
├── Phase 3 Authorized Capability Domains
├── Capability-to-Doctrine Matrix
├── Prohibited Capability Routing
├── Required Doctrine Inventory
├── Missing Doctrine Blockers
├── Task Generation Rules
└── Exit Conditions
```

The heart of it should be the matrix.

**What This Means Practically**

For each Phase 3 capability, task generation should be blocked unless the row is complete:

```text
Capability → Governing Doctrine → Allowed Task Surface → Forbidden Task Surface → Blocker Status
```

Example:

| Capability | Governing Doctrine | Tasks May Define | Tasks Must Not Define | Blocker |
|---|---|---|---|---|
| Projection Universe | `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | projection runtime, derived views, replay inputs | historical truth, sovereign legitimacy meaning | blocked until doctrine exists |
| Spatial Constraint Evaluation | `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md` | mechanical geospatial checks | statutory environmental interpretation | blocked if doctrine missing |
| Authority Scope | `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md` | validation mechanics | authority semantics | blocked if doctrine missing |

That is not too complicated. It is the minimum structure needed to stop agents from inventing doctrine.

**Bottom Line**

Your proposed model is correct, but the implementation should be intentionally lean.

`AGENT_ENTRYPOINT.md` answers: “May this agent proceed, and under what operational mode?”

`PHASE3_CAPABILITY_BOUNDARY.md` answers: “May this work exist in Phase 3, what doctrine controls it, and what must not be invented by the task?”

That difference is exactly why Phase capability boundaries will improve task creation. They turn task generation from agent interpretation into doctrine-routed scoping.

> Continue. You got cut off

Continuing from there:

The clean implementation should make `PHASE3_CAPABILITY_BOUNDARY.md` a **pre-task validation gate**.

Before any Phase 3 task is created, the task generator should be able to answer:

1. Which Phase 3 capability domain does this task belong to?
2. Is that domain authorized?
3. Which doctrine controls the behavior?
4. Does the doctrine exist and have enough authority?
5. What is the task allowed to implement?
6. What is the task forbidden from defining?
7. Is the task blocked until doctrine is created or updated?

If any answer is missing, the task should not be generated as implementation work. It should become a doctrine-gap task instead.

**The Main Improvement Over AGENT_ENTRYPOINT.md**

`AGENT_ENTRYPOINT.md` is agent-facing. It protects process integrity.

It can say:

- classify the prompt
- identify the mode
- pick the right agent role
- run conformance checks
- respect operational manuals
- avoid unauthorized regulated edits

But it does not deeply answer:

- whether “projection universe” is Phase 3 or later
- whether “DNSH legality” means mechanical spatial checks or sovereign statutory interpretation
- whether “regulator arbitration” may define precedence rules
- whether replay can supersede historical truth
- whether contradiction categories already exist
- whether task creation is blocked because doctrine is missing

Those are capability-scoping questions, not agent-routing questions.

So the Phase boundary adds a missing layer:

```text
AGENT_ENTRYPOINT.md
  → Who is acting, under what workflow?

PHASE3_CAPABILITY_BOUNDARY.md
  → What work is allowed, governed by which doctrine?

Task Plan
  → What should be implemented?

Implementation Task
  → How to implement it without inventing doctrine?
```

**How Not To Overcomplicate It**

The danger is creating a bureaucracy where every task needs to consult fifteen documents manually. That would slow everything down and make agents worse, not better.

The simplification is to make the boundary document do the routing work once.

Each capability row should have:

```text
Capability Domain
Authorized / Prohibited / Blocked
Governing Doctrine
Allowed Implementation Surface
Forbidden Doctrine Surface
Required Verifier Evidence
```

That gives agents a compact operating rule.

For example:

| Capability | Status | Governing Doctrine | Allowed | Forbidden |
|---|---|---|---|---|
| Replay Projection | Authorized after doctrine exists | `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | deterministic derived views | mutation of historical truth |
| Spatial DNSH Gates | Authorized mechanically | `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md` | geospatial invariant checks | legal interpretation of protected-area policy |
| Regulator Arbitration | Authorized if doctrine-defined | `REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md` | enforcement of declared precedence | invention of regulator hierarchy |
| Methodology Runtime | Prohibited | Phase 5 docs | none in Phase 3 | methodology execution |

That table becomes the working surface. Agents should not have to infer the boundary from long prose.

**The Right Governance Sequence**

The ordering you proposed is right, with one important refinement.

I would use this order:

1. **Identify required doctrine inventory**
   Determine all doctrines Phase 3 needs to avoid improvisation.

2. **Classify doctrine status**
   Existing, existing-but-needs-update, missing, or out-of-phase.

3. **Create/update missing governing doctrines**
   Especially projection universe, authority scope, contradiction classification, failure composition, and spatial constraints.

4. **Update `PHASE3_CAPABILITY_BOUNDARY.md`**
   Make it route each capability to the correct doctrine.

5. **Update phase legality/contract artifacts**
   Ensure `PHASE_CAPABILITY_LEGALITY_MATRIX.md`, phase contract, and task generation rules align.

6. **Generate Phase 3 task plan**
   Only after the doctrine map is complete.

7. **Generate implementation tasks**
   Each task cites controlling doctrine and verifier expectations.

That avoids the failure mode where the boundary says “refer to X” but X does not exist yet.

**My View On Your Proposal**

Your proposal is not too complicated in concept. It becomes too complicated only if the boundary tries to become a full constitutional textbook.

The right version is:

- keep the **principle language**
- keep the **authorized/prohibited capability lists**
- keep the **capability-to-doctrine matrix**
- keep the **missing doctrine blockers**
- keep the **anti-improvisation rule**
- reduce long doctrinal explanations inside the boundary itself

So yes: your framing is correct, but the final artifact should be more table-driven and less essay-driven.

The strongest final principle is:

> `PHASE3_CAPABILITY_BOUNDARY.md` should decide whether a task may be created, not teach the agent the entire doctrine.

That keeps the process rigorous without making it heavy.

> Apart from what is listed below, tell me what else should the  implementation plan cover:
> 1. The doctrines required for Phase 3 completion that the PHASE3_CAPABILITY_BOUNDARY.md  document will reference. You said you had all the material for this so you should have all the documents to be edited or created known by now
> 2. The actual PHASE3_CAPABILITY_BOUNDARY.md. This is why I had you create the draft so that it is easier to now clean it up and make fully compliant with the project plan
> 3. Any other pre phase 3 clean up like moving the assessment document in docs/PHASE3/ that might cause confusion

Beyond those three items, the implementation plan should cover these additional workstreams:

1. **Doctrine Dependency Matrix**
   Not just the list of required doctrines, but a matrix that maps:

   ```text
   Phase 3 capability → governing doctrine → task may define → task must not define → blocker status
   ```

   This is the mechanism that makes `PHASE3_CAPABILITY_BOUNDARY.md` usable by task-generation agents.

2. **Doctrine Status Classification**
   Each referenced doctrine should be classified as:

   - existing and sufficient
   - existing but needs amendment
   - missing and must be created
   - out-of-phase and should only be referenced as a future dependency

   This prevents the boundary from citing documents that do not actually carry enough authority.

3. **Phase 3 Task-Generation Rules**
   The plan should define the rules that every Phase 3 task must satisfy, for example:

   - every task must cite at least one governing doctrine
   - tasks may implement doctrine but may not define doctrine
   - tasks with missing doctrine become doctrine-gap tasks, not implementation tasks
   - tasks must declare authorized capability domain
   - tasks must declare prohibited surfaces avoided

4. **Missing-Doctrine Blocker Register**
   A concrete register of doctrine gaps that block Phase 3 task creation.

   This should include projection universe doctrine, authority scope/delegation, contradiction classification, failure composition, spatial constraints/DNSH, replay acceleration/projection artifacts, and possibly policy artifact ontology if not already covered elsewhere.

5. **Alignment With Existing Governance Artifacts**
   The plan should identify which existing governance/phase documents need updates so the new boundary is not isolated.

   Likely candidates:

   - `PHASE_CAPABILITY_LEGALITY_MATRIX.md`
   - Phase 3 contract artifacts, if present
   - task-generation constitution/rules
   - constitutional glossary
   - NotebookLM ingestion policy, if new drafts should be excluded
   - constitutional history/change record, if the repo uses one

6. **Canonical Naming and File Placement**
   The plan should decide exact filenames and locations before implementation.

   This matters because the current corpus already has naming/path sensitivity. The plan should prevent duplicate concepts under slightly different names, such as “projection universe,” “legitimacy projection,” and “replay projection” becoming separate accidental doctrines.

7. **Promotion / Demotion Rules for Drafts**
   Since draft and assessment docs can pollute task generation, the plan should specify:

   - which files are canonical
   - which files are draft-only
   - which files must be moved to an archive/research folder
   - which files must carry `DO-NOT-INGEST` or equivalent metadata
   - whether the draft I created should be retained, archived, or superseded

8. **Boundary Compliance Checklist**
   The plan should define a lightweight checklist that task generators or reviewers can apply to each future Phase 3 task.

   Example:

   ```text
   - Authorized capability identified?
   - Governing doctrine cited?
   - No doctrine invented locally?
   - Out-of-phase surfaces excluded?
   - Missing doctrine blocker resolved?
   - Verifier expectation stated?
   ```

9. **Verifier and Evidence Expectations**
   Even if implementation comes later, the plan should define what evidence Phase 3 tasks must eventually produce.

   Not full test implementation yet, but enough to say:

   - what must be verifiable
   - which claims require mechanical checks
   - which claims are documentation-only until implementation
   - what must not be marked complete without verifier evidence

10. **Conflict Resolution Rules**
   The plan should say what happens if two doctrines appear to conflict.

   Minimum rule:

   - higher-rank constitutional doctrine controls
   - phase boundary cannot override doctrine
   - unresolved doctrine conflict blocks task generation
   - agents must create a doctrine-conflict remediation task instead of choosing a side

11. **Out-of-Phase Routing**
   The plan should define where prohibited Phase 3 work goes.

   Examples:

   - methodology execution → Phase 5
   - statutory deductions → Phase 4
   - data deletion/erasure mechanics → Phase 6
   - MAIN/MADD authorization → Phase 8A
   - external registry integration → Phase 8B

12. **Acceptance Criteria for the Cleanup**
   The plan should include clear completion criteria, such as:

   - all Phase 3 capabilities map to governing doctrine
   - all missing doctrines are created or explicitly blocking
   - `PHASE3_CAPABILITY_BOUNDARY.md` no longer carries standalone doctrine except routing/scoping rules
   - confusing draft/assessment files are archived or marked non-canonical
   - task generation can proceed without agents inventing projection, replay, legitimacy, authority, or contradiction rules

So the implementation plan should cover five big areas:

```text
1. Doctrine creation/update
2. Phase boundary rewrite
3. Governance alignment
4. Draft/assessment cleanup
5. Task-generation enforcement rules
```

Your listed items cover the first, second, and part of the fourth. The missing critical piece is the **enforcement layer**: the matrix, blocker register, task-generation rules, and acceptance checklist that make the boundary operational rather than just descriptive.

> Just to be clear, Is this task plan creation or actual task creation? The distinction is important because the atomicity of the task and the anti hallucination and other aspects like verification scripts are done at the implementation level. These tasks are broader and should actually be more in line with implementation plans used for task/plan/exec_log creation. Do we distinguish that? Work is the workflow from this point to the final task completion?

Yes, we should distinguish it clearly.

What we are discussing now is **implementation plan creation**, not atomic implementation task creation.

The hierarchy should be:

```text
Doctrine / Governance Corpus
        ↓
Phase Capability Boundary
        ↓
Implementation Plan
        ↓
Task Plan
        ↓
Atomic Implementation Tasks
        ↓
Execution Logs / Evidence
```

For this current work, we are at the **implementation plan** level.

That means the plan should be broader than atomic tasks. It should define:

- which doctrine documents need to be created or updated
- how `PHASE3_CAPABILITY_BOUNDARY.md` should be rewritten
- what cleanup is needed before Phase 3 task generation
- what governance artifacts need alignment
- what rules future task plans must obey

It should **not** yet break everything into final atomic implementation tasks with detailed verification scripts for each one. That belongs one layer later.

**How The Layers Differ**

`Implementation Plan`
Defines the full work package and sequencing.

Example:
- create missing projection doctrine
- update replay doctrine references
- rewrite Phase 3 capability boundary as a doctrine router
- archive confusing draft assessments
- align legality matrix and task-generation rules

`Task Plan`
Breaks the implementation plan into coherent work units.

Example:
- Task Group A: doctrine creation
- Task Group B: boundary rewrite
- Task Group C: governance alignment
- Task Group D: cleanup and canonicalization

`Atomic Implementation Tasks`
Concrete, executable tasks with file paths, acceptance criteria, validation commands, and evidence expectations.

Example:
- create `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`
- update `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md`
- run specific doc consistency checks
- record evidence in exec log

So yes, the implementation plan should be **decision-complete**, but not atomized down to every final implementation task.

**Workflow From Here To Completion**

The workflow should be:

1. **Implementation Plan**
   Define the full scope and intended changes.

2. **Task Plan**
   Convert the implementation plan into work packages.

3. **Atomic Task Creation**
   Create implementation-ready tasks with exact paths, acceptance criteria, verification scripts, and anti-hallucination controls.

4. **Execution**
   Implement the tasks.

5. **Verification**
   Run checks, review doctrine consistency, confirm no phase contamination.

6. **Execution Log**
   Record what changed, why, which doctrine authorized it, and what verification passed.

For the next step, the deliverable should be an **implementation plan for Phase 3 boundary and doctrine readiness**, not atomic tasks yet.

> Proceed to create the implementation plan for Phase 3 Boundary and Doctrine Readiness

<details><summary>1 previous message</summary>

> Plan
>
> # Phase 3 Boundary and Doctrine Readiness Implementation Plan
>
> ## Summary
>
> Create a governance-ready Phase 3 foundation before atomic task creation begins. This is **implementation plan work**, not final task creation: it prepares the doctrine corpus, boundary routing document, cleanup rules, and task-plan constraints that later implementation tasks must follow.
>
> The target outcome is that `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY.md` becomes a lean **capability-to-doctrine router**, while all legitimacy, replay, projection, contradiction, authority, spatial, and failure semantics live in authoritative constitutional doctrine documents.
>
> ## Key Changes
>
> ### 1. Create Missing Phase 3 Governing Doctrines
>
> Create these new constitutional documents under `C:\Workspace\GitHub\Symphony\docs\constitutional\`:
>
> - `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`
>   Defines projection universes, derived legitimacy/admissibility views, replay reconstruction, projection isolation, non-mutation of historical truth, replay acceleration limits, and operational exhaust rules.
>
> - `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`
>   Defines authority domains, delegated authority, authority scope boundaries, evidence required for authority claims, and the rule that tasks may validate authority but not invent authority semantics.
>
> - `CONTRADICTION_CLASSIFICATION_DOCTRINE.md`
>   Defines contradiction types, replay-visible contradiction handling, quarantine, supersession, compensating lineage, escalation, and the difference between contradiction detection and contradiction resolution.
>
> - `FAILURE_COMPOSITION_TAXONOMY.md`
>   Defines Phase 3 failure categories and composition rules so recursive legitimacy failures do not become agent-invented prose.
>
> - `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`
>   Defines mechanical spatial constraint evaluation, DNSH gating, protected-area intersection handling, and anti-double-counting boundaries without inventing sovereign environmental law.
>
> - `POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`
>   Defines policy artifact classes, versioning, effective-time rules, authority lineage, policy lineage, precedence linkage, and replay-addressability.
>
> Replay acceleration should be covered inside `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` unless it becomes too large. Do not create a separate replay-acceleration doctrine unless implementation review shows that projection doctrine is becoming unclear.
>
> ### 2. Amend Existing Constitutional Documents
>
> Update these existing documents so the new doctrines fit the current authority model:
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\CONSTITUTIONAL_GLOSSARY.md`
>   Add canonical definitions for projection universe, historical truth, replay reconstruction, operational exhaust, authority lineage, policy artifact, contradiction quarantine, and derived legitimacy state.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\PHASE_CAPABILITY_LEGALITY_MATRIX.md`
>   Add Phase 3 legality rows that route authorized, prohibited, and blocked capability domains.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\TASK_GENERATION_CONSTITUTION.md`
>   Add the binding rule: agents may implement doctrine, but may not define doctrine. Require every Phase 3 task plan to cite governing doctrine.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md`
>   Clarify that drafts, assessments, and non-canonical review documents must not be treated as governing doctrine.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\CONSTITUTIONAL_HISTORY_RECORD.md`
>   Record the creation and authority purpose of the Phase 3 doctrine set.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\CONSTITUTIONAL_GRAPH.md`
>   Add dependency edges from Phase 3 boundary to each governing doctrine.
>
> Only make targeted amendments to existing replay, sovereignty, evidentiary, retention, regulator, and cryptographic doctrines if cross-references are needed. Do not rewrite their core doctrine unless a contradiction is found.
>
> ### 3. Rewrite Phase 3 Capability Boundary
>
> Replace the current body of `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY.md` with a clean routing/scoping document.
>
> Required structure:
>
> - Constitutional Purpose
> - Phase 3 Scope Summary
> - Authorized Capability Domains
> - Capability-to-Doctrine Matrix
> - Prohibited Capability Routing
> - Required Doctrine Inventory
> - Missing Doctrine and Blocking Conditions
> - Task-Plan Generation Rules
> - Boundary Compliance Checklist
> - Constitutional Exit Conditions
>
> The boundary must not define doctrine locally. It should route each capability using this row shape:
>
> ```text
> Capability Domain → Status → Governing Doctrine → Tasks May Define → Tasks Must Not Define → Blocker Status
> ```
>
> Required task-plan rule:
>
> ```text
> Every Phase 3 task plan must identify an authorized capability domain, cite governing doctrine, declare allowed implementation surface, declare prohibited doctrine surface, and state whether any doctrine blocker remains unresolved.
> ```
>
> ### 4. Pre-Phase 3 Cleanup
>
> Clean up confusing Phase 3 draft/review artifacts so task-generation agents do not treat them as canonical.
>
> Handle these files explicitly:
>
> - `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md`
> - `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_BOUNDARY_REVIEW_ASSESSMENT.md`
>
> Default action: move both to a clearly non-canonical archive location such as `C:\Workspace\GitHub\Symphony\docs\PHASE3\archive\`, and mark them with non-canonical status if retained.
>
> Also check for duplicate/confusing doctrine names, especially `MADD_MAIN_INTEGRATION_DOCTRINE.md` and `MADD_MAIN_INTEGRATION_DOCTRINE-2.md`, and route any cleanup recommendation into the implementation plan notes unless it must be fixed before Phase 3 task planning.
>
> ### 5. Workflow From This Plan to Completion
>
> Use this sequence:
>
> 1. Finalize the implementation plan.
> 2. Create/update the required doctrine documents.
> 3. Rewrite `PHASE3_CAPABILITY_BOUNDARY.md` as a capability router.
> 4. Align legality matrix, task-generation constitution, glossary, graph, ingestion policy, and history record.
> 5. Archive or mark non-canonical Phase 3 draft/assessment documents.
> 6. Create a Phase 3 task plan from the completed boundary.
> 7. Break the task plan into atomic implementation tasks.
> 8. For each atomic task, define exact file paths, acceptance criteria, verification commands, and execution-log evidence.
> 9. Execute implementation tasks.
> 10. Verify and record evidence.
>
> This plan stops at step 5. Steps 6-10 are downstream task-plan and implementation execution work.
>
> ## Test and Review Plan
>
> - Run documentation consistency searches to confirm every doctrine referenced by `PHASE3_CAPABILITY_BOUNDARY.md` exists.
> - Verify no Phase 3 task-generation rule depends on a draft, assessment, or archived document.
> - Check that every authorized Phase 3 capability has a governing doctrine and explicit allowed/forbidden task surface.
> - Check that prohibited capabilities route to the correct later phase instead of being silently omitted.
> - Confirm that no new doctrine contradicts historical truth primacy, temporal replay doctrine, regulator non-collapse, data retention doctrine, or constitutional authority hierarchy.
> - Run the repo’s required documentation/governance verification command only after file edits are complete.
>
> ## Assumptions
>
> - This is an implementation-plan deliverable, not atomic task creation.
> - `PHASE3_CAPABILITY_BOUNDARY.md` should function as a constitutional import map, not a doctrinal specification.
> - Missing doctrine blocks Phase 3 task planning for that capability.
> - Draft and assessment documents should be retained only as non-canonical references, not deleted unless later requested.
> - The implementation should minimize new doctrine files by combining replay acceleration and operational exhaust into the projection doctrine unless separation becomes necessary.
</details>

I’ll ground the plan against the current repo structure before finalizing it, so the document names and cleanup targets are concrete rather than inferred. This will be read-only.

> PLEASE IMPLEMENT THIS PLAN:
> # Phase 3 Boundary and Doctrine Readiness Implementation Plan
>
> ## Summary
>
> Create a governance-ready Phase 3 foundation before atomic task creation begins. This is **implementation plan work**, not final task creation: it prepares the doctrine corpus, boundary routing document, cleanup rules, and task-plan constraints that later implementation tasks must follow.
>
> The target outcome is that `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY.md` becomes a lean **capability-to-doctrine router**, while all legitimacy, replay, projection, contradiction, authority, spatial, and failure semantics live in authoritative constitutional doctrine documents.
>
> ## Key Changes
>
> ### 1. Create Missing Phase 3 Governing Doctrines
>
> Create these new constitutional documents under `C:\Workspace\GitHub\Symphony\docs\constitutional\`:
>
> - `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`
>   Defines projection universes, derived legitimacy/admissibility views, replay reconstruction, projection isolation, non-mutation of historical truth, replay acceleration limits, and operational exhaust rules.
>
> - `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`
>   Defines authority domains, delegated authority, authority scope boundaries, evidence required for authority claims, and the rule that tasks may validate authority but not invent authority semantics.
>
> - `CONTRADICTION_CLASSIFICATION_DOCTRINE.md`
>   Defines contradiction types, replay-visible contradiction handling, quarantine, supersession, compensating lineage, escalation, and the difference between contradiction detection and contradiction resolution.
>
> - `FAILURE_COMPOSITION_TAXONOMY.md`
>   Defines Phase 3 failure categories and composition rules so recursive legitimacy failures do not become agent-invented prose.
>
> - `SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`
>   Defines mechanical spatial constraint evaluation, DNSH gating, protected-area intersection handling, and anti-double-counting boundaries without inventing sovereign environmental law.
>
> - `POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`
>   Defines policy artifact classes, versioning, effective-time rules, authority lineage, policy lineage, precedence linkage, and replay-addressability.
>
> Replay acceleration should be covered inside `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` unless it becomes too large. Do not create a separate replay-acceleration doctrine unless implementation review shows that projection doctrine is becoming unclear.
>
> ### 2. Amend Existing Constitutional Documents
>
> Update these existing documents so the new doctrines fit the current authority model:
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\CONSTITUTIONAL_GLOSSARY.md`
>   Add canonical definitions for projection universe, historical truth, replay reconstruction, operational exhaust, authority lineage, policy artifact, contradiction quarantine, and derived legitimacy state.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\PHASE_CAPABILITY_LEGALITY_MATRIX.md`
>   Add Phase 3 legality rows that route authorized, prohibited, and blocked capability domains.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\TASK_GENERATION_CONSTITUTION.md`
>   Add the binding rule: agents may implement doctrine, but may not define doctrine. Require every Phase 3 task plan to cite governing doctrine.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md`
>   Clarify that drafts, assessments, and non-canonical review documents must not be treated as governing doctrine.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\CONSTITUTIONAL_HISTORY_RECORD.md`
>   Record the creation and authority purpose of the Phase 3 doctrine set.
>
> - `C:\Workspace\GitHub\Symphony\docs\constitutional\CONSTITUTIONAL_GRAPH.md`
>   Add dependency edges from Phase 3 boundary to each governing doctrine.
>
> Only make targeted amendments to existing replay, sovereignty, evidentiary, retention, regulator, and cryptographic doctrines if cross-references are needed. Do not rewrite their core doctrine unless a contradiction is found.
>
> ### 3. Rewrite Phase 3 Capability Boundary
>
> Replace the current body of `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY.md` with a clean routing/scoping document.
>
> Required structure:
>
> - Constitutional Purpose
> - Phase 3 Scope Summary
> - Authorized Capability Domains
> - Capability-to-Doctrine Matrix
> - Prohibited Capability Routing
> - Required Doctrine Inventory
> - Missing Doctrine and Blocking Conditions
> - Task-Plan Generation Rules
> - Boundary Compliance Checklist
> - Constitutional Exit Conditions
>
> The boundary must not define doctrine locally. It should route each capability using this row shape:
>
> ```text
> Capability Domain → Status → Governing Doctrine → Tasks May Define → Tasks Must Not Define → Blocker Status
> ```
>
> Required task-plan rule:
>
> ```text
> Every Phase 3 task plan must identify an authorized capability domain, cite governing doctrine, declare allowed implementation surface, declare prohibited doctrine surface, and state whether any doctrine blocker remains unresolved.
> ```
>
> ### 4. Pre-Phase 3 Cleanup
>
> Clean up confusing Phase 3 draft/review artifacts so task-generation agents do not treat them as canonical.
>
> Handle these files explicitly:
>
> - `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md`
> - `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_BOUNDARY_REVIEW_ASSESSMENT.md`
>
> Default action: move both to a clearly non-canonical archive location such as `C:\Workspace\GitHub\Symphony\docs\PHASE3\archive\`, and mark them with non-canonical status if retained.
>
> Also check for duplicate/confusing doctrine names, especially `MADD_MAIN_INTEGRATION_DOCTRINE.md` and `MADD_MAIN_INTEGRATION_DOCTRINE-2.md`, and route any cleanup recommendation into the implementation plan notes unless it must be fixed before Phase 3 task planning.
>
> ### 5. Workflow From This Plan to Completion
>
> Use this sequence:
>
> 1. Finalize the implementation plan.
> 2. Create/update the required doctrine documents.
> 3. Rewrite `PHASE3_CAPABILITY_BOUNDARY.md` as a capability router.
> 4. Align legality matrix, task-generation constitution, glossary, graph, ingestion policy, and history record.
> 5. Archive or mark non-canonical Phase 3 draft/assessment documents.
> 6. Create a Phase 3 task plan from the completed boundary.
> 7. Break the task plan into atomic implementation tasks.
> 8. For each atomic task, define exact file paths, acceptance criteria, verification commands, and execution-log evidence.
> 9. Execute implementation tasks.
> 10. Verify and record evidence.
>
> This plan stops at step 5. Steps 6-10 are downstream task-plan and implementation execution work.
>
> ## Test and Review Plan
>
> - Run documentation consistency searches to confirm every doctrine referenced by `PHASE3_CAPABILITY_BOUNDARY.md` exists.
> - Verify no Phase 3 task-generation rule depends on a draft, assessment, or archived document.
> - Check that every authorized Phase 3 capability has a governing doctrine and explicit allowed/forbidden task surface.
> - Check that prohibited capabilities route to the correct later phase instead of being silently omitted.
> - Confirm that no new doctrine contradicts historical truth primacy, temporal replay doctrine, regulator non-collapse, data retention doctrine, or constitutional authority hierarchy.
> - Run the repo’s required documentation/governance verification command only after file edits are complete.
>
> ## Assumptions
>
> - This is an implementation-plan deliverable, not atomic task creation.
> - `PHASE3_CAPABILITY_BOUNDARY.md` should function as a constitutional import map, not a doctrinal specification.
> - Missing doctrine blocks Phase 3 task planning for that capability.
> - Draft and assessment documents should be retained only as non-canonical references, not deleted unless later requested.
> - The implementation should minimize new doctrine files by combining replay acceleration and operational exhaust into the projection doctrine unless separation becomes necessary.

<details><summary>5 previous messages</summary>

> I’ll implement this as a documentation/governance change, so I’m first checking the repo’s agent entrypoint and current document shapes. After that I’ll make the doctrine additions, rewrite the Phase 3 boundary, archive the draft artifacts, and run the relevant verification/search checks.
>
> The repo entrypoint adds one more required read: `docs/operations/PHASE_EXECUTION_ENVELOPE.md`. I’m also working around Git’s safe-directory warning non-mutatively by passing `-c safe.directory=...` per command instead of changing global config.
>
> The current branch is `main`, so I’m creating a feature branch before touching files. The worktree is already heavily dirty from pre-existing changes; I’ll scope my edits to the requested Phase 3 and constitutional docs and avoid unrelated files.
>
> The `codex/...` branch name is blocked because Git cannot create that nested ref in this repository. I’m checking the existing branch refs and will use a flat fallback branch name if needed.
>
> Branch creation needs access to `.git` that the sandbox could not write, and the escalation request was declined. I’ll try switching to an existing Phase 3 feature branch without creating a new ref; if that also fails, I need to stop rather than edit directly on `main`.
</details>

> Don't use git for anything. Just write directly to the file. I will take care of any git concerns

<details><summary>15 previous messages</summary>

> Understood. I will avoid Git entirely from here and write only the requested files directly. I’ll keep the edits scoped to `docs/constitutional` and `docs/PHASE3`, with the two Phase 3 review artifacts moved into a non-canonical archive.
>
> I’ve got the current shapes. The new doctrines will use the existing constitutional metadata style; the boundary will be reduced to a router and the deeper semantics will move into the new doctrine set.
>
> I’m going to add the six missing doctrine files now, then append narrow alignment sections to the existing constitutional docs. I’ll keep the doctrine language authoritative enough for task scoping, but avoid embedding implementation-task detail.
>
> <details><summary>Created 6 files</summary>
>
> - Wrote `./docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md` (+141 -0)
> - Wrote `./docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md` (+123 -0)
> - Wrote `./docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md` (+120 -0)
> - Wrote `./docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` (+234 -0)
> - Wrote `./docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md` (+136 -0)
> - Wrote `./docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md` (+128 -0)
>
> </details>
>
> The doctrine files are in place. Next I’m replacing the Phase 3 boundary with a compact routing document that references those doctrines instead of restating their semantics.
>
> <details><summary>Created 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` (+240 -0)
>
> </details>
>
> The boundary is now a doctrine router. I’m adding the required alignment sections to the existing constitutional documents next, with targeted append-only style changes rather than broad rewrites.
>
> One multi-file patch missed an encoded line in `TASK_GENERATION_CONSTITUTION.md`, so it did not apply. I’m splitting the alignment patches and anchoring them on simpler headings to avoid encoding-sensitive matches.
>
> <details><summary>Edited 6 files</summary>
>
> - Wrote `./docs/constitutional/CONSTITUTIONAL_GLOSSARY.md` (+61 -0)
> - Wrote `./docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md` (+28 -0)
> - Wrote `./docs/constitutional/TASK_GENERATION_CONSTITUTION.md` (+19 -0)
> - Wrote `./docs/constitutional/NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md` (+17 -0)
> - Wrote `./docs/constitutional/CONSTITUTIONAL_HISTORY_RECORD.md` (+52 -0)
> - Wrote `./docs/constitutional/CONSTITUTIONAL_GRAPH.md` (+15 -0)
>
> </details>
>
> The existing constitutional docs are aligned. I’m archiving the two Phase 3 review/draft artifacts now and adding explicit non-canonical headers so they cannot be mistaken for governing doctrine.
>
> <details><summary>Edited 2 files</summary>
>
> - Wrote `./docs/PHASE3/archive/PHASE3_BOUNDARY_REVIEW_ASSESSMENT.md` (+10 -3)
> - Wrote `./docs/PHASE3/archive/PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md` (+8 -2)
>
> </details>
>
> The archive markers are in place. I’m checking the duplicate MADD/MAIN doctrine names now; unless there is a hard blocker, I’ll record it as a non-blocking cleanup note rather than broadening this change.
>
> <details><summary>Edited 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` (+11 -1)
>
> </details>
>
> The MADD duplicate is recorded as a non-blocking cleanup note with the canonical file named. I’m running read-only consistency checks now: referenced doctrine existence, archive isolation, and whether any Phase 3 surface still points to the archived draft files as governing sources.
>
> The consistency checks passed for the new doctrine references and the archived draft files are no longer referenced as governing sources. I’m doing one final read-through of the changed headings and metadata before I close this out.
</details>

Implemented the Phase 3 Boundary and Doctrine Readiness plan.

Created the six governing doctrines in `docs/constitutional`:

- [LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md)
- [AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md)
- [CONTRADICTION_CLASSIFICATION_DOCTRINE.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md)
- [FAILURE_COMPOSITION_TAXONOMY.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md)
- [SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md)
- [POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md)

Rewrote [PHASE3_CAPABILITY_BOUNDARY.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md) as a capability-to-doctrine router. It now contains the authorized capability domains, doctrine matrix, prohibited routing, blocker rules, task-plan generation rules, compliance checklist, and cleanup notes.

Updated the supporting constitutional docs:

- [CONSTITUTIONAL_GLOSSARY.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/CONSTITUTIONAL_GLOSSARY.md)
- [PHASE_CAPABILITY_LEGALITY_MATRIX.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md)
- [TASK_GENERATION_CONSTITUTION.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/TASK_GENERATION_CONSTITUTION.md)
- [NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md)
- [CONSTITUTIONAL_HISTORY_RECORD.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/CONSTITUTIONAL_HISTORY_RECORD.md)
- [CONSTITUTIONAL_GRAPH.md](/C:/Workspace/GitHub/Symphony/docs/constitutional/CONSTITUTIONAL_GRAPH.md)

Archived the confusing Phase 3 draft/review files under:

- [PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/archive/PHASE3_CAPABILITY_BOUNDARY_DRAFT_CONSTITUTIONAL_REVIEW.md)
- [PHASE3_BOUNDARY_REVIEW_ASSESSMENT.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/archive/PHASE3_BOUNDARY_REVIEW_ASSESSMENT.md)

Both are now explicitly marked non-canonical and `DO-NOT-INGEST`.

I also recorded the duplicate `MADD_MAIN_INTEGRATION_DOCTRINE-2.md` issue as a non-blocking cleanup note in the boundary, with `MADD_MAIN_INTEGRATION_DOCTRINE.md` named as the only canonical citation target.

Verification performed:

- Confirmed all new required doctrine files exist.
- Confirmed all local dependencies listed by the new doctrine/boundary files exist.
- Confirmed the archived Phase 3 draft/assessment files are no longer referenced as governing sources.
- Confirmed archive files carry non-canonical / do-not-ingest markers.

I did not run Git commands or `scripts/dev/pre_ci.sh`, per your instruction not to use Git for anything.

> Are we ready to start creating the implemenation plans now? IF now what is next

Yes, we are ready to start creating the **Phase 3 implementation plans**.

What is now in place:

- `PHASE3_CAPABILITY_BOUNDARY.md` now routes capabilities to doctrine.
- The missing governing doctrines now exist.
- Task-generation rules now say agents may implement doctrine but may not define doctrine.
- Draft/assessment docs have been archived and marked non-canonical.
- The boundary now identifies authorized, conditional, blocked, and prohibited Phase 3 work.

The next step is **not atomic task creation yet**. The next step is to create one or more **implementation plans** that sit between the boundary/doctrine corpus and final task packs.

Recommended next sequence:

1. Create the **Phase 3 Master Implementation Plan**
   This should map each authorized capability domain to implementation-plan work packages, dependencies, acceptance criteria, verifier expectations, and sequencing.

2. Create capability-specific implementation plans, likely:
   - Typed Dependency Graph
   - Replay Projection / Recursive Legitimacy
   - Contradiction Detection
   - Failure Composition
   - Authority Scope and Delegation
   - Conflict-of-Interest Enforcement
   - Spatial Constraint / DNSH Gates
   - Dwell-Time Forensics
   - Phase 3 Verifier and CI Enforcement

3. Review those plans against:
   - `PHASE3_CAPABILITY_BOUNDARY.md`
   - the new doctrine documents
   - `phase3_contract.yml`
   - `PHASE3_INVARIANT_REGISTER.md`

4. Only after that, create atomic implementation tasks with:
   - exact file paths
   - acceptance criteria
   - verifier commands
   - evidence outputs
   - anti-hallucination / out-of-scope controls

One caveat: before generating task packs, I would first review `phase3_contract.yml` because I noticed it has a likely YAML indentation defect around `P3-004`:

```yaml
  - id: "P3-004"
    ...
    phase_scope: "PHASE-3"
status: "planned"
```

That `status` appears incorrectly de-indented. It should probably be fixed before implementation plans depend on the contract mechanically.

So the practical next step is:

**Create the Phase 3 Master Implementation Plan, while also flagging contract/invariant-register cleanup items that must be resolved before atomic task creation.**

> Go ahead and create the Phase 3 Master Implementation Plan, while also flagging contract/invariant-register cleanup items that must be resolved before atomic task creation.

<details><summary>4 previous messages</summary>

> I’ll create this as a Phase 3 planning artifact, not atomic task packs. First I’m reading the Phase 3 contract and invariant register so the master plan can flag concrete cleanup items rather than generic ones.
>
> The concrete cleanup issues are clear: `phase3_contract.yml` has a malformed `P3-004` indentation, `docs/PHASE3/README.md` is stale and contradicts the opened Constraint and Legitimacy Engine posture, and the invariant register still needs doctrine-reference alignment before atomic tasks are generated. I’m creating the master implementation plan with those blockers called out explicitly.
>
> <details><summary>Created 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` (+342 -0)
>
> </details>
>
> The master implementation plan is created. I’m running quick consistency checks on the new plan’s dependencies and the cleanup flags so I can tell you exactly what remains before atomic task creation.
</details>

Created the Phase 3 Master Implementation Plan at:

[PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md)

It defines the planning hierarchy, the work package sequence `P3-WP-00` through `P3-WP-11`, capability-specific implementation plan requirements, acceptance criteria, and the atomic task creation gate.

It also flags these cleanup blockers before atomic task creation:

- `P3-CLEAN-001`: fix malformed YAML indentation in [phase3_contract.yml](/C:/Workspace/GitHub/Symphony/docs/PHASE3/phase3_contract.yml)
- `P3-CLEAN-002`: rewrite stale [README.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/README.md)
- `P3-CLEAN-003`: add governing doctrine references to [PHASE3_INVARIANT_REGISTER.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_INVARIANT_REGISTER.md)
- `P3-CLEAN-004`: review [PHASE3_OPENING_ACT.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_OPENING_ACT.md) against the active execution envelope
- `P3-CLEAN-005`: handle duplicate generated `MADD_MAIN_INTEGRATION_DOCTRINE-2.md`
- `P3-CLEAN-006`: ensure archived Phase 3 drafts are excluded from ingestion/task-generation

Verification done: all dependencies listed in the new plan exist, and the cleanup/work-package IDs are present in the plan.

> Look at the attached file and tell me if the tasks in it are covered by the one you created. Do a gap analysis of:
> 1. If the Pre-phase 3 tasks are true
> 2. What both cover
> 3. What the attached covers in full that yours doesn't and if the tasks are relevant,
>
> User context
>
> Attachments:
> - STEP2_Phase3_Codebase_Revised_Task_Plan.md: `C:/Workspace/GitHub/Symphony-Buraucracy/Task_Fleshing/STEP2_Phase3_Codebase_Revised_Task_Plan.md`

<details><summary>1 previous message</summary>

> I’ll compare the attached plan against the Phase 3 master plan and the current Phase 3 docs, read-only. I’m going to check the attachment, then map its task groups against the cleanup blockers and work packages already created.
</details>

The attachment makes several “codebase ground truth” claims, especially about completed `TSK-P3-*` tasks and migrations `0205/0206`. I’m going to verify those specific claims against the repo before calling the pre-phase tasks true or false.

> You got cut off. Resume

<details><summary>1 previous message</summary>

> I have enough to resume the comparison. I’m going to verify the status fields for the specific pre-existing `TSK-P3-*` tasks because the attachment’s pre-phase conclusions depend on whether those tasks are really completed or only scaffolded.
</details>

Resuming the comparison:

**Short Answer**

The attachment is **not fully covered** by the Phase 3 Master Implementation Plan I created, because they operate at different levels.

My plan is a **master implementation-plan scaffold**: work packages, doctrine routing, cleanup blockers, and atomic-task gate.

The attachment is closer to a **codebase-revised task inventory**: it names specific `TSK-P3-*` tasks, completed tasks, migrations, missing task IDs, verifier gaps, and wave/domain-level task candidates.

So: **the master plan covers the same major capability areas, but it does not yet absorb the attachment’s detailed task inventory.** The attachment contains useful material that should feed the next planning layer.

**1. Are The Pre-Phase 3 Claims True?**

Mostly yes, with one important caveat.

I verified locally:

- `tasks/TSK-P3-*` directories exist.
- These are marked `status: completed` in `meta.yml`:
  - `TSK-P3-PRE-001`
  - `TSK-P3-GOV-001`
  - `TSK-P3-GOV-002`
  - `TSK-P3-GOV-003`
  - `TSK-P3-W1-DB-007`
  - `TSK-P3-W8-SEAL-001`
  - `TSK-P3-W8-ARCH-001`
- `TSK-P3-PRE-009` exists and is marked `status: planned`.
- `schema/migrations/0205_evidence_nodes_data_class.sql` exists.
- `schema/migrations/0206_phase3_invariant_registry_seed.sql` exists.
- `docs/constitutional/data_class_registry.yml` exists.
- The repo has scripts for several completed claims, including:
  - `scripts/constitutional/compile_phase3_constraints.py`
  - `scripts/db/verify_p3_evidence_nodes_data_class.sh`
  - `scripts/db/verify_p3_invariant_registry_seed.sh`
  - `scripts/db/verify_p3_epoch_sealing.sh`
  - `scripts/audit/verify_p3_hash_chain_bridge.sh`
  - `scripts/audit/verify_p3_task_archival_gate.sh`

Caveat: I did **not** run the verifiers or validate evidence freshness, so I can confirm repo status/artifact presence, not independent True-Complete closure.

Also, the attachment says no Wave 1 task may begin until `TSK-P3-PRE-009` passes. That is not historically true anymore because `TSK-P3-W1-DB-007` is already marked completed while `PRE-009` remains planned. As a forward-looking gate before **new remaining implementation**, the idea is relevant. As a statement about prior execution order, it is contradicted by the repo.

**2. What Both Cover**

Both my master plan and the attachment cover these areas:

- Typed dependency graph foundations
- Recursive legitimacy / replay reconstruction
- Policy and authority lineage
- Contradiction detection
- Failure composition
- Authority scope and delegation
- Regulator non-collapse / arbitration
- Conflict-of-interest enforcement
- Spatial/DNSH gates
- Dwell-time / temporal forensic enforcement
- Verifier and CI enforcement
- Pre-atomic cleanup/readiness before broader task creation

The difference is granularity.

My plan groups these into `P3-WP-00` through `P3-WP-11`.

The attachment breaks them into named `TSK-P3-*` task candidates and wave/domain inventories.

**3. What The Attachment Covers Better Or In Full**

The attachment covers several things my master plan only gestures at or does not yet include.

Immediately relevant additions:

- Completed-task exclusion list
  Useful. The master plan should explicitly say these completed `TSK-P3-*` tasks must not be recreated.

- `TSK-P3-PRE-009` as a readiness exit gate
  Relevant. This should be folded into `P3-WP-00`, but phrased as a remaining readiness gate for new task generation, not as a historical precondition that was obeyed.

- Exact Phase 3 task inventory by wave/domain
  Relevant for the next layer: capability-specific implementation plans or task-plan creation.

- `mutability_class` gap on `evidence_nodes`
  Potentially relevant, but needs doctrine check. It touches MRV mutability/retention and may overlap Phase 6 or retention doctrine. It should become a cleanup/doctrine-routing candidate, not be accepted automatically.

- `INV-301` through `INV-310` promotion from `is_blocking=FALSE` to `TRUE`
  Relevant, but only after implementation and verifier evidence exist. This belongs late in verifier/CI planning, not early Wave 2 unless dependencies are proven.

- Capability boundary enforcement verifier
  Highly relevant. My master plan says boundary compliance must be enforceable, but the attachment gives the concrete missing task: a CI verifier for prohibited Phase 3 scope.

- Per-invariant verifier suite and negative-test enforcement
  Highly relevant. This belongs in `P3-WP-11`.

- Migration numbering note: next Phase 3 migration is `0207`
  Relevant if atomic DB tasks are created later.

- Existing substrate notes
  Useful: reuse `proof_pack_batches`, `canonicalization_archive_snapshots`, `canonicalization_registry`, `interpretation_version_id`, `wave8_signer_resolution`, and existing append-only trigger patterns instead of creating parallel systems.

Potentially relevant but needs caution:

- Retention/tombstoning/cold exhaust tasks
  Some are Phase 3-relevant only as replay/projection constraints. Full PII erasure, sovereign retention runtime, WORM/cold storage, and statutory retention arbitration may belong to Phase 4/6/8 depending on doctrine.

- External verifier package generation
  Relevant if scoped as artifact-alone replay package mechanics. Not relevant if it becomes external registry/auditor portal integration.

- Large Domain G-P inventory
  Useful as a task source, but too broad to import directly. It needs mapping through the new boundary matrix before becoming task plans.

**Gap Summary**

What my plan has that the attachment lacks:

- Doctrine-router discipline.
- Explicit “agents may implement doctrine but may not define doctrine.”
- Cleanup blockers around stale `README`, malformed `phase3_contract.yml`, invariant-register doctrine alignment, archived draft isolation, and duplicate MADD doctrine.
- Clear pre-atomic gate before task creation.

What the attachment has that my plan lacks:

- Specific existing task IDs and completion statuses.
- Concrete task inventory by wave/domain.
- Known codebase substrate reuse instructions.
- Specific missing tasks:
  - mutability class axis
  - INV blocking promotion
  - Phase 3 capability-boundary verifier
  - INV verifier suite
  - negative-test coverage enforcement
- Migration numbering and completed migration awareness.

**Conclusion**

The attachment is valuable, but it should not replace the master plan. It should be treated as the **candidate task inventory input** for the next layer.

Next correct step: revise or extend the master plan with a section called something like **Codebase-Revised Task Inventory Inputs**, then create `P3-WP-00` cleanup implementation plan first. That cleanup plan should reconcile the attachment’s task inventory with the new doctrine-router boundary before any atomic task packs are generated.

> Do this:
> 1. Make sure all task IDs are created starting with prefix TSK-
> 2. Are there instructions for an AI Agent to create these initial plans like how the atomic plans and tasks have [TASK_CREATION_PROCESS.md](docs/operations/TASK_CREATION_PROCESS.md) [SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md](docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md) [SYMPHONY_TASKS_CREATION_SUMMARY.md](SYMPHONY_TASKS_CREATION_SUMMARY.md) etc.
> 3. Won't we need to decide a mode in [AGENT_ENTRYPOINT.md](symphony-enforcement-v2/enf-004-agent-entrypoint-docs/AGENT_ENTRYPOINT.md) for an agent to use for this process

<details><summary>10 previous messages</summary>

> I’ll treat this as a governance-doc update: first I’ll inspect the existing task/implementation process docs and entrypoint modes, then I’ll add the missing planning-process guidance and make the master plan’s IDs conform to `TSK-` where needed.
>
> I found there is no dedicated process document for this “master/capability implementation plan before atomic tasks” layer, and `AGENT_ENTRYPOINT.md` only exposes task-pack modes. I’m going to add a planning mode plus a process document, then update the Phase 3 master plan IDs so the cleanup/work-package identifiers are `TSK-` prefixed.
>
> The envelope still conflicts with Phase 3 execution claims, which matches the blocker already captured in the master plan. I’m not going to create implementation tasks; I’ll add the missing initial-plan process/mode and normalize planning IDs so future task creation is mechanically distinguishable from these broader plans.
>
> The combined patch hit the same encoding issue around the router’s mode heading. I’m splitting the edits and anchoring on simpler text so the updates apply cleanly.
>
> <details><summary>Created 1 file, edited 2 files</summary>
>
> - Wrote `./docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` (+190 -0)
> - Wrote `./AGENT_ENTRYPOINT.md` (+2 -0)
> - Wrote `./docs/operations/AGENT_PROMPT_ROUTER.md` (+1 -1)
> - Wrote `./docs/operations/AGENT_PROMPT_ROUTER.md` (+35 -0)
>
> </details>
>
> The new mode and process doc are in place. I’m now normalizing the Phase 3 master plan’s cleanup/work-package identifiers to `TSK-` prefixed planning IDs.
>
> <details><summary>Edited 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` (+19 -19)
> - Wrote `./docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` (+15 -15)
>
> </details>
>
> The ID normalization is applied. I’m checking for any remaining non-`TSK-` planning identifiers and confirming the new mode/process references resolve.
>
> The primary files are updated. I found two secondary docs still saying “five modes,” so I’m correcting those references to avoid drift now that `CREATE-IMPLEMENTATION-PLAN` exists.
>
> <details><summary>Edited 2 files</summary>
>
> - Wrote `./docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md` (+3 -2)
> - Wrote `./docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md` (+3 -1)
>
> </details>
</details>

Implemented the governance updates.

What changed:

- Added [IMPLEMENTATION_PLAN_CREATION_PROCESS.md](/C:/Workspace/GitHub/Symphony/docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md)
  - Defines how agents create master/capability/cleanup implementation plans before atomic task packs.
  - Requires all planning work items that may become tasks to use `TSK-` prefixes.
  - Separates implementation-plan creation from `TASK_CREATION_PROCESS.md`.

- Updated [AGENT_ENTRYPOINT.md](/C:/Workspace/GitHub/Symphony/AGENT_ENTRYPOINT.md)
  - Added new mode: `CREATE-IMPLEMENTATION-PLAN`.
  - Added the new process doc to canonical references.

- Updated [AGENT_PROMPT_ROUTER.md](/C:/Workspace/GitHub/Symphony/docs/operations/AGENT_PROMPT_ROUTER.md)
  - Added `Mode 0 - CREATE-IMPLEMENTATION-PLAN`.
  - Clarifies this mode cannot create atomic task packs, migrations, verifiers, or evidence.

- Updated [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md)
  - Changed cleanup IDs from `P3-CLEAN-*` to `TSK-P3-CLEAN-*`.
  - Changed work package IDs from `P3-WP-*` to `TSK-P3-WP-*`.
  - Added dependency on the new implementation-plan process doc.

- Updated secondary references:
  - [SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md](/C:/Workspace/GitHub/Symphony/docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md)
  - [AGENT_WORKFLOW_CONTROL_PLAN.md](/C:/Workspace/GitHub/Symphony/docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md)

Verification performed:

- Confirmed `CREATE-IMPLEMENTATION-PLAN` appears in `AGENT_ENTRYPOINT.md` and `AGENT_PROMPT_ROUTER.md`.
- Confirmed the new process doc exists.
- Confirmed no remaining non-`TSK-` `P3-CLEAN-*` or `P3-WP-*` IDs remain in the master plan.

I did not run Git or broader CI/pre-ci.

> If all TSK-P3-CLEAN-00* tasks are done, create Todo list from now till full and complete implementation of Phase 3 tasks

<details><summary>2 previous messages</summary>

> I’ll first verify whether the six `TSK-P3-CLEAN-00*` blockers are actually resolved from the repo state. If any remain open, I’ll make the todo list start with those rather than pretending Phase 3 implementation planning can safely proceed.
>
> Context compaction
>
> Source: automatic
> Status: completed
</details>

Not yet. Based on the checks, `TSK-P3-CLEAN-00*` is **not complete**. The todo list needs to start with cleanup blockers before Phase 3 task planning or atomic task creation.

**Phase 3 Todo List**

| Order | ID | Todo | Status |
|---:|---|---|---|
| 1 | `TSK-P3-CLEAN-001` | Fix malformed YAML in `C:\Workspace\GitHub\Symphony\docs\PHASE3\phase3_contract.yml`, especially the de-indented `status` field under `P3-004`; then validate YAML parsing. | Blocker |
| 2 | `TSK-P3-CLEAN-002` | Rewrite `C:\Workspace\GitHub\Symphony\docs\PHASE3\README.md`; it still describes Phase 3 as “External Trust Surfaces” and “NOT OPEN FOR IMPLEMENTATION,” which conflicts with the current Phase 3 legitimacy/constraint boundary. | Blocker |
| 3 | `TSK-P3-CLEAN-003` | Update `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_INVARIANT_REGISTER.md` so Phase 3 invariants cite the new governing doctrines. | Blocker |
| 4 | `TSK-P3-CLEAN-004` | Reconcile Phase 3 opening posture: `PHASE3_OPENING_ACT.md` appears to open Phase 3, while execution-envelope doctrine still appears to say Phase 3 is not open/executable. This must be authoritatively resolved before implementation tasks. | Blocker |
| 5 | `TSK-P3-CLEAN-005` | Resolve `C:\Workspace\GitHub\Symphony\docs\constitutional\MADD_MAIN_INTEGRATION_DOCTRINE-2.md`; it still reads like non-canonical prompt-response material and should be archived, marked non-canonical, or merged intentionally. | Blocker |
| 6 | `TSK-P3-CLEAN-006` | Confirm archived Phase 3 draft/review docs are excluded from ingestion/task-generation tooling, not just marked non-canonical in the files. | Mostly done, needs verifier check |

After cleanup:

| Order | ID | Todo |
|---:|---|---|
| 7 | `TSK-P3-PLAN-001` | Refresh the Phase 3 Master Implementation Plan to include the cleanup outcomes and exclude already-completed tasks. |
| 8 | `TSK-P3-PLAN-002` | Create implementation-plan instructions for Phase 3 planning mode, aligned with `CREATE-IMPLEMENTATION-PLAN`, before atomic task creation begins. |
| 9 | `TSK-P3-PLAN-003` | Convert each Phase 3 work package into implementation plans, not atomic tasks yet. |
| 10 | `TSK-P3-TASKGEN-001` | Once implementation plans are approved, generate atomic tasks using the existing task creation process. |
| 11 | `TSK-P3-TASKGEN-002` | For each atomic task, require exact file paths, doctrine citations, acceptance criteria, verification commands, and execution-log evidence. |
| 12 | `TSK-P3-IMPL-001` | Implement typed dependency graph work. |
| 13 | `TSK-P3-IMPL-002` | Implement policy artifact and authority lineage runtime. |
| 14 | `TSK-P3-IMPL-003` | Implement projection universe and recursive legitimacy evaluation. |
| 15 | `TSK-P3-IMPL-004` | Implement contradiction detection and quarantine handling. |
| 16 | `TSK-P3-IMPL-005` | Implement failure composition and evidence continuity. |
| 17 | `TSK-P3-IMPL-006` | Implement authority scope and delegation validation. |
| 18 | `TSK-P3-IMPL-007` | Implement regulator arbitration and non-collapse handling. |
| 19 | `TSK-P3-IMPL-008` | Implement conflict-of-interest enforcement. |
| 20 | `TSK-P3-IMPL-009` | Implement spatial legality, DNSH gates, and anti-double-counting checks. |
| 21 | `TSK-P3-IMPL-010` | Implement dwell-time forensic logic. |
| 22 | `TSK-P3-VERIFY-001` | Build Phase 3 verifier suite, including boundary, doctrine-reference, invariant, and negative-test checks. |
| 23 | `TSK-P3-VERIFY-002` | Promote Phase 3 invariants to blocking only after enforcement and verifier evidence exists. |
| 24 | `TSK-P3-CLOSE-001` | Run full governance/docs verification, record evidence, and confirm Phase 3 exit criteria are satisfied. |

The immediate next step is **not full Phase 3 implementation**. It is completing `TSK-P3-CLEAN-001` through `TSK-P3-CLEAN-006`, especially the Phase 3 opening-status conflict. Without that, downstream task creation can still inherit contradictory authority.

> How do I write prompt for an AI agent to begin the implementation in the proper mode in AGENT_ENTRYPOINT.md? Doea this process require two prompts? One to create the initial plan then the next to create the atomic plans/tasks?

<details><summary>1 previous message</summary>

> I’ll check the current entrypoint wording before answering so the prompt matches the modes that actually exist in the repo.
</details>

Yes. This should be at least **two prompts**, and in practice usually **three stages**:

1. **CREATE-IMPLEMENTATION-PLAN**
   Creates or revises broad Phase 3 implementation plans. No atomic task packs.

2. **CREATE-TASK**
   Converts approved plan items into atomic task packs.

3. **RESUME-TASK / IMPLEMENT-TASK**
   Executes one atomic task after its task pack exists and passes readiness checks.

Do **not** ask one agent to create the implementation plan, create task packs, and implement code in the same prompt. That collapses the governance layers.

**Prompt 1: Create Or Update Implementation Plan**

Use this when you want the agent to plan the work but not create task directories.

```text
Read AGENT_ENTRYPOINT.md first and classify this prompt as CREATE-IMPLEMENTATION-PLAN.

Create or update the Phase 3 implementation plan for [SCOPE].

This is implementation-plan work only. Do not create tasks/<TASK_ID>/ directories. Do not create atomic task PLAN.md or EXEC_LOG.md files. Do not implement code, migrations, verifier scripts, or evidence artifacts.

Follow:
- docs/operations/AGENT_PROMPT_ROUTER.md
- docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md
- docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md
- docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md

The plan must:
- use only TSK-prefixed planning IDs;
- identify governing doctrines;
- identify cleanup blockers;
- identify out-of-phase routing exclusions;
- define work packages and sequencing;
- state the gate conditions required before atomic task creation.

If the execution envelope or phase-opening state conflicts with the requested work, record it as a blocker and do not treat Phase 3 as executable.
```

For the current repo, `[SCOPE]` should probably be:

```text
remaining TSK-P3-CLEAN-00* cleanup blockers and readiness conditions before Phase 3 atomic task creation
```

**Prompt 2: Create Atomic Task Packs**

Use this only after the implementation plan is accepted.

```text
Read AGENT_ENTRYPOINT.md first and classify this prompt as CREATE-TASK.

Create atomic task packs from the approved Phase 3 implementation plan for the following work package:

[WORK PACKAGE ID AND NAME]

Follow:
- docs/operations/AGENT_PROMPT_ROUTER.md
- docs/operations/TASK_CREATION_PROCESS.md
- docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md
- docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md
- docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md

Create only atomic task-pack artifacts. Do not implement the task.

Each task must include:
- tasks/<TASK_ID>/meta.yml
- docs/plans/phase3/<TASK_ID>/PLAN.md
- docs/plans/phase3/<TASK_ID>/EXEC_LOG.md
- governing doctrine citations
- exact allowed file paths
- prohibited doctrine surface
- dependencies
- acceptance criteria
- verifier commands
- required evidence outputs

Do not create tasks for unresolved blockers. If the work package depends on unresolved cleanup or doctrine conflicts, stop and report the blocker.
```

**Prompt 3: Implement One Atomic Task**

Use this after the task pack exists.

```text
Read AGENT_ENTRYPOINT.md first and classify this prompt according to the repo router.

Resume and implement task <TASK_ID>.

Follow:
- docs/operations/AGENT_PROMPT_ROUTER.md
- docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md
- the task meta.yml
- the task PLAN.md
- the task EXEC_LOG.md

Do not expand scope beyond the task pack. If dependencies are incomplete, verification fails, or the task is not resume-ready, stop and report the blocking condition.
```

So the short answer is:

- **Yes, two prompts minimum**: one for implementation planning, one for atomic task creation.
- **Actual execution requires a third prompt** per task or per resumable task.
- For Phase 3 specifically, you should first use `CREATE-IMPLEMENTATION-PLAN` to close the remaining `TSK-P3-CLEAN-00*` blockers before creating atomic tasks.

> Is there a default place that the initial implementation plan is saved? This is important for continuity so that another agent or IDE can pick up the tasks created using different IDEs. Do these plans also have statuses to show which have been completed or planned?

<details><summary>1 previous message</summary>

> I’ll ground this in the repo conventions rather than guessing, especially because continuity across IDEs depends on the exact path/status scheme.
</details>

Current repo state: **partially, but not strongly enough yet.**

There is a default-ish place by convention, but the implementation-plan process does **not yet define one canonical storage rule**.

For Phase 3, the current broad plan is here:

`C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_MASTER_IMPLEMENTATION_PLAN.md`

Atomic task execution plans are different and already have a stronger convention:

`C:\Workspace\GitHub\Symphony\docs\plans\phase3\<TASK_ID>\PLAN.md`
`C:\Workspace\GitHub\Symphony\docs\plans\phase3\<TASK_ID>\EXEC_LOG.md`

So the distinction should be:

| Artifact | Purpose | Default Location |
|---|---|---|
| Master implementation plan | Broad phase/work-package planning before atomic task creation | `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` |
| Capability-specific implementation plan | Planning layer for one Phase 3 work package before atomic tasks | Should probably be `docs/PHASE3/implementation_plans/<TSK-P3-WP-###>.md` |
| Atomic task pack | Actual executable implementation unit | `tasks/<TASK_ID>/meta.yml` plus `docs/plans/phase3/<TASK_ID>/PLAN.md` and `EXEC_LOG.md` |

Right now, `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` requires metadata like:

```text
Constitutional-Status: PLANNING
NotebookLM-Ingestion: DO-NOT-INGEST
```

But that is **not the same as workflow status**. It tells us the authority class of the document, not whether the plan is completed, blocked, accepted, converted to tasks, or implemented.

So yes, I think we should add explicit statuses for implementation plans.

A clean minimal status model would be:

```text
Plan-Status: DRAFT | READY-FOR-TASK-CREATION | BLOCKED | SUPERSEDED | CONVERTED-TO-TASKS | COMPLETED
```

And for work-package rows inside the master plan:

```text
Work-Package-Status: PLANNED | BLOCKED | READY-FOR-TASK-CREATION | TASKS-CREATED | IN-PROGRESS | COMPLETE
```

The important governance distinction:

- `Constitutional-Status: PLANNING` means “this is not doctrine and not an atomic task.”
- `Plan-Status: READY-FOR-TASK-CREATION` means “another agent may now use this to create atomic tasks.”
- `Plan-Status: CONVERTED-TO-TASKS` means “atomic task packs now exist; do not recreate them.”
- `Plan-Status: COMPLETED` should only be used when all downstream atomic tasks are complete and verified.

For cross-IDE continuity, I would standardize this:

```text
docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
docs/PHASE3/implementation_plans/<TSK-P3-WP-###>_<short_name>.md
docs/PHASE3/implementation_plans/README.md
```

The `README.md` should act as the index/registry, with rows like:

```text
Plan ID | Title | Plan Status | Source Work Package | Atomic Tasks Created | Blocking Cleanup IDs | Last Updated
```

That gives Cursor, Codex, NotebookLM, or another IDE a stable place to resume from without guessing.

> This isn't properly thought through. I want you to tell me if there is a smooth flow of events in the following workflow starting from a new phase:
> Step 1: define boundaries from an initial document like [Symphony-Phase-Specification-Document_v1.md](docs/architecture/Symphony-Phase-Specification-Document_v1.md)
> Step 2: create Master Implementation plan from boundaries
> Step 3: Extract individual implementation plans from Master Implementation plan using agent in CREATE-IMPLEMENTATION-PLAN mode in AGENT_ENTRYPOINT.md

<details><summary>1 previous message</summary>

> I’ll check the current phase-spec, boundary, and implementation-plan process shape, then I’ll answer whether the workflow has a smooth handoff or where it needs another control point.
</details>

No. The workflow is directionally right, but it is **not yet smooth enough** for reliable cross-agent continuity.

The main problem is that your Step 1 → Step 2 jump is too large, and Step 3 has no canonical storage/status handoff yet.

**Current Proposed Flow**
```text
Step 1: Define boundaries from phase spec
Step 2: Create Master Implementation Plan from boundaries
Step 3: Extract individual implementation plans from Master Plan using CREATE-IMPLEMENTATION-PLAN
```

That is missing three controls:

1. **Doctrine readiness gate** between boundary and master plan.
2. **Phase execution/opening gate** before any plan claims work is executable.
3. **Plan registry/status layer** so other IDEs/agents know what exists, what is blocked, and what has already been converted into atomic tasks.

The smoother flow should be:

```text
0. Phase Source Intake
   ↓
1. Phase Capability Boundary
   ↓
2. Doctrine / Contract / Invariant Readiness Check
   ↓
3. Master Implementation Plan
   ↓
4. Capability-Specific Implementation Plans
   ↓
5. Atomic Task Creation
   ↓
6. Task Implementation
   ↓
7. Verification / Evidence / Completion
```

For a new phase, the clean version is:

| Step | Artifact | Mode |
|---|---|---|
| 0 | Read phase spec, legality matrix, execution envelope, constitutional docs | Non-mutating inspection |
| 1 | Create `PHASE<N>_CAPABILITY_BOUNDARY.md` | `CREATE-IMPLEMENTATION-PLAN` or governance planning |
| 2 | Create/update required doctrine, contract, invariant register readiness notes | `CREATE-IMPLEMENTATION-PLAN` |
| 3 | Create `PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md` | `CREATE-IMPLEMENTATION-PLAN` |
| 4 | Create individual work-package implementation plans | `CREATE-IMPLEMENTATION-PLAN` |
| 5 | Create atomic task packs from approved implementation plans | `CREATE-TASK` |
| 6 | Execute each task | `RESUME-TASK` / `IMPLEMENT-TASK` |

So yes: **Step 3 still uses `CREATE-IMPLEMENTATION-PLAN`**, but it should not be described as merely “extracting” plans. The agent should create **capability-specific implementation plans** from the master plan, while checking doctrine, blockers, dependencies, and existing task packs.

The missing continuity piece should be added:

```text
docs/PHASE<N>/PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md
docs/PHASE<N>/implementation_plans/README.md
docs/PHASE<N>/implementation_plans/<TSK-P<N>-WP-###>_<short_name>.md
```

And the `README.md` should act as a plan registry:

```text
Plan ID | Title | Status | Source Boundary Row | Depends On | Atomic Tasks Created | Blockers
```

The status model should be explicit:

```text
DRAFT
BLOCKED
READY-FOR-TASK-CREATION
CONVERTED-TO-TASKS
IN-PROGRESS
COMPLETE
SUPERSEDED
```

Without that registry, a second agent or IDE has to infer continuity from scattered files, which is exactly the kind of ambiguity that causes duplicate tasks and scope drift.

The corrected workflow is therefore:

```text
Phase spec
  → capability boundary
  → doctrine / contract / invariant readiness
  → master implementation plan
  → implementation-plan registry
  → capability-specific implementation plans
  → atomic task packs
  → implementation
  → evidence-backed completion
```

The key correction: **the Master Implementation Plan is not enough by itself.** It needs a persistent implementation-plan registry and statuses before it becomes a reliable source for downstream task creation.

> The next issue is that this process depends on the full scope of the Phase being established from the start. This is the only way that tasks can then be grouped in Waves or domains and a proper task DAG graph created. A Phase's tasks/plans have to be fully pre-planned for and all tasks established. If there are any gaps, they can be added as one of the remedial task modes through AGENT_ENTRYPOINT.md. Your pocess doesn't consider the DAG or sequence of tasks implementation

<details><summary>2 previous messages</summary>

> You’re right: the process I described was too linear and file-artifact focused. I’m going to check the existing task/DAG conventions briefly so the corrected workflow fits Symphony’s current planning model instead of inventing a parallel one.
>
> Plan
>
> # Phase Planning and DAG Workflow
>
> ## Summary
>
> A new phase must be planned as a complete implementation universe before atomic task creation begins. The boundary defines what the phase may build, but the master implementation plan must then enumerate the full phase scope, group it into domains/waves, create the task DAG, identify blockers, and reserve task IDs. Individual implementation plans and atomic tasks are derived from that complete DAG, not created opportunistically.
>
> ## Correct Flow
>
> 1. **Phase Source Intake**
>    - Read the phase specification, legality matrix, execution envelope, existing phase artifacts, contracts, invariant registers, and governing doctrines.
>    - Output: source inventory and unresolved authority conflicts.
>
> 2. **Capability Boundary Definition**
>    - Create or update `PHASE<N>_CAPABILITY_BOUNDARY.md`.
>    - Purpose: define authorized domains, prohibited domains, doctrine references, and doctrine blockers.
>    - This is not yet task planning.
>
> 3. **Doctrine / Contract / Invariant Readiness**
>    - Confirm every authorized capability has governing doctrine.
>    - Confirm contract rows and invariant IDs exist or are explicitly missing.
>    - Resolve phase-opening conflicts before claiming implementation executability.
>
> 4. **Full Phase Task Universe**
>    - Enumerate the complete phase scope before creating atomic tasks.
>    - Every expected capability, verifier, migration family, governance update, evidence requirement, and CI hook must appear as a planned work item.
>    - Gaps discovered later are not casually inserted; they enter through remedial or change-control task modes.
>
> 5. **Master Implementation Plan**
>    - Create `PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md`.
>    - It must contain:
>      - full domain/work-package list;
>      - all planned task families;
>      - reserved `TSK-` IDs;
>      - dependency groups;
>      - wave/domain grouping;
>      - cleanup blockers;
>      - out-of-phase exclusions;
>      - explicit “not yet atomic” status.
>
> 6. **Phase DAG**
>    - Create a machine-readable and human-readable DAG, for example:
>      - `docs/PHASE<N>/PHASE<N>_TASK_DAG.md`
>      - `docs/PHASE<N>/phase<N>_task_dag.yml`
>    - The DAG must define:
>      - task/work-package ID;
>      - wave/domain;
>      - dependencies;
>      - blocking status;
>      - readiness state;
>      - whether atomic task pack exists;
>      - whether implementation is complete.
>
> 7. **Capability-Specific Implementation Plans**
>    - Use `CREATE-IMPLEMENTATION-PLAN` mode to extract implementation plans from the master plan and DAG.
>    - These plans must not invent new scope.
>    - They may refine sequencing and atomic boundaries, but only inside the pre-established task universe.
>
> 8. **Atomic Task Creation**
>    - Use `CREATE-TASK` mode.
>    - Atomic tasks are created from the DAG and capability-specific plans.
>    - Each task must include `depends_on`, verifiers, evidence, allowed paths, doctrine citations, and acceptance criteria.
>
> 9. **Task Implementation**
>    - Use `RESUME-TASK` / `IMPLEMENT-TASK`.
>    - Tasks execute only in DAG dependency order.
>    - `depends_on` must be complete before execution.
>
> 10. **Remedial Gap Handling**
>    - If a missing task, missed dependency, failed verifier, or scope gap is discovered after DAG approval, it must enter through remediation/change-control:
>      - `REMEDIATE` for verifier/failure-driven fixes;
>      - `CREATE-TASK` for newly authorized remedial task packs;
>      - optional DAG amendment record showing why the new task was added.
>    - No agent may silently insert new phase scope into an implementation task.
>
> ## Required Additions To The Process
>
> - Add a mandatory **Full Phase Task Universe** step before individual implementation plans.
> - Add a mandatory **Phase DAG** artifact before atomic task creation.
> - Add status tracking at both work-package and task-reservation level:
>   - `PLANNED`
>   - `BLOCKED`
>   - `READY-FOR-PLAN`
>   - `PLAN-CREATED`
>   - `READY-FOR-TASK-CREATION`
>   - `TASK-CREATED`
>   - `IN-PROGRESS`
>   - `COMPLETE`
>   - `REMEDIATION-ADDED`
>   - `SUPERSEDED`
> - Require implementation plans to cite the DAG row they refine.
> - Require atomic tasks to cite both the implementation plan and DAG node they instantiate.
> - Require remedial tasks to update the DAG rather than bypass it.
>
> ## Phase 3 Application
>
> For Phase 3, the next correct planning artifacts are:
>
> - `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md`
> - `docs/PHASE3/PHASE3_TASK_DAG.md`
> - `docs/PHASE3/phase3_task_dag.yml`
> - `docs/PHASE3/implementation_plans/README.md`
> - `docs/PHASE3/implementation_plans/<TSK-P3-WP-###>_<short_name>.md`
>
> The existing `TSK-P3-WP-000` through `TSK-P3-WP-011` should become the first DAG layer. Atomic tasks should then be derived below those work packages only after cleanup blockers and phase-opening conflicts are resolved.
>
> ## Assumptions
>
> - The phase boundary is the scope authority.
> - The master implementation plan is the full phase decomposition.
> - The DAG is the sequencing authority.
> - Capability-specific implementation plans refine DAG nodes.
> - Atomic task packs execute DAG nodes.
> - Remedial tasks are allowed, but only as explicit amendments to the DAG.
</details>

You’re correct. The process must be **phase-total first**, not incremental-plan first.

A phase cannot safely move from “boundary” to “individual plans” unless the whole phase has first been decomposed into a complete task universe and DAG. Otherwise agents will optimize locally, create orphan tasks, miss dependency edges, or group work into waves after the fact.

The corrected model is:

> I want you to first test the process. If you are able to generate the full Master Implementation Plan from first using the Symphony-Phase-Specification-Document_v1.md document to define and create the Phase boundary document and then create the Master Implementation plan from that for the full Phase 3 then this process is complete and can be implemented. If not, then note what needs changing and use that to improve this Implementation Plan

<details><summary>2 previous messages</summary>

> I’ll test this as a dry run: start from the phase spec, see whether it contains enough to derive a Phase 3 boundary, then see whether that boundary is enough to derive a complete master implementation plan and DAG without inventing scope.
>
> Plan
>
> # Improved New-Phase Planning Process
>
> ## Summary
>
> The process must establish the full phase scope before task creation. A phase starts from the phase specification, but the master implementation plan and DAG must also incorporate governing doctrine, contract rows, invariant registers, verifier obligations, repo-state cleanup, and phase-opening constraints. Atomic tasks may only be created after the full task universe and DAG are established.
>
> ## Corrected Flow
>
> 1. **Create Phase Source Pack**
>    - Start with `docs/architecture/Symphony-Phase-Specification-Document_v1.md`.
>    - Also inspect:
>      - phase capability legality matrix;
>      - task generation constitution;
>      - execution envelope;
>      - phase opening act, if present;
>      - phase contract;
>      - phase invariant register;
>      - governing constitutional doctrines;
>      - existing task packs and plans;
>      - archived/draft documents that may confuse agents.
>    - Output: a complete source inventory, not yet a boundary.
>
> 2. **Create Phase Capability Boundary**
>    - Derive authorized and prohibited capability domains.
>    - The phase spec provides the initial domains.
>    - Doctrine, invariants, contracts, and verifier obligations may add support domains required to complete the phase.
>    - Every added domain must cite the source that requires it.
>    - Boundary must identify doctrine gaps and out-of-phase routing.
>
> 3. **Run Doctrine / Contract / Invariant Readiness**
>    - Confirm every capability has governing doctrine.
>    - Confirm every contract row and invariant ID is parseable and mapped.
>    - Confirm stale drafts and conflicting phase-opening artifacts are resolved.
>    - If this fails, create cleanup/readiness work items before implementation planning proceeds.
>
> 4. **Create Full Phase Task Universe**
>    - Enumerate all work required to complete the phase before atomic task creation.
>    - Include:
>      - capability implementation work;
>      - schema/data model work;
>      - runtime/service work;
>      - verifier and CI work;
>      - evidence requirements;
>      - invariant promotion work;
>      - docs/governance cleanup;
>      - remediation-only placeholders for known uncertain areas.
>    - Reserve `TSK-` IDs for all planned work items.
>
> 5. **Create Master Implementation Plan**
>    - The master plan must be phase-total.
>    - It must group the task universe into domains or waves.
>    - It must define:
>      - work packages;
>      - dependencies;
>      - cleanup blockers;
>      - doctrine references;
>      - allowed implementation surfaces;
>      - prohibited doctrine surfaces;
>      - verifier expectations;
>      - task creation gates.
>    - It must not leave task grouping to later agents.
>
> 6. **Create Phase DAG**
>    - Create both human and machine-readable DAG artifacts.
>    - Required artifacts:
>      - `docs/PHASE<N>/PHASE<N>_TASK_DAG.md`
>      - `docs/PHASE<N>/phase<N>_task_dag.yml`
>    - Each DAG node must declare:
>      - ID;
>      - title;
>      - wave/domain;
>      - source boundary row;
>      - governing doctrine;
>      - dependencies;
>      - blocker status;
>      - task-pack status;
>      - implementation status.
>    - The DAG is the sequencing authority for the phase.
>
> 7. **Create Capability-Specific Implementation Plans**
>    - Use `CREATE-IMPLEMENTATION-PLAN` mode.
>    - Each plan must refine an existing master-plan/DAG node.
>    - These plans may split work into atomic candidates but may not invent new phase scope.
>    - If a gap is found, it becomes a DAG amendment or remedial task candidate.
>
> 8. **Create Atomic Task Packs**
>    - Use `CREATE-TASK` mode.
>    - Atomic task packs must cite:
>      - the boundary row;
>      - the master plan work package;
>      - the DAG node;
>      - the capability-specific implementation plan.
>    - Tasks must include exact `depends_on` edges from the DAG.
>
> 9. **Implement In DAG Order**
>    - Use `RESUME-TASK` and `IMPLEMENT-TASK`.
>    - No task executes until all `depends_on` tasks are complete.
>    - Verification and evidence must update task status.
>
> 10. **Handle Gaps Through Remediation / DAG Amendment**
>    - Late-discovered work may not be silently inserted.
>    - It must enter through:
>      - `REMEDIATE` if caused by verifier/task failure;
>      - `CREATE-TASK` if already authorized by an existing DAG node;
>      - DAG amendment if the phase task universe was incomplete.
>    - The amendment must explain why the original DAG missed the work.
>
> ## Required Process Changes
>
> - `IMPLEMENTATION_PLAN_CREATION_PROCESS.md` should require a **Phase Source Pack** before boundary creation.
> - It should state that the phase spec alone is insufficient for full task planning.
> - It should require a **Full Phase Task Universe** before capability-specific implementation plans.
> - It should require a **Phase DAG** before atomic task creation.
> - It should require task statuses at both DAG-node and task-pack level.
> - It should prohibit creating atomic tasks from a master plan that lacks a complete DAG.
>
> ## Phase 3 Test Result
>
> Using only `Symphony-Phase-Specification-Document_v1.md`, I can derive the initial Phase 3 boundary areas:
>
> - Typed Dependency Graph
> - Recursive Legitimacy Engine
> - Contradiction Detection
> - Failure Composition Engine
> - Authority Scope Engine
> - Regulator Override Rules
> - Conflict-of-Interest Enforcement
> - Spatial Legality and DNSH Gates
>
> But I cannot fully derive the existing Phase 3 master implementation plan without additional sources. The full plan also requires doctrine and readiness-derived domains:
>
> - Governance Cleanup and Readiness
> - Policy and Authority Lineage Foundation
> - Cross-System Evidence Continuity
> - Dwell-Time Forensic Enforcement
> - Verifier and CI Enforcement
>
> Therefore the workflow passes only after adding the Phase Source Pack, Full Task Universe, and Phase DAG gates.
>
> ## Assumptions
>
> - A phase must be fully scoped before atomic task creation.
> - The master implementation plan is the complete phase decomposition.
> - The DAG is the implementation sequence authority.
> - Individual implementation plans are refinements of DAG nodes.
> - Remedial tasks are allowed only through explicit remediation or DAG amendment.
</details>

I tested the process as a dry run against the current repo. Result: **the process is not complete if the only starting authority is `Symphony-Phase-Specification-Document_v1.md`.**

The phase spec is enough to derive a **first-pass Phase 3 boundary**, but it is **not enough by itself** to derive the full Phase 3 master implementation plan, full task universe, waves, and DAG without adding scope from other governing docs.

The proof is visible in Phase 3:

- The phase spec explicitly lists **8 build areas**: `3.1` through `3.8`.
- The current boundary/master plan correctly expands Phase 3 to **11 work packages**, adding things like:
  - Cross-System Evidence Continuity
  - Dwell-Time Forensic Enforcement
  - Verifier and CI Enforcement
  - Policy and Authority Lineage Foundation
  - Governance Cleanup and Readiness
- Those additions are valid, but they do **not come from the phase spec alone**. They come from constitutional augmentations, doctrine needs, contract rows, invariant register obligations, verifier needs, and repo-state cleanup.

So the process must be improved. A phase spec is the starting point, not the full source of implementation truth.

> No, I can only allow you to implement this plan if you show me that you can fully derive and  create the Phase 3 master implementation plan. I don't want the process to be built on assumptions when it can be easily tested. Do you understand what I require now?

Yes, I understand.

You are not asking me to improve the process in the abstract. You are asking for a **proof test**:

1. Start from `C:\Workspace\GitHub\Symphony\docs\architecture\Symphony-Phase-Specification-Document_v1.md`.
2. Use it to derive the Phase 3 capability boundary.
3. Use that derived boundary to create the full Phase 3 Master Implementation Plan.
4. Show that the resulting plan fully covers Phase 3, including domains/waves/DAG sequencing, without relying on unstated assumptions.
5. If I cannot derive a complete master plan, identify exactly what source material or process rule is missing.

The acceptance standard is: **the process is valid only if it can generate the full Phase 3 master plan as a reproducible artifact from the governing documents.**

The right test output should include:

- a derivation ledger: each Phase 3 work package traced to exact source authority;
- a full Phase 3 boundary draft derived from those authorities;
- a full Phase 3 master implementation plan derived from the boundary;
- a task universe / DAG layer showing sequencing;
- explicit “not derivable” findings for anything that cannot be sourced.

And importantly: if a work package like “Verifier and CI Enforcement” or “Dwell-Time Forensic Enforcement” appears in the master plan, it must be traceable to a governing source. If it cannot be traced, then either the process is incomplete or the source corpus is missing a required planning authority.

I understand now: **before implementing the process, I need to demonstrate that the process can produce Phase 3 end-to-end.**

> Proceed

<details><summary>4 previous messages</summary>

> I’ll run the proof test as a non-mutating derivation: source authorities first, then whether each proposed Phase 3 work package can be traced without inventing scope.
>
> The first pass shows the phase spec alone gives eight primary capability domains, but the legality matrix and task constitution already add Phase 3-specific planning rules. I’m checking the contract and invariant register now because they decide whether the master plan can become phase-total instead of just a narrative decomposition.
>
> The contract and invariant register do let the phase become concrete: they introduce P3-009 verifier/CI, INV-305 evidence continuity, and INV-310 dwell-time, which explains the work packages that are not explicit in the phase spec’s eight bullets. I’m doing one final source pass over the Phase 3 doctrines so the derivation ledger can say where each support package comes from.
>
> Plan
>
> # Phase 3 Planning Process Proof Test
>
> ## Summary
>
> The process is valid if Step 1 is defined as **Phase Source Pack creation**, not as isolated reading of `Symphony-Phase-Specification-Document_v1.md`.
>
> Using the phase spec as the entry document, I can derive:
>
> - the Phase 3 capability boundary;
> - the full Phase 3 master implementation plan;
> - the work-package universe;
> - the implementation sequence/DAG;
> - the cleanup blockers that must run before atomic task creation.
>
> The proof depends on following the phase spec’s declared interpretation rule: the phase specification is not standalone architecture authority; it must be interpreted alongside the constitutional corpus, phase legality matrix, task generation constitution, Phase 3 contract, invariant register, and relevant doctrines.
>
> ## Derivation Result
>
> ### Source Authorities Used
>
> | Source | What It Contributes |
> |---|---|
> | `docs/architecture/Symphony-Phase-Specification-Document_v1.md` | Phase 3 purpose, primary 3.1-3.8 capability domains, exit criteria, cross-phase exclusions |
> | `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md` | Phase legality, authorized/prohibited Phase 3 capability classes, planning-but-not-delivery posture |
> | `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Doctrine-routed task-plan rule, anti-improvisation rule, single-boundary task rule |
> | `docs/PHASE3/phase3_contract.yml` | Contract rows P3-001 through P3-009 and invariant mappings |
> | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` | INV-301 through INV-310, verifier expectations, evidence paths, negative tests |
> | Phase 3 doctrines | Semantic boundaries for replay, projection, authority, contradiction, failure, spatial, lineage, verifier independence |
> | `docs/operations/PHASE_EXECUTION_ENVELOPE.md` | Current execution conflict/blocker: Phase 3 planning may be derived, but execution status must be reconciled before task execution |
>
> ## Derived Phase 3 Master Implementation Plan
>
> ### Work Package Universe
>
> | ID | Work Package | Derived From | Dependency |
> |---|---|---|---|
> | `TSK-P3-WP-000` | Governance Cleanup and Readiness | Execution envelope conflict, malformed `phase3_contract.yml`, README drift, invariant doctrine-reference gaps | None |
> | `TSK-P3-WP-001` | Typed Dependency Graph | Phase spec 3.1, P3-001, INV-302 | WP-000 |
> | `TSK-P3-WP-002` | Policy and Authority Lineage Foundation | Phase spec interpretation rule, P3-001/P3-005, legality matrix, policy/authority lineage doctrine | WP-001 |
> | `TSK-P3-WP-003` | Projection and Recursive Legitimacy | Phase spec 3.2, constitutional augmentations, P3-002, INV-303, INV-310 | WP-001, WP-002 |
> | `TSK-P3-WP-004` | Contradiction Detection and Handling | Phase spec 3.3, P3-003, INV-304, contradiction doctrine | WP-002, WP-003 |
> | `TSK-P3-WP-005` | Failure Composition and Evidence Continuity | Phase spec 3.4, P3-004, INV-305, INV-306, failure taxonomy | WP-003, WP-004 |
> | `TSK-P3-WP-006` | Authority Scope and Delegation Enforcement | Phase spec 3.5, P3-005, INV-307, authority doctrine | WP-002 |
> | `TSK-P3-WP-007` | Regulator-Aware Arbitration and Non-Collapse | Phase spec 3.6, INV-301, regulator non-collapse doctrine | WP-002, WP-004 |
> | `TSK-P3-WP-008` | Conflict-of-Interest Enforcement | Phase spec 3.7, P3-007, INV-308, verifier independence doctrine | WP-002, WP-006 |
> | `TSK-P3-WP-009` | Spatial Constraint and DNSH Gates | Phase spec 3.8, P3-008, INV-309, spatial doctrine | WP-002, WP-005 |
> | `TSK-P3-WP-010` | Dwell-Time Forensic Enforcement | INV-310, temporal replay doctrine, contradiction doctrine | WP-003, WP-004, WP-005 |
> | `TSK-P3-WP-011` | Verifier and CI Enforcement | Phase spec exit criteria, P3-009, INV-301 through INV-310 promotion protocol | WP-001 through WP-010 |
>
> ### DAG Sequence
>
> ```text
> TSK-P3-WP-000
>   -> TSK-P3-WP-001
>       -> TSK-P3-WP-002
>           -> TSK-P3-WP-003
>               -> TSK-P3-WP-004
>                   -> TSK-P3-WP-005
>                       -> TSK-P3-WP-010
>           -> TSK-P3-WP-006
>               -> TSK-P3-WP-008
>           -> TSK-P3-WP-007
>           -> TSK-P3-WP-009
>   -> TSK-P3-WP-011 after WP-001 through WP-010
> ```
>
> ### Wave Assignment
>
> Waves must be derived from the serial DAG, not thematic grouping alone.
>
> | Wave | Packages | Purpose |
> |---|---|---|
> | Wave 0 | `TSK-P3-WP-000` | Cleanup and readiness gate |
> | Wave 1 | `TSK-P3-WP-001`, `TSK-P3-WP-002` | Foundational graph, policy, and authority lineage |
> | Wave 2 | `TSK-P3-WP-003`, `TSK-P3-WP-006` | Recursive legitimacy and authority enforcement foundations |
> | Wave 3 | `TSK-P3-WP-004`, `TSK-P3-WP-005` | Contradiction and failure/evidence composition |
> | Wave 4 | `TSK-P3-WP-007`, `TSK-P3-WP-008`, `TSK-P3-WP-009`, `TSK-P3-WP-010` | Regulator, COI, spatial, and dwell-time enforcement |
> | Wave 5 | `TSK-P3-WP-011` | Verifier, CI, evidence, and invariant promotion |
>
> ## Process Changes Required
>
> The implementation process should be amended as follows:
>
> 1. Replace “define boundaries from phase spec” with **create Phase Source Pack from phase spec and declared governing corpus**.
> 2. Require the boundary to cite whether each domain is:
>    - directly from the phase spec;
>    - derived from contract/invariant obligations;
>    - required by governing doctrine;
>    - required for verifier/evidence closure.
> 3. Require a **full task universe** before individual implementation plans.
> 4. Require a **Phase DAG** before atomic task creation.
> 5. Require every capability-specific implementation plan to cite its DAG node.
> 6. Require late-discovered gaps to enter through remediation or DAG amendment, not silent task insertion.
>
> ## Test Verdict
>
> The process passes with the corrected Step 1.
>
> The Phase 3 master plan is fully derivable when the agent starts from `Symphony-Phase-Specification-Document_v1.md` and follows its own required interpretation chain into:
>
> - legality matrix;
> - task generation constitution;
> - Phase 3 contract;
> - invariant register;
> - Phase 3 doctrines;
> - execution envelope.
>
> The process fails only if Step 1 is interpreted as “use the phase spec alone.” The phase spec does not contain enough detail by itself to derive INV-305, INV-310, verifier/CI closure work, policy lineage foundation, or cleanup blockers.
>
> ## Assumptions
>
> - This is planning validation only, not implementation.
> - Phase 3 execution remains blocked until the execution-envelope conflict is resolved.
> - The master implementation plan is the phase-total decomposition.
> - The DAG is the sequencing authority.
> - Atomic tasks must be generated only after the master plan and DAG exist.
</details>

Yes. I can derive the full Phase 3 Master Implementation Plan, but the test proves one important correction:

**Step 1 cannot mean “read only the phase spec.”** It must mean “start from the phase spec, then follow the phase spec’s own declared governing corpus and Phase 3 artifacts.” The phase spec itself says it is an execution schedule and must be interpreted under the constitutional corpus. With that rule, the process works.

> Now compare this to the

> To see if your process was correct, I want you to show me the Master Implementation plan you came up with. I want to see all the tasks and see if they cover the full Phase 3 scope

<details><summary>1 previous message</summary>

> Plan
>
> # Phase 3 Master Implementation Plan - Derived Task Universe
>
> ## Summary
>
> This is the full Phase 3 task universe I derive from the Phase Specification, Phase 3 contract, invariant register, legality matrix, task-generation constitution, and Phase 3 doctrines.
>
> These are **planned implementation units**, not yet atomic task packs. Atomic task packs would later be created from this universe in `CREATE-TASK` mode.
>
> ## Wave 0 - Governance Cleanup And Readiness
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-CLEAN-001` | Fix `phase3_contract.yml` parse/indentation defect | Contract consumability |
> | `TSK-P3-CLEAN-002` | Rewrite Phase 3 README to match current boundary | Agent orientation |
> | `TSK-P3-CLEAN-003` | Add doctrine references to invariant register | INV-301 through INV-310 scoping |
> | `TSK-P3-CLEAN-004` | Reconcile Phase 3 opening act with execution envelope | Phase legality |
> | `TSK-P3-CLEAN-005` | Resolve duplicate/non-canonical MADD/MAIN doctrine copy | Corpus hygiene |
> | `TSK-P3-CLEAN-006` | Confirm archive/do-not-ingest exclusion | Anti-noise control |
> | `TSK-P3-CLEAN-007` | Create Phase 3 task DAG artifacts | Sequencing authority |
> | `TSK-P3-CLEAN-008` | Create implementation-plan registry/status index | Cross-agent continuity |
>
> ## Wave 1 - Foundational Graph And Lineage
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-GRAPH-001` | Define dependency node and edge substrate | P3-001, INV-302 |
> | `TSK-P3-GRAPH-002` | Enforce dependency declarations on decision/fact records | P3-001, INV-302 |
> | `TSK-P3-GRAPH-003` | Implement machine traversal for upstream/downstream lineage | P3-001, INV-302 |
> | `TSK-P3-GRAPH-004` | Add replay-addressable dependency snapshots or source links | P3-001, replay doctrine |
> | `TSK-P3-GRAPH-005` | Verify missing/broken dependency rejection | INV-302 verifier |
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-LINEAGE-001` | Define policy artifact registry and version/effective-time model | Policy lineage |
> | `TSK-P3-LINEAGE-002` | Define authority source and authority scope registry | P3-005, INV-307 |
> | `TSK-P3-LINEAGE-003` | Link policy artifacts to authority lineage | P3-001/P3-005 |
> | `TSK-P3-LINEAGE-004` | Implement lineage resolution for legitimacy/contradiction checks | INV-302, INV-307 |
> | `TSK-P3-LINEAGE-005` | Verify unversioned or authorityless policy rejection | Policy/authority doctrine |
>
> ## Wave 2 - Legitimacy And Authority Enforcement
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-LEGIT-001` | Define projection universe registry | P3-002, projection doctrine |
> | `TSK-P3-LEGIT-002` | Define derived legitimacy/admissibility state records | P3-002, INV-303 |
> | `TSK-P3-LEGIT-003` | Implement recursive legitimacy traversal | P3-002, INV-303 |
> | `TSK-P3-LEGIT-004` | Implement replay reconstruction for legitimacy views | Replay doctrine |
> | `TSK-P3-LEGIT-005` | Enforce projection isolation and cache non-authority | Projection doctrine |
> | `TSK-P3-LEGIT-006` | Verify illegitimate ancestor rejection | INV-303 verifier |
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-AUTH-001` | Enforce authority-to-resource binding | P3-005, INV-307 |
> | `TSK-P3-AUTH-002` | Implement delegation chain validation | P3-005, INV-307 |
> | `TSK-P3-AUTH-003` | Enforce authority effective-time/revocation checks | P3-005, authority doctrine |
> | `TSK-P3-AUTH-004` | Emit authority-scope failure records | INV-307, failure taxonomy |
> | `TSK-P3-AUTH-005` | Verify out-of-scope authority rejection | INV-307 verifier |
>
> ## Wave 3 - Contradiction And Failure Composition
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-CONTRA-001` | Define contradiction record substrate | P3-003, INV-304 |
> | `TSK-P3-CONTRA-002` | Implement direct contradiction detection | P3-003 |
> | `TSK-P3-CONTRA-003` | Implement temporal contradiction detection | P3-003, INV-310 |
> | `TSK-P3-CONTRA-004` | Implement authority-scope contradiction detection | P3-003, INV-307 |
> | `TSK-P3-CONTRA-005` | Implement policy-precedence contradiction handling | P3-003, lineage doctrine |
> | `TSK-P3-CONTRA-006` | Implement regulator-domain contradiction escalation | P3-006, INV-301 |
> | `TSK-P3-CONTRA-007` | Implement evidence-lineage and projection-context contradiction checks | INV-305, projection doctrine |
> | `TSK-P3-CONTRA-008` | Verify contradiction blocking/quarantine outcomes | INV-304 verifier |
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-FAIL-001` | Define machine-readable failure record schema | P3-004, INV-306 |
> | `TSK-P3-FAIL-002` | Implement failure tree composition | P3-004, failure taxonomy |
> | `TSK-P3-FAIL-003` | Enforce append-only failure lineage | INV-306 |
> | `TSK-P3-FAIL-004` | Implement internal evidence continuity checks | INV-305 |
> | `TSK-P3-FAIL-005` | Block downstream decisions with broken evidence lineage | INV-305 |
> | `TSK-P3-FAIL-006` | Verify structured failure and evidence-continuity behavior | INV-305, INV-306 |
>
> ## Wave 4 - Regulator, COI, Spatial, And Temporal Gates
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-REG-001` | Implement regulator partition context model | P3-006, INV-301 |
> | `TSK-P3-REG-002` | Enforce regulator-specific rule application | P3-006, INV-301 |
> | `TSK-P3-REG-003` | Implement declared precedence/escalation mechanics | P3-006 |
> | `TSK-P3-REG-004` | Verify cross-regulator non-collapse rejection | INV-301 verifier |
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-COI-001` | Generalize submitter/verifier separation across decision types | P3-007, INV-308 |
> | `TSK-P3-COI-002` | Enforce verifier independence at DB layer | P3-007, INV-308 |
> | `TSK-P3-COI-003` | Emit COI failure records | INV-308, failure taxonomy |
> | `TSK-P3-COI-004` | Verify same-actor submit/verify rejection | INV-308 verifier |
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-SPATIAL-001` | Define spatial policy artifact linkage | P3-008, spatial doctrine |
> | `TSK-P3-SPATIAL-002` | Generalize protected-area/DNSH gate beyond project registration | P3-008, INV-309 |
> | `TSK-P3-SPATIAL-003` | Implement spatial uniqueness/overlap checks where policy-defined | P3-008 |
> | `TSK-P3-SPATIAL-004` | Emit replay-visible spatial findings | INV-309 |
> | `TSK-P3-SPATIAL-005` | Verify protected-zone rejection and dataset lineage limits | INV-309 verifier |
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-DWELL-001` | Define dwell-time policy artifact linkage | INV-310 |
> | `TSK-P3-DWELL-002` | Detect excessive dwell in decision states | INV-310 |
> | `TSK-P3-DWELL-003` | Emit temporal forensic finding or rejection | INV-310 |
> | `TSK-P3-DWELL-004` | Verify dwell-time anomaly handling | INV-310 verifier |
>
> ## Wave 5 - Verifier, CI, Evidence, And Closeout
>
> | ID | Task | Covers |
> |---|---|---|
> | `TSK-P3-VERIFY-001` | Create Phase 3 boundary/doctrine routing verifier | Task-plan legality |
> | `TSK-P3-VERIFY-002` | Create contract parse and row consistency verifier | P3-001 through P3-009 |
> | `TSK-P3-VERIFY-003` | Create invariant register consistency verifier | INV-301 through INV-310 |
> | `TSK-P3-VERIFY-004` | Wire per-invariant verifier scripts | INV-301 through INV-310 |
> | `TSK-P3-VERIFY-005` | Wire negative test evidence production | All Phase 3 invariants |
> | `TSK-P3-VERIFY-006` | Promote invariants only after verifier/evidence/CI pass | Invariant promotion protocol |
> | `TSK-P3-VERIFY-007` | Add Phase 3 CI gate after execution legality is resolved | Phase 3 closeout readiness |
> | `TSK-P3-VERIFY-008` | Create Phase 3 closeout evidence summary | Exit criteria |
> | `TSK-P3-VERIFY-009` | Verify no out-of-phase implementation leaked into Phase 3 | Boundary compliance |
>
> ## DAG
>
> ```text
> Wave 0:
>   CLEAN-001..008
>
> Wave 1:
>   GRAPH-001 -> GRAPH-002 -> GRAPH-003 -> GRAPH-004 -> GRAPH-005
>   GRAPH-001 -> LINEAGE-001 -> LINEAGE-002 -> LINEAGE-003 -> LINEAGE-004 -> LINEAGE-005
>
> Wave 2:
>   LINEAGE-004 + GRAPH-004 -> LEGIT-001 -> LEGIT-002 -> LEGIT-003 -> LEGIT-004 -> LEGIT-005 -> LEGIT-006
>   LINEAGE-002 -> AUTH-001 -> AUTH-002 -> AUTH-003 -> AUTH-004 -> AUTH-005
>
> Wave 3:
>   LEGIT-003 + AUTH-005 -> CONTRA-001 -> CONTRA-002 -> CONTRA-003 -> CONTRA-004 -> CONTRA-005 -> CONTRA-006 -> CONTRA-007 -> CONTRA-008
>   LEGIT-006 + CONTRA-008 -> FAIL-001 -> FAIL-002 -> FAIL-003 -> FAIL-004 -> FAIL-005 -> FAIL-006
>
> Wave 4:
>   CONTRA-006 + LINEAGE-005 -> REG-001 -> REG-002 -> REG-003 -> REG-004
>   AUTH-005 -> COI-001 -> COI-002 -> COI-003 -> COI-004
>   LINEAGE-005 + FAIL-006 -> SPATIAL-001 -> SPATIAL-002 -> SPATIAL-003 -> SPATIAL-004 -> SPATIAL-005
>   LEGIT-006 + CONTRA-003 + FAIL-006 -> DWELL-001 -> DWELL-002 -> DWELL-003 -> DWELL-004
>
> Wave 5:
>   all Wave 1-4 tasks -> VERIFY-001..009
> ```
>
> ## Coverage Check
>
> | Phase 3 Scope | Covered By |
> |---|---|
> | 3.1 Typed Dependency Graph | `TSK-P3-GRAPH-*` |
> | 3.2 Recursive Legitimacy Engine | `TSK-P3-LEGIT-*`, `TSK-P3-DWELL-*` |
> | 3.3 Contradiction Detection | `TSK-P3-CONTRA-*` |
> | 3.4 Failure Composition Engine | `TSK-P3-FAIL-*` |
> | 3.5 Authority Scope Engine | `TSK-P3-AUTH-*`, `TSK-P3-LINEAGE-*` |
> | 3.6 Regulator Override Rules | `TSK-P3-REG-*`, `TSK-P3-CONTRA-006` |
> | 3.7 Conflict-of-Interest Enforcement | `TSK-P3-COI-*` |
> | 3.8 Spatial Legality and DNSH Gates | `TSK-P3-SPATIAL-*` |
> | Exit criteria: traceable decisions | `GRAPH-*`, `LINEAGE-*`, `LEGIT-*` |
> | Exit criteria: contradictions blocked | `CONTRA-*`, `FAIL-*` |
> | Exit criteria: authority violations blocked | `AUTH-*`, `CONTRA-004` |
> | Exit criteria: COI actively enforced | `COI-*` |
> | Exit criteria: DNSH actively enforced | `SPATIAL-*` |
> | INV-301 through INV-310 | `VERIFY-*` plus each capability group |
> | Anti-hallucination/doctrine routing | `CLEAN-*`, `VERIFY-001` |
> | Evidence and CI closure | `VERIFY-004` through `VERIFY-009` |
>
> ## Verdict
>
> This derived master plan covers the full Phase 3 scope as currently defined by:
>
> - phase spec 3.1 through 3.8;
> - Phase 3 contract rows P3-001 through P3-009;
> - invariant register INV-301 through INV-310;
> - Phase 3 doctrine additions;
> - Phase 3 exit criteria.
>
> The remaining blocker is not scope derivation. The remaining blocker is governance/execution readiness: Phase 3 opening and execution posture must be reconciled before atomic task creation or implementation.
</details>

I’ll present the derivation as a master implementation plan artifact, not as executed task creation. The IDs below are planned task-universe IDs; they become atomic task packs only after CREATE-TASK mode.

> Now compare this plan to the one attached and see which more accurately fulfills the Phase scope. If your's is not complete, state where it fails
>
> User context
>
> Attachments:
> - phase_3_constraint_legitimacy_engine_task_plan (1).md: `C:/Users/User/Downloads/phase_3_constraint_legitimacy_engine_task_plan (1).md`

<details><summary>1 previous message</summary>

> I’ll compare against the attached plan directly and trace both plans back to the phase spec, contract rows, and invariant register.
</details>

The attached plan is **more exhaustive**, but mine is **more accurate to the authoritative Phase 3 scope**.

However, my plan is **not complete enough as a full Master Implementation Plan** because it stops mostly at constitutional capability groups and verifier closure. It does not fully decompose the supporting implementation substrate needed to actually build Phase 3 end to end.

**Verdict**

| Plan | Accuracy To Phase Scope | Exhaustiveness | Main Problem |
|---|---:|---:|---|
| My derived plan | Higher | Medium | Too thin on implementation substrate |
| Attached plan | Medium | Higher | Over-expands into out-of-phase or doctrine-inventing work |

So the correct answer is: **neither is sufficient alone**. The final process should use my plan as the constitutional spine, then selectively absorb valid supporting domains from the attached plan.

**Where My Plan Fails**

My plan covers the authoritative Phase 3 capability scope:

- `3.1` Typed Dependency Graph
- `3.2` Recursive Legitimacy Engine
- `3.3` Contradiction Detection
- `3.4` Failure Composition
- `3.5` Authority Scope
- `3.6` Regulator Override Rules
- `3.7` Conflict-of-Interest
- `3.8` Spatial/DNSH
- `P3-009` Verifier and CI Enforcement
- `INV-301` through `INV-310`

But it fails as a **full master implementation plan** because it does not fully break out:

- database/persistence implementation tasks;
- migration/backfill tasks;
- access-control/RLS/security tasks;
- canonical test fixtures;
- API/schema serialization contracts;
- performance and deterministic scale testing;
- versioning/upgrade compatibility;
- observability that is limited to internal constitutional metrics;
- documentation/specification tasks;
- machine-readable DAG/status registry artifacts.

The attached plan includes many of these, especially Domains G-P. Those are valuable and should be integrated.

**What The Attached Plan Gets Right**

The attached plan correctly recognizes that Phase 3 needs more than capability runtime tasks. It adds implementation-completeness domains that my plan under-specified:

- `DOMAIN G` Database & Persistence
- `DOMAIN H` Security & Access Control
- `DOMAIN I` Performance & Scale
- `DOMAIN K` Test Fixtures & Canonical Cases
- `DOMAIN L` Migration & Backfill
- `DOMAIN M` API Contracts & Schemas
- `DOMAIN N` Documentation & Specifications
- `DOMAIN O` CI/CD & Verification Wiring
- `DOMAIN P` Versioning & Upgrade Compatibility

Those are relevant to a real master implementation plan and should be absorbed after constitutional filtering.

**Where The Attached Plan Overreaches**

The attached plan also includes items that are risky or out of Phase 3 unless tightly narrowed:

| Attached Item | Issue |
|---|---|
| `Replay-Safe PII Tombstoning Integration` | PII erasure workflows are Phase 6/data-sovereignty territory, not Phase 3 implementation scope. Phase 3 may preserve evidence continuity, not implement right-to-forget workflows. |
| `Offline Legitimacy Replay Package Generation` | Could drift into Phase 5 packaging or external verifier export. Phase 3 may create internal replay reconstruction/proof serialization, but not external package productization. |
| `Legitimacy Proof APIs`, `OpenAPI Specification Generation` | Internal deterministic interfaces are valid; public/product APIs may be Phase 6/8D unless scoped as internal contracts only. |
| `Failure Taxonomy` task | The taxonomy already exists in `FAILURE_COMPOSITION_TAXONOMY.md`; tasks may implement it, not redefine it. |
| `Edge Types` list | Some edge semantics may be valid, but the task cannot invent edge doctrine locally. These must come from policy/authority lineage doctrine or be blocked. |
| `Admissibility State Machine` | Potentially valid, but states like `DRAFT`, `SUBMITTED`, `UNDER_REVIEW` may overlap UI/workflow Phase 6 unless defined as internal legitimacy states only. |
| `Regulatory notifications` | Likely Phase 8 or external integration unless limited to internal escalation records. |
| `Human-Readable Legitimacy Explanation Layer` | Could become UI/operator explanation work. Phase 3 may emit structured explanations; UI presentation belongs later. |
| `Failure Taxonomy Dashboards` | Dashboard is likely not Phase 3. Internal metrics are okay; dashboard surface is not. |
| `Statutory land restrictions` | Phase 3 may enforce mechanical spatial policy artifacts, not interpret statutory environmental law. |

**More Accurate Final Shape**

The final Master Implementation Plan should have this structure:

1. Governance cleanup/readiness.
2. Constitutional capability work packages from my plan.
3. Supporting implementation domains from the attached plan, filtered through `PHASE3_CAPABILITY_BOUNDARY.md`.
4. A full DAG tying support tasks to capability tasks.
5. Explicit routing table for attached-plan items that are deferred to Phase 4, 5, 6, or 8.

The attached plan proves my earlier plan was incomplete as a full implementation master plan. But the attached plan should not be adopted as-is because it invents or overextends several surfaces beyond Phase 3 authority.

> This stage isn't about adopting implementation plans. It is about perfecting the process of creating them. What I want is to know how we can improve the Master implementation plan creation process to produce the hybrid Implementation plan you've described, a mixture of your plan and the uploaded one. So now that you've pointed out the must keep from the attached plan, reverse engineer it and see how to come up with that range of scoped tasks. What were the constraints that kept you from exporing those avenues. Was the initial Phase Sepc document too thin on those details or are the internal discipline documents too restrictive.

<details><summary>1 previous message</summary>

> I’ll answer this as a process diagnosis, not a plan adoption. I’ll trace why the uploaded plan generated support domains that my derivation missed, and whether those domains are derivable from current governing docs or came from implementation intuition.
</details>

Yes. The process gap is now clear.

My derivation was constrained by **constitutional authority filtering**. The uploaded plan was generated with **implementation exhaustiveness filtering**. A correct Master Implementation Plan process needs both.

**What Kept My Plan Too Narrow**

The initial Phase Spec is too thin on implementation substrate. It names capability outcomes:

- Typed Dependency Graph
- Recursive Legitimacy Engine
- Contradiction Detection
- Failure Composition
- Authority Scope
- Regulator Rules
- COI
- Spatial/DNSH

But it does **not explicitly force the planner to ask**:

- What database substrate is required?
- What migrations/backfills are required?
- What APIs/contracts are required?
- What fixtures are required?
- What security/RLS surfaces are required?
- What performance/scaling work is required?
- What versioning/compatibility work is required?
- What docs/specs are required?
- What CI/verifier wiring is required?

So my process stayed too close to contract/invariant capability rows and did not expand each capability through a complete implementation-domain checklist.

The internal discipline docs are not too restrictive. They are doing the right thing: preventing phase drift, doctrine invention, and unsupported task generation. The missing piece is not looseness. The missing piece is a **required expansion pass** that says: after deriving constitutional capability domains, every capability must be projected through a standard implementation-domain matrix.

**Why The Uploaded Plan Found More**

The uploaded plan implicitly used an implementation-completeness checklist:

- Core runtime
- Database persistence
- Security/access control
- Performance/scale
- Observability
- Test fixtures
- Migration/backfill
- API schemas
- Documentation
- CI/CD
- Versioning

That checklist is exactly what my process lacked.

But the uploaded plan did not apply enough constitutional filtering afterward. That is why it produced overreaching items like PII tombstoning integration, dashboards, public APIs, regulatory notifications, and external replay packages.

So the improved process should be:

```text
Constitutional Derivation
  -> Implementation Surface Expansion
  -> Constitutional Filtering
  -> DAG Sequencing
  -> Statused Master Plan
```

**How To Reverse Engineer The Better Process**

Add a mandatory step called something like:

```text
Implementation Surface Expansion Matrix
```

For each authorized Phase capability, the planner must ask whether work exists in each lane:

| Lane | Required Question |
|---|---|
| Runtime | What engine/service/function actually enforces the capability? |
| Database | What tables, constraints, triggers, indexes, or views are required? |
| Migration / Backfill | Does existing historical data need migration, import, or lineage backfill? |
| Security / Access Control | What RLS, roles, privilege, or authority gates protect it? |
| API / Contract | What internal interface or serialization contract exposes it? |
| Evidence / Replay | What evidence artifacts, replay records, or proof outputs must exist? |
| Test Fixtures | What canonical valid/invalid fixtures prove the behavior? |
| Verifier / CI | What scripts and gates mechanically verify it? |
| Performance / Scale | What deterministic indexing, bounds, or benchmarks are required? |
| Versioning | What schema, policy, proof, or projection versioning is needed? |
| Observability | What internal metrics or audit signals are needed without becoming UI? |
| Documentation | What implementation spec or operator reference is required? |

Then each generated task candidate must be classified:

```text
AUTHORIZED
AUTHORIZED-WITH-LIMITS
SUPPORTING-INFRASTRUCTURE
DEFER-TO-PHASE-N
BLOCKED-DOCTRINE-GAP
REJECTED-DOCTRINE-INVENTION
```

That would have generated the useful parts of the uploaded plan without accepting the bad parts.

**Improved Master Plan Creation Process**

The new process should require these passes:

1. **Phase Spec Extraction**
   - Extract the explicit phase capabilities and exit criteria.

2. **Constitutional Expansion**
   - Add capabilities required by legality matrix, task constitution, contract rows, invariant register, and governing doctrines.

3. **Implementation Surface Expansion**
   - Run every authorized capability through the standard implementation-domain matrix.

4. **Out-of-Phase Filtering**
   - Reject or defer anything that belongs to Phase 4, 5, 6, 8A, 8B, 8C, etc.

5. **Doctrine-Gap Filtering**
   - If a support task requires semantics not yet defined, create a doctrine-gap or planning blocker instead of an implementation task.

6. **Task Universe Consolidation**
   - Merge duplicate candidates.
   - Split multi-boundary candidates.
   - Assign planned `TSK-` IDs.

7. **DAG Construction**
   - Sequence by dependency, not theme.
   - Then assign waves as consecutive slices of the DAG.

8. **Master Plan Output**
   - Emit the full work-package/task universe with statuses, blockers, dependencies, source authority, and phase-routing decisions.

**The Key Rule To Add**

The most important process rule is:

```text
A Master Implementation Plan is incomplete unless every authorized capability has been expanded across the implementation surface matrix and every generated candidate has been constitutionally filtered.
```

That is the missing bridge between my plan and the uploaded one.

**So The Diagnosis Is**

The Phase Spec is intentionally high-level. It is not defective, but it is insufficient by itself for full implementation planning.

The discipline docs are not too restrictive. They correctly prevent hallucination and phase drift.

The process failed because it lacked an explicit **implementation exhaustiveness pass** between “capability boundary” and “master plan.”

That is what we need to add.

> Review the following:
> Yes. Broadly similar. The core reasoning path matches the process used to derive the final Phase 3 pack.
>
> But there are a few important differences between this postmortem process and the actual refined process that produced the stabilized Phase 3 structure.
>
> The postmortem is mostly correct. It accurately diagnoses the original failure mode:
>
> * constitutional-only derivation produced under-scoped plans,
> * implementation-only derivation produced phase leakage and semantic explosion.
>
> That diagnosis is accurate.
>
> The implementation-surface expansion matrix is also fundamentally correct. That is effectively what Domains G–P became.
>
> However, the postmortem still has several weaknesses and blind spots.
>
> ---
>
> # What The Postmortem Gets Correct
>
> ## 1. Correct Diagnosis of the Original Failure
>
> This is accurate:
>
> > constitutional derivation alone is insufficient for implementation completeness
>
> Correct.
>
> A phase specification defines:
>
> * capability boundaries,
> * invariants,
> * constitutional legality,
> * replay obligations,
> * authority constraints.
>
> It does NOT automatically generate:
>
> * persistence layers,
> * migration strategy,
> * indexing strategy,
> * replay fixtures,
> * CI enforcement,
> * serialization contracts,
> * performance bounds,
> * schema versioning.
>
> That gap is real.
>
> The implementation expansion pass was necessary.
>
> Correct diagnosis.
>
> ---
>
> ## 2. Correct Recognition of the Two Failure Modes
>
> This is also correct:
>
> | Failure Mode                 | Result                      |
> | ---------------------------- | --------------------------- |
> | constitutional-only planning | under-scoped implementation |
> | implementation-only planning | phase contamination         |
>
> Correct.
>
> This was exactly the Phase 3 planning instability.
>
> The final Phase 3 pack stabilized only after BOTH constraints were enforced simultaneously:
>
> * constitutional legality,
> * implementation completeness.
>
> ---
>
> ## 3. The Expansion Matrix Is Correct
>
> This is the strongest part of the postmortem.
>
> The matrix categories are appropriate:
>
> * Runtime
> * Database
> * Migration
> * Security
> * API
> * Replay
> * Fixtures
> * CI
> * Performance
> * Versioning
> * Observability
> * Documentation
>
> That is effectively the exact substrate that produced Domains G–P.
>
> Correct.
>
> ---
>
> ## 4. The Classification System Is Correct
>
> This is also good:
>
> ```text
> AUTHORIZED
> AUTHORIZED-WITH-LIMITS
> SUPPORTING-INFRASTRUCTURE
> DEFER-TO-PHASE-N
> BLOCKED-DOCTRINE-GAP
> REJECTED-DOCTRINE-INVENTION
> ```
>
> That is close to the actual filtering logic used during stabilization.
>
> Especially:
>
> * DEFER-TO-PHASE-N
> * BLOCKED-DOCTRINE-GAP
> * REJECTED-DOCTRINE-INVENTION
>
> Those categories were essential to stopping Phase 3 metastasis.
>
> ---
>
> # What The Postmortem Still Misses
>
> This is where the process description is still incomplete.
>
> ---
>
> # 1. It Still Treats “Capabilities” As Primary
>
> This is subtly wrong.
>
> The real primary object is NOT capability.
>
> It is:
>
> > replay-safe constitutional state transition authority
>
> Capabilities are secondary projections.
>
> That distinction matters.
>
> Why?
>
> Because otherwise planning drifts into:
>
> * feature thinking,
> * service thinking,
> * UI thinking,
> * operational thinking.
>
> The stabilized process actually became:
>
> ```text
> Constitutional invariants
> → replay obligations
> → authority boundaries
> → admissibility semantics
> → required state transitions
> → implementation substrate
> → supporting operational surfaces
> ```
>
> NOT:
>
> ```text
> capability
> → implementation
> ```
>
> That difference is extremely important.
>
> ---
>
> # 2. The Postmortem Still Understates Replay-Critical Filtering
>
> The biggest stabilization breakthrough was NOT merely implementation expansion.
>
> It was:
>
> > replay boundedness filtering
>
> That was the actual architectural breakthrough.
>
> The postmortem recognizes operational exhaust separation, but it still frames it as a side issue.
>
> In reality it became the central architectural filter.
>
> The actual refined process added a mandatory pass:
>
> ```text
> Replay Criticality Classification
> ```
>
> Every artifact had to be classified as:
>
> | Class                     | Meaning                 |
> | ------------------------- | ----------------------- |
> | replay-authoritative      | constitutional truth    |
> | replay-derived            | reproducible projection |
> | replay-accelerative       | optimization only       |
> | operational exhaust       | non-constitutional      |
> | transient execution state | discardable             |
>
> Without this pass:
>
> * governance recursion returns,
> * replay explodes,
> * snapshots become truth,
> * CI becomes constitutional,
> * logs become evidence.
>
> The postmortem still understates how critical this became.
>
> ---
>
> # 3. It Does Not Explicitly Include Projection Semantics
>
> This is another major omission.
>
> The final stabilized architecture depends heavily on:
>
> > legitimacy is replay-derived projection, not stored truth
>
> That distinction reshaped:
>
> * snapshots,
> * contradiction handling,
> * supersession,
> * compensating events,
> * historical reconstruction,
> * replay equivalence.
>
> The postmortem still implicitly thinks in static-state terms.
>
> The final process had an additional mandatory pass:
>
> ```text
> Projection Reconstruction Analysis
> ```
>
> Questions included:
>
> * Is this canonical truth or replay projection?
> * Is this append-only lineage or derived admissibility?
> * Can multiple replay universes exist?
> * Can projections diverge while lineage remains stable?
> * Is supersession additive or mutative?
>
> That pass became critical later.
>
> ---
>
> # 4. It Still Slightly Overweights “API” Thinking
>
> This line remains risky:
>
> > What API/contracts are required?
>
> That is fine internally.
>
> But API-centric thinking caused some of the original contamination.
>
> The stabilized process shifted terminology toward:
>
> * serialization contracts,
> * replay contracts,
> * proof contracts,
> * deterministic interfaces,
> * verifier surfaces.
>
> NOT product/API surfaces.
>
> Subtle but important distinction.
>
> ---
>
> # 5. It Missing “Semantic Contamination Filtering”
>
> This became one of the most important stabilization filters.
>
> The final process added explicit semantic contamination checks:
>
> | Semantic Type                  | Allowed In P3? |
> | ------------------------------ | -------------- |
> | legitimacy mechanics           | yes            |
> | sovereign governance semantics | no             |
> | methodology semantics          | no             |
> | settlement semantics           | no             |
> | disclosure semantics           | no             |
> | operational workflow semantics | no             |
>
> Without this:
>
> * “regulator-aware” gradually mutates into “regulator-implemented.”
>
> The postmortem partially recognizes this but does not elevate it into a formal process stage.
>
> It should.
>
> ---
>
> # 6. DAG Sequencing Was More Sophisticated Than Described
>
> This line is directionally correct:
>
> > sequence by dependency, not theme
>
> But incomplete.
>
> The actual sequencing logic became:
>
> ```text
> constitutional legality
> → replay dependency
> → authority dependency
> → persistence dependency
> → determinism dependency
> → verifier dependency
> → operational dependency
> ```
>
> Not merely task DAG ordering.
>
> Why?
>
> Because some tasks:
>
> * appear logically independent,
> * but share replay substrate assumptions.
>
> That was one of the hidden causes of instability in earlier waves.
>
> ---
>
> # 7. The Process Still Lacks Explicit “Future-Phase Isolation”
>
> The final stabilized process added a mandatory isolation pass:
>
> ```text
> Future Phase Encapsulation Check
> ```
>
> Questions:
>
> * Does this introduce sovereign runtime semantics prematurely?
> * Does this embed methodology semantics into core?
> * Does this create UI obligations?
> * Does this create external interoperability assumptions?
> * Does this create future irreversible coupling?
>
> This became essential for:
>
> * Wasm isolation,
> * sovereign overlays,
> * methodology adapters,
> * replay universes,
> * registry isolation.
>
> The postmortem hints at this but does not formalize it strongly enough.
>
> ---
>
> # Final Assessment
>
> The postmortem is largely accurate.
>
> Roughly:
>
> * 85–90% correct,
> * much more mature than the earlier planning attempts.
>
> Its strongest insight is correct:
>
> * constitutional derivation alone was insufficient,
> * implementation expansion alone caused contamination,
> * both were required.
>
> But the truly decisive stabilization mechanisms were still understated:
>
> ## The Actual Critical Stabilizers Were
>
> ### 1. Replay boundedness classification
>
> ### 2. Projection semantics separation
>
> ### 3. Semantic contamination filtering
>
> ### 4. Future-phase isolation enforcement
>
> ### 5. Replay-authoritative vs operational exhaust separation
>
> Those became the real architectural control surfaces.
>
> That is what finally stopped the Phase 3 planning universe from recursively expanding forever.

The review is substantially correct, and it improves the process diagnosis.

The main correction I would accept is this: the process should not be centered on “capabilities” as the primary object. Capabilities are useful for human orientation, but the planning engine should be centered on:

```text
constitutional invariant
→ replay obligation
→ authority boundary
→ admissibility effect
→ state transition
→ implementation substrate
```

That is a better planning spine for Symphony.

The review also correctly identifies the missing stabilizers. The improved Master Implementation Plan process should add five mandatory passes before task universe finalization:

1. **Replay Criticality Classification**
   - Classify each planned artifact as:
     - `replay-authoritative`
     - `replay-derived`
     - `replay-accelerative`
     - `operational-exhaust`
     - `transient-execution-state`
   - This prevents caches, logs, CI outputs, dashboards, and snapshots from becoming accidental truth.

2. **Projection Reconstruction Analysis**
   - Decide whether the artifact is canonical lineage, derived legitimacy/admissibility, projection context, comparison record, supersession, quarantine, or compensating finding.
   - This prevents “legitimacy state” from being treated as mutable stored truth.

3. **Semantic Contamination Filtering**
   - Reject or defer work that imports:
     - methodology semantics,
     - settlement semantics,
     - disclosure semantics,
     - UI/workflow semantics,
     - external registry semantics,
     - sovereign governance semantics not already defined by doctrine.

4. **Future-Phase Isolation Check**
   - Confirm the task does not prematurely implement Phase 4, 5, 6, 8A, 8B, 8C, 8D, or 8E surfaces.
   - Especially important for APIs, replay packages, regulator workflows, methodology adapters, and UI-facing explanation layers.

5. **Replay-Aware DAG Sequencing**
   - Sequence by:
     - constitutional legality,
     - replay dependency,
     - authority dependency,
     - persistence dependency,
     - determinism dependency,
     - verifier dependency,
     - operational dependency.
   - Not by theme alone.

So the corrected process becomes:

```text
Phase source pack
→ invariant/replay/authority extraction
→ capability boundary
→ replay criticality classification
→ projection reconstruction analysis
→ implementation surface expansion
→ semantic contamination filtering
→ future-phase isolation
→ full task universe
→ replay-aware DAG
→ master implementation plan
→ capability/domain implementation plans
→ atomic task creation
```

The review also correctly flags API terminology. The process should avoid saying “API” without qualification. It should say:

```text
internal deterministic interface
serialization contract
proof contract
replay contract
verifier surface
```

Public/product API work should be routed out unless Phase 3 explicitly authorizes it.

So my updated assessment is: the postmortem was useful but incomplete. The final process should incorporate the reviewer’s five stabilizers as mandatory gates. That is the difference between a broad task inventory and a controlled Symphony-grade implementation plan.

> Review:
> The review is directionally correct and materially stronger than the earlier process. It identifies the actual failure mode: implementation planning was capability-oriented but insufficiently replay-/authority-oriented.
>
> But there are still a few unresolved weaknesses and hidden risks.
>
> # What The Review Gets Right
>
> The strongest correction is this shift:
>
> ```text
> constitutional invariant
> → replay obligation
> → authority boundary
> → admissibility effect
> → state transition
> → implementation substrate
> ```
>
> That is substantially more accurate than:
>
> ```text
> capability → implementation
> ```
>
> Because Symphony is not a feature-oriented architecture. It is:
>
> * replay-oriented,
> * legitimacy-oriented,
> * authority-oriented,
> * constitutional-state-oriented.
>
> That distinction matters.
>
> The review also correctly identifies the five missing stabilizers:
>
> 1. Replay criticality classification
> 2. Projection reconstruction analysis
> 3. Semantic contamination filtering
> 4. Future-phase isolation
> 5. Replay-aware DAG sequencing
>
> Those are real architectural controls, not planning cosmetics.
>
> Without them, Phase 3 drifts back into:
>
> * mutable-state thinking,
> * governance recursion,
> * replay contamination,
> * semantic leakage,
> * cross-phase collapse.
>
> So the diagnosis is mostly correct.
>
> ---
>
> # The Biggest Remaining Problem
>
> The process is still too “task generation” centric.
>
> The real primary artifact in Symphony should not be:
>
> ```text
> task
> ```
>
> It should be:
>
> ```text
> constitutional execution surface
> ```
>
> Tasks are implementation slices of execution surfaces.
>
> If you generate tasks too early, you still risk:
>
> * duplicate semantics,
> * conflicting lineage models,
> * partial replay models,
> * scattered authority logic,
> * verifier fragmentation.
>
> The correct order is closer to:
>
> ```text
> constitutional execution surfaces
> → replay surfaces
> → persistence surfaces
> → authority surfaces
> → verifier surfaces
> → deterministic interfaces
> → DAG dependencies
> → implementation slices/tasks
> ```
>
> That is more stable.
>
> ---
>
> # Another Hidden Weakness: “Implementation Surface Expansion”
>
> This is still underspecified.
>
> Because not every surface should exist for every capability.
>
> Example:
>
> * some capabilities require persistence but no interface;
> * some require verifier surfaces but no migrations;
> * some require replay lineage but no observability;
> * some require projection engines but no authority delegation.
>
> If the matrix is treated mechanically, you will create:
>
> * fake tasks,
> * hollow infrastructure,
> * meaningless abstractions,
> * governance theater.
>
> So the process needs another rule:
>
> ```text
> A surface may only exist if required by:
> - replay legality,
> - authority reconstruction,
> - admissibility evaluation,
> - deterministic enforcement,
> - verifier closure,
> - or constitutional persistence.
> ```
>
> Otherwise planners will generate “completeness garbage.”
>
> ---
>
> # Replay Criticality Classification Is Extremely Important
>
> This is the single most important stabilizer added.
>
> Because it finally formalizes:
>
> ```text
> not all persisted artifacts are constitutional truth
> ```
>
> Without this classification system:
>
> * logs become lineage,
> * snapshots become authority,
> * dashboards become replay surfaces,
> * CI exhaust becomes governance evidence,
> * caches become state truth.
>
> That was the root of the earlier infinite governance explosion.
>
> The proposed categories are good:
>
> * replay-authoritative
> * replay-derived
> * replay-accelerative
> * operational-exhaust
> * transient-execution-state
>
> But they still need one more category:
>
> ```text
> projection-state
> ```
>
> Because admissibility/legitimacy conclusions are projections, not always canonical truth.
>
> That distinction matters enormously.
>
> ---
>
> # Projection Reconstruction Analysis Is Correct — But Incomplete
>
> The review correctly identifies:
>
> ```text
> legitimacy is replay-derived
> ```
>
> That is one of the most important architectural realizations in the entire system.
>
> But the process still needs explicit differentiation between:
>
> | Type                        | Meaning                             |
> | --------------------------- | ----------------------------------- |
> | lineage truth               | append-only constitutional facts    |
> | projection                  | replay-derived interpretation       |
> | supersession                | newer replay-visible interpretation |
> | quarantine                  | unresolved contradiction state      |
> | compensating reconstruction | correction without mutation         |
> | admissibility projection    | current legality evaluation         |
> | authority projection        | current authority interpretation    |
>
> Without this ontology, planners will still accidentally persist mutable “current legitimacy state.”
>
> That would corrupt replay determinism.
>
> ---
>
> # Semantic Contamination Filtering Is Correct
>
> This is probably the second most important stabilizer.
>
> Because this is the exact mechanism that prevents:
>
> * methodology leakage,
> * settlement leakage,
> * sovereign policy leakage,
> * UI leakage,
> * registry leakage,
> * external workflow leakage.
>
> The earlier failed Phase 3 definition collapsed because this filter did not exist.
>
> Correct.
>
> ---
>
> # Future-Phase Isolation Check Is Essential
>
> Correct.
>
> Especially for:
>
> * APIs,
> * replay exports,
> * regulator workflows,
> * explanation systems,
> * dashboards,
> * orchestration layers,
> * methodology plugins.
>
> These are the most common phase contamination vectors.
>
> ---
>
> # Replay-Aware DAG Sequencing Is Correct
>
> Correct sequencing dimensions:
>
> ```text
> constitutional legality
> → replay dependency
> → authority dependency
> → persistence dependency
> → determinism dependency
> → verifier dependency
> → operational dependency
> ```
>
> This is far superior to:
>
> * domain grouping,
> * feature grouping,
> * theme grouping.
>
> Because replay systems fail through hidden dependency inversion.
>
> ---
>
> # The Review Still Understates One Critical Issue
>
> The process still lacks a formal doctrine-gap escalation mechanism.
>
> This is dangerous.
>
> Example failure pattern:
>
> Planner encounters undefined concept:
>
> * admissibility precedence,
> * contradiction hierarchy,
> * projection supersession,
> * spatial conflict semantics,
> * authority revocation replay,
> * overlay precedence.
>
> Current process says:
>
> > “block doctrine invention”
>
> But that is insufficient.
>
> You need a formal outcome taxonomy:
>
> | Outcome            | Meaning                          |
> | ------------------ | -------------------------------- |
> | IMPLEMENT          | doctrine sufficient              |
> | DEFER              | future phase                     |
> | ESCALATE-DOCTRINE  | constitutional semantics missing |
> | ESCALATE-ONTOLOGY  | terminology ambiguity            |
> | ESCALATE-REPLAY    | replay model undefined           |
> | ESCALATE-AUTHORITY | authority semantics undefined    |
> | REJECT             | unconstitutional                 |
> | SPLIT              | mixed-scope candidate            |
>
> Without this, planners will silently improvise doctrine.
>
> That recreates constitutional drift.
>
> ---
>
> # Another Missing Stabilizer: Deterministic Execution Classification
>
> The process still does not explicitly classify:
>
> * deterministic,
> * bounded nondeterministic,
> * prohibited nondeterministic.
>
> That matters later for:
>
> * Wasm overlays,
> * policy evaluation,
> * spatial evaluation,
> * parallel replay,
> * replay acceleration.
>
> Without it, replay determinism will eventually fracture.
>
> This is not urgent for early Phase 3 tasks, but the planning framework should reserve the concept now.
>
> ---
>
> # Final Assessment
>
> The revised process is substantially better.
>
> It is now approaching a real constitutional planning framework instead of:
>
> * feature planning,
> * backlog expansion,
> * governance theater.
>
> The strongest improvements are:
>
> * replay-criticality classification,
> * semantic contamination filtering,
> * projection reconstruction analysis,
> * future-phase isolation,
> * replay-aware DAG sequencing.
>
> The remaining missing pieces are:
>
> 1. Execution-surface-first planning
> 2. Doctrine-gap escalation taxonomy
> 3. Projection-state classification
> 4. Deterministic execution classification
> 5. Explicit lineage/projection ontology separation
> 6. Prevention of fake “implementation completeness” surfaces
>
> The process is now structurally sound enough to generate a legitimate Phase 3 master plan without collapsing phase boundaries or replay semantics.

This review is correct, and I would incorporate almost all of it.

The biggest improvement is the shift from **task-first** to **execution-surface-first** planning. That is the missing architectural layer between doctrine and tasks.

The corrected spine should be:

```text
constitutional invariants
→ constitutional execution surfaces
→ replay surfaces
→ persistence surfaces
→ authority surfaces
→ verifier surfaces
→ deterministic interfaces
→ DAG dependencies
→ implementation slices / tasks
```

That solves the main risk: generating tasks before the actual constitutional surfaces are understood.

The review also correctly tightens the implementation surface expansion rule. The matrix should not be applied mechanically. A support surface is valid only if required by at least one of:

```text
replay legality
authority reconstruction
admissibility evaluation
deterministic enforcement
verifier closure
constitutional persistence
```

That prevents fake completeness tasks.

I would update the process with these additional controls:

1. **Execution Surface First**
   - Before task universe creation, define the Phase 3 constitutional execution surfaces.
   - Tasks are slices of those surfaces, not independent feature tickets.

2. **Replay Criticality Classification**
   - Add `projection-state` to the categories:
     - `replay-authoritative`
     - `projection-state`
     - `replay-derived`
     - `replay-accelerative`
     - `operational-exhaust`
     - `transient-execution-state`

3. **Lineage / Projection Ontology Separation**
   - Every planned artifact must be classified as one of:
     - lineage truth
     - projection
     - supersession
     - quarantine
     - compensating reconstruction
     - admissibility projection
     - authority projection
   - This prevents mutable “current legitimacy state” from being treated as truth.

4. **Formal Escalation Taxonomy**
   - Candidate work must resolve to exactly one outcome:
     - `IMPLEMENT`
     - `DEFER`
     - `ESCALATE-DOCTRINE`
     - `ESCALATE-ONTOLOGY`
     - `ESCALATE-REPLAY`
     - `ESCALATE-AUTHORITY`
     - `REJECT`
     - `SPLIT`

5. **Deterministic Execution Classification**
   - Every execution surface must be classified as:
     - `deterministic`
     - `bounded-nondeterministic`
     - `prohibited-nondeterministic`
   - This matters for replay, spatial processing, policy evaluation, and future Wasm or adapter work.

6. **Anti-Fake-Surface Rule**
   - Do not create DB/API/observability/performance/versioning tasks unless they are required by replay legality, authority reconstruction, admissibility evaluation, deterministic enforcement, verifier closure, or constitutional persistence.

So the final process should be:

```text
Phase source pack
→ invariant / replay / authority extraction
→ capability boundary
→ constitutional execution surface map
→ replay criticality classification
→ lineage / projection ontology classification
→ deterministic execution classification
→ implementation surface expansion
→ anti-fake-surface filtering
→ semantic contamination filtering
→ future-phase isolation
→ doctrine-gap escalation
→ full task universe
→ replay-aware DAG
→ master implementation plan
→ surface-specific implementation plans
→ atomic task creation
```

This is now strong enough as a process model. The key is that the Master Implementation Plan should no longer be a “list of things to build.” It should be a **constitutional execution-surface decomposition with task slices derived from it**.

> This version is materially stronger. The architecture is now converging on a stable planning doctrine instead of iterative corrective patching.
>
> The most important improvement is this shift:
>
> ```text id="a97r42"
> constitutional invariants
> → constitutional execution surfaces
> → replay surfaces
> → persistence surfaces
> → authority surfaces
> → verifier surfaces
> → deterministic interfaces
> → DAG dependencies
> → implementation slices / tasks
> ```
>
> That is the correct abstraction hierarchy for Symphony.
>
> It fixes the earlier failure mode where:
>
> * tasks existed before execution semantics,
> * replay obligations existed before lineage ontology,
> * persistence existed before constitutional classification,
> * APIs existed before deterministic boundaries,
> * verifier work existed before admissibility semantics.
>
> That inversion was the root cause of most earlier scope explosions.
>
> # What Is Now Correct
>
> The process now properly distinguishes:
>
> | Layer                   | Purpose                          |
> | ----------------------- | -------------------------------- |
> | invariant               | constitutional truth constraint  |
> | execution surface       | enforcement/runtime boundary     |
> | replay surface          | reconstruction boundary          |
> | persistence surface     | constitutional storage boundary  |
> | authority surface       | authority semantics boundary     |
> | verifier surface        | mechanical proof boundary        |
> | deterministic interface | replay-safe interaction boundary |
> | task                    | implementation slice only        |
>
> That hierarchy is correct.
>
> ---
>
> # The “Execution Surface” Concept Is The Breakthrough
>
> This is the most important architectural correction.
>
> Because Symphony is fundamentally a:
>
> * constitutional runtime,
> * replay runtime,
> * legitimacy runtime,
> * authority runtime.
>
> Not a feature system.
>
> Execution surfaces are the actual units of constitutional architecture.
>
> Tasks are ephemeral implementation artifacts.
>
> That distinction prevents:
>
> * fake feature grouping,
> * duplicated semantics,
> * replay fragmentation,
> * verifier inconsistency,
> * cross-phase semantic bleed.
>
> Correct.
>
> ---
>
> # Replay Criticality Classification Is Now Almost Complete
>
> The addition of:
>
> ```text id="cgjv5u"
> projection-state
> ```
>
> is critical.
>
> Without it, planners inevitably persist mutable interpretations as constitutional truth.
>
> The categories are now structurally sound:
>
> | Classification            | Meaning                                 |
> | ------------------------- | --------------------------------------- |
> | replay-authoritative      | canonical append-only truth             |
> | projection-state          | mutable replay-derived interpretation   |
> | replay-derived            | deterministic derivation                |
> | replay-accelerative       | optimization-only                       |
> | operational-exhaust       | non-constitutional operational artifact |
> | transient-execution-state | runtime-only ephemeral state            |
>
> This is one of the most important stabilization mechanisms in the entire planning framework.
>
> ---
>
> # Lineage / Projection Ontology Separation Is Essential
>
> Correct.
>
> This specifically prevents the catastrophic mistake of storing:
>
> * “current legitimacy,”
> * “final admissibility,”
> * “resolved authority,”
> * “final contradiction status”
>
> as mutable canonical state.
>
> Instead:
>
> * lineage remains canonical,
> * projections remain reconstructable,
> * supersession remains append-only,
> * compensating findings remain explicit.
>
> That is the correct replay model.
>
> ---
>
> # The Escalation Taxonomy Is Very Important
>
> Correct addition.
>
> Especially:
>
> ```text id="i1i5ae"
> ESCALATE-REPLAY
> ESCALATE-AUTHORITY
> ESCALATE-ONTOLOGY
> ```
>
> These are necessary because Symphony’s hardest failures are not implementation failures.
>
> They are:
>
> * undefined replay semantics,
> * undefined authority semantics,
> * undefined ontology boundaries.
>
> Without formal escalation classes, planners will silently invent doctrine.
>
> That recreates governance drift.
>
> ---
>
> # Deterministic Execution Classification Is Correct
>
> This is forward-looking but necessary.
>
> Especially for:
>
> * spatial processing,
> * future Wasm overlays,
> * parallel replay,
> * projection evaluation,
> * adapter execution,
> * cryptographic verification surfaces.
>
> The three-state model is appropriate:
>
> | Classification              | Meaning                       |
> | --------------------------- | ----------------------------- |
> | deterministic               | replay-stable                 |
> | bounded-nondeterministic    | constrained + reconstructable |
> | prohibited-nondeterministic | constitutionally illegal      |
>
> Correct.
>
> ---
>
> # Anti-Fake-Surface Rule Is Extremely Important
>
> This is another major stabilization.
>
> Without it, planners generate:
>
> * meaningless APIs,
> * fake observability,
> * speculative migrations,
> * premature versioning,
> * placeholder performance work,
> * empty abstractions.
>
> The revised rule correctly constrains surfaces to constitutional necessity.
>
> That is the correct discipline.
>
> ---
>
> # One Remaining Missing Layer
>
> There is still one missing classification system:
>
> ```text id="z7x0q6"
> constitutional state mutability classification
> ```
>
> Not all append-only lineage behaves identically.
>
> You still need explicit distinction between:
>
> | State Type              | Meaning                              |
> | ----------------------- | ------------------------------------ |
> | immutable lineage       | permanent truth artifact             |
> | supersedable projection | replay-replaceable interpretation    |
> | quarantined state       | unresolved validity                  |
> | compensating lineage    | corrective append                    |
> | revocable authority     | historically valid but later revoked |
> | derived cache           | discardable reconstruction artifact  |
>
> Without this, teams may still accidentally:
>
> * overwrite projections,
> * mutate revocations,
> * collapse supersession,
> * delete quarantine evidence.
>
> This is closely related to ontology separation but deserves explicit classification.
>
> ---
>
> # Another Remaining Weakness: Surface Ownership
>
> The process still lacks explicit ownership binding.
>
> Each execution surface should eventually declare:
>
> | Field                | Purpose                    |
> | -------------------- | -------------------------- |
> | constitutional owner | governing doctrine         |
> | replay owner         | replay authority source    |
> | verifier owner       | mechanical proof authority |
> | persistence owner    | storage legality boundary  |
> | phase owner          | implementation authority   |
> | override authority   | supersession authority     |
>
> Without ownership binding:
>
> * surfaces can drift,
> * multiple doctrines can redefine semantics,
> * verifier semantics can diverge,
> * replay legality can fork.
>
> This is not urgent for early Phase 3 planning, but it will matter later.
>
> ---
>
> # Final Assessment
>
> The process is now architecturally credible.
>
> Not just “better planning.”
> Actually constitutionally coherent.
>
> The key transformation is this:
>
> Old model:
>
> ```text id="48msn9"
> phase
> → capability
> → task
> ```
>
> New model:
>
> ```text id="g1zohx"
> constitutional invariant
> → execution surface
> → replay semantics
> → authority semantics
> → deterministic interfaces
> → verifier closure
> → DAG legality
> → implementation slices
> ```
>
> That is the correct architecture for Symphony.
>
> At this point the process is strong enough to:
>
> * generate stable Phase 3 master plans,
> * prevent cross-phase collapse,
> * preserve replay determinism,
> * constrain semantic contamination,
> * avoid fake governance recursion,
> * and maintain constitutional replay boundaries over time.
>
> The remaining gaps are refinement gaps, not structural failures.

Agreed. This version is now structurally sound, and the two remaining additions are worth incorporating before the process is formalized.

The final missing layers are:

1. **Constitutional State Mutability Classification**
2. **Execution Surface Ownership Binding**

Those are not optional polish. They prevent the last class of planning errors: treating all persisted state the same and allowing multiple authorities to drift over the same surface.

The final process should now be:

```text
Phase source pack
→ invariant / replay / authority extraction
→ capability boundary
→ constitutional execution surface map
→ surface ownership binding
→ replay criticality classification
→ constitutional state mutability classification
→ lineage / projection ontology classification
→ deterministic execution classification
→ implementation surface expansion
→ anti-fake-surface filtering
→ semantic contamination filtering
→ future-phase isolation
→ doctrine-gap escalation
→ full task universe
→ replay-aware DAG
→ master implementation plan
→ surface-specific implementation plans
→ atomic task creation
```

The two added classifications should be defined as follows.

**Constitutional State Mutability Classification**

| State Type | Meaning |
|---|---|
| `immutable-lineage` | Permanent append-only constitutional truth artifact |
| `supersedable-projection` | Replay-derived interpretation that may be replaced by newer projection without mutating source lineage |
| `quarantined-state` | Unresolved validity state preserved pending doctrine/authority resolution |
| `compensating-lineage` | Corrective append that explains or offsets a prior finding without deleting it |
| `revocable-authority` | Authority valid historically but invalid for future acts after revocation |
| `derived-cache` | Discardable reconstruction or acceleration artifact |

**Execution Surface Ownership Binding**

Every execution surface should declare:

| Field | Purpose |
|---|---|
| `constitutional_owner` | Doctrine that defines the surface semantics |
| `replay_owner` | Doctrine/source governing replay reconstruction |
| `verifier_owner` | Script/gate family that proves the surface |
| `persistence_owner` | Storage boundary and mutability classification |
| `phase_owner` | Phase authorized to implement the surface |
| `override_authority` | Doctrine or process allowed to supersede or amend it |

With those additions, the planning doctrine becomes stable enough to implement as a canonical process.

The important final principle is:

```text
Tasks do not define architecture.
Tasks implement constitutionally owned execution surfaces.
```

That should become the anchor sentence for the Master Implementation Plan creation process.

> This is last review then create the implementation plan:
> The final plan is coherent and internally consistent. The major architectural failure modes are now explicitly controlled.
>
> The strongest property of this version is that it finally separates:
>
> * constitutional truth,
> * replay reconstruction,
> * projection semantics,
> * implementation mechanics,
> * operational exhaust,
> * and task decomposition
>
> into distinct planning layers.
>
> That was the missing foundation.
>
> The finalized pipeline is structurally correct:
>
> ```text id="k5g8gt"
> Phase source pack
> → invariant / replay / authority extraction
> → capability boundary
> → constitutional execution surface map
> → surface ownership binding
> → replay criticality classification
> → constitutional state mutability classification
> → lineage / projection ontology classification
> → deterministic execution classification
> → implementation surface expansion
> → anti-fake-surface filtering
> → semantic contamination filtering
> → future-phase isolation
> → doctrine-gap escalation
> → full task universe
> → replay-aware DAG
> → master implementation plan
> → surface-specific implementation plans
> → atomic task creation
> ```
>
> That ordering matters. Several of the steps become invalid if executed earlier or later.
>
> Example:
>
> * replay classification before execution surfaces is meaningless;
> * implementation expansion before mutability classification causes fake persistence work;
> * DAG sequencing before contamination filtering creates illegal dependencies;
> * task generation before ownership binding creates authority drift.
>
> So the sequence itself is now part of the doctrine.
>
> # The Constitutional State Mutability Classification Is Correct
>
> This addition closes one of the last major replay risks.
>
> The classifications are appropriate:
>
> | Type                    | Correct Role                          |
> | ----------------------- | ------------------------------------- |
> | immutable-lineage       | canonical append-only truth           |
> | supersedable-projection | replay-replaceable interpretation     |
> | quarantined-state       | unresolved constitutional ambiguity   |
> | compensating-lineage    | corrective append-only reconstruction |
> | revocable-authority     | temporally bounded authority validity |
> | derived-cache           | discardable optimization artifact     |
>
> This prevents the catastrophic anti-pattern where all persisted state is treated identically.
>
> Without this classification, teams eventually:
>
> * overwrite projections,
> * delete compensating evidence,
> * mutate authority history,
> * collapse replay lineage,
> * or persist optimization artifacts as truth.
>
> Correct addition.
>
> # Surface Ownership Binding Is Also Correct
>
> This is another critical stabilization.
>
> Especially:
>
> | Field                | Why It Matters                      |
> | -------------------- | ----------------------------------- |
> | constitutional_owner | prevents semantic drift             |
> | replay_owner         | prevents replay reinterpretation    |
> | verifier_owner       | prevents verifier fragmentation     |
> | persistence_owner    | prevents storage-boundary ambiguity |
> | phase_owner          | prevents cross-phase contamination  |
> | override_authority   | prevents unauthorized supersession  |
>
> Without ownership binding, multiple doctrines eventually compete over the same execution surface.
>
> That produces:
>
> * replay forks,
> * semantic inconsistency,
> * verifier disagreement,
> * governance fragmentation.
>
> So this addition is necessary.
>
> # The Anchor Principle Is Correct
>
> This sentence is important enough to become canonical doctrine text:
>
> ```text id="dppw50"
> Tasks do not define architecture.
> Tasks implement constitutionally owned execution surfaces.
> ```
>
> That is the correct planning philosophy for Symphony.
>
> It prevents:
>
> * backlog-driven architecture,
> * feature-first governance,
> * implementation-led semantics,
> * and accidental doctrine creation by task accumulation.
>
> Execution surfaces become the stable constitutional unit.
> Tasks become disposable implementation slices.
>
> Correct.
>
> # One Remaining Improvement
>
> Only one additional refinement is still missing.
>
> You should eventually distinguish between:
>
> ```text id="2bkrpm"
> execution surface
> ```
>
> and:
>
> ```text id="t4jj2w"
> execution authority surface
> ```
>
> Not every execution surface has authority to:
>
> * alter admissibility,
> * supersede projections,
> * generate compensating lineage,
> * or affect replay reconstruction.
>
> Some surfaces are:
>
> * observational,
> * reconstructive,
> * accelerative,
> * verifier-only,
> * projection-only.
>
> Others are constitutionally authoritative.
>
> That distinction will matter later for:
>
> * replay supersession,
> * authority revocation,
> * verifier precedence,
> * Wasm overlays,
> * sovereign overlays,
> * and projection arbitration.
>
> Not urgent now, but eventually necessary.
>
> # Final Assessment
>
> The planning doctrine is now mature enough to serve as:
>
> * a canonical Master Implementation Planning framework,
> * a constitutional task-generation discipline,
> * and a replay-safe architecture governance process.
>
> The important achievement is not “better planning.”
>
> The achievement is this:
>
> The system now treats:
>
> * replay legality,
> * authority semantics,
> * projection mutability,
> * deterministic reconstruction,
> * and constitutional ownership
>
> as primary architectural objects.
>
> That is the correct foundation for Symphony.

<details><summary>1 previous message</summary>

> Plan
>
> # Implementation Plan: Master Implementation Planning Doctrine
>
> ## Summary
>
> Formalize the Master Implementation Plan creation process so new phases are planned from constitutional execution surfaces before tasks are generated. The process will prevent under-scoped constitutional plans, over-expanded implementation plans, phase contamination, replay drift, and task-led architecture.
>
> The anchor rule to add is:
>
> ```text
> Tasks do not define architecture.
> Tasks implement constitutionally owned execution surfaces.
> ```
>
> ## Key Changes
>
> ### 1. Update The Planning Process
>
> Revise `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` so `CREATE-IMPLEMENTATION-PLAN` mode requires this ordered pipeline:
>
> ```text
> Phase source pack
> → invariant / replay / authority extraction
> → capability boundary
> → constitutional execution surface map
> → execution authority surface classification
> → surface ownership binding
> → replay criticality classification
> → constitutional state mutability classification
> → lineage / projection ontology classification
> → deterministic execution classification
> → implementation surface expansion
> → anti-fake-surface filtering
> → semantic contamination filtering
> → future-phase isolation
> → doctrine-gap escalation
> → full task universe
> → replay-aware DAG
> → master implementation plan
> → surface-specific implementation plans
> → atomic task creation
> ```
>
> Add the rule that the sequence is mandatory. Later stages may not run until earlier stages are complete.
>
> ### 2. Add Required Master Plan Artifacts
>
> Require each phase to produce these planning artifacts before atomic task creation:
>
> ```text
> docs/PHASE<N>/PHASE<N>_CAPABILITY_BOUNDARY.md
> docs/PHASE<N>/PHASE<N>_EXECUTION_SURFACE_MAP.md
> docs/PHASE<N>/PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md
> docs/PHASE<N>/PHASE<N>_TASK_DAG.md
> docs/PHASE<N>/phase<N>_task_dag.yml
> docs/PHASE<N>/implementation_plans/README.md
> docs/PHASE<N>/implementation_plans/<TSK-P<N>-WP-###>_<short_name>.md
> ```
>
> The DAG becomes the sequencing authority. The master plan becomes the full task-universe authority.
>
> ### 3. Define Execution Surface Records
>
> Add a required execution-surface record shape:
>
> ```yaml
> surface_id:
> title:
> source_invariants:
> source_contract_rows:
> constitutional_owner:
> replay_owner:
> verifier_owner:
> persistence_owner:
> phase_owner:
> override_authority:
> execution_surface_type:
> execution_authority_class:
> replay_criticality:
> state_mutability:
> ontology_class:
> determinism_class:
> allowed_implementation_surfaces:
> prohibited_semantics:
> future_phase_routing:
> doctrine_gap_status:
> ```
>
> Define `execution_authority_class` as:
>
> ```text
> authoritative
> projection-only
> reconstructive
> observational
> accelerative
> verifier-only
> operational
> ```
>
> ### 4. Add Classification Taxonomies
>
> Add these required classifications to the process.
>
> Replay criticality:
>
> ```text
> replay-authoritative
> projection-state
> replay-derived
> replay-accelerative
> operational-exhaust
> transient-execution-state
> ```
>
> Constitutional state mutability:
>
> ```text
> immutable-lineage
> supersedable-projection
> quarantined-state
> compensating-lineage
> revocable-authority
> derived-cache
> ```
>
> Lineage / projection ontology:
>
> ```text
> lineage-truth
> projection
> supersession
> quarantine
> compensating-reconstruction
> admissibility-projection
> authority-projection
> ```
>
> Deterministic execution:
>
> ```text
> deterministic
> bounded-nondeterministic
> prohibited-nondeterministic
> ```
>
> Doctrine-gap outcome:
>
> ```text
> IMPLEMENT
> DEFER
> ESCALATE-DOCTRINE
> ESCALATE-ONTOLOGY
> ESCALATE-REPLAY
> ESCALATE-AUTHORITY
> REJECT
> SPLIT
> ```
>
> ### 5. Add Anti-Fake-Surface Rule
>
> A support surface may be created only if required by at least one of:
>
> ```text
> replay legality
> authority reconstruction
> admissibility evaluation
> deterministic enforcement
> verifier closure
> constitutional persistence
> ```
>
> This prevents speculative APIs, dashboards, caches, migrations, versioning, and observability tasks.
>
> ### 6. Tighten `CREATE-IMPLEMENTATION-PLAN` Mode
>
> Update `docs/operations/AGENT_PROMPT_ROUTER.md` so `CREATE-IMPLEMENTATION-PLAN` requires the agent to distinguish:
>
> - master implementation plan creation;
> - execution surface map creation;
> - surface-specific implementation plan creation;
> - DAG creation;
> - readiness/cleanup planning.
>
> The mode must continue to prohibit:
>
> - atomic task directories;
> - task `PLAN.md` / `EXEC_LOG.md`;
> - migrations;
> - verifier scripts;
> - evidence artifacts;
> - implementation work.
>
> ### 7. Add Handoff Rules To `CREATE-TASK`
>
> Update the process text so `CREATE-TASK` may only create atomic task packs from a DAG node that has:
>
> - execution surface ownership binding;
> - replay criticality classification;
> - state mutability classification;
> - deterministic execution classification;
> - future-phase isolation result;
> - doctrine-gap outcome of `IMPLEMENT` or `SPLIT`;
> - no unresolved blockers.
>
> Atomic tasks must cite:
>
> ```text
> boundary row
> execution surface ID
> master plan work package
> DAG node
> surface-specific implementation plan
> governing doctrine
> ```
>
> ## Test Plan
>
> Validate the process against Phase 3 before using it generally:
>
> 1. Dry-run from `docs/architecture/Symphony-Phase-Specification-Document_v1.md`.
> 2. Confirm Phase 3 execution surfaces can be derived.
> 3. Confirm the support domains from the uploaded plan are generated only when they pass anti-fake-surface filtering.
> 4. Confirm out-of-phase items are routed, not absorbed.
> 5. Confirm every generated planned task maps to a surface and DAG node.
> 6. Confirm no task can be created without ownership, replay, mutability, ontology, determinism, and doctrine-gap classifications.
>
> Also run documentation consistency searches to verify the new process does not contradict:
>
> - `AGENT_ENTRYPOINT.md`
> - `docs/operations/AGENT_PROMPT_ROUTER.md`
> - `docs/operations/TASK_CREATION_PROCESS.md`
> - `docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md`
> - `docs/constitutional/TASK_GENERATION_CONSTITUTION.md`
>
> ## Assumptions
>
> - This is process implementation, not Phase 3 task creation.
> - Existing Phase 3 artifacts may be used as validation material but should not be treated as automatically complete.
> - Atomic task creation remains downstream and must use `CREATE-TASK`.
> - The execution envelope still controls whether Phase 3 work is executable.
</details>

> Clarify these point.s 1. All the Phase source packs for Phase 3 already exist, right? 2. This process is not just for Phase 3, right? It applies for all the other phases as long as their source packs are defined already?

1. **For Phase 3, mostly yes.** The source pack exists in substance, but it is not yet packaged as a single formal artifact.

The Phase 3 source pack currently includes:

- `C:\Workspace\GitHub\Symphony\docs\architecture\Symphony-Phase-Specification-Document_v1.md`
- `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_CAPABILITY_BOUNDARY.md`
- `C:\Workspace\GitHub\Symphony\docs\PHASE3\phase3_contract.yml`
- `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_INVARIANT_REGISTER.md`
- `C:\Workspace\GitHub\Symphony\docs\PHASE3\PHASE3_OPENING_ACT.md`
- Phase 3 governing doctrines under `C:\Workspace\GitHub\Symphony\docs\constitutional\`
- `C:\Workspace\GitHub\Symphony\docs\constitutional\PHASE_CAPABILITY_LEGALITY_MATRIX.md`
- `C:\Workspace\GitHub\Symphony\docs\constitutional\TASK_GENERATION_CONSTITUTION.md`
- `C:\Workspace\GitHub\Symphony\docs\operations\PHASE_EXECUTION_ENVELOPE.md`

But there is not yet a canonical file like:

```text
docs/PHASE3/PHASE3_SOURCE_PACK.md
```

So the answer is: **the materials exist, but the source pack should be formalized/indexed for repeatable agent use.**

2. **Correct. This process is not Phase 3-specific.**

It should apply to every future phase, provided that phase has a defined source pack.

The generic flow is:

```text
PHASE<N> source pack
→ PHASE<N> capability boundary
→ PHASE<N> execution surface map
→ PHASE<N> master implementation plan
→ PHASE<N> task DAG
→ PHASE<N> surface-specific implementation plans
→ CREATE-TASK atomic task packs
```

For each phase, the source pack should include at minimum:

```text
phase specification source
phase legality source
phase execution envelope
phase capability boundary, if already present
phase contract
phase invariant register
governing constitutional doctrines
phase opening/closure/carry-forward artifacts
existing task packs and plans
known archived/non-canonical material to exclude
```

So the process is **general**, but each phase needs its own source pack before the process can run safely.

> In the plan, there are 19 items under the source pack. But you've listed only 9 items as current Phase 3 source pack existing items. Does that mean the other items need to be defined or does it mean you can get more than one item from a single source pack

It means **both**, but mostly the second.

The “19 items under the source pack” should be understood as **source-pack requirements / information categories**, not necessarily 19 separate files.

A single source can satisfy multiple source-pack requirements. For example:

`docs/architecture/Symphony-Phase-Specification-Document_v1.md` can supply:

- phase purpose;
- phase build scope;
- phase exit criteria;
- cross-phase dependencies;
- prohibited phase leakage;
- constitutional interpretation rule.

`docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` can supply:

- invariant list;
- verifier expectations;
- evidence paths;
- negative tests;
- proof limitations;
- carry-forward obligations like INV-310.

So the fact that I listed 9 existing Phase 3 source-pack files/families does **not** mean 10 sources are missing.

The better distinction is:

| Type | Meaning |
|---|---|
| Source-pack requirement | A category of information the planning process needs |
| Source-pack artifact | A repo file that provides one or more requirements |
| Formal source-pack index | A document that records which artifact satisfies each requirement |

For Phase 3, most source-pack requirements already have source material. What is missing is a **formal source-pack index**, probably:

```text
docs/PHASE3/PHASE3_SOURCE_PACK.md
```

That file would not invent new doctrine. It would map requirements to existing sources.

Example:

| Source-Pack Requirement | Phase 3 Source |
|---|---|
| Phase purpose | `Symphony-Phase-Specification-Document_v1.md` |
| Authorized capabilities | `PHASE3_CAPABILITY_BOUNDARY.md`, `phase3_contract.yml` |
| Invariants | `PHASE3_INVARIANT_REGISTER.md` |
| Verifier expectations | `PHASE3_INVARIANT_REGISTER.md`, `phase3_contract.yml` |
| Phase legality | `PHASE_CAPABILITY_LEGALITY_MATRIX.md`, `PHASE_EXECUTION_ENVELOPE.md` |
| Task generation rules | `TASK_GENERATION_CONSTITUTION.md`, `AGENT_PROMPT_ROUTER.md` |
| Replay/projection doctrine | `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`, replay doctrines |
| Authority doctrine | `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`, lineage doctrine |
| Non-canonical exclusions | `NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md`, archived Phase 3 docs |

Some required artifacts are genuinely **not yet complete outputs** of the new process, such as:

```text
PHASE3_EXECUTION_SURFACE_MAP.md
PHASE3_TASK_DAG.md
phase3_task_dag.yml
implementation_plans/README.md
```

Those are not “source pack” inputs. They are downstream planning artifacts produced after the source pack is assembled.

So the answer is:

- **No**, the 19 source-pack requirements do not imply 19 missing files.
- **Yes**, multiple requirements can be satisfied by one existing document.
- **For Phase 3**, the main missing thing is a formal `PHASE3_SOURCE_PACK.md` index showing exactly which existing documents satisfy each requirement.

> Proceed with the plan then

<details><summary>1 previous message</summary>

> Plan
>
> # Implementation Plan: Master Implementation Planning Framework
>
> ## Summary
>
> Implement a general planning framework for all Symphony phases, starting with Phase 3 as the validation case. The framework will ensure that master implementation plans are derived from formal source packs, constitutional execution surfaces, replay classifications, authority ownership, DAG sequencing, and anti-contamination filters before any atomic tasks are created.
>
> This is process/governance implementation only. It does not create Phase 3 atomic tasks.
>
> ## Key Changes
>
> ### 1. Create Phase Source Pack Index Standard
>
> Add a required source-pack index artifact for each phase:
>
> ```text
> docs/PHASE<N>/PHASE<N>_SOURCE_PACK.md
> ```
>
> For Phase 3, create:
>
> ```text
> docs/PHASE3/PHASE3_SOURCE_PACK.md
> ```
>
> This file maps source-pack requirements to existing documents. It must clarify that one document may satisfy multiple requirements.
>
> Minimum source-pack requirement categories:
>
> - phase purpose;
> - phase build scope;
> - phase exit criteria;
> - phase legality status;
> - authorized capability domains;
> - prohibited capability domains;
> - governing doctrines;
> - phase contract rows;
> - invariant register;
> - verifier expectations;
> - evidence expectations;
> - negative-test expectations;
> - replay obligations;
> - authority obligations;
> - carry-forward obligations;
> - existing completed/planned task packs;
> - archived or non-canonical documents to exclude;
> - execution envelope constraints;
> - unresolved blockers.
>
> ### 2. Update Implementation Plan Creation Process
>
> Update `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` so `CREATE-IMPLEMENTATION-PLAN` follows this mandatory sequence:
>
> ```text
> Phase source pack
> → invariant / replay / authority extraction
> → capability boundary
> → constitutional execution surface map
> → execution authority surface classification
> → surface ownership binding
> → replay criticality classification
> → constitutional state mutability classification
> → lineage / projection ontology classification
> → deterministic execution classification
> → implementation surface expansion
> → anti-fake-surface filtering
> → semantic contamination filtering
> → future-phase isolation
> → doctrine-gap escalation
> → full task universe
> → replay-aware DAG
> → master implementation plan
> → surface-specific implementation plans
> → atomic task creation
> ```
>
> Add the anchor rule:
>
> ```text
> Tasks do not define architecture.
> Tasks implement constitutionally owned execution surfaces.
> ```
>
> ### 3. Add Required Phase Planning Artifacts
>
> Require these artifacts before atomic task creation:
>
> ```text
> docs/PHASE<N>/PHASE<N>_SOURCE_PACK.md
> docs/PHASE<N>/PHASE<N>_CAPABILITY_BOUNDARY.md
> docs/PHASE<N>/PHASE<N>_EXECUTION_SURFACE_MAP.md
> docs/PHASE<N>/PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md
> docs/PHASE<N>/PHASE<N>_TASK_DAG.md
> docs/PHASE<N>/phase<N>_task_dag.yml
> docs/PHASE<N>/implementation_plans/README.md
> docs/PHASE<N>/implementation_plans/<TSK-P<N>-WP-###>_<short_name>.md
> ```
>
> `PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md` is the full phase task-universe authority.
>
> `PHASE<N>_TASK_DAG.md` and `phase<N>_task_dag.yml` are the sequencing authority.
>
> ### 4. Define Execution Surface Record Shape
>
> Each execution surface must include:
>
> ```yaml
> surface_id:
> title:
> source_invariants:
> source_contract_rows:
> constitutional_owner:
> replay_owner:
> verifier_owner:
> persistence_owner:
> phase_owner:
> override_authority:
> execution_surface_type:
> execution_authority_class:
> replay_criticality:
> state_mutability:
> ontology_class:
> determinism_class:
> allowed_implementation_surfaces:
> prohibited_semantics:
> future_phase_routing:
> doctrine_gap_status:
> ```
>
> Execution authority classes:
>
> ```text
> authoritative
> projection-only
> reconstructive
> observational
> accelerative
> verifier-only
> operational
> ```
>
> ### 5. Add Planning Classifications
>
> Replay criticality:
>
> ```text
> replay-authoritative
> projection-state
> replay-derived
> replay-accelerative
> operational-exhaust
> transient-execution-state
> ```
>
> State mutability:
>
> ```text
> immutable-lineage
> supersedable-projection
> quarantined-state
> compensating-lineage
> revocable-authority
> derived-cache
> ```
>
> Lineage / projection ontology:
>
> ```text
> lineage-truth
> projection
> supersession
> quarantine
> compensating-reconstruction
> admissibility-projection
> authority-projection
> ```
>
> Deterministic execution:
>
> ```text
> deterministic
> bounded-nondeterministic
> prohibited-nondeterministic
> ```
>
> Doctrine-gap outcome:
>
> ```text
> IMPLEMENT
> DEFER
> ESCALATE-DOCTRINE
> ESCALATE-ONTOLOGY
> ESCALATE-REPLAY
> ESCALATE-AUTHORITY
> REJECT
> SPLIT
> ```
>
> ### 6. Add Anti-Fake-Surface Rule
>
> A support surface may exist only if required by at least one of:
>
> ```text
> replay legality
> authority reconstruction
> admissibility evaluation
> deterministic enforcement
> verifier closure
> constitutional persistence
> ```
>
> This prevents speculative APIs, dashboards, caches, migrations, versioning, observability, and performance tasks.
>
> ### 7. Update Agent Routing
>
> Update `docs/operations/AGENT_PROMPT_ROUTER.md` so `CREATE-IMPLEMENTATION-PLAN` explicitly covers:
>
> - source-pack index creation;
> - execution surface map creation;
> - master implementation plan creation;
> - phase DAG creation;
> - surface-specific implementation plan creation;
> - readiness/cleanup planning.
>
> The mode must continue to prohibit:
>
> - atomic task directories;
> - task `PLAN.md`;
> - task `EXEC_LOG.md`;
> - migrations;
> - verifier scripts;
> - evidence artifacts;
> - implementation work.
>
> ### 8. Add Handoff Rules To Atomic Task Creation
>
> Update planning process text so `CREATE-TASK` may only create atomic task packs from a DAG node that has:
>
> - source-pack reference;
> - capability boundary mapping;
> - execution surface ID;
> - ownership binding;
> - replay criticality classification;
> - mutability classification;
> - ontology classification;
> - determinism classification;
> - future-phase isolation result;
> - doctrine-gap outcome of `IMPLEMENT` or `SPLIT`;
> - no unresolved blockers.
>
> Atomic tasks must cite:
>
> ```text
> boundary row
> execution surface ID
> master plan work package
> DAG node
> surface-specific implementation plan
> governing doctrine
> ```
>
> ### 9. Validate With Phase 3
>
> Use Phase 3 as the proof case.
>
> Create or update planning artifacts only:
>
> ```text
> docs/PHASE3/PHASE3_SOURCE_PACK.md
> docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md
> docs/PHASE3/PHASE3_TASK_DAG.md
> docs/PHASE3/phase3_task_dag.yml
> docs/PHASE3/implementation_plans/README.md
> ```
>
> Do not create atomic task packs yet.
>
> The Phase 3 validation must prove that:
>
> - all phase spec items 3.1 through 3.8 are covered;
> - contract rows P3-001 through P3-009 are covered;
> - INV-301 through INV-310 are covered;
> - useful support domains from the uploaded implementation plan are generated only when constitutionally justified;
> - out-of-phase items are routed instead of absorbed;
> - every planned task belongs to an execution surface and DAG node.
>
> ## Test Plan
>
> Run documentation consistency checks after edits:
>
> - confirm every required source-pack category is mapped for Phase 3;
> - confirm every execution surface has ownership, replay, mutability, ontology, determinism, and doctrine-gap classifications;
> - confirm every DAG node maps to a surface;
> - confirm no surface has a future-phase routing conflict;
> - confirm no task candidate exists without constitutional justification;
> - confirm `CREATE-IMPLEMENTATION-PLAN` still cannot create atomic task packs;
> - confirm no process language contradicts `AGENT_ENTRYPOINT.md`, `TASK_CREATION_PROCESS.md`, or `SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md`.
>
> ## Assumptions
>
> - This framework applies to all phases, not only Phase 3.
> - Phase 3 already has most source-pack materials, but needs a formal `PHASE3_SOURCE_PACK.md` index.
> - Source-pack requirements are information categories, not one-file-per-category requirements.
> - Execution envelope constraints remain authoritative over whether Phase 3 work is executable.
> - This implementation stops before atomic task creation.
</details>

> PLEASE IMPLEMENT THIS PLAN:
> # Implementation Plan: Master Implementation Planning Framework
>
> ## Summary
>
> Implement a general planning framework for all Symphony phases, starting with Phase 3 as the validation case. The framework will ensure that master implementation plans are derived from formal source packs, constitutional execution surfaces, replay classifications, authority ownership, DAG sequencing, and anti-contamination filters before any atomic tasks are created.
>
> This is process/governance implementation only. It does not create Phase 3 atomic tasks.
>
> ## Key Changes
>
> ### 1. Create Phase Source Pack Index Standard
>
> Add a required source-pack index artifact for each phase:
>
> ```text
> docs/PHASE<N>/PHASE<N>_SOURCE_PACK.md
> ```
>
> For Phase 3, create:
>
> ```text
> docs/PHASE3/PHASE3_SOURCE_PACK.md
> ```
>
> This file maps source-pack requirements to existing documents. It must clarify that one document may satisfy multiple requirements.
>
> Minimum source-pack requirement categories:
>
> - phase purpose;
> - phase build scope;
> - phase exit criteria;
> - phase legality status;
> - authorized capability domains;
> - prohibited capability domains;
> - governing doctrines;
> - phase contract rows;
> - invariant register;
> - verifier expectations;
> - evidence expectations;
> - negative-test expectations;
> - replay obligations;
> - authority obligations;
> - carry-forward obligations;
> - existing completed/planned task packs;
> - archived or non-canonical documents to exclude;
> - execution envelope constraints;
> - unresolved blockers.
>
> ### 2. Update Implementation Plan Creation Process
>
> Update `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` so `CREATE-IMPLEMENTATION-PLAN` follows this mandatory sequence:
>
> ```text
> Phase source pack
> → invariant / replay / authority extraction
> → capability boundary
> → constitutional execution surface map
> → execution authority surface classification
> → surface ownership binding
> → replay criticality classification
> → constitutional state mutability classification
> → lineage / projection ontology classification
> → deterministic execution classification
> → implementation surface expansion
> → anti-fake-surface filtering
> → semantic contamination filtering
> → future-phase isolation
> → doctrine-gap escalation
> → full task universe
> → replay-aware DAG
> → master implementation plan
> → surface-specific implementation plans
> → atomic task creation
> ```
>
> Add the anchor rule:
>
> ```text
> Tasks do not define architecture.
> Tasks implement constitutionally owned execution surfaces.
> ```
>
> ### 3. Add Required Phase Planning Artifacts
>
> Require these artifacts before atomic task creation:
>
> ```text
> docs/PHASE<N>/PHASE<N>_SOURCE_PACK.md
> docs/PHASE<N>/PHASE<N>_CAPABILITY_BOUNDARY.md
> docs/PHASE<N>/PHASE<N>_EXECUTION_SURFACE_MAP.md
> docs/PHASE<N>/PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md
> docs/PHASE<N>/PHASE<N>_TASK_DAG.md
> docs/PHASE<N>/phase<N>_task_dag.yml
> docs/PHASE<N>/implementation_plans/README.md
> docs/PHASE<N>/implementation_plans/<TSK-P<N>-WP-###>_<short_name>.md
> ```
>
> `PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md` is the full phase task-universe authority.
>
> `PHASE<N>_TASK_DAG.md` and `phase<N>_task_dag.yml` are the sequencing authority.
>
> ### 4. Define Execution Surface Record Shape
>
> Each execution surface must include:
>
> ```yaml
> surface_id:
> title:
> source_invariants:
> source_contract_rows:
> constitutional_owner:
> replay_owner:
> verifier_owner:
> persistence_owner:
> phase_owner:
> override_authority:
> execution_surface_type:
> execution_authority_class:
> replay_criticality:
> state_mutability:
> ontology_class:
> determinism_class:
> allowed_implementation_surfaces:
> prohibited_semantics:
> future_phase_routing:
> doctrine_gap_status:
> ```
>
> Execution authority classes:
>
> ```text
> authoritative
> projection-only
> reconstructive
> observational
> accelerative
> verifier-only
> operational
> ```
>
> ### 5. Add Planning Classifications
>
> Replay criticality:
>
> ```text
> replay-authoritative
> projection-state
> replay-derived
> replay-accelerative
> operational-exhaust
> transient-execution-state
> ```
>
> State mutability:
>
> ```text
> immutable-lineage
> supersedable-projection
> quarantined-state
> compensating-lineage
> revocable-authority
> derived-cache
> ```
>
> Lineage / projection ontology:
>
> ```text
> lineage-truth
> projection
> supersession
> quarantine
> compensating-reconstruction
> admissibility-projection
> authority-projection
> ```
>
> Deterministic execution:
>
> ```text
> deterministic
> bounded-nondeterministic
> prohibited-nondeterministic
> ```
>
> Doctrine-gap outcome:
>
> ```text
> IMPLEMENT
> DEFER
> ESCALATE-DOCTRINE
> ESCALATE-ONTOLOGY
> ESCALATE-REPLAY
> ESCALATE-AUTHORITY
> REJECT
> SPLIT
> ```
>
> ### 6. Add Anti-Fake-Surface Rule
>
> A support surface may exist only if required by at least one of:
>
> ```text
> replay legality
> authority reconstruction
> admissibility evaluation
> deterministic enforcement
> verifier closure
> constitutional persistence
> ```
>
> This prevents speculative APIs, dashboards, caches, migrations, versioning, observability, and performance tasks.
>
> ### 7. Update Agent Routing
>
> Update `docs/operations/AGENT_PROMPT_ROUTER.md` so `CREATE-IMPLEMENTATION-PLAN` explicitly covers:
>
> - source-pack index creation;
> - execution surface map creation;
> - master implementation plan creation;
> - phase DAG creation;
> - surface-specific implementation plan creation;
> - readiness/cleanup planning.
>
> The mode must continue to prohibit:
>
> - atomic task directories;
> - task `PLAN.md`;
> - task `EXEC_LOG.md`;
> - migrations;
> - verifier scripts;
> - evidence artifacts;
> - implementation work.
>
> ### 8. Add Handoff Rules To Atomic Task Creation
>
> Update planning process text so `CREATE-TASK` may only create atomic task packs from a DAG node that has:
>
> - source-pack reference;
> - capability boundary mapping;
> - execution surface ID;
> - ownership binding;
> - replay criticality classification;
> - mutability classification;
> - ontology classification;
> - determinism classification;
> - future-phase isolation result;
> - doctrine-gap outcome of `IMPLEMENT` or `SPLIT`;
> - no unresolved blockers.
>
> Atomic tasks must cite:
>
> ```text
> boundary row
> execution surface ID
> master plan work package
> DAG node
> surface-specific implementation plan
> governing doctrine
> ```
>
> ### 9. Validate With Phase 3
>
> Use Phase 3 as the proof case.
>
> Create or update planning artifacts only:
>
> ```text
> docs/PHASE3/PHASE3_SOURCE_PACK.md
> docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md
> docs/PHASE3/PHASE3_TASK_DAG.md
> docs/PHASE3/phase3_task_dag.yml
> docs/PHASE3/implementation_plans/README.md
> ```
>
> Do not create atomic task packs yet.
>
> The Phase 3 validation must prove that:
>
> - all phase spec items 3.1 through 3.8 are covered;
> - contract rows P3-001 through P3-009 are covered;
> - INV-301 through INV-310 are covered;
> - useful support domains from the uploaded implementation plan are generated only when constitutionally justified;
> - out-of-phase items are routed instead of absorbed;
> - every planned task belongs to an execution surface and DAG node.
>
> ## Test Plan
>
> Run documentation consistency checks after edits:
>
> - confirm every required source-pack category is mapped for Phase 3;
> - confirm every execution surface has ownership, replay, mutability, ontology, determinism, and doctrine-gap classifications;
> - confirm every DAG node maps to a surface;
> - confirm no surface has a future-phase routing conflict;
> - confirm no task candidate exists without constitutional justification;
> - confirm `CREATE-IMPLEMENTATION-PLAN` still cannot create atomic task packs;
> - confirm no process language contradicts `AGENT_ENTRYPOINT.md`, `TASK_CREATION_PROCESS.md`, or `SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md`.
>
> ## Assumptions
>
> - This framework applies to all phases, not only Phase 3.
> - Phase 3 already has most source-pack materials, but needs a formal `PHASE3_SOURCE_PACK.md` index.
> - Source-pack requirements are information categories, not one-file-per-category requirements.
> - Execution envelope constraints remain authoritative over whether Phase 3 work is executable.
> - This implementation stops before atomic task creation.

<details><summary>12 previous messages</summary>

> I’ll implement this as governance/process documentation only: no task packs, no migrations, no verifier scripts, and no evidence artifacts. First I’m grounding against the current entrypoint/router/process docs and Phase 3 planning files so the edits fit the existing structure.
>
> Mode classification is `CREATE-IMPLEMENTATION-PLAN`: the requested outputs are governance/planning artifacts and process docs, and the prompt explicitly forbids atomic task creation. I’m checking the root execution envelope and DRD state before editing because those constraints still govern planning artifacts.
>
> I’m going to add the process standard and Phase 3 validation artifacts now. I’ll keep them explicitly non-atomic and planning-only, and I’ll avoid creating any `tasks/`, verifier, migration, or evidence files.
>
> <details><summary>Created 1 file</summary>
>
> - Wrote `./docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` (+500 -0)
>
> </details>
>
> The core process doc is updated with the execution-surface-first pipeline and handoff gate. Next I’m updating the router so agents entering `CREATE-IMPLEMENTATION-PLAN` know this mode covers source packs, surface maps, DAGs, and surface-specific plans, while still prohibiting atomic task artifacts.
>
> <details><summary>Edited 1 file</summary>
>
> - Wrote `./docs/operations/AGENT_PROMPT_ROUTER.md` (+21 -3)
>
> </details>
>
> I’m adding the Phase 3 proof artifacts now: a source-pack index, execution-surface map, human DAG, machine DAG, and implementation-plan registry. These are deliberately planning artifacts with blocker/status language, not atomic task packs.
>
> <details><summary>Created 5 files</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md` (+362 -0)
> - Wrote `./docs/PHASE3/PHASE3_SOURCE_PACK.md` (+60 -0)
> - Wrote `./docs/PHASE3/PHASE3_TASK_DAG.md` (+121 -0)
> - Wrote `./docs/PHASE3/implementation_plans/README.md` (+62 -0)
> - Wrote `./docs/PHASE3/phase3_task_dag.yml` (+205 -0)
>
> </details>
>
> The Phase 3 planning artifacts are in place. I’m running consistency checks now: required source-pack categories, execution-surface classifications, DAG-to-surface mappings, and mode guardrails.
>
> The textual checks found the expected mode/process guardrails and the Phase 3 DAG/surface mappings. I’m doing a tighter sanity pass now for broken references and basic YAML parseability of the new DAG file.
>
> The checks found one bad doctrine path in the new surface map: I referenced a regulatory subdirectory path that does not exist in this repo. I’m correcting that reference to the actual constitutional file path, then I’ll rerun the reference check.
>
> <details><summary>Edited 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md` (+1 -1)
>
> </details>
</details>

Implemented the planning framework as governance/process docs only. No atomic task packs, migrations, verifier scripts, or evidence artifacts were created.

Changed/added:

- Updated [docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md](/C:/Workspace/GitHub/Symphony/docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md) with the execution-surface-first pipeline, classifications, anti-fake-surface rule, DAG rules, and `CREATE-TASK` handoff gates.
- Updated [docs/operations/AGENT_PROMPT_ROUTER.md](/C:/Workspace/GitHub/Symphony/docs/operations/AGENT_PROMPT_ROUTER.md) so `CREATE-IMPLEMENTATION-PLAN` explicitly covers source packs, execution-surface maps, master plans, DAGs, surface-specific plans, and readiness/cleanup planning.
- Created [PHASE3_SOURCE_PACK.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_SOURCE_PACK.md).
- Created [PHASE3_EXECUTION_SURFACE_MAP.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md).
- Created [PHASE3_TASK_DAG.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_TASK_DAG.md).
- Created [phase3_task_dag.yml](/C:/Workspace/GitHub/Symphony/docs/PHASE3/phase3_task_dag.yml).
- Created [implementation_plans/README.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/implementation_plans/README.md).

Validation performed:

- Confirmed all 19 Phase 3 source-pack categories are mapped.
- Confirmed 12 execution surfaces exist and each has ownership, replay, mutability, ontology, determinism, and doctrine-gap classifications.
- Confirmed all DAG surface references resolve to defined surfaces.
- Confirmed the machine DAG has no duplicate node IDs and every node has `surface_ids` plus `doctrine_gap_status`.
- Confirmed no atomic task directories were created for the new Phase 3 planning IDs.
- Confirmed Phase 3 spec sections 3.1 through 3.8, contract rows P3-001 through P3-009, and INV-301 through INV-310 are covered in the DAG.

Remaining blockers are intentionally recorded, not fixed here:

- `docs/PHASE3/phase3_contract.yml` still has the P3-004 indentation/parse defect.
- The active execution envelope still conflicts with Phase 3 opening/claimability posture.
- Phase 3 atomic task creation remains blocked until those cleanup items are resolved.

I did not run full `pre_ci.sh`; this was a docs/process implementation and the repo has known active execution-envelope constraints around Phase 3 execution.

> So what is next?

Next is **not atomic Phase 3 task creation yet**. The new framework is in place, but the Phase 3 DAG correctly marks Wave 0 cleanup blockers first.

The next step is to create and execute a cleanup implementation plan for:

1. `TSK-P3-CLEAN-001`
   Fix `docs/PHASE3/phase3_contract.yml` parse/indentation defect.

2. `TSK-P3-CLEAN-002`
   Rewrite `docs/PHASE3/README.md` so it no longer describes the old external-trust-surface posture.

3. `TSK-P3-CLEAN-003`
   Add governing doctrine references to `PHASE3_INVARIANT_REGISTER.md`.

4. `TSK-P3-CLEAN-004`
   Resolve the conflict between `PHASE3_OPENING_ACT.md` / `phase3_contract.yml` and the active `PHASE_EXECUTION_ENVELOPE.md`.

5. `TSK-P3-CLEAN-005`
   Resolve or archive `MADD_MAIN_INTEGRATION_DOCTRINE-2.md`.

6. `TSK-P3-CLEAN-006`
   Confirm archived Phase 3 review artifacts are excluded from ingestion/task-generation.

After those are done:

```text
Wave 0 cleanup complete
→ create surface-specific implementation plans
→ update DAG node statuses
→ only then create atomic task packs in CREATE-TASK mode
```

The most important blocker is `TSK-P3-CLEAN-004`. Until the execution-envelope conflict is resolved, Phase 3 can be planned, but should not be treated as executable.

> Has the Master Implementation Plan been created yet? All these plans should first be confirmed to be in the master plan together with the rest of the Phase 3 plans. Is this the case?

<details><summary>1 previous message</summary>

> I’ll inspect the current master plan against the new surface map and DAG to see whether it already includes the expanded execution-surface framework or still reflects the older work-package-only structure.
</details>

No. The file named [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/C:/Workspace/GitHub/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md) exists, but it is still the **older master plan**.

It does **not yet incorporate** the new framework we just created:

- `PHASE3_SOURCE_PACK.md`
- `PHASE3_EXECUTION_SURFACE_MAP.md`
- `PHASE3_TASK_DAG.md`
- `phase3_task_dag.yml`
- `implementation_plans/README.md`
- support-domain DAG nodes like `TSK-P3-SUPPORT-DB-001`, `TSK-P3-SUPPORT-SEC-001`, `TSK-P3-SUPPORT-MIG-001`, etc.
- execution surface IDs `P3-SURF-000` through `P3-SURF-011`
- replay/mutability/ontology/determinism classifications

So the current state is:

```text
Framework process: implemented
Phase 3 source pack: created
Phase 3 execution surface map: created
Phase 3 DAG: created
Implementation-plan registry: created
Master Implementation Plan: exists, but not yet updated to include the new framework artifacts
```

That means your concern is valid: **the next correct step is to update `PHASE3_MASTER_IMPLEMENTATION_PLAN.md` so it becomes the authoritative consolidated plan that references and incorporates the new source pack, execution surfaces, DAG, support domains, and implementation-plan registry.**

Until that happens, the planning universe is split across the older master plan and the new framework artifacts. Atomic task creation should stay blocked.

> Explain what you mean "update" the master plan. I prefer if you say generaate from the process just implemented. Unless you are thinking of using a different method

You’re right to push on that wording.

I do **not** mean “patch the old master plan until it kind of matches.” That would reintroduce the exact problem we just fixed.

What I mean is:

```text
Regenerate PHASE3_MASTER_IMPLEMENTATION_PLAN.md using the new Master Implementation Planning Framework.
```

The existing file should be treated as an older planning artifact, not as the structure to preserve.

The regeneration should use this input chain:

```text
PHASE3_SOURCE_PACK.md
→ PHASE3_CAPABILITY_BOUNDARY.md
→ PHASE3_EXECUTION_SURFACE_MAP.md
→ PHASE3_TASK_DAG.md
→ phase3_task_dag.yml
→ implementation_plans/README.md
→ PHASE3_MASTER_IMPLEMENTATION_PLAN.md
```

So the method is:

1. Read the source pack.
2. Use the capability boundary as the scope router.
3. Use the execution surface map as the architecture authority.
4. Use the DAG as the sequencing authority.
5. Use the implementation-plan registry as the handoff index.
6. Generate a new master implementation plan from those artifacts.

The regenerated master plan should become the consolidated top-level plan. It should not invent new scope and should not merely repeat the old capability-only work-package table.

So the better phrasing is:

**Next step: regenerate the Phase 3 Master Implementation Plan from the newly implemented process.**

> Proceed

<details><summary>8 previous messages</summary>

> I’ll regenerate the Phase 3 master plan from the new source pack, execution surface map, DAG, and implementation-plan registry, replacing the older capability-only plan with the framework-derived consolidated plan.
>
> Context compaction
>
> Source: automatic
> Status: completed
>
> I understand “update” here as regenerate from the planning framework we just implemented, not patch the old master plan opportunistically. I’m going to replace the Phase 3 master plan body with a framework-derived version tied to the source pack, execution surfaces, DAG, and known blockers.
>
> The existing master plan is still the older work-package draft. It does not yet use the new required artifacts as authorities, so I’m replacing it with a generated master plan whose task universe is the DAG and execution-surface map rather than the older capability-only sequence.
>
> <details><summary>Created 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` (+305 -0)
>
> </details>
>
> The regenerated master plan is now written. I’m checking it against the DAG and surface map so we know it did not drop a node, surface, or required coverage item.
>
> <details><summary>Edited 1 file</summary>
>
> - Wrote `./docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` (+5 -4)
>
> </details>
>
> The plan now passes the local consistency checks for DAG-node presence, surface IDs, and phase-scope coverage. I’m going to try the repo’s standard pre-CI command next; if the environment can’t run it cleanly, I’ll report that rather than hiding it.
</details>

Generated the Phase 3 Master Implementation Plan from the new process, not by patching the old one.

The regenerated plan is here: [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](./docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md:1)

It now includes:
- source-pack authority and execution-envelope caveat
- all 12 execution surfaces `P3-SURF-000` through `P3-SURF-011`
- the full DAG task universe from Wave 0 through Wave 5
- support-domain justification to prevent fake completeness work
- coverage for Phase spec `3.1` through `3.8`
- coverage for contract rows `P3-001` through `P3-009`
- coverage for invariants `INV-301` through `INV-310`
- future-phase routing exclusions
- surface-specific plan registry
- atomic task creation gate

Validation I ran:
- all DAG node IDs are present in the master plan
- all execution surface IDs are present
- all Phase 3 scope items, contract rows, and invariant IDs are present
- no atomic task directories were created

Important blocker: `scripts/dev/pre_ci.sh` could not run because this Windows environment has WSL installed but no Linux distribution configured. The command failed before repo checks could execute.

Next step is Wave 0 cleanup, especially `TSK-P3-CLEAN-001` and `TSK-P3-CLEAN-004`, before creating surface-specific implementation plans.
