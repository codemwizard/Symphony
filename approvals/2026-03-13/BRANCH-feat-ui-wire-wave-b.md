## 1. Summary of Change

Complete Wave B of the GreenTech4CE supervisory UI port: wire the main reveal panels to the repo-native reveal API, complete browser-safe operator action flows, add the synchronous supervisory export route, and keep privileged credentials server-side by removing the admin API key from the browser bootstrap context.

## 2. Scope of Impact

Phase-1 task packs, Phase-1 planning docs, supervisory UI governance docs, the Wave B remediation casefile, Wave B verifier scaffolding, approval metadata, pilot-demo route wiring, supervisory dashboard client behavior, browser-safe instruction verification contract, and the committed HYBRID fallback dataset.

## 3. Invariants & Phase Discipline

This batch completes Wave B. It preserves truthful Phase-1 claim discipline by keeping privileged credentials server-side, preventing the browser from replaying `x-admin-api-key` on admin-only routes, and requiring route-level verification for reveal and export behavior.

## 4. AI Involvement Disclosure

Prepared with Codex; human review required for branch closeout.

## 5. Verification & Evidence

Wave B task-pack schema/readiness checks, agent conformance, targeted Wave B verifiers, evidence validation, dotnet build, remediation trace verification, human governance signoff verification, and pre-CI execution are used for this branch batch.

## 6. Risk Assessment

Moderate controlled runtime risk. This batch changes pilot-demo supervisory routing, reveal hydration, operator action contracts, and export behavior. It removes a secret-to-browser exposure and keeps later-wave detail and ack/interrupt projection out of scope.

## 7. Approval

Status: APPROVED
Approver: governance-human-reviewer
Approved At: 2026-03-13T13:40:00Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-13/BRANCH-feat-ui-wire-wave-b.approval.json
