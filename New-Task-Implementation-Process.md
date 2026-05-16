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
