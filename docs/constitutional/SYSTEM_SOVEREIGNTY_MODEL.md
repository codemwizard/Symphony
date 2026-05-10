# SYSTEM_SOVEREIGNTY_MODEL.md

```
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 10
Phase-Scope: GLOBAL
Supersedes: NONE
Depends-On: CONSTITUTIONAL_GLOSSARY.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md, CONSTITUTIONAL_ARTIFACT_STATUS_STANDARD.md, NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md
```

---

## Purpose

This document defines Symphony's sovereign trust architecture. It establishes the complete model of sovereignty domains, their constitutional boundaries, their coexistence semantics, and the doctrines that prevent unconstitutional collapse between them. It is the constitutional model from which all authority assignments, enforcement decisions, admissibility determinations, and phase governance obligations derive their structural grounding.

This document does not describe an aspirational architecture. It describes the constitutional structure that Symphony's substrate — its DB enforcement, CI gates, cryptographic infrastructure, regulatory partitioning, and replay mechanisms — mechanically instantiates. The sovereignty model is not a design intention; it is a constitutional fact expressed in running enforcement code.

---

## Constitutional Scope

This document governs:

1. The definition of each sovereignty domain within Symphony's architecture.
2. The boundaries between sovereignty domains and the legal conditions governing boundary traversal.
3. The non-collapse doctrine that prohibits unconstitutional merger of domains.
4. The mutual veto doctrine that defines how each domain may block operations within its plane.
5. The compositional validation semantics governing how multiple sovereignty domains certify a single artifact or operation.
6. The replay survivability obligations that apply across all sovereignty domains.
7. The admissibility continuity doctrine governing how historical sovereignty findings remain valid over time.

This document does NOT govern:

1. The specific technical implementation of any enforcement mechanism (governed by source migrations and the Canonical Capability Report).
2. The substantive requirements of any regulatory jurisdiction (governed by regulator-partitioned instruments).
3. The specific phase transition criteria (governed by phase lifecycle constitutional documents).
4. The specific invariant identifiers (governed by INVARIANTS_MANIFEST.yml).

---

## Part I: Symphony as a Sovereign Trust Arbitration Fabric

Symphony is a **sovereign trust arbitration fabric**. This framing is constitutional, not metaphorical, and carries precise architectural implications that must be understood before any other aspect of the sovereignty model can be applied correctly.

### 1.1 What a Sovereign Trust Arbitration Fabric Is

A sovereign trust arbitration fabric is a system whose primary function is not to execute operations, store data, or enforce business rules, but to provide a constitutionally grounded substrate within which multiple independent sovereignty domains can coexist, interact, and produce findings that are mutually admissible across domain boundaries without any domain's findings being unconstitutionally subordinated to another's.

The word **sovereign** means that each domain within the fabric derives its authority from a source that is not subordinate to any other domain within the fabric. Symphony does not create sovereignty; it provides the infrastructure within which pre-existing sovereignties — regulatory jurisdictions, cryptographic proof authorities, operational enforcement authorities, historical permanence obligations — can operate without collapsing into each other.

The word **arbitration** means that Symphony provides the defined protocols through which domain boundaries are traversed when operations require cross-domain certification. Arbitration is not convergence. Arbitration preserves each domain's independent finding while providing a defined interface through which those findings are combined for specific downstream purposes.

The word **fabric** means that sovereignty domains are woven together at defined interaction points — not merged into a single authority structure, and not isolated into non-interacting silos. The fabric has seams (defined cross-domain protocols) and texture (distinct enforcement mechanisms per domain), not a uniform surface.

### 1.2 What Symphony Is NOT

Symphony is NOT a centralized authority platform. A centralized authority platform routes all trust determinations through a single authority that produces a unitary finding. Symphony produces no unitary trust findings. It produces domain-specific findings from each relevant sovereignty domain, which downstream consumers combine for their specific purposes.

Symphony is NOT a trust aggregator. Aggregation implies that findings from multiple sources are combined into a single score or status. Symphony's compositional validation semantics require that each domain's finding be preserved independently, not aggregated into a single validity metric.

Symphony is NOT a policy engine. A policy engine applies rules to produce decisions. Symphony applies constitutional enforcement mechanisms across multiple orthogonal domains, each governed by its own authority. The rules in one domain are not inputs to the policy engine of another.

Symphony is NOT a settlement layer. Settlement implies finality of a single determination. Symphony produces determinations that are final within their sovereignty plane, not final across all planes simultaneously.

---

## Part II: Sovereignty Domains

Symphony's sovereign trust architecture comprises six constitutionally distinct sovereignty domains. Each domain is orthogonal to the others: it governs a constitutionally distinct class of questions, derives its authority from an independent source, and produces findings that are non-comparable to findings from other domains without a defined cross-domain protocol.

---

### Domain SD-1: Runtime Sovereignty (Wave 4)

**Constitutional definition:**
Runtime sovereignty is the sovereignty domain that governs the constitutional validity of Symphony's operational execution state at the moment of each operation. It answers the constitutional question: *Is this operation — transaction, state transition, evidence record, asset issuance, ledger posting — constitutionally valid under the operational rules in force at the time it occurs?*

**Authority source:**
Runtime sovereignty derives its authority from Wave 4 mechanisms: the DB trigger chain, state machine rule enforcement, confidence threshold gates, phase boundary triggers, and CI verification gates. These mechanisms are the runtime sovereignty authority.

**Scope of governance:**
- State transition permissibility (`state_rules`, trigger chain migrations 0135–0154)
- Evidence quality thresholds (`data_authority_level` enforcement, `GF037`)
- Issuance confidence requirements (`enforce_confidence_before_issuance()`, `GF020`–`GF022`)
- Ledger balance integrity (`verify_internal_ledger_journal_balance()`, `23514`)
- Phase boundary compliance (`enforce_phase1_boundary()`, `GF071`/`GF072`)
- Attestation freshness (`enforce_attestation_freshness()`, `GF073`)
- Instruction finality (`enforce_instruction_reversal_source()`, `P7003`)

