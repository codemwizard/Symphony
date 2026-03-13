## 1. Summary of Change

Implement Wave A of the GreenTech4CE supervisory UI port: create the Wave A task packs, freeze the canonical supervisory UI source-of-truth, port and serve the v3 shell on pilot-demo routes, align the client adapter to repo-native `/v1` routes and explicit HYBRID fallback behavior, and record the required remediation trace casefile for the pre-push governance gate.

## 2. Scope of Impact

Phase-1 task packs, Phase-1 planning docs, supervisory UI governance docs, task verifiers, approval metadata, supervisory dashboard HTML and fallback fixture, LedgerApi pilot-demo route wiring, and Wave A task evidence.

## 3. Invariants & Phase Discipline

This batch defines the canonical supervisory UI contract and completes Wave A implementation without claiming later-wave wiring is complete. It preserves Phase-1 truthful-claim discipline, preserves DEMO-008 verifier compatibility IDs, adds pilot-demo-only serving routes, and requires repo-native routing and explicit backing-mode semantics.

## 4. AI Involvement Disclosure

Prepared with Codex; human review required for branch closeout.

## 5. Verification & Evidence

Wave A task-pack schema/readiness checks, the TASK-UI-WIRE-000/001/002 verifiers, evidence validation, the fast invariants gate, agent conformance checks, and pre_ci are used for this branch.

## 6. Risk Assessment

Moderate controlled runtime risk. This batch changes the pilot-demo supervisory shell, adds pilot-demo-only serving routes, and introduces the canonical HYBRID fallback fixture, but it does not yet implement later-wave export/detail/ack route work.

## 7. Approval

Status: APPROVED
Approver: governance-human-reviewer
Approved At: 2026-03-13T10:30:00Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-13/BRANCH-feat-ui-wire-wave-a.approval.json
