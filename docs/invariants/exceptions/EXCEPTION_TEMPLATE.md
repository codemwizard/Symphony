---
exception_id: EXC-000
inv_scope: change-rule
expiry: 2099-12-31
follow_up_ticket: PLACEHOLDER-000
remediation_task: TASK-ID
approved_by: approver-id
approval_artifact_ref: approvals/YYYY-MM-DD/BRANCH-example.md
reason: This is a template file, not an actual exception
author: system
created_at: 2024-01-01
---

# Exception Template

This is a template for documenting invariant exceptions.

## Usage

1. Copy this file to `exception_<INV-ID>_<date>.md`
2. Fill in the YAML front matter with real values
3. Set a real `follow_up_ticket` and `remediation_task`
4. Link the human approval artifact in `approval_artifact_ref`
5. Document the reason, compensating controls, and exit condition below

## Reason

[Describe why this exception is needed]

## Compensating Controls

[Describe any mitigating controls in place]

## Verification

[List the verifier or evidence that constrains the exception while it is active]

## Exit Criteria

[Describe the condition and task/remediation required to close this exception]
