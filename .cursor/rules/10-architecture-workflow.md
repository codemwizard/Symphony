Architecture workflow:
- The Architect agent writes plans, interfaces, invariants, ADRs, and work orders.
- Worker agents implement exactly what the Architect specifies and must not change core architecture without an ADR.

Definition of Done (DoD) for any change:
- Threat model updated (even brief).
- Control Matrix updated (what control, what evidence, where implemented).
- Invariants manifest updated if behavior/security changes.
- Tests added/updated to prove invariants and security properties.
- Migration reviewed for least privilege and safe defaults.

Evidence-first:
- Every “payment attempt” must be attributable, traceable, and immutable.
- All privileged actions must be audit logged with actor identity and reason.
