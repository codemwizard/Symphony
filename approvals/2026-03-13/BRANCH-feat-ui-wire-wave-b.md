## 1. Summary of Change

Start Wave B of the GreenTech4CE supervisory UI port: create the Wave B task packs, record the proxy-only rule for privileged operator actions, remove the admin API key from the browser bootstrap context, and add server-side pilot-demo proxy routes for future privileged UI actions.

## 2. Scope of Impact

Phase-1 task packs, Phase-1 planning docs, supervisory UI governance docs, Wave B verifier scaffolding, approval metadata, pilot-demo route wiring, and supervisory dashboard client behavior.

## 3. Invariants & Phase Discipline

This batch starts Wave B without claiming full Wave B completion. It preserves truthful Phase-1 claim discipline by keeping privileged credentials server-side and preventing the browser from replaying `x-admin-api-key` on admin-only routes.

## 4. AI Involvement Disclosure

Prepared with Codex; human review required for branch closeout.

## 5. Verification & Evidence

Wave B task-pack schema/readiness checks, the TASK-UI-WIRE-004 verifier, evidence validation, and agent conformance checks are used for this branch slice.

## 6. Risk Assessment

Moderate controlled runtime risk. This batch changes pilot-demo supervisory routing and client bootstrap behavior, but it removes a secret-to-browser exposure and does not claim later-wave export/detail/ack work is complete.

## 7. Approval

Status: APPROVED
Approver: governance-human-reviewer
Approved At: 2026-03-13T11:25:00Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-13/BRANCH-feat-ui-wire-wave-b.approval.json