**Veto authority:**
Runtime sovereignty exercises a **hard veto** over operations that violate its enforcement rules. A hard veto is unconditional: no finding from any other sovereignty domain overrides a runtime sovereignty veto. A state transition that violates `state_rules` is constitutionally impermissible regardless of its cryptographic validity (provenance sovereignty) or regulatory compliance (regulatory sovereignty).

**Boundary definition:**
Runtime sovereignty's authority terminates at the boundary of questions about cryptographic origin. Whether an operationally valid artifact was produced by an authorized signer with a valid key is not a runtime sovereignty question — it is a provenance sovereignty question. An artifact that satisfies all runtime sovereignty requirements but fails provenance sovereignty requirements is simultaneously operationally valid and cryptographically inadmissible.

**Replay obligation:**
Runtime sovereignty findings are subject to historical replay preservation. The operational validity determination made at time T MUST remain reconstructable at time T+N by preserving the rules (`state_rules`, `data_authority_level` values) that were in force at time T.

---

### Domain SD-2: Provenance Sovereignty (Wave 8)

**Constitutional definition:**
Provenance sovereignty is the sovereignty domain that governs the cryptographic authenticity, origin integrity, and non-repudiation of evidentiary artifacts produced within Symphony. It answers the constitutional question: *Can the cryptographic origin of this artifact be verified as having been produced by an authorized signer with an authorized key, attesting to an unmodified canonical payload, at the declared time?*

**Authority source:**
Provenance sovereignty derives its authority from Wave 8 mechanisms: `ed25519_verify()`, `resolve_authoritative_signer()`, `public_keys_registry` temporal validity periods, `wave8_cryptographic_enforcement()`, and the canonical payload binding contracts. These mechanisms constitute the provenance sovereignty authority.

**Scope of governance:**
- Signature cryptographic validity (ed25519 verification, `P7809`)
- Signer authorization (authorized key, valid period, `resolve_authoritative_signer()`, `P7806` on ambiguity)
- Canonical payload integrity (hash binding, `P7811`)
- Timestamp consistency (internal consistency with canonical payload, `P7814`)
- Context binding (operation context matches signature context, `P7814`)
- Key supersession chain (preservation of historical key validity through `wave8_signer_resolution.superseded_by`)

**Veto authority:**
Provenance sovereignty exercises a **hard cryptographic veto** over artifact admissibility for provenance-dependent downstream uses. An artifact that fails Wave 8 cryptographic verification is constitutionally inadmissible for any downstream use that requires provenance certification, regardless of its operational validity.

**Boundary definition:**
Provenance sovereignty's authority terminates at the boundary of questions about operational correctness. Whether a cryptographically valid artifact was produced through a constitutionally permitted state transition, under a valid policy decision, with adequate confidence — these are runtime sovereignty questions. Provenance sovereignty confirms the artifact's origin; runtime sovereignty confirms the artifact's operational legitimacy.

**Replay obligation:**
Provenance sovereignty carries a permanent replay obligation. The cryptographic verification performed at time T must remain reproducible at time T+N using the key version active at time T (preserved through the supersession chain), the canonical payload version in force at time T (preserved through `canonicalization_registry`), and the signature produced at time T (preserved in the immutable artifact record).

---

### Domain SD-3: Replay Sovereignty

**Constitutional definition:**
Replay sovereignty is the sovereignty domain that governs the permanent constitutional validity of historical evidentiary artifacts — their reconstructability, admissibility continuity, and historical legitimacy — across time, through system changes, and across phase transitions. It answers the constitutional question: *Does this historical artifact remain constitutionally legitimate when subjected to forensic reconstitution under its original production conditions?*

**Authority source:**
Replay sovereignty derives its authority from Symphony's constitutional permanence infrastructure: `canonicalization_registry`, `proof_pack_batch_leaves`, `archive_verification_runs`, `anchor_backfill_jobs`, `anchor_sync_operations`, and the historical preservation requirements encoded in this document and the Constitutional Glossary.

**Scope of governance:**
- Canonicalization version preservation (permanent retention of deprecated algorithm specs and test vectors)
- Merkle proof path preservation (`proof_pack_batch_leaves`, `verify_merkle_leaf()`)
- Archive verification integrity (`archive_verification_runs`)
- Backfill reconstruction tracking (`anchor_backfill_jobs`)
- Anchor synchronization state (`anchor_sync_operations`)
- Historical validity of superseded-key signatures (no retroactive invalidation)
- Evidence survivability across phase transitions

**Veto authority:**
Replay sovereignty exercises a **prospective veto** over operations that would destroy historical admissibility. A prospective veto is exercised at the design and planning stage: any Phase 3 capability that produces evidentiary outputs without including replay survivability mechanisms in its Definition of Done is constitutionally vetoed before execution. Replay sovereignty does not primarily veto live operational events (runtime sovereignty does that); it vetoes the design of systems that would make historical reconstruction impossible.

**Boundary definition:**
Replay sovereignty governs historical artifacts. It does not govern whether current operations are valid (runtime sovereignty) or whether current artifacts are cryptographically authentic (provenance sovereignty). Its domain begins where the operation ends and extends indefinitely into the future.

**Replay obligation:**
Replay sovereignty is itself the governance domain for replay obligations. Its primary obligation is that it must remain continuously operative: the replay substrate must be populated, maintained, and resolvable at all times, not only when a replay event is triggered.

---

### Domain SD-4: Regulatory Sovereignty

