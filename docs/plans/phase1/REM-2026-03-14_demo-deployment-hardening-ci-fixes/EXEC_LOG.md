# Remediation Log

- 2026-03-14: opened remediation for governance-signoff parity and ledger-api image build context failure on `feat/demo-deployment-hardening-tasks`.
- 2026-03-14: replaced stage-dependent service Dockerfiles with root-context multi-stage builds, updated direct container pipeline verification, and added `scripts/audit/verify_tsk_p1_demo_028.sh` to the mutable Git script audit after `TSK-P1-063` surfaced the missing inventory entry.
- 2026-03-14: fixed the linked-worktree `.git` bug exposed by `TSK-P1-076` by resolving the hooks directory through `git rev-parse --git-path hooks` in both the installer and the verifier, and updated the workflow/topology docs to match that canonical behavior.
