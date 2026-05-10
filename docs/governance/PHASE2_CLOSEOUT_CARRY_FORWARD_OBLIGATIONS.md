# Phase-2 Closeout: Carry-Forward Obligations

## Purpose
This document strictly records the non-immediate obligations identified during the Phase-2 closeout review. These are real deferred obligations, but they are explicitly NOT the immediate `app.bypass_rls` closeout blocker.

This record does NOT constitute Phase-3 readiness or executable task authority. It merely files these obligations for future assessment.

## Obligations

### 1. Methodology Adapter Extraction
- **Owner Domain**: Architecture / Integration
- **Rationale**: The current architecture tightly couples the registry methodology to core application logic. It must be extracted into a modular adapter, but this does not compromise the current tenant isolation boundary.
- **Blocker-Escalation Condition**: Becomes an immediate blocker if a new registry methodology is introduced into the core without adapter abstraction.
- **Future Executable Boundary**: Requires a future-phase task pack and `docs/architecture/` approval metadata to begin implementation.

### 2. Dwell-Time Forensic Enforcement
- **Owner Domain**: Security Guardian
- **Rationale**: While tenant isolation is proven at runtime, the strict detection of dwell-time metrics during security audits is not yet mechanically enforced. It is not an immediate bypass vulnerability but an operational gap.
- **Escalation Condition**: Becomes an immediate blocker if any current Phase-2 artifact claims that dwell-time forensic enforcement is already implemented.
- **Future Executable Boundary**: Requires dedicated Phase-3 security verifier tasks to establish.

### 3. Sovereign Authorization Schema
- **Owner Domain**: Invariants Curator / Domain Authority
- **Rationale**: Expanding into Article 6 sovereign contexts requires a specialized authorization schema, which is currently deferred. It is orthogonal to the local DB RLS bypass issue.
- **Escalation Condition**: Becomes an immediate blocker if sovereign credit issuance is attempted without the schema being implemented.
- **Future Executable Boundary**: Requires domain-canonical policy review and Stage A approval metadata before schema modifications begin.