**Constitutional definition:**
Regulatory sovereignty is the sovereignty domain of a specific regulatory jurisdiction or accreditation body that defines the requirements an evidentiary artifact must satisfy to be considered admissible within that jurisdiction's regulatory framework. It answers the constitutional question: *Does this artifact satisfy the regulatory requirements of jurisdiction J under interpretation pack version V active at time T?*

**Authority source:**
Regulatory sovereignty derives its authority from the regulatory jurisdiction itself — an external, pre-existing sovereign authority whose requirements Symphony's interpretation packs encode. Symphony does not create regulatory sovereignty; it provides the substrate within which regulatory sovereignty is expressed, enforced, and partitioned from other regulatory jurisdictions.

**Scope of governance:**
- Interpretation pack content and versioning (`interpretation_packs`, `resolve_interpretation_pack()`)
- Taxonomy alignment requirements (K13 taxonomy alignment, `trg_k13_taxonomy_alignment`)
- Do No Significant Harm compliance (`trg_enforce_dns_harm`)
- Validator/verifier independence requirements (`check_reg26_separation()`, `GF001`)
- Jurisdiction-specific factor and unit requirements (`factor_registry`, `unit_conversions`)
- Jurisdiction-specific project boundary and protected area requirements (`project_boundaries`, `protected_areas`)
- Article 6 / ITMO authorization requirements (jurisdiction-scoped)

**Veto authority:**
Each regulatory jurisdiction exercises a **sovereign veto** over the regulatory admissibility of artifacts within its jurisdiction. A sovereign veto is jurisdiction-scoped: it blocks admissibility within the vetoing jurisdiction only. It does not affect admissibility in other jurisdictions or operational validity in the runtime sovereignty domain.

**Regulator orthogonality:**
Regulatory sovereignty domains are constitutionally orthogonal. No regulatory jurisdiction's sovereign veto extends to another jurisdiction's admissibility determination. No regulatory jurisdiction's admissibility certification confers or implies certification in another jurisdiction. Each regulatory sovereignty domain is complete and self-contained within its defined jurisdiction scope.

**Boundary definition:**
Regulatory sovereignty's authority is jurisdiction-scoped. It does not govern the cryptographic authenticity of artifacts (provenance sovereignty), the operational validity of the state transitions that produced them (runtime sovereignty), or their long-term reconstructability (replay sovereignty). It governs only whether they satisfy the jurisdiction's substantive requirements.

**Enforcement mechanism:**
`current_jurisdiction_code_or_null()` SECURITY DEFINER enforces the session-level jurisdiction context. All regulatory sovereignty determinations require a valid `app.jurisdiction_code` session variable. Operations executed without a valid jurisdiction context are constitutionally unscoped and their regulatory admissibility is indeterminate.

---

### Domain SD-5: Tenant Sovereignty

**Constitutional definition:**
Tenant sovereignty is the sovereignty domain of a specific authorized tenant within Symphony's multi-tenant architecture. It governs the isolation, integrity, and non-contamination of a tenant's data, operations, and evidentiary record from other tenants. It answers the constitutional question: *Is this operation authorized by, and directed to, the correct tenant context, without cross-tenant contamination?*

**Authority source:**
Tenant sovereignty derives its authority from Symphony's dual-policy RLS architecture: the PERMISSIVE baseline policy establishing tenant identity assertions and the RESTRICTIVE isolation policy preventing cross-tenant access. The `tenant_id` column, enforced across ~35 tables, is the constitutional boundary marker of tenant sovereignty.

**Scope of governance:**
- Row-level tenant isolation (dual-policy RLS, `0095_rls_dual_policy_architecture.sql`)
- Cross-tenant posting rejection (`trg_enforce_internal_ledger_posting_context`)
- Escrow cross-tenant isolation (`0046_escrow_ceiling_enforcement_cross_tenant.sql`)
- Supplier and programme tenant scoping (`0075`)
- Coverage kill switch (RLS coverage must be complete for all tenant-scoped tables)

**Veto authority:**
Tenant sovereignty exercises a **data boundary veto** over cross-tenant operations. Any operation that would expose one tenant's data to another tenant's context, or post a ledger entry across tenant boundaries, is constitutionally blocked. The data boundary veto is enforced at the DB layer and is unconditional.

**Boundary definition:**
Tenant sovereignty governs data access and operation scope within the multi-tenant architecture. It does not govern the substantive requirements for an artifact's admissibility (regulatory sovereignty), its cryptographic authenticity (provenance sovereignty), or its operational validity (runtime sovereignty). Tenant sovereignty ensures that valid operations occur in the correct tenant context; it does not make operations valid.

---

### Domain SD-6: Jurisdictional Sovereignty

**Constitutional definition:**
Jurisdictional sovereignty is the sovereignty domain that governs the partition of Symphony's operational scope by legal jurisdiction — the condition under which operations executed in or for a specific legal jurisdiction are scoped to that jurisdiction's interpretation context, regulatory framework, and admissibility requirements, without contamination from other jurisdictions' frameworks.

**Distinction from regulatory sovereignty:**
Jurisdictional sovereignty and regulatory sovereignty are related but distinct. Regulatory sovereignty is the authority of a specific regulator or accreditation body to define admissibility requirements. Jurisdictional sovereignty is the constitutional partition that ensures operations are executed under the correct jurisdiction's interpretation context.

A single jurisdiction may have multiple regulatory authorities (e.g., Zambia may have both a national carbon authority and a provincial land authority). Jurisdictional sovereignty governs which overall interpretation context applies; regulatory sovereignty governs the specific requirements within that context.

**Authority source:**
Jurisdictional sovereignty derives its authority from the `app.jurisdiction_code` session variable, the `rls_jurisdiction_isolation_interpretation_packs` RESTRICTIVE RLS policy, and the jurisdiction-scoped metadata in `interpretation_packs` and `regulatory_authorities`.

