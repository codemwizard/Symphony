# Symphony Regulator Evidence Pack Template

Version: 1.0  
Status: TEMPLATE (Operational Baseline)  
Audience: regulators, auditors, licensed partners, supervisory reviewers

## Purpose
Provide a deterministic, reproducible structure for presenting Symphony control evidence.
This template is evidence-centric and tied to existing invariant/gate artifacts.

## Packaging Rules
1. All referenced artifacts must exist in `evidence/phase0/**` or `evidence/phase1/**`.
2. Evidence must be schema-valid where schema is defined.
3. Every control claim must map to invariant ID(s).
4. Any exception must include template-compliant record and expiry.

## Section A: Cover
- reporting period
- environment (`sandbox`, `staging`, `production-simulated`)
- declared lifecycle phase
- pack version + generation timestamp
- responsible officers

## Section B: Executive Attestation
Include signed statement that:
- control claims are based on attached evidence,
- non-custodial boundary claims are accurate,
- known exceptions/deviations are disclosed.

## Section C: Invariant Compliance Index
Include table:
- Invariant ID
- Status (`implemented`/`roadmap`)
- Verifier command
- CI gate/job
- Evidence path
- Notes/exception link

Use as source:
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md`

## Section D: Financial/Execution Integrity Evidence
Attach (as applicable):
- `evidence/phase1/instruction_finality_invariant.json`
- `evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json`
- `evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json`
- replay/finality-linked evidence artifacts required by contract

## Section E: Security & Supply-Chain Evidence
Attach:
- `evidence/phase0/security_secrets_scan.json`
- `evidence/phase0/security_dotnet_deps_audit.json`
- `evidence/phase0/security_insecure_patterns.json`
- semgrep/lint evidence as required by current gate set

## Section F: Policy & Control-Plane Evidence
Attach:
- `evidence/phase0/control_planes_drift.json`
- `evidence/phase0/three_pillars_doc.json`
- policy/finality/anchor gate evidence required by current phase contract

## Section G: Tenant, Privacy, and Jurisdiction Evidence
Attach:
- `evidence/phase0/pii_leakage_payloads.json`
- `evidence/phase1/pii_decoupling_invariant.json`
- tenant allowlist / cross-tenant protection evidence

## Section H: Operational Containment Evidence
Attach:
- kill-switch / containment test evidence (if in scope)
- phase closeout evidence summary
- pilot onboarding readiness evidence (if Phase-1 handoff)

## Section I: Exceptions and Compensating Controls
For each active exception:
- exception file path under `docs/invariants/exceptions/`
- reason + scope + expiry
- compensating control verifier/evidence
- linked remediation task ID

## Section J: Change Management & Approvals
Attach:
- relevant approval metadata artifact(s)
- CI run references
- migration list for reporting window
- remediation trace links (if production-affecting)

## Section K: Incident Summary (If Any)
For each incident:
- date/time window
- severity/classification
- invariant(s) impacted
- containment action
- customer-fund impact declaration
- evidence reference

## Section L: Final Declaration
Include sign-off block:
- name/title/date/signature
- statement that pack is complete and accurate to best knowledge

## Minimum Bundle Checklist
- [ ] Invariant compliance index included
- [ ] All mandatory evidence paths exist
- [ ] Schema validation passed for schema-governed evidence
- [ ] Exceptions disclosed and time-boxed
- [ ] Approval metadata attached for regulated-surface changes

## Canonical References
- `docs/architecture/COMPLIANCE_MAP.md`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md`
- `docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
