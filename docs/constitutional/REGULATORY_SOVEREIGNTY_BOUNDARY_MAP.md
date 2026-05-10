# REGULATORY_SOVEREIGNTY_BOUNDARY_MAP.md

```
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: REGULATORY
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 9
Phase-Scope: GLOBAL
Supersedes: NONE
Depends-On: SYSTEM_SOVEREIGNTY_MODEL.md, CONSTITUTIONAL_GLOSSARY.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md, TASK_GENERATION_CONSTITUTION.md
```

---

## Purpose

This document formally maps the sovereign regulatory boundaries within which Symphony operates. It defines each regulator as a constitutionally distinct sovereignty domain, assigns each domain its specific veto authority, admissibility authority, provenance authority, replay authority, and evidence jurisdiction. It defines the cross-border trust boundaries governing how domain findings interact, and prohibits the constitutional pathologies of regulator flattening, cross-regime equivalence assumptions, universal admissibility assumptions, and replay authority collapse.

Symphony operates across eight regulatory sovereignty domains simultaneously. These domains are orthogonal: they derive their authority from independent legal instruments, govern constitutionally distinct classes of questions, and produce findings that are non-comparable without a defined cross-domain arbitration protocol. This document is the canonical map of those domains and their constitutional relationships.

This document is grounded in verified legal and regulatory facts as of the date of its generation. Where specific regulatory instruments are cited, those citations reflect the current state of the regulatory framework. Regulatory frameworks evolve; the constitutional structure defined herein is designed to accommodate evolution through version-controlled interpretation pack updates, not through structural revision of this document.

---

## Constitutional Scope

This document governs:

1. The definition and boundary of each of Symphony's eight regulatory sovereignty domains.
2. The veto, admissibility, provenance, replay, and evidence jurisdiction authority assigned to each domain.
3. The cross-border trust boundaries governing domain interaction.
4. The admissibility partitioning doctrine preventing cross-regime equivalence assumptions.
5. The replay-jurisdiction mappings establishing which domain's standards govern replay reconstruction of artifacts produced within that domain.

This document does NOT govern:

1. The internal content of any specific interpretation pack for any regulatory domain (governed by the pack itself).
2. The technical enforcement mechanisms of Symphony's DB substrate (governed by source migrations and the Canonical Capability Report).
3. Phase transition criteria (governed by phase lifecycle constitutional documents).
4. The specific task generation requirements derived from this boundary map (governed by TASK_GENERATION_CONSTITUTION.md).

---

## Part I: Regulatory Sovereignty Framework

### 1.1 Foundational Principle: Regulators as Orthogonal Sovereign Domains

Each regulator operating within Symphony's ecosystem is a constitutionally distinct sovereignty domain. This is not an administrative categorization. It is a constitutional determination with the following implications:

(a) A regulator's authority derives from its enabling legal instrument — a national statute, an international treaty, a bilateral agreement, or an independent standards body's governance charter. Symphony does not create or delegate this authority; it provides the substrate within which the authority operates.

(b) A regulator's findings — approvals, rejections, authorizations, certifications — are sovereign within their defined domain and do not automatically extend to, imply, or substitute for findings in any other domain.

(c) When two regulatory domains produce findings about the same artifact or project, neither finding overrides or qualifies the other. Each is sovereign within its plane. The artifact carries both findings simultaneously as distinct constitutional statuses.

(d) Traversal of a regulatory sovereignty boundary requires an explicitly defined cross-domain protocol. Absent such a protocol, findings from one domain MUST NOT be used to satisfy requirements in another.

### 1.2 The Eight Regulatory Sovereignty Domains

Symphony's operations engage the following eight regulatory sovereignty domains:

| Domain ID | Regulator | Legal Instrument | Sovereignty Type |
|---|---|---|---|
| RSD-ZM-1 | Ministry of Green Economy and Environment (MGEE) / A6 Secretariat | Zambia SI 5 of 2026 (Green Economy and Climate Change (Carbon Market) Regulations, 2026) | National Carbon Market Regulatory Sovereignty |
| RSD-ZM-2 | Zambia Environmental Management Agency (ZEMA) | Environmental Management Act No. 12 of 2011 | National Environmental Regulatory Sovereignty |
| RSD-ZM-3 | Bank of Zambia (BoZ) | Bank of Zambia Act, Banking and Financial Services Act | National Financial Regulatory Sovereignty |
| RSD-ZM-4 | Office of the Data Protection Commissioner (DPC) | Data Protection Act No. 3 of 2021 | National Data Sovereignty |
| RSD-INT-1 | UNFCCC / Paris Agreement Article 6 Counterparty States | Paris Agreement Article 6.2, Article 6.4; Decision 3/CMA.3 | International Climate Treaty Sovereignty |
| RSD-INT-2 | Verra (Verified Carbon Standard) | VCS Program Rules and Methodology Requirements | Independent Standards Body Sovereignty |
| RSD-INT-3 | Gold Standard Foundation | Gold Standard for the Global Goals (GS4GG) | Independent Standards Body Sovereignty |
| RSD-INT-4 | European Commission / CBAM Authority | Regulation (EU) 2023/956 as amended by Regulation (EU) 2025/2083 | Supranational Trade Regulatory Sovereignty |

---

## Part II: Constitutional Domain Profiles

Each domain is profiled across six authority dimensions: operational authority, provenance authority, admissibility authority, replay authority, veto authority, and evidence jurisdiction.

---

### Domain RSD-ZM-1: MGEE / A6 Secretariat — National Carbon Market Regulatory Sovereignty

**Legal instrument:** Statutory Instrument No. 5 of 2026, Green Economy and Climate Change (Carbon Market) Regulations, 2026 (the "SI 5 Regulations"), enacted under the Green Economy and Climate Change Act, 2024.

**Institutional seat:** Ministry of Green Economy and Environment (MGEE), Article 6 Secretariat, Technical Subcommittee on Climate Change (TSCCC).

**Operational authority:**
MGEE/A6 Secretariat exercises operational authority over: (a) the authorization of Activity Proponents (APs) to develop mitigation activities; (b) the issuance of Letters of No Objection (LNOs) and full Authorizations for Article 6.2 participation; (c) the corresponding adjustment (CA) process that applies sovereign accounting adjustments to ITMOs transferred internationally; (d) the national carbon registry's issuance, transfer, and retirement functions; (e) the Share of Proceeds (SOP) fee collection mechanism; (f) the approval of Designated Operational Entities (DOEs) as validation and verification bodies.

**Provenance authority:**
MGEE/A6 Secretariat holds provenance authority over the governmental authorization chain of any ITMO produced in Zambia: the LNO, the Authorization letter, and the corresponding adjustment record together constitute the governmental provenance of the ITMO. No ITMO produced in Zambia carries valid international provenance without this chain.

**Admissibility authority:**
MGEE/A6 Secretariat controls Article 6 admissibility — whether a mitigation outcome is admissible as an ITMO for international transfer under the Paris Agreement. This admissibility is independent of and does not substitute for methodology admissibility (Verra/Gold Standard), financial admissibility (BoZ), or EU trade admissibility (CBAM).