**Scope of governance:**
- Interpretation pack jurisdiction scoping (`interpretation_packs.jurisdiction_code`)
- Regulatory authority jurisdiction scoping (`regulatory_authorities.jurisdiction_code`)
- Session-level jurisdiction context (`current_jurisdiction_code_or_null()`)
- Cross-jurisdiction boundary enforcement (RLS RESTRICTIVE policies prevent cross-jurisdiction data access without explicit authorization)

**Veto authority:**
Jurisdictional sovereignty exercises a **context veto** over operations executed without a valid jurisdiction context. An operation executed under an incorrect or absent jurisdiction context produces jurisdictionally-unscoped outputs that are constitutionally inadmissible for jurisdiction-specific regulatory purposes.

---

## Part III: Non-Collapse Doctrine

The non-collapse doctrine is the constitutional principle that prohibits the unconstitutional merger of sovereignty domains. It is the foundational principle governing how Symphony's multiple sovereignty domains coexist.

### 3.1 Statement of the Non-Collapse Doctrine

**No sovereignty domain may be merged with, subordinated to, or collapsed into another sovereignty domain without a constitutionally defined cross-domain protocol that explicitly preserves the independent authority of each domain at the point of interaction.**

Non-collapse is not merely a design preference. It is constitutionally mandated by the nature of the sovereignty domains themselves. Regulatory sovereignty derives from external regulatory authorities whose requirements Symphony does not create. Provenance sovereignty derives from cryptographic proof principles that are independent of operational state. Replay sovereignty derives from the constitutional obligation of historical permanence that exists independently of current operational conditions. These sources of authority cannot be merged because they are independently grounded.

### 3.2 Consequences of Non-Collapse

**Consequence NC-001 — Parallel Certifications Are Required, Not Optional:**
When an operation or artifact is subject to multiple sovereignty domains, each domain's certification is constitutionally required for the artifact to be fully admissible across all its relevant uses. The certifications are parallel, not sequential with one substituting for another.

**Consequence NC-002 — Domain-Specific Failures Are Not Universal Failures:**
When an artifact fails certification within one sovereignty domain, it does not universally fail. An artifact that fails provenance sovereignty certification (invalid signature) but satisfies runtime sovereignty requirements is operationally valid and cryptographically inadmissible. Neither status cancels the other. The artifact carries both statuses simultaneously.

**Consequence NC-003 — Domain-Specific Successes Are Not Universal Successes:**
When an artifact satisfies one sovereignty domain's requirements, this creates no constitutional presumption of satisfaction in other domains. An artifact that passes Wave 8 cryptographic verification has established its provenance sovereignty status. It has established nothing about its regulatory admissibility or operational validity.

**Consequence NC-004 — Convergence Tasks Are Constitutionally Prohibited Without Protocol:**
Any architectural task, system redesign, or consolidation effort that would merge two sovereignty domains into a single enforcement surface — without defining a cross-domain protocol that explicitly preserves each domain's independent authority — is constitutionally prohibited under the non-collapse doctrine.

### 3.3 Non-Collapse Doctrine and Architectural Complexity

The non-collapse doctrine is the constitutional justification for Symphony's architectural multiplicity. Where a conventional platform might implement one "enforcement layer," Symphony implements distinct enforcement surfaces for each sovereignty domain. This multiplicity is not accidental complexity; it is constitutionally required complexity.

Any analysis that characterizes Symphony's multiple enforcement surfaces as redundant, over-engineered, or candidates for consolidation without first establishing that the surfaces in question serve the same sovereignty plane is constitutionally malformed analysis (per NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.1 and §1.6).

---

## Part IV: Mutual Veto Doctrine

The mutual veto doctrine defines how each sovereignty domain may block operations or artifact admissibility within its plane, and how veto findings from multiple domains combine for composite admissibility determinations.

### 4.1 Veto Types

**Hard Veto:**
A hard veto is an unconditional block applied within a sovereignty domain's enforcement surface. No finding from any other sovereignty domain overrides a hard veto. Hard vetoes are exercised by: runtime sovereignty (DB trigger rejections), provenance sovereignty (Wave 8 cryptographic rejections), and tenant sovereignty (RLS isolation rejections).

*Hard veto SQLSTATE examples:* `GF037` (runtime data authority), `P7809` (provenance cryptographic), `GF071`/`GF072` (runtime phase boundary), `23514` (runtime ledger balance).

**Sovereign Veto:**
A sovereign veto is a jurisdiction-scoped block applied by a regulatory sovereignty domain. A sovereign veto blocks admissibility within the vetoing jurisdiction only. It does not affect other jurisdictions or operational domains.

*Sovereign veto enforcement:* `check_reg26_separation()` (`GF001`); jurisdiction RLS policies; `enforce_dns_harm_trigger`.

**Prospective Veto:**
A prospective veto is exercised at the design and constitutional planning stage. Replay sovereignty's prospective veto blocks the constitutional authorization of Phase 3 capabilities that would produce non-replay-survivable evidentiary outputs.

*Prospective veto mechanism:* Definition of Done constitutional requirements; replay obligation inclusion rule (CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md §8.4).

**Context Veto:**
A context veto is applied when an operation is executed without a valid sovereignty context (jurisdiction code, tenant identity, canonical entrypoint). A context veto blocks the operation's outputs from being constitutionally scoped to the relevant domain.

*Context veto mechanisms:* `current_jurisdiction_code_or_null()` (jurisdictional); dual-policy RLS (tenant); `task_execution_authority_gate.py` (execution authority).

### 4.2 Veto Arbitration

Veto arbitration is the process by which multiple sovereignty domains' veto findings are combined when an operation requires composite admissibility certification.

