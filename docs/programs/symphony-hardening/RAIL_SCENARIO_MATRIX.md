# Rail Scenario Matrix

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

| scenario_type | description | expected_system_response | evidence_artifact_type | implementing_task_id |
|---|---|---|---|---|
| SILENT_RAIL | Rail does not return callback within expected polling windows. | Keep funds unreleased, continue inquiry cadence, mark inquiry exhausted when policy limits are reached. | inquiry_event | TSK-HARD-012 |
| CONFLICTING_FINALITY | Two trusted surfaces disagree on finality status. | Enter `FINALITY_CONFLICT`, block release, route to dispute handling. | finality_conflict_record | TSK-HARD-015 |
| LATE_CALLBACK | Callback arrives after inquiry exhausted/sealed state. | Reconcile into orphan/late-callback flow with deterministic linkage and no silent overwrite. | orphaned_attestation_event | TSK-HARD-014 |
| MALFORMED_RESPONSE | Adapter response is syntactically or semantically malformed. | Quarantine payload, capture hash+error details, fail closed on execution. | malformed_quarantine_event | TSK-HARD-016 |
| PARTIAL_RESPONSE | Response is structurally valid but missing required attestation fields. | Treat as orphan/incomplete attestation and block progression until resolved. | orphaned_attestation_event | TSK-HARD-013B |
| TIMEOUT_EXCEEDED | Inquiry process exceeds timeout thresholds defined by policy. | Transition inquiry to exhausted/containment state and emit timeout evidence. | inquiry_event | TSK-HARD-012 |