**Replay authority:**
SI 5 Regulations require transparent, auditable project records throughout the project lifecycle (MAIN phase, MADD phase, Implementation phase). Replay authority for Zambia-jurisdiction ITMOs rests with MGEE: the reconstruction of the authorization chain and corresponding adjustment history uses MGEE's national carbon registry records as the authoritative historical source.

**Veto authority:**
MGEE holds a **national sovereign veto** over all ITMOs and voluntary carbon credits produced in Zambia. A mitigation activity that has not received MGEE authorization cannot produce constitutionally valid credits for international transfer regardless of its methodology compliance. This veto is pre-eminent within Zambia's national jurisdiction.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: authorization documents (LNO, Authorization letter), project design documents (MAIN, MADD), monitoring reports, verification reports from approved DOEs, corresponding adjustment records, and national registry transaction logs.

**Key regulatory distinctions for Symphony:**
- SI 5 of 2026 distinguishes between: purely voluntary carbon market (VCM) projects (not subject to Article 6 CA), VCM projects with Article 6 labelling (subject to CA and MGEE authorization), and standalone Article 6.2 projects. Symphony's interpretation pack for this domain MUST distinguish these three categories because their admissibility requirements differ materially.
- The TSCCC is the technical body that reviews MAINs and MADDs; the MGEE Minister issues Authorizations. Symphony records must preserve this institutional distinction in provenance records.
- SOP payment is a statutory obligation under SI 5; its receipt constitutes an MGEE-jurisdiction financial event that intersects with BoZ financial regulatory jurisdiction (RSD-ZM-3).

---

### Domain RSD-ZM-2: ZEMA — National Environmental Regulatory Sovereignty

**Legal instrument:** Environmental Management Act No. 12 of 2011, administered by the Zambia Environmental Management Agency (ZEMA), an independent statutory body.

**Operational authority:**
ZEMA exercises operational authority over: (a) Environmental Impact Assessments (EIAs) — any project likely to significantly affect the environment requires ZEMA EIA approval before implementation; (b) Environmental Project Briefs (EPBs) for smaller projects; (c) environmental permits and licences for activities affecting air, water, land, and biodiversity; (d) compliance monitoring and enforcement; (e) Do No Significant Harm (DNSH) assessment for projects seeking carbon market access.

**Provenance authority:**
ZEMA holds provenance authority over the environmental compliance chain of any carbon project: EIA approval certificates and environmental permits constitute the ZEMA provenance record. A project without a valid ZEMA approval carries no environmental compliance provenance regardless of its carbon methodology certification.

**Admissibility authority:**
ZEMA controls environmental admissibility — whether a project is operationally lawful under Zambia's environmental laws. ZEMA admissibility is a constitutional prerequisite for MGEE authorization (no LNO without environmental compliance) but is constitutionally distinct from MGEE's carbon market admissibility determination. Environmental compliance does not confer carbon market authorization; carbon market authorization does not excuse environmental non-compliance.

**Replay authority:**
ZEMA's compliance records — EIA approvals, monitoring reports, enforcement actions — constitute the environmental compliance history of a project. Replay reconstruction of a project's environmental status requires ZEMA records from the relevant compliance period, using the regulatory standards in force at the time.

**Veto authority:**
ZEMA holds an **environmental compliance hard veto** over project implementation. A project that has not received ZEMA EIA approval cannot lawfully operate in Zambia, and any carbon credits generated by an unlawfully operating project are constitutionally inadmissible for both national and international purposes.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: EIA approval certificates, Environmental Project Brief approvals, environmental impact statements, monitoring compliance reports, enforcement notices and resolution records, biodiversity impact assessments, DNSH certification records.

**Key regulatory distinctions for Symphony:**
- ZEMA's mandate under the Environmental Management Act is distinct from MGEE's mandate under the Green Economy and Climate Change Act. ZEMA governs environmental lawfulness; MGEE governs carbon market participation. A project may satisfy ZEMA requirements without being eligible for carbon market participation (and vice versa is impossible — carbon market participation requires prior ZEMA clearance).
- Symphony's ZEMA interpretation pack must not conflate ZEMA's EIA approval with MGEE's project authorization. These are sequential but distinct administrative acts from distinct sovereign authorities.

---

### Domain RSD-ZM-3: Bank of Zambia (BoZ) — National Financial Regulatory Sovereignty

**Legal instrument:** Bank of Zambia Act, Chapter 360 of the Laws of Zambia; Banking and Financial Services Act No. 7 of 2017; applicable AML/CFT regulations; Green Loans Guidelines (2023).

**Operational authority:**
BoZ exercises operational authority over: (a) the financial integrity of transactions involving carbon credit proceeds flowing through Zambian financial institutions; (b) AML/CFT compliance for carbon market financial flows, including SOP payments, ITMO transfer proceeds, and green bond proceeds; (c) foreign exchange control over international financial flows from carbon credit sales; (d) the regulatory framework for green finance instruments, including green loans and green bonds; (e) oversight of fintech and digital payment systems that handle carbon market financial flows.

**Provenance authority:**
BoZ holds financial provenance authority: the legitimacy of a financial transaction involving carbon credit proceeds is a BoZ-jurisdiction question. The source of funds, the compliance of the transaction with AML/CFT requirements, and the foreign exchange reporting of international proceeds are BoZ provenance questions. A financially compliant ITMO transaction has BoZ-certified financial provenance distinct from its environmental provenance (ZEMA) and its carbon market provenance (MGEE).

**Admissibility authority:**
BoZ controls financial admissibility — whether financial flows associated with carbon market activities are admissible within Zambia's financial regulatory framework. Financial inadmissibility (e.g., AML/CFT non-compliance) can block the settlement of an otherwise environmentally and methodologically compliant carbon transaction.

**Replay authority:**
BoZ's transaction records, AML/CFT compliance records, and foreign exchange reporting records constitute the financial compliance history. Replay reconstruction of a carbon transaction's financial legitimacy requires BoZ-jurisdiction records, using the financial regulations in force at the time of the transaction.

**Veto authority:**
BoZ holds a **financial compliance veto** over the settlement of carbon market financial flows. A transaction that fails AML/CFT requirements cannot be settled through Zambian financial institutions regardless of its carbon market validity. BoZ's veto operates at the settlement layer; it does not retroactively invalidate the carbon credit itself (which remains in MGEE's jurisdiction) but blocks its financial proceeds.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: transaction settlement records, AML/CFT compliance certifications, foreign exchange reporting records, green loan and green bond compliance records, financial institution approval records.

**Key regulatory distinctions for Symphony:**
- BoZ's authority covers financial flows; it does not cover carbon credit issuance, environmental compliance, or methodology certification. A financially compliant transaction can involve a methodologically deficient carbon credit. These are distinct sovereign determinations.
- The intersection point between BoZ and MGEE jurisdiction is the SOP payment: SOP is a statutory financial obligation owed to MGEE, paid through BoZ-regulated channels. Symphony must record SOP payment as both a MGEE-jurisdiction compliance event (carbon market) and a BoZ-jurisdiction financial event.
- Green Loans Guidelines (2023) create a BoZ-regulated framework for loans with environmental use-of-proceeds requirements that intersects with ZEMA's environmental compliance requirements. Symphony's handling of green loan disbursements must preserve both jurisdictional records independently.