**Arbitration Rule VA-001 — Independent Parallel Evaluation:**
Each sovereignty domain evaluates the operation independently. Veto evaluation is not sequential with later domains deferring to earlier ones. All relevant domains evaluate in parallel (or in compositional sequence without priority among domains).

**Arbitration Rule VA-002 — Conjunctive Admissibility:**
Full composite admissibility requires that NO relevant sovereignty domain has exercised a veto. The composite admissibility determination is the conjunction of all domain-specific admissibility findings. A single sovereignty domain veto produces domain-specific inadmissibility; the other domains' findings are not negated by it.

**Arbitration Rule VA-003 — No Cross-Domain Override:**
A positive finding in one sovereignty domain does not override a veto in another. A cryptographically valid artifact (provenance sovereignty positive) cannot override a runtime sovereignty hard veto. A regulatorily admissible artifact (regulatory sovereignty positive) cannot override a provenance sovereignty veto.

**Arbitration Rule VA-004 — No Implicit Arbitration:**
Cross-domain arbitration occurs only through explicitly defined protocols. Where no cross-domain arbitration protocol exists, domain findings are non-interacting and MUST NOT be compared or combined. A conflict between a DB-layer GF-prefix rejection and a CI-layer evidence FAIL for the same invariant constitutes a constitutional ambiguity, not an arbitration event, because no cross-layer arbitration protocol is currently defined.

**Arbitration Rule VA-005 — Downstream Use Determines Applicable Domains:**
Which sovereignty domains' findings are relevant to a composite admissibility determination is determined by the downstream use of the artifact, not by the artifact's production path. An artifact used for: international carbon credit trading requires runtime + provenance + regulatory (Article 6) + replay sovereignty certifications. The same artifact used for internal monitoring requires runtime sovereignty certification only.

---

## Part V: Compositional Validation Semantics

Compositional validation is the doctrine governing how Symphony's multiple sovereignty domains certify a single artifact or operation. Each domain contributes a constitutionally distinct certification. The complete constitutional status of an artifact is the sum of all applicable domain certifications, preserved independently.

### 5.1 The Compositional Certification Model

For any artifact or operation, the complete constitutional status is expressed as:

```
Constitutional_Status(artifact) = {
    runtime_validity:       [VALID | INVALID | NOT-APPLICABLE],
    provenance_validity:    [VALID | INVALID | NOT-APPLICABLE],
    replay_survivability:   [SURVIVABLE | NOT-SURVIVABLE | NOT-YET-ASSESSED],
    regulatory_admissibility: {
        jurisdiction_J1:    [ADMISSIBLE | INADMISSIBLE | NOT-APPLICABLE],
        jurisdiction_J2:    [ADMISSIBLE | INADMISSIBLE | NOT-APPLICABLE],
        ...
    },
    tenant_integrity:       [INTACT | CONTAMINATED | NOT-APPLICABLE],
    jurisdictional_scope:   [SCOPED | UNSCOPED]
}
```

This model is constitutional, not technical. It does not imply that a database stores this structure. It defines the complete set of constitutionally relevant status dimensions for any artifact.

**Compositional rule CV-001 — No Dimension Subsumes Another:**
No single dimension of the Constitutional_Status model subsumes or replaces another. `runtime_validity: VALID` does not imply any value for `provenance_validity`. `regulatory_admissibility.J1: ADMISSIBLE` does not imply any value for `regulatory_admissibility.J2`.

**Compositional rule CV-002 — Downstream Use Selects Applicable Dimensions:**
A given downstream use of an artifact requires specific dimensions to be in valid states. The selection of applicable dimensions is determined by the downstream use's constitutional requirements, not by the artifact's production process.

**Compositional rule CV-003 — Partial Certification Is Not Failure:**
An artifact for which only some Constitutional_Status dimensions have been certified is not constitutionally failed. It is certified for uses that require only the dimensions that have been certified, and uncertified for uses that require additional dimensions.

**Compositional rule CV-004 — Status Is Not a Score:**
The Constitutional_Status model MUST NOT be reduced to a scalar score, percentage, or aggregate validity metric. Each dimension is a distinct constitutional determination. Aggregation destroys the sovereignty-preserving information content of the model.

### 5.2 Compositional Validation in Symphony's Enforcement Substrate

The compositional validation model is mechanically instantiated in Symphony's enforcement substrate as follows:

An asset batch insertion triggers:
1. Runtime sovereignty: `enforce_confidence_before_issuance()` (confidence gate), `enforce_monitoring_authority()` (data authority), `state_rules` + trigger chain (state transition permissibility)
2. Provenance sovereignty: `wave8_cryptographic_enforcement()` (signature verification, signer resolution, payload integrity, timestamp consistency)
3. Tenant sovereignty: `trg_enforce_internal_ledger_posting_context` (cross-tenant rejection), dual-policy RLS (session isolation)
4. Replay sovereignty: attestation seam columns populated (`invariant_attestation_hash`, etc.), anti-replay nonce registry (`wave8_attestation_nonces`)
5. Jurisdictional sovereignty: interpretation pack binding (`interpretation_version_id` FK), jurisdiction context session variable

Each enforcement surface is independent. Failure in any one produces domain-specific inadmissibility. Success in all produces full composite constitutional certification for the uses that require all dimensions.

---

## Part VI: Sovereign Partitioning

Sovereign partitioning is the constitutional architectural principle whereby Symphony's data, operations, and evidentiary records are partitioned by sovereignty domain boundaries, such that data belonging to one sovereignty context is constitutionally isolated from data belonging to another sovereignty context without explicit boundary traversal.

### 6.1 Partitioning Dimensions

