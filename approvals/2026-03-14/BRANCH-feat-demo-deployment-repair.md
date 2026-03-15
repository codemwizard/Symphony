## 1. Summary of Change

Move the demo deployment work off the published Wave-E branch onto `feat/demo-deployment-repair`, restore the canonical `TSK-P1-DEMO-024..028` task line from updated mainline truth, rehome the provisioning sample-pack task to `TSK-P1-DEMO-029`, add the follow-on remediation task pack `TSK-P1-206..210`, and implement the approved security and traceability fixes in `supervisor_api`, `Program.cs`, `index.html`, and the related verifier surfaces while preserving the host-based demo runbook hardening batch on the repaired branch.

## 2. Scope of Impact

This branch affects regulated Phase-1 operator, runtime, and governance surfaces for the demo deployment line: operator docs, task packs, runtime auth boundaries, UI traceability, plan/log files, audit verifiers, approval metadata, and evidence used to prove the branch relocation, task-line repair, follow-on audit remediation task pack creation, and the approved implementation fixes.

## 3. Invariants & Phase Discipline

This repair preserves INV-105, INV-119, and INV-133 by keeping the canonical demo task identities intact, preventing branch contamination of the published Wave-E line, and ensuring the repaired branch has branch-linked approval artifacts that match its own scope.

## 4. AI Involvement Disclosure

Prepared with Codex; human review required for branch closeout.

## 5. Verification & Evidence

Task-pack readiness, branch-repair verification, approval-metadata validation, agent conformance, and full local pre-CI must pass on `feat/demo-deployment-repair` before push readiness is claimed.

## 6. Risk Assessment

Moderate governance risk. This batch changes task identity ownership, branch-linked approval artifacts, and the governed remediation backlog for a regulated demo deployment and audit-remediation workstream.

## 7. Approval

Status: APPROVED
Approver: governance-human-reviewer
Approved At: 2026-03-14T18:10:00Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.approval.json
