---
description: how to create and execute security remediation tasks following the evidence-driven DOD process
---

# Security Remediation Workflow

This workflow defines the mandatory steps for creating and implementing security fixes and bug remediations in the Symphony repository.

## 1. Task Definition Phase

1. Identify the vulnerability or bug root cause.
2. Cross-reference the [8-point review checklist](file:///home/mwiza/workspace/Symphony/docs/process/EVIDENCE_DRIVEN_TASK_PROCESS.md#8-point-review-checklist) against the repository state.
3. Create a task entry in [SECURITY_REMEDIATION_DOD.yml](file:///home/mwiza/workspace/Symphony/docs/contracts/SECURITY_REMEDIATION_DOD.yml) using the [TASK_DOD_TEMPLATE.yml](file:///home/mwiza/workspace/Symphony/docs/contracts/templates/TASK_DOD_TEMPLATE.yml).
4. Define at least one negative test that proves the exploit path is blocked.
5. Specify the evidence JSON artifact path and its required fields.

## 2. Implementation Phase

1. Create a feature branch for the task: `git checkout -b feat/remediation-<task-id>`.
2. Implement the fix ensuring "fail-closed" logic and proper secret redaction in logs.
3. Add the verification script to `scripts/audit/` or `scripts/security/` as defined in the DOD.
4. If the fix touches a regulated surface, ensure approval metadata is ready.

## 3. Verification & Evidence Phase

// turbo
1. Run the local verification command specified in the task DOD:
   ```bash
   bash <verification_script_path>
   ```
2. Ensure the evidence artifact is generated at `evidence/security_remediation/<task_id>.json`.
// turbo
3. Validate the evidence against its schema:
   ```bash
   # example validation command
   check-jsonschema --schemafile evidence_schemas/<task_id>.schema.json evidence/security_remediation/<task_id>.json
   ```

## 4. Closure Phase

1. Commit the code, verification scripts, and evidence artifact.
2. Open a PR and ensure CI (`security_scan`, `mechanical_invariants`, etc.) passes.
3. Merge the PR after human approval is recorded in the evidence/approvals directory.