**By Tenant:**
All tenant-scoped tables carry `tenant_id` as a mandatory partition key. Dual-policy RLS enforces the partition at the DB layer. No cross-tenant data access is constitutionally permissible without explicit authorization through the supervisor access mechanism.

**By Jurisdiction:**
Interpretation packs and regulatory authorities carry `jurisdiction_code` as a partition key. The `rls_jurisdiction_isolation_interpretation_packs` RESTRICTIVE policy enforces jurisdiction partitioning at the DB layer. Operations executed under jurisdiction J cannot read interpretation packs for jurisdiction K.

**By Phase:**
Monitoring records carry a `phase` column enforcing Phase 1 boundary constraints (`enforce_phase1_boundary()`). Data produced in Phase 1 carries permanent Phase 1 constitutional classification that cannot be elevated by subsequent phase transitions.

**By Canonicalization Version:**
Evidentiary artifacts are bound to a specific canonicalization version. The `canonicalization_registry` preserves each version's specifications permanently. Evidence produced under `canon-v1` is partitioned into the `canon-v1` admissibility plane; it does not inherit `canon-v2` semantics.

**By Interpretation Pack Version:**
Execution records and state transitions carry `interpretation_version_id` FK binding them to the specific interpretation pack version active at the time of execution. Historical operations remain bound to their original interpretation version regardless of subsequent pack updates.

### 6.2 Boundary Traversal Protocols

A **sovereignty boundary traversal** occurs when an operation requires data or authority from one sovereignty partition to be used in the context of another. The following traversal protocols are constitutionally defined:

**Tenant-to-Supervisor Traversal:**
Governed by `supervisor_access_modes` and `supervisor_access_mechanisms` (migrations 0051, 0058). Explicit authorization required. No implicit cross-tenant elevation.

**Phase Traversal:**
Governed by phase lifecycle constitutional documents and GOV-CONV ratification sequence. Phase N data does not automatically acquire Phase N+1 attributes upon phase transition.

**Canonicalization Version Traversal:**
Not constitutionally defined for retroactive purposes. Forward traversal (producing new evidence under a new canonicalization version) is permitted. Retroactive traversal (re-canonicalizing historical evidence under a new version) is constitutionally prohibited.

**Interpretation Pack Version Traversal:**
Historical operations remain bound to their original interpretation version. Current operations are bound to the current active version via `resolve_interpretation_pack()`. No retroactive rebinding is constitutionally authorized.

---

## Part VII: Trust-Boundary Coexistence

Trust-boundary coexistence is the constitutional condition under which multiple sovereignty domains operate simultaneously over the same substrate, each sovereign within its plane, without any domain's operation constituting a violation of or interference with another domain's sovereignty.

### 7.1 Coexistence Conditions

Trust-boundary coexistence is constitutionally stable when the following conditions are maintained:

**Condition TC-001 — Plane Distinctness:**
Each coexisting sovereignty domain governs a constitutionally distinct class of questions. No two domains govern the same constitutional question without a defined cross-domain protocol.

**Condition TC-002 — Authority Independence:**
Each coexisting sovereignty domain derives its authority from an independent source. No domain's authority is a subset of or derived from another domain's authority.

**Condition TC-003 — Finding Non-Comparability:**
Findings from different sovereignty domains are non-comparable across domain boundaries without a defined cross-domain protocol. Coexistence does not require that findings be reconcilable; it requires only that they be independently valid within their respective planes.

**Condition TC-004 — Boundary Legibility:**
The boundaries between sovereignty domains are explicitly defined and mechanically enforced. An operation can determine which sovereignty domains apply to it and what each domain requires.

**Condition TC-005 — Non-Interference:**
The operation of one sovereignty domain does not interfere with the operation of another. Runtime sovereignty enforcement does not prevent provenance sovereignty evaluation; regulatory sovereignty compliance does not affect tenant sovereignty isolation.

### 7.2 Constitutional Coexistence Semantics

When multiple sovereignty domains are simultaneously active over an artifact or operation, the following semantic rules apply:

**Coexistence Semantic CS-001 — Simultaneous Validity:**
An artifact may simultaneously be: operationally valid (runtime sovereignty VALID), cryptographically admissible (provenance sovereignty VALID), regulatorily admissible in jurisdiction J1 (regulatory sovereignty ADMISSIBLE for J1), regulatorily inadmissible in jurisdiction J2 (regulatory sovereignty INADMISSIBLE for J2), and replay-survivable. All of these statuses are simultaneously true and non-contradictory.

**Coexistence Semantic CS-002 — Simultaneous Partial Status:**
An artifact may simultaneously be: operationally valid AND cryptographically inadmissible. These are not contradictory states; they are sovereignty-plane-specific states coexisting over the same artifact.