---

### Domain RSD-ZM-4: Office of the Data Protection Commissioner (DPC) — National Data Sovereignty

**Legal instrument:** Data Protection Act No. 3 of 2021 (DPA), enforcement commenced March 2025.

**Operational authority:**
The DPC exercises operational authority over: (a) the registration of data controllers and licensing of data auditors; (b) the lawfulness of personal data collection, processing, storage, and transfer by Symphony operating in Zambia; (c) mandatory data protection impact assessments (DPIAs) for high-risk processing; (d) cross-border personal data transfer authorization; (e) enforcement of data subjects' rights (access, correction, erasure, objection); (f) 24-hour breach notification obligations.

**Data localisation authority:**
The DPA imposes a **data localisation requirement**: personal data must be processed and stored within a server or data center in Zambia. Sensitive personal data must always remain in Zambia regardless of ministerial exemptions. Cross-border transfers of non-sensitive personal data require: data subject consent plus DPC-approved standard contracts or intra-group schemes, OR ministerial prescription, OR DPC authorization for specific categories.

**Provenance authority:**
The DPC holds data provenance authority: the lawfulness of the processing history of any personal data that Symphony handles as a data controller is a DPC-jurisdiction question. Processing that occurred without a lawful basis (consent, contract, legal obligation, vital interests, public task, or legitimate interests) carries no lawful data provenance regardless of its technical accuracy.

**Admissibility authority:**
DPC controls data admissibility — whether personal data held in Symphony's substrate was collected and processed lawfully under the DPA and is admissible as evidence in proceedings that require lawfully obtained personal data.

**Replay authority:**
The DPA's record-keeping requirements (data controllers must maintain records of processing activities) create a DPC-jurisdiction replay record. Replay of data processing history for compliance verification must use records consistent with the DPA's record-keeping requirements in force at the time of processing.

**Veto authority:**
The DPC holds a **data sovereignty veto** over cross-border transfers of personal data. No personal data about Zambian data subjects may be transferred outside Zambia by Symphony without DPC authorization (or the conditions specified in sections 70-71 of the DPA being satisfied). This veto applies to Symphony's evidentiary data exports, including any transfer of project participant data, community data, or beneficiary data to international verification bodies or acquiring party states.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: data controller registration records, DPIA records, processing activity records, data subject rights request records, cross-border transfer authorization records, breach notification records.

**Key regulatory distinctions for Symphony:**
- The DPA applies to personal data. Not all data that Symphony processes is personal data. Symphony's operational monitoring data (sensor readings, measurement values, GPS coordinates without individual identifiers) may fall outside DPA scope. Symphony's community benefit data (names, household identifiers, community participation records) is squarely within DPA scope.
- Data localisation creates an architectural constraint on Symphony: personal data about Zambian data subjects held in Symphony's substrate must be stored on infrastructure located within Zambia. Symphony's multi-region data architecture must preserve this partition.
- DPC authority is orthogonal to all carbon market regulatory authorities. A project's data processing can be DPA-compliant and carbon-market-non-compliant simultaneously. Data compliance does not establish carbon market compliance.

---

### Domain RSD-INT-1: Paris Agreement Article 6 Counterparty States — International Climate Treaty Sovereignty

**Legal instrument:** Paris Agreement (2015), specifically Articles 6.2 and 6.4; Decision 3/CMA.3 (Glasgow Rulebook, 2021); subsequent CMA decisions on Article 6 operational modalities.

