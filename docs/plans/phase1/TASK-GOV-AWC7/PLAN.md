# PLAN — TASK-GOV-AWC7

## Mission

Align the mechanically enforced approval-surface policy with the broader
regulated-surface contract written in `AGENTS.md`.

## Scope

Approval-surface policy, verifier spec, and approval-requirement tests only.
This task also updates the shared approval path matcher so `/**` patterns behave
as nested prefix matches.

## Verification Commands

```bash
rg -n "docs/operations/\\*\\*|evidence/\\*\\*" docs/operations/REGULATED_SURFACE_PATHS.yml
rg -n "pattern.endswith\\(\"/\\*\\*\"\\)|startswith\\(prefix \\+ \"/\"\\)" scripts/audit/lib/approval_requirement.py
rg -n "docs/operations|evidence/phase1" scripts/audit/tests/test_approval_metadata_requirements.sh
rg -n "REGULATED_SURFACE_PATHS.yml" docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md
bash scripts/audit/tests/test_approval_metadata_requirements.sh
```

## Evidence

- `evidence/phase1/task_gov_awc7_regulated_surface_alignment.json`

## Remediation Markers

```text
failure_signature: GOV.AWC7.REGULATED_SURFACE_ALIGNMENT
origin_task_id: TASK-GOV-AWC7
repro_command: bash scripts/audit/tests/test_approval_metadata_requirements.sh
verification_commands_run: see Verification Commands
final_status: PASS
```