**Coexistence Semantic CS-003 — Historical Coexistence:**
Historical sovereignty findings (from the time of an artifact's production) coexist with current sovereignty findings. An artifact that was regulatorily admissible under the interpretation pack active at time T remains historically admissible under that pack, even if the current active pack would produce a different finding.

**Coexistence Semantic CS-004 — Domain Activation Coexistence:**
Sovereignty domains that are not currently active (because their activation condition has not been triggered) coexist with active domains as dormant domains. Dormant domains do not constitute absent domains. Their constitutional authority remains intact; they are simply not currently exercising it.

---

## Part VIII: Admissibility Continuity Doctrine

Admissibility continuity doctrine is the constitutional principle that once an artifact achieves a valid admissibility status within a sovereignty domain at time T, that status must be preservable and reconstructable at time T+N, regardless of changes to the system that produced it.

### 8.1 Components of Admissibility Continuity

**Runtime Admissibility Continuity:**
The operational validity determination made at time T is preserved by: the immutability of the artifacts it produced (append-only ledgers, trigger-enforced mutation blocks), the preservation of the `state_rules` that were in force at time T, and the preservation of the `data_authority_level` value assigned at time T (which cannot be retroactively elevated per `enforce_phase1_boundary()`).

**Provenance Admissibility Continuity:**
The cryptographic admissibility determination made at time T is preserved by: the signature produced at time T (stored immutably), the signing key version active at time T (preserved through the `wave8_signer_resolution.superseded_by` chain without deletion), and the canonical payload version in force at time T (preserved in `canonicalization_registry`).

**Regulatory Admissibility Continuity:**
The regulatory admissibility determination made at time T under interpretation pack version V is preserved by: the temporal record of interpretation pack versions in `interpretation_packs`, the `effective_from`/`effective_to` fields that establish which pack was active at time T, and the `interpretation_version_id` FK on execution records binding them to their original interpretation version.

**Replay Admissibility Continuity:**
The replay reconstructability of an artifact is preserved by: the Merkle proof path in `proof_pack_batch_leaves`, the canonicalization version record in `canonicalization_registry`, the anchor record in `anchor_sync_operations`, and the archive verification record in `archive_verification_runs`.

### 8.2 Admissibility Continuity Obligations

**Obligation AC-001 — No Retroactive Invalidation:**
No system change — key rotation, canonicalization version upgrade, interpretation pack update, phase transition — may retroactively invalidate the admissibility status of an artifact achieved before that change.

**Obligation AC-002 — Reconstruction Path Permanence:**
The reconstruction path for any historical artifact MUST be permanently preserved. No element of the reconstruction path (signing key version, canonicalization spec, Merkle proof path, interpretation pack version) may be deleted.

**Obligation AC-003 — New Standards Create New Planes:**
When a new standard (new canonicalization version, new interpretation pack version, new cryptographic algorithm) is introduced, it creates a new admissibility plane for future artifacts. It does not require retroactive reprocessing of historical artifacts under the new standard.

**Obligation AC-004 — Phase Transition Non-Disruption:**
A phase transition does not disrupt the admissibility continuity of artifacts produced in prior phases. Phase 1 artifacts retain their Phase 1 admissibility. Phase 2 standards apply to Phase 2 artifacts. The phases create distinct admissibility populations, not a sequence in which later phases retroactively govern earlier ones.

---

## Part IX: Prohibited Sovereignty Assumptions

The following assumptions are constitutionally prohibited across all Symphony governance, analysis, and implementation activities.

### 9.1 Monolithic Trust Assumption

**Prohibited assumption:** Symphony has a single trust root from which all trust determinations flow.

**Constitutional reality:** Symphony has multiple domain-specific trust roots, each grounded in a distinct sovereignty domain. The Wave 4 operational trust root, the Wave 8 provenance trust root, the regulatory sovereignty authority for each jurisdiction, and the phase authority of each ratified phase boundary are all constitutionally distinct and independently grounded. No single root subsumes the others.

**Why this assumption is constitutionally destructive:** The monolithic trust assumption would, if accepted, collapse all sovereignty domains into a single authority hierarchy. This would: (a) make regulatory sovereignty subordinate to operational sovereignty, permitting operationally valid but regulatorily inadmissible artifacts to be presented as fully valid; (b) make provenance sovereignty subordinate to runtime sovereignty, permitting cryptographically compromised artifacts to be operationally admitted without provenance review; and (c) make replay sovereignty subordinate to operational sovereignty, permitting the elimination of replay infrastructure whenever operational performance suggests it.

### 9.2 Runtime Supremacy Assumption

**Prohibited assumption:** When runtime enforcement and any other sovereignty domain produce conflicting findings, runtime enforcement governs.

**Constitutional reality:** Runtime sovereignty governs questions about operational validity. It does not govern questions about cryptographic origin (provenance sovereignty), regulatory admissibility (regulatory sovereignty), historical validity (replay sovereignty), or tenant isolation (tenant sovereignty). These are not conflicts between runtime sovereignty and other domains — they are distinct constitutional questions.

**Why this assumption is constitutionally destructive:** Runtime supremacy, if accepted, would permit operationally executed but cryptographically compromised artifacts to be declared valid. It would permit operationally executed but regulatorily non-compliant artifacts to proceed without regulatory remediation. It would permit operational efficiency arguments to override replay survivability obligations.

### 9.3 Provenance Centralization Assumption

**Prohibited assumption:** Provenance is established by a single signing authority whose findings are universally applicable and whose supersession eliminates the validity of prior signatures.

**Constitutional reality:** Provenance sovereignty is distributed: multiple signing authorities may be constitutionally authorized within their defined scopes (via `wave8_signer_resolution` with scope-based authorization). Signing key supersession does not retroactively invalidate signatures made under the superseded key before its supersession date. Provenance determination for a historical artifact uses the key version active at the time of original signing, not the current active key.

**Why this assumption is constitutionally destructive:** Provenance centralization, if accepted, would permit a key rotation event to retroactively invalidate all historical signatures produced under the rotated key. This would destroy the historical admissibility of all artifacts whose provenance depends on those signatures — a catastrophic and unconstitutional disruption of admissibility continuity.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
All six of Symphony's sovereignty domains — runtime, provenance, replay, regulatory, tenant, and jurisdictional — including their definitions, boundaries, veto semantics, and coexistence rules.

**Sovereignty domains this document MUST NOT redefine:**
- The specific technical enforcement implementations within each sovereignty domain (governed by source migrations and the Canonical Capability Report).
- The substantive regulatory requirements of any specific jurisdiction (governed by regulator-partitioned instruments).
- The specific phase transition criteria (governed by phase lifecycle constitutional documents).
- The specific invariant content (governed by INVARIANTS_MANIFEST.yml).
- The specific SQLSTATE assignments (governed by the SQLSTATE canonical map).

**Replay obligations preserved:**
This document defines replay sovereignty (SD-3) as a constitutionally distinct and coequal sovereignty domain. It establishes the prospective veto as the mechanism by which replay sovereignty prevents the design of non-replay-survivable systems. It defines admissibility continuity doctrine (Part VIII) as the obligation structure preserving historical validity across time and system change. It prohibits retroactive invalidation (Obligation AC-001) and mandates reconstruction path permanence (Obligation AC-002).

**Regulator boundaries constraining this document:**
This document defines regulatory sovereignty (SD-4) and jurisdictional sovereignty (SD-6) as constitutional domains. It does not define the substantive requirements of any specific regulatory jurisdiction — those are defined within each jurisdiction's interpretation pack. The regulator orthogonality doctrine (§SD-4) constrains cross-jurisdiction analysis: no jurisdiction's findings, including those asserted by this document, constrain another jurisdiction's substantive requirements.

**Phases this document applies to:**
GLOBAL — this sovereignty model applies across all phases from Phase 1 onward. Phase sovereignty (expressed in the Phase-Scope field of constitutional artifacts and in the `enforce_phase1_boundary()` trigger) is one dimension of the overall sovereignty model defined here. New phases do not alter the sovereignty model; they apply it to new capability populations.

**Constitutional layers possessing override authority:**
No document with Authority-Rank below 10. Override requires a ROOT-level constitutional instrument that explicitly supersedes this document and provides replacement sovereignty domain definitions for each domain it supersedes.

**Lower-layer documents prohibited from reinterpretation:**
- Phase-specific execution envelopes
- Wave-specific implementation guides
- Task-level Definitions of Done
- Governance convergence documents (GOV-CONV series)
- Agent authority documents (AGENTS.md, AGENT_ENTRYPOINT.md)
- Evidence schema documents
- Migration metadata files
- Any document with Authority-Rank < 10

These documents operate within the sovereignty model defined herein. They may not redefine sovereignty domains, alter veto semantics, modify coexistence conditions, or qualify the non-collapse doctrine.

---

## Prohibited Misinterpretations

**PMI-001 — Runtime Sovereignty as Primary:**
Runtime sovereignty MUST NOT be characterized as Symphony's "primary" or "core" sovereignty domain with other domains as supplementary. All six sovereignty domains are constitutionally coequal within their planes. The description of Wave 4 as "operational" and Wave 8 as "supplementary cryptographic layer" is constitutionally impermissible.

**PMI-002 — Regulatory Sovereignty as Compliance Checkbox:**
Regulatory sovereignty is a constitutionally independent sovereignty domain derived from external regulatory authorities. It is not a compliance checklist applied after operational and cryptographic validity are established. Regulatory admissibility determination is independent of and coequal to operational and provenance determinations.

**PMI-003 — Tenant Sovereignty as Access Control:**
Tenant sovereignty is a constitutional data partition boundary, not an access control system. Access control systems can be overridden by administrative authority. Tenant sovereignty cannot be overridden without constitutional authorization — there is no "admin override" that constitutionally permits cross-tenant data access without an explicit supervisor access traversal protocol.

**PMI-004 — Replay Sovereignty as Disaster Recovery:**
Replay sovereignty is a constitutionally distinct sovereignty domain governing historical permanence. It is not a disaster recovery feature activated only when failures occur. Its substrate must be continuously operative, its obligations attach to every evidentiary output from the moment of production, and its authority is not contingent on any failure event.

**PMI-005 — Jurisdictional and Regulatory Sovereignty as Identical:**
Jurisdictional sovereignty (which context governs an operation) and regulatory sovereignty (what requirements that context imposes) are constitutionally distinct domains. A single jurisdiction may host multiple regulatory authorities. Conflating them would collapse the distinction between the partition mechanism and the substantive requirements it isolates.

**PMI-006 — Mutual Veto as Mutual Exclusion:**
The mutual veto doctrine does not mean that the exercise of a veto by one sovereignty domain prevents other domains from operating. A hard veto by runtime sovereignty blocks the operation within the runtime sovereignty plane. Provenance sovereignty evaluation of the same operation can still occur and produce a finding. The veto blocks the specific operational consequence; it does not freeze all sovereignty domain activity.

**PMI-007 — Compositional Validation as Sequential Pipeline:**
Compositional validation is not a sequential pipeline in which one sovereignty domain's approval unlocks the next domain's evaluation. All relevant sovereignty domains evaluate independently. The compositional result is the conjunction of all domain findings, not the output of the last domain in a chain.

**PMI-008 — Non-Collapse as Non-Interaction:**
The non-collapse doctrine prohibits unconstitutional merger of sovereignty domains. It does not prohibit interaction between them. Sovereignty domains interact at defined cross-domain protocols (the `interpretation_version_id` FK, the `wave8_cryptographic_enforcement` trigger running alongside the `state_rules` trigger chain, the jurisdiction context binding operational outputs). Non-collapse governs the nature of interaction, not the existence of interaction.

**PMI-009 — Sovereign Trust Arbitration Fabric as Marketing Language:**
The characterization of Symphony as a "sovereign trust arbitration fabric" is a constitutional definition, not a marketing framing. Each word carries precise constitutional meaning as defined in Part I. Treating this characterization as rhetorical while applying conventional platform assumptions to Symphony's architecture is constitutionally impermissible.

**PMI-010 — Six Domains as Final and Exhaustive:**
The six sovereignty domains defined in this document represent the current constitutionally declared domains. Future phases may ratify additional sovereignty domains as Symphony's capability scope expands. The addition of new sovereignty domains does not contradict the non-collapse doctrine; it extends the sovereignty model. The six domains defined herein are not a closed list; they are the constitutionally declared domains as of the current phase.
