## 1. Summary of Change

Extend the branch batch to implement Wave 2 integrity controls for
`TSK-P1-INT-002` through `TSK-P1-INT-006`, the full Wave 3 DR bundle,
offline verification, storage policy gating, SeaweedFS cutover proof, and
restore-parity work for `TSK-P1-INT-007`, `TSK-P1-INT-008`,
`TSK-P1-INT-009A`, `TSK-P1-STOR-001`, and `TSK-P1-INT-009B`, plus the Wave 4
language/retention closeout work for `TSK-P1-INT-010`, `TSK-P1-INT-011`, and
`TSK-P1-INT-012`, after closing the AWC governance blockers, and add the
operator-facing Phase-1 demo deployment/test checklist plus the canonical
evidence churn cleanup policy.

## 2. Scope of Impact

Regulated verifier scripts, approval metadata, Phase-1 evidence artifacts,
the `TSK-P1-INT-002` / `003` / `004` / `005` / `006` / `007` / `008` / `009A` /
`STOR-001` / `009B` / `010` / `011` / `012` task packs, the ledger-api
service/runtime files required to add governed chain records and prove tamper
detection, the DR bundle/offline verification tooling and outputs, the
forward-only schema migration that adds acknowledgement-gap escalation and
recovery controls, the governed schema baseline refresh and baseline ADR
update required by that migration, the storage policy/RTO gating update, the
SeaweedFS cutover config and backend-neutral retention controls, the measured
PITR restore proof updates, the product-language synchronization doc update,
the evidence retention boundary policy updates, the semantic closeout gate
that aggregates the predecessor INT evidence set, the operator-facing
Phase-1 demo deployment/test checklist under `docs/operations/`, and the
canonical evidence churn cleanup policy for batch-safe evidence pruning.

## 3. Invariants & Phase Discipline

This batch strengthens `INV-105` and `INV-119` by:
- adding synchronous tamper-evident chain records to governed instruction and
  evidence-event flows
- preserving signed-artifact verification and append-only evidence behavior
- generating verifier-backed latency evidence for `TSK-P1-INT-002`
- generating chain-break and metadata-divergence tamper evidence for
  `TSK-P1-INT-003`
- adding fail-closed acknowledgement-gap escalation, supervisor recovery, and
  append-only interrupt audit controls for `TSK-P1-INT-004`
- refreshing the governed schema baseline and ADR log through migration cutoff
  `0073_int_004_ack_gap_controls.sql`
- proving restricted/offline posture only on implemented guarded paths for
  `TSK-P1-INT-005`
- aggregating the signed offline/pre-rail bridge proof pack for
  `TSK-P1-INT-006`
- generating the governed disaster-recovery bundle, manifest, custody, and
  encrypted package for `TSK-P1-INT-007`
- proving bundle-only offline verification and tamper rejection for
  `TSK-P1-INT-008`
- establishing the explicit Phase-1 storage RTO/signoff policy and backend-neutral
  storage cutover language required before `TSK-P1-STOR-001`
- moving the sandbox archive endpoint to the SeaweedFS S3 gateway and proving
  smoke IO, archive run, restore drill, retention controls, integrity parity,
  and rollback coverage for `TSK-P1-STOR-001`
- replacing timestamp-only PITR proof with measured restore-time evidence tied
  to the SeaweedFS cutover proof for `TSK-P1-INT-009B`
- synchronizing product/demo wording to the proven tamper-evident offline
  bridge and acknowledgement posture for `TSK-P1-INT-010`
- defining evidence retention/archival boundaries and DR-bundle linkage for
  `TSK-P1-INT-012`
- adding the semantic closeout gate that reruns predecessor verifiers and
  fails closed on missing Wave 2-4 proof semantics for `TSK-P1-INT-011`

## 4. AI Involvement Disclosure

Prepared with Codex; human review required for branch closeout.

## 5. Verification & Evidence

Targeted verifier checks for `TSK-P1-INT-002`, `TSK-P1-INT-003`,
`TSK-P1-INT-004`, `TSK-P1-INT-005`, `TSK-P1-INT-006`, `TSK-P1-INT-007`,
`TSK-P1-INT-008`, `TSK-P1-INT-009A`, `TSK-P1-STOR-001`, `TSK-P1-INT-009B`,
`TSK-P1-INT-010`, `TSK-P1-INT-011`, `TSK-P1-INT-012`,
`bash scripts/db/check_baseline_drift.sh`, and
`bash scripts/audit/verify_agent_conformance.sh` will be used to confirm the
integrity-chain runtime behavior, baseline freshness, DR/offline verification
evidence, storage policy gating, SeaweedFS cutover proof, restore-time parity,
language sync, evidence-retention boundaries, and the governed closeout gate.

## 6. Risk Assessment

Moderate contained runtime risk. This batch changes ledger-api command/demo
surfaces, verifier scripts, approval metadata, task-pack artifacts, Phase-1
evidence generation, DR/offline verification tooling, storage policy docs,
storage cutover/PITR proof surfaces, and one forward-only schema migration for
acknowledgement-gap controls.

## 7. Approval

Status: APPROVED
Approver: governance-human-reviewer
Approved At: 2026-03-12T08:45:00Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-12/BRANCH-feat-task-gov-awc8-wave-ordering.approval.json
