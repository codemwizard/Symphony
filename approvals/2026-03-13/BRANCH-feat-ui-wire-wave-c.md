## 1. Summary of Change

Complete Wave C of the GreenTech4CE supervisory UI port: expand the reveal read model to canonical PT-001 through PT-004 proof rows, add the real instruction-detail route, and wire the supervisory drill-down to the backend payload while keeping ack/interrupt slots explicitly pending until Wave D.

## 2. Scope of Impact

Wave C task packs, Wave C planning docs, supervisory reveal API documentation, Wave C verifier scripts, approval metadata, reveal read-model code, supervisory detail route wiring, demo self-test coverage, and supervisory dashboard drill-down behavior.

## 3. Invariants & Phase Discipline

This batch completes Wave C. It preserves truthful Phase-1 claim discipline by backing proof rows with real reveal data, keeping the detail route read-only and tenant-scoped, and making ack/interrupt state explicitly pending until Wave D rather than inventing frontend state.

## 4. AI Involvement Disclosure

Prepared with Codex; human review required for branch closeout.

## 5. Verification & Evidence

Wave C task-pack schema/readiness checks, targeted Wave C verifiers, evidence validation, dotnet build, human governance signoff verification, agent conformance, and pre-CI execution are used for this branch batch.

## 6. Risk Assessment

Moderate controlled runtime risk. This batch changes the reveal payload shape, adds a new supervisory instruction-detail route, and changes the dashboard drill-down behavior. It preserves top-level reveal compatibility and keeps ack/interrupt projection explicitly out of scope until Wave D.

## 7. Approval

Status: APPROVED
Approver: governance-human-reviewer
Approved At: 2026-03-13T14:10:00Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-13/BRANCH-feat-ui-wire-wave-c.approval.json