**Institutional structure:**
Article 6.2 operates through bilateral and multilateral cooperative arrangements between Parties. The acquiring party state (the state that receives the ITMO) and the host party state (Zambia, in Symphony's context) are both sovereign parties to Article 6.2 arrangements. Each party state is a distinct sovereignty domain within this mapping. UNFCCC's Article 6.4 Supervisory Body governs the multilateral mechanism.

**Operational authority:**
Acquiring party states exercise operational authority over: (a) the acceptance or rejection of ITMOs for use toward their NDC; (b) the recognition of Zambia's corresponding adjustment as valid for their accounting purposes; (c) the determination of whether ITMO characteristics (vintage, sector, project type) satisfy their NDC accounting requirements; (d) the approval of Authorized Participants in their jurisdiction who may hold and retire ITMOs.

**Provenance authority:**
International treaty sovereignty over provenance is distributed: Zambia holds provenance authority over the origin of the ITMO (MGEE); the acquiring party state holds provenance authority over the ITMO's accounting status in the acquiring party's NDC registry; the UNFCCC International Registry holds provenance authority over the transfer record.

**Admissibility authority:**
Each acquiring party state holds sovereign admissibility authority over whether ITMOs satisfy that state's NDC accounting requirements. Switzerland's admissibility requirements for ITMOs differ from Japan's, which differ from Singapore's. No acquiring party state's acceptance creates any presumption of acceptance by another. Each bilateral Article 6.2 arrangement defines its own admissibility criteria.

**Replay authority:**
The UNFCCC International Registry maintains the authoritative transfer ledger. Replay reconstruction of ITMO transfer history uses UNFCCC registry records as the international authoritative source, supplemented by Zambia's national carbon registry records (MGEE jurisdiction) and the acquiring party's national registry records.

**Veto authority:**
Each acquiring party state exercises a **bilateral treaty veto** over the recognition of a specific Zambia-origin ITMO. Zambia may have validly issued an ITMO (satisfying MGEE authority), the credit may be methodologically valid (satisfying Verra or Gold Standard authority), and the transaction may be financially valid (satisfying BoZ authority) — yet the acquiring party may decline to accept the ITMO against its NDC based on its own sovereign assessment.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: Authorization for Participation (AP) documents, Cooperative Approach agreements between Zambia and acquiring parties, ITMO transfer records in UNFCCC International Registry, corresponding adjustment records in both national registries, NDC accounting records in acquiring party registries.

**Key regulatory distinctions for Symphony:**
- Article 6.2 ITMOs and Article 6.4 ERs (Emission Reductions under the multilateral mechanism) are constitutionally distinct instruments governed by different institutional arrangements, though both originate under the Paris Agreement. Symphony's interpretation packs must distinguish these.
- The VCM-to-Article-6 migration pathway (for projects transitioning from voluntary to Article 6 status) creates a cross-domain jurisdictional transition that requires simultaneous satisfaction of Verra/Gold Standard (RSD-INT-2/3) and MGEE/Article 6 (RSD-ZM-1/RSD-INT-1) requirements. This transition is not a substitution of one domain for another; both must be satisfied concurrently during the transition.
- Article 6 counterparty states are NOT equivalent to each other. Switzerland's Article 6.2 arrangement with Zambia creates a bilateral treaty sovereignty that is distinct from and non-interchangeable with any other acquiring party's arrangement.

---

### Domain RSD-INT-2: Verra (Verified Carbon Standard Program) — Independent Standards Body Sovereignty

**Legal instrument:** VCS Program Rules v4.x; applicable VCS methodologies; Verra's validation and verification (V&V) requirements; AFOLU Non-Permanence Risk Tool (NPRT).

**Operational authority:**
Verra exercises operational authority over: (a) the acceptance of project concept notes (PCNs) and registration of VCS projects; (b) the approval of VCS methodologies applicable to Zambian project types; (c) the accreditation and oversight of validation and verification bodies (VVBs); (d) the issuance of Verified Carbon Units (VCUs) in the Verra Registry; (e) the non-permanence risk buffer pool management for AFOLU projects; (f) AFOLU project area monitoring requirements.

**Verra's recognized status in Zambia:** Verra's VCS Program has been explicitly recognized in Zambia's Carbon Market Framework (published 2025) for its carbon accounting methodologies and non-permanence risk tool in the AFOLU sector. This recognition creates a defined intersection between Verra's standards body sovereignty (RSD-INT-2) and MGEE's national carbon market sovereignty (RSD-ZM-1).

**Provenance authority:**
Verra holds methodology provenance authority: the determination that a VCU was produced by a project using an approved VCS methodology, verified by an accredited VVB, and registered in Verra's registry constitutes Verra-jurisdiction provenance. Verra's registry record is the authoritative source for VCU provenance within the VCS program.

**Admissibility authority:**
Verra controls methodology admissibility — whether a project's emission reduction or removal quantification methodology is acceptable under VCS program rules. A project may be legally authorized (MGEE), environmentally compliant (ZEMA), and financially sound (BoZ) while being methodology-inadmissible in the Verra system (e.g., using an unapproved baseline or an expired methodology version).

**Replay authority:**
Verra's registry maintains a transaction history for each VCU. Replay reconstruction of a VCU's issuance and retirement history uses Verra registry records as the authoritative Verra-domain source. The applicable VCS methodology version at the time of issuance is the operative standard for replay — later methodology revisions do not retroactively govern prior issuances.

**Veto authority:**
Verra exercises a **methodology compliance veto** over VCU issuance. A project that fails VCS methodology compliance — incorrect baseline determination, inadequate additionality demonstration, insufficient monitoring plan — will not receive VCUs from Verra regardless of its national regulatory status. Verra's veto is methodology-specific; it does not block MGEE authorization (which Zambia may grant independently), but it prevents VCS-labeled credit issuance.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: Project Design Documents (PDDs), monitoring reports, verification reports from accredited VVBs, Verra registry issuance records, buffer pool contribution records, AFOLU NPRT assessments, AFOLU project area delineation records.

**Key regulatory distinctions for Symphony:**
- Verra VCUs and MGEE-authorized ITMOs are not the same instrument. A VCU becomes an ITMO only if: the project has received MGEE authorization AND the corresponding adjustment has been applied AND the ITMO has been transferred to the UNFCCC International Registry. VCU status in the Verra registry does not confer ITMO status.
- Verra's Reg 26 analogue: VCS program rules require that the validation body and verification body for a project must be different entities. Symphony's `check_reg26_separation()` enforcement is constitutionally consistent with this requirement but must be understood as Symphony's platform-level implementation of a principle that Verra also independently enforces at the methodology level. The two enforcement surfaces serve the same principle but are constitutionally distinct and independently operative.
- Verra's buffer pool for non-permanence risk creates a deferred liability that is Verra-jurisdiction: Verra may draw from the buffer pool to address reversal events. This contingent liability exists in Verra's sovereignty domain and is not resolved by MGEE authorization or BoZ compliance.

---

### Domain RSD-INT-3: Gold Standard Foundation — Independent Standards Body Sovereignty

**Legal instrument:** Gold Standard for the Global Goals (GS4GG) Standard, Version 1.2+; Gold Standard Principles and Requirements; applicable Gold Standard methodologies; Gold Standard Impact Registry.

**Operational authority:**
Gold Standard exercises operational authority over: (a) the certification of projects under GS4GG; (b) the approval of Gold Standard-compliant methodologies and technologies; (c) the issuance of Verified Emission Reductions (VERs) and other Gold Standard credit types in the Gold Standard Impact Registry; (d) the accreditation of validation and verification bodies approved by Gold Standard; (e) the sustainable development monitoring requirements including SDG Impact Claims.

**Provenance authority:**
Gold Standard holds methodology provenance authority over GS4GG-certified projects: the determination that a VER was produced under an approved Gold Standard methodology, verified by an approved auditor, and registered in the Gold Standard Impact Registry constitutes Gold Standard-jurisdiction provenance.

**Admissibility authority:**
Gold Standard controls GS4GG methodology admissibility and sustainable development admissibility — whether a project meets Gold Standard's requirements for both emission reduction quantification AND demonstrated co-benefits aligned with the Sustainable Development Goals. Gold Standard admissibility is two-dimensional: environmental integrity AND sustainable development. A project may be Verra-admissible (environmental integrity only) and not Gold Standard-admissible (insufficient SDG co-benefits), or vice versa.

**Replay authority:**
Gold Standard Impact Registry records constitute the authoritative Gold Standard-domain source for replay reconstruction. The applicable GS4GG standard version at the time of certification governs replay — later standard revisions do not retroactively apply.

**Veto authority:**
Gold Standard exercises a **methodology and SDG compliance veto** over VER issuance under its program. Its veto authority is independent of and non-interchangeable with Verra's veto authority. A project may satisfy Verra's requirements and fail Gold Standard's SDG co-benefit requirements, or vice versa.

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: Gold Standard Project Design Documents, monitoring and evaluation reports, verification reports from Gold Standard-approved auditors, SDG Impact Claim evidence, Gold Standard Impact Registry records.

**Key regulatory distinctions for Symphony:**
- Gold Standard and Verra are alternative — not cumulative — certification paths for most projects. A project typically seeks certification under one program. However, some projects pursue dual certification. Symphony must maintain separate, independent registry records for each certification path without conflating their findings.
- Gold Standard's SDG Impact Claims framework creates an evidence category that has no direct Verra equivalent: evidence that a project is producing specific, measurable sustainable development outcomes. This evidence serves a distinct admissibility purpose (impact investor requirements, development finance institution requirements) that is separate from carbon market admissibility.
- Gold Standard's VERs are not, by default, ITMOs. The same VCM-to-Article-6 migration pathway that applies to Verra credits applies to Gold Standard credits: MGEE authorization and corresponding adjustment are required.

---

### Domain RSD-INT-4: European Commission / CBAM Authority — Supranational Trade Regulatory Sovereignty

**Legal instrument:** Regulation (EU) 2023/956 establishing the Carbon Border Adjustment Mechanism as amended by Regulation (EU) 2025/2083 (Omnibus simplification), in definitive force from 1 January 2026. Certificate price as of Q1 2026: €75.36/tCO₂e.

**Scope of CBAM goods (current):** Iron and steel, aluminium, cement, fertilisers, traded electricity, hydrogen, and specific downstream products.

**CBAM is emphatically NOT a carbon credit market.** CBAM is a certificate-based trade mechanism that equalises the carbon cost between goods produced inside the EU under the EU ETS and equivalent goods imported from third countries without comparable carbon pricing. CBAM certificates are not carbon credits; they do not certify emission reductions; they certify the carbon cost adjustment obligation of an EU importer.

**Operational authority:**
CBAM authority exercises operational authority over: (a) the authorization of CBAM declarants; (b) the verification of embedded emissions calculations in imported CBAM goods; (c) the issuance, pricing, and surrender of CBAM certificates; (d) the recognition (or non-recognition) of carbon prices effectively paid in third countries (deduction mechanism); (e) enforcement of annual CBAM declarations (first due May 2027 for 2026 imports); (f) the de minimis threshold (50 tonnes per calendar year) determining declarant obligation.

**Provenance authority:**
CBAM authority holds embedded emissions provenance authority: whether a specific imported product's embedded greenhouse gas emissions have been accurately calculated and third-party verified according to CBAM's implementing regulations. This is a product-level provenance determination, not a project-level provenance determination.

**Admissibility authority:**
CBAM authority controls trade admissibility — whether a CBAM-scope product imported into the EU satisfies CBAM's embedded emissions reporting and certificate surrender requirements. CBAM admissibility is trade-specific: it governs whether goods may be placed on the EU market, not whether carbon credits may be recognized or used.

**Deduction mechanism:** If a carbon price has been effectively paid in the country of origin for CBAM goods, the corresponding amount may be deducted from CBAM certificate obligations. This creates a potential intersection between Zambia's national carbon pricing mechanism (to the extent one applies to CBAM-scope goods exported to the EU) and CBAM obligations. As of 2026, Zambia does not have a national carbon tax or ETS; however, voluntary carbon market purchases by Zambian manufacturers do NOT qualify for CBAM deduction. Only mandatory carbon prices effectively paid qualify.

**Replay authority:**
CBAM records — annual CBAM declarations, embedded emissions verification records, certificate surrender records — must be retained for at least four years (CBAM Regulation). Replay reconstruction of CBAM compliance history uses these records against the CBAM implementing regulations in force at the time of the relevant import period.

**Veto authority:**
CBAM authority holds a **EU market access veto** over imports of CBAM goods that fail to comply with CBAM requirements. Non-compliant CBAM declarants face financial penalties and may be prevented from placing goods on the EU market. This veto is trade-specific: it does not affect the validity of any carbon credit produced in Zambia (which is governed by MGEE, Verra, or Gold Standard authority).

**Evidence jurisdiction:**
Primary evidence jurisdiction covers: embedded emissions calculation methodologies and actual measurements, third-party verification reports for embedded emissions (by accredited EU-framework verifiers), CBAM declarant registration records, annual CBAM declaration records, CBAM certificate purchase and surrender records, carbon price deduction documentation.

**Key regulatory distinctions for Symphony:**
- **CBAM and carbon credits are constitutionally separate domains.** A Zambian manufacturer who sells carbon credits AND exports CBAM goods to the EU is subject to two entirely distinct regulatory regimes for those two activities. The carbon credits do not offset CBAM obligations. The CBAM certificates do not represent carbon credits. These are orthogonal sovereignty domains.
- CBAM's embedded emissions verification is performed by EU-accredited third-party verifiers under EU implementing regulations — not by Verra, Gold Standard, or ZEMA-approved DOEs. The verifier accreditation regime is distinct across these domains.
- Symphony's role in relation to CBAM is as an MRV infrastructure platform that may support the embedded emissions data collection and chain-of-custody documentation required by CBAM. This role does not make Symphony a CBAM declarant or CBAM authority. Symphony's data outputs are inputs to the EU importer's CBAM compliance process; they do not substitute for the importer's CBAM certificate obligations.
- The current CBAM scope (iron/steel, aluminium, cement, fertilisers, electricity, hydrogen) does not directly include carbon credits or forestry outputs. However, CBAM's 2027 review may extend scope. Symphony must be architected to accommodate scope extension without structural revision.

---

## Part III: Sovereignty Matrix

The following matrix maps each regulatory sovereignty domain against six authority dimensions. Each cell contains one of: **PRIMARY** (this domain holds primary constitutional authority), **PARTIAL** (this domain holds partial or conditional authority), **NONE** (this domain holds no authority), or **INTERSECTS** (authority intersects with another domain through a defined protocol).

### 3.1 Authority Dimension Matrix

| Domain | Operational Authority | Provenance Authority | Admissibility Authority | Replay Authority | Veto Authority | Evidence Jurisdiction |
|---|---|---|---|---|---|---|
| RSD-ZM-1 (MGEE/A6) | PRIMARY — carbon market operations | PRIMARY — ITMO authorization chain | PRIMARY — Article 6 admissibility | PRIMARY — national registry | SOVEREIGN VETO — national carbon market | PRIMARY — project authorization, registry |
| RSD-ZM-2 (ZEMA) | PRIMARY — environmental compliance | PRIMARY — EIA compliance chain | PRIMARY — environmental admissibility | PRIMARY — EIA compliance history | HARD VETO — environmental compliance | PRIMARY — EIA, permits, monitoring |
| RSD-ZM-3 (BoZ) | PRIMARY — financial flows | PRIMARY — financial compliance | PRIMARY — financial admissibility | PRIMARY — transaction records | FINANCIAL VETO — settlement | PRIMARY — transaction, AML/CFT records |
| RSD-ZM-4 (DPC) | PRIMARY — personal data processing | PRIMARY — lawful processing chain | PRIMARY — data admissibility | PRIMARY — processing records | DATA SOVEREIGNTY VETO — cross-border | PRIMARY — processing records, DPIAs |
| RSD-INT-1 (A6 States) | PARTIAL — acquiring party recognition | PRIMARY — distributed across UNFCCC + states | PRIMARY — NDC accounting admissibility | PRIMARY — UNFCCC registry | BILATERAL TREATY VETO — per counterparty | PRIMARY — bilateral agreements, UNFCCC registry |
| RSD-INT-2 (Verra) | PRIMARY — within VCS program | PRIMARY — VCU issuance and registry | PRIMARY — VCS methodology admissibility | PRIMARY — Verra registry | METHODOLOGY VETO — VCU issuance | PRIMARY — PDDs, VERs, registry |
| RSD-INT-3 (Gold Standard) | PRIMARY — within GS4GG program | PRIMARY — VER issuance and registry | PRIMARY — GS4GG methodology + SDG admissibility | PRIMARY — GS4GG registry | METHODOLOGY + SDG VETO — VER issuance | PRIMARY — PDDs, SDG claims, registry |
| RSD-INT-4 (CBAM) | PRIMARY — EU market access for goods | PRIMARY — embedded emissions | PRIMARY — EU trade admissibility for CBAM goods | PRIMARY — CBAM declaration records | EU MARKET ACCESS VETO — CBAM goods | PRIMARY — embedded emissions, certificates |

---

### 3.2 Admissibility Partitioning Matrix

The following matrix defines which admissibility question each domain governs, and explicitly declares which questions it does NOT govern. This matrix enforces the prohibition on cross-regime equivalence assumptions.

| Admissibility Question | Governing Domain | Explicitly NOT Governed By |
|---|---|---|
| May this mitigation activity be authorized for carbon market participation in Zambia? | RSD-ZM-1 (MGEE) | ZEMA, BoZ, DPC, Verra, Gold Standard, CBAM, A6 States |
| Is this project environmentally lawful in Zambia? | RSD-ZM-2 (ZEMA) | MGEE, BoZ, DPC, Verra, Gold Standard, CBAM, A6 States |
| Is this carbon transaction financially compliant in Zambia? | RSD-ZM-3 (BoZ) | MGEE, ZEMA, DPC, Verra, Gold Standard, CBAM, A6 States |
| Is this personal data processing lawful in Zambia? | RSD-ZM-4 (DPC) | MGEE, ZEMA, BoZ, Verra, Gold Standard, CBAM, A6 States |
| Is this ITMO admissible for Country X's NDC accounting? | RSD-INT-1 (Country X state) | All other domains — each acquiring state determines independently |
| Is this project's emission quantification valid under VCS methodology? | RSD-INT-2 (Verra) | MGEE, ZEMA, BoZ, DPC, Gold Standard, CBAM, A6 States |
| Does this project meet GS4GG methodology and SDG co-benefit requirements? | RSD-INT-3 (Gold Standard) | MGEE, ZEMA, BoZ, DPC, Verra, CBAM, A6 States |
| Is this CBAM good compliant for EU market access? | RSD-INT-4 (CBAM) | MGEE, ZEMA, BoZ, DPC, Verra, Gold Standard, A6 States |

---

### 3.3 Veto Matrix

This matrix defines the veto authority of each domain, its scope, and what it does NOT veto.

| Domain | Veto Type | Veto Scope | Does NOT Veto |
|---|---|---|---|
| RSD-ZM-1 (MGEE) | Sovereign national veto | Carbon market participation, ITMO authorization, DOE approval | Environmental lawfulness, financial compliance, data processing, methodology validity, CBAM trade admissibility |
| RSD-ZM-2 (ZEMA) | Environmental hard veto | Project implementation in Zambia, environmental permit conditions | Carbon market authorization, financial flows, data processing, international methodology, CBAM |
| RSD-ZM-3 (BoZ) | Financial compliance veto | Settlement of carbon financial flows through Zambian institutions | Carbon credit validity, environmental compliance, data processing, methodology, CBAM obligations |
| RSD-ZM-4 (DPC) | Data sovereignty veto | Cross-border transfer of Zambian personal data, unlawful data processing | Carbon credit validity, environmental compliance, financial flows, methodology |
| RSD-INT-1 (A6 States) | Bilateral treaty veto | NDC accounting recognition by specific acquiring state | National authorization, environmental compliance, methodology validity in other states' domains |
| RSD-INT-2 (Verra) | Methodology compliance veto | VCS program VCU issuance | National authorization, environmental compliance, financial flows, Gold Standard certification, CBAM |
| RSD-INT-3 (Gold Standard) | Methodology + SDG veto | GS4GG program VER issuance | National authorization, environmental compliance, financial flows, Verra certification, CBAM |
| RSD-INT-4 (CBAM) | EU market access veto | EU import of CBAM goods by non-compliant declarants | Carbon credit validity, national authorization, environmental compliance in Zambia, methodology certification |

---

## Part IV: Cross-Border Trust Boundaries

### 4.1 Defined Cross-Domain Interaction Points

The following cross-domain interactions are constitutionally defined — they occur through a specific, named protocol that allows information from one domain to be used in another without collapsing either domain's sovereignty.

**Interaction CX-001 — ZEMA → MGEE (Sequential Prerequisite):**
ZEMA environmental compliance is a prerequisite for MGEE carbon market authorization. An MGEE LNO will not be issued for a project that lacks ZEMA clearance. This is a sequential dependency, not an authority merger: ZEMA's approval is a factual input to MGEE's authorization decision; it does not make MGEE's decision a ZEMA decision, and MGEE's authorization does not constitute ZEMA approval.

**Interaction CX-002 — MGEE → RSD-INT-2/3 (Recognized Standards):**
Zambia's Carbon Market Framework explicitly recognizes VCS (Verra) and implicitly Gold Standard as approved methodology standards for carbon market projects. This recognition creates a defined interface: a project using an MGEE-recognized methodology methodology may proceed through MGEE's authorization process. Recognition does not make Verra a subordinate of MGEE, nor does MGEE authorization constitute Verra certification.

**Interaction CX-003 — Verra/Gold Standard → MGEE → RSD-INT-1 (VCM-to-Article-6 Migration Path):**
A VCM project (Verra or Gold Standard certified) may migrate to Article 6 status by: (a) obtaining MGEE authorization for Article 6.2 participation, (b) applying a corresponding adjustment to the credits used for international transfer, (c) transferring to the UNFCCC International Registry. This migration crosses three domains simultaneously. Each domain's requirements must be satisfied independently; satisfaction of one does not substitute for another.

**Interaction CX-004 — MGEE + BoZ (SOP Payment):**
The statutory Share of Proceeds payment under SI 5 of 2026 creates an interaction between MGEE's carbon market authority and BoZ's financial authority. SOP is owed to MGEE; it is paid through BoZ-regulated channels. Symphony must record SOP compliance as two distinct events: a MGEE-jurisdiction carbon market compliance event and a BoZ-jurisdiction financial transaction event.

**Interaction CX-005 — DPC → All Domains (Data Layer Constraint):**
Personal data generated by operations in any other regulatory domain (MGEE project records, ZEMA EIA participant data, BoZ transaction records, Verra project community data) is simultaneously subject to DPC authority. DPC jurisdiction runs transversally across all other domains: it governs the personal data dimension of every cross-domain operation without collapsing any other domain's authority.

**Interaction CX-006 — Verra/Gold Standard → RSD-INT-4 (CBAM Intersection — Limited):**
CBAM's embedded emissions verification is not the same as Verra or Gold Standard certification. CBAM does not recognize VCUs or VERs as embedded emissions offsets. A Zambian manufacturer who is a Verra project proponent may not deduct VCU retirements from CBAM obligations. However: if a Zambian manufacturer uses cleaner production processes whose emissions reductions are documented through Verra-compatible MRV, that documentation may support the embedded emissions calculation for CBAM purposes — as evidence of actual emissions levels, not as a carbon credit offset. This is a data-sharing interface, not an authority merger.

### 4.2 Prohibited Cross-Domain Interactions

The following interactions are constitutionally prohibited because they would collapse distinct sovereignty domains:

**Prohibited CX-P-001 — VCU Retirement as CBAM Compliance:**
A Verra VCU retirement in Zambia does not satisfy, reduce, or substitute for CBAM certificate obligations for EU importers of Zambian CBAM goods. These are instruments in categorically distinct regulatory systems.

**Prohibited CX-P-002 — MGEE Authorization as Verra Certification:**
MGEE national authorization of a mitigation activity does not constitute Verra VCS certification, Gold Standard GS4GG certification, or any methodology admissibility determination. MGEE authorizes national carbon market participation; it does not validate methodology or quantification approach.

**Prohibited CX-P-003 — ZEMA EIA as Carbon Credit Quality Guarantee:**
ZEMA environmental compliance does not constitute a guarantee of carbon credit quality, additionality, or permanence. Environmental lawfulness is a distinct determination from emission reduction validity.

**Prohibited CX-P-004 — BoZ Compliance as Carbon Market Authorization:**
Financial compliance of a carbon transaction does not authorize the underlying carbon credit or validate its environmental integrity. A financially compliant transaction in an invalid carbon credit remains an invalid credit regardless of financial compliance.

**Prohibited CX-P-005 — One Acquiring State's Article 6 Acceptance as Universal:**
One acquiring party state's acceptance of a Zambia-origin ITMO under a bilateral Article 6.2 arrangement does not make that ITMO acceptable to any other acquiring party state. Each bilateral arrangement is a distinct sovereignty relationship.

**Prohibited CX-P-006 — DPA Compliance as Cross-Domain Data Authorization:**
Satisfying DPC requirements for data processing does not authorize the use of that data in other regulatory domains without those domains' own authorization requirements being met.

---

## Part V: Replay-Jurisdiction Mappings

Each regulatory sovereignty domain possesses its own replay jurisdiction — the set of records, standards, and institutional sources that govern the replay reconstruction of compliance history for that domain.

| Domain | Replay Jurisdiction Holder | Authoritative Replay Source | Governing Standard at Time T | Replay Reconstruction Constraint |
|---|---|---|---|---|
| RSD-ZM-1 (MGEE) | MGEE / A6 Secretariat | National Carbon Registry records; Authorization documents | SI 5 of 2026 and predecessor instruments in force at time T | Replay uses registry state at time T; subsequent registry amendments do not retroactively govern |
| RSD-ZM-2 (ZEMA) | ZEMA | EIA approval records; Compliance monitoring records | Environmental Management Act No. 12 of 2011 and applicable regulations in force at time T | Replay uses ZEMA records from relevant compliance period; enforcement context may evolve |
| RSD-ZM-3 (BoZ) | Bank of Zambia | Transaction records; AML/CFT compliance records | BoZ Act and applicable prudential regulations in force at time T | Replay uses BoZ transaction records; financial regulation changes do not retroactively govern prior transactions |
| RSD-ZM-4 (DPC) | Data Protection Commissioner | Processing activity records; DPIAs | Data Protection Act No. 3 of 2021 in force at time T | Replay uses processing records; subsequent DPC guidance does not retroactively govern prior processing |
| RSD-INT-1 (A6 States) | UNFCCC Secretariat + bilateral counterparties | UNFCCC International Registry transfer ledger; bilateral Cooperative Approach records | CMA decisions in force at time T of transfer | Replay uses UNFCCC registry records and bilateral agreement texts in force at time T |
| RSD-INT-2 (Verra) | Verra Foundation | Verra Registry transaction history; verification reports | VCS Program Rules version in force at time T of issuance | Replay uses Verra registry records; methodology revisions do not retroactively govern prior issuances |
| RSD-INT-3 (Gold Standard) | Gold Standard Foundation | Gold Standard Impact Registry; verification reports | GS4GG Standard version in force at time T | Replay uses Gold Standard registry records; standard revisions do not retroactively govern prior certifications |
| RSD-INT-4 (CBAM) | European Commission / national CBAM authorities | CBAM declaration records; certificate surrender records | CBAM Regulation version in force at time T of importation | 4-year record retention required; replay uses records under CBAM rules applicable to the import period |

### 5.1 Replay Authority Prohibition

No domain's replay jurisdiction extends to another domain's records. Specifically:

- MGEE replay authority does not cover Verra registry records (which are Verra's replay jurisdiction). A dispute about a VCU's issuance history is resolved using Verra registry records, not MGEE records.
- Verra replay authority does not cover MGEE's authorization records. A dispute about ITMO authorization is resolved using MGEE records, not Verra records.
- CBAM replay authority does not cover any carbon credit registry. CBAM's replay jurisdiction is limited to embedded emissions in traded goods.

The collapse of replay jurisdictions — treating one domain's records as authoritative for another domain's historical questions — constitutes **replay authority collapse**, which is a constitutionally prohibited pathology under this document.

---

## Part VI: Prohibited Constitutional Pathologies

### 6.1 Regulator Flattening

Regulator flattening occurs when analysis, task generation, or system design treats two or more regulatory sovereignty domains as equivalent, interchangeable, or as expressing the same underlying compliance requirement in different forms.

**Prohibited manifestations:**
- Describing all regulatory requirements as "compliance" without distinguishing which domain's requirements are referenced.
- Treating ZEMA environmental clearance as equivalent to MGEE carbon market authorization.
- Treating Verra VCS certification as equivalent to Article 6 ITMO authorization.
- Treating CBAM certificate compliance as equivalent to carbon credit retirement.
- Treating DPA compliance as satisfying the data requirements of any carbon market regulator.
- Creating a single "compliance status" field that aggregates all domains into one boolean.

**Constitutional correction:** Each regulatory domain's requirements must be tracked, recorded, and reported independently. A project's "compliance status" is a multi-dimensional constitutional status, not a single flag. Symphony's data model MUST preserve this multi-dimensionality.

### 6.2 Universal Admissibility Assumptions

Universal admissibility occurs when analysis assumes that an artifact certified in one regulatory domain is thereby admissible in all domains relevant to its downstream uses.

**Prohibited manifestations:**
- Assuming that MGEE authorization makes a credit acceptable to all acquiring parties.
- Assuming that Verra VCS certification makes a credit CBAM-compliant.
- Assuming that BoZ-compliant financial flows make a transaction valid in all domains.
- Treating a "verified carbon credit" as a universally admissible instrument without specifying which domain's verification and for which downstream use.

**Constitutional correction:** Admissibility determinations are use-specific and domain-specific. Symphony MUST record, separately, which domain has determined admissibility for which use, and MUST NOT produce composite admissibility declarations that span domains.

### 6.3 Cross-Regime Equivalence Assumptions

Cross-regime equivalence occurs when analysis treats two regulatory regimes as covering the same ground, such that compliance with one confers compliance with the other.

**Prohibited manifestations:**
- Treating Verra VCS and Gold Standard as equivalent (they share some principles but are constitutionally distinct domains with distinct veto authority and distinct admissibility determinations).
- Treating different acquiring party states' Article 6.2 arrangements as equivalent to each other.
- Treating MGEE's national authorization as the Article 6 equivalent of Verra certification.
- Treating EU CBAM compliance as carbon pricing equivalent to a national carbon tax for purposes of international carbon market accounting.

**Constitutional correction:** Cross-regime equivalence requires a constitutionally defined equivalence protocol — a bilateral agreement, a formal recognition instrument, or a defined interface. Absent such a protocol, regimes must be treated as orthogonal.

### 6.4 Replay Authority Collapse

Replay authority collapse occurs when historical compliance reconstruction treats records from one regulatory domain as authoritative for another domain's historical questions.

**Prohibited manifestations:**
- Using Verra registry records to reconstruct MGEE authorization history (MGEE records are authoritative for MGEE authority questions).
- Using national registry records to reconstruct UNFCCC International Registry transfer history (UNFCCC registry is authoritative for international transfer history).
- Using CBAM embedded emissions records to reconstruct carbon credit issuance history.
- Using MGEE records as a substitute for BoZ transaction records in AML/CFT compliance reconstruction.

**Constitutional correction:** Each domain's replay jurisdiction is defined in the Replay-Jurisdiction Matrix (Part V). Replay reconstruction MUST use the authoritative source for the domain whose historical question is being answered.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
All eight regulatory sovereignty domains operating within Symphony's ecosystem: RSD-ZM-1 through RSD-ZM-4 (Zambia national domains), and RSD-INT-1 through RSD-INT-4 (international domains). The cross-border trust boundaries between them, the admissibility partitioning of their authority, and the replay-jurisdiction mapping of their historical compliance records.

**Sovereignty domains this document MUST NOT redefine:**
- The operational sovereignty of Wave 4 (runtime enforcement) and provenance sovereignty of Wave 8 (cryptographic enforcement) as defined in SYSTEM_SOVEREIGNTY_MODEL.md. This document maps regulatory sovereignty domains; it does not redefine operational or provenance sovereignty.
- The specific technical enforcement mechanisms in Symphony's DB substrate (governed by source migrations and the Canonical Capability Report).
- The constitutional meaning of foundational concepts such as admissibility, sovereignty, and verifier independence (governed by CONSTITUTIONAL_GLOSSARY.md).
- Phase transition criteria (governed by phase lifecycle constitutional documents).

**Replay obligations preserved:**
Part V of this document defines a Replay-Jurisdiction Mapping for each of the eight regulatory sovereignty domains. The constitutional principle that replay reconstruction uses the standards and records in force at the time of original production is preserved for each domain. The prohibition on replay authority collapse (§6.4) preserves domain-specific replay integrity. The "retroactive governance prohibition" — that later standard revisions do not retroactively govern prior certifications, authorizations, or compliance determinations — is declared for each domain in Part V.

**Regulator boundaries constraining this document:**
This document maps eight regulatory sovereignty domains. Each domain's substantive requirements are governed by its own enabling instrument and are outside the scope of this document. This document defines the constitutional structure of domain relationships; it does not define the content of interpretation packs for any domain. Interpretation packs for each domain are governed by REGULATORY-authority artifacts specific to each domain, operating within the framework this document establishes.

**Phases this document applies to:**
GLOBAL — this boundary map applies across all phases. Regulatory framework evolution (new statutory instruments, standard revisions, bilateral Article 6.2 agreements) is accommodated through interpretation pack updates within the framework this document defines, not through structural revision of this document.

**Constitutional layers possessing override authority:**
SYSTEM_SOVEREIGNTY_MODEL.md (Authority-Rank 10, ROOT) possesses override authority over this document on questions of foundational sovereignty doctrine. No document with Authority-Rank below 9 possesses override authority over this regulatory boundary map. Override of specific domain mappings requires a REGULATORY-authority instrument for the relevant domain, explicitly superseding the relevant section of this document.

**Lower-layer documents prohibited from reinterpretation:**
- Phase-specific execution envelopes
- Wave-specific implementation guides
- Task-level Definitions of Done
- Governance convergence documents (GOV-CONV series)
- Agent authority documents
- Evidence schema documents
- Individual jurisdiction interpretation packs (which apply the domain definitions herein; they may not redefine the domain boundaries)
- Any document with Authority-Rank < 9

---

## Prohibited Misinterpretations

**PMI-001 — Carbon Credits as CBAM Offsets:**
Carbon credits (Verra VCUs, Gold Standard VERs, MGEE-authorized ITMOs) MUST NOT be characterized as offsets against CBAM certificate obligations. CBAM certificates and carbon credits are instruments in constitutionally separate regulatory domains. Their conflation is a cross-regime equivalence assumption that this document explicitly prohibits.

**PMI-002 — MGEE Authorization as Methodology Certification:**
MGEE's authorization of a mitigation activity under SI 5 of 2026 MUST NOT be characterized as certification of the activity's emission quantification methodology. MGEE authorizes national carbon market participation; Verra or Gold Standard certifies methodology validity. These are distinct veto authorities in distinct sovereign domains.

**PMI-003 — ZEMA EIA as Carbon Credit Quality:**
ZEMA's EIA approval MUST NOT be characterized as a quality endorsement for carbon credits generated by the project. Environmental lawfulness and carbon credit quality are distinct constitutional determinations in distinct sovereign domains.

**PMI-004 — One Article 6 Counterparty's Acceptance as Universal:**
A specific acquiring party state's acceptance of a Zambia-origin ITMO under its bilateral Article 6.2 arrangement MUST NOT be characterized as evidence that other acquiring party states will or should accept the same ITMO. Each bilateral arrangement is a distinct sovereignty relationship. RSD-INT-1 is not a single domain; it is a domain class, each instance of which is sovereignty-distinct.

**PMI-005 — Verra and Gold Standard as Interchangeable:**
Verra VCS and Gold Standard GS4GG are constitutionally distinct sovereignty domains with independent veto authority and independent admissibility determinations. A project certified by one is NOT thereby certified by the other. They MUST NOT be described as "equivalent certification paths" without qualification of the specific dimension on which they differ.

**PMI-006 — DPA Compliance as Carbon Market Authorization:**
Data Protection Act compliance MUST NOT be characterized as satisfying any carbon market regulatory requirement. DPC authority governs personal data processing; it is orthogonal to all carbon market regulatory domains. A project may be DPA-compliant and carbon-market-non-compliant simultaneously without contradiction.

**PMI-007 — BoZ Financial Compliance as Carbon Credit Validation:**
Financial compliance of carbon market transactions with BoZ requirements MUST NOT be characterized as validating the underlying carbon credits. Financial admissibility is constitutionally distinct from environmental integrity, methodology validity, and national carbon market authorization. Financial compliance certifies the transaction; it does not certify the credit.

**PMI-008 — This Document as Exhaustive of Applicable Regulations:**
The eight regulatory sovereignty domains mapped herein reflect Symphony's current operational regulatory context. This document is not a comprehensive inventory of all laws and regulations that may apply to Symphony's operations or to carbon market projects in Zambia. Additional regulatory requirements (sector-specific, activity-specific, project-specific) may apply within one or more of the domains mapped. This document maps constitutional domain boundaries; it does not exhaustively define the content of each domain.

**PMI-009 — Cross-Border Data Transfer as Carbon Credit Export:**
The DPC's authority over cross-border personal data transfer MUST NOT be conflated with the MGEE's authority over international ITMO transfer. These are categorically distinct regulatory events governed by distinct sovereign authorities. Personal data embedded in carbon project documentation (e.g., community benefit data, project participant data) is subject to DPC cross-border transfer authority independently of and simultaneously with the MGEE's ITMO transfer authority.

**PMI-010 — Replay Jurisdiction as Symphony's Own Record:**
Symphony's evidentiary records are NOT the authoritative replay source for any regulatory domain's historical compliance questions. MGEE's national registry, ZEMA's compliance records, Verra's registry, and the UNFCCC International Registry are the authoritative replay sources within their respective jurisdictions. Symphony's records support and evidence compliance with those sources; they do not substitute for them. Replay reconstruction of regulatory compliance history MUST use the domain-specific authoritative source defined in the Replay-Jurisdiction Matrix (Part V).
