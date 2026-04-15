# REMEDIATION EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: SKIP_DOTNET_QUALITY_LINT=1 scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

- created_at_utc: 2026-04-15T05:48:47Z
- action: remediation casefile scaffold created

## Session 3 — 2026-04-15T05:30:00Z

### Actions

- After skipping dotnet quality lint, pre_ci.sh failed at DDL lock risk lint (SEC-DDL-LOCK-RISK)
- Root cause: ALTER TABLE statement in migration 0115 flagged as risky DDL pattern
- Migration adds nullable supplier_type column to non-hot supplier_registry table
- Migration is already documented in exception_change-rule_ddl_2026-04-15.md (EXC-1000)
- Applied fix: Added DDL-ALLOW-0102 entry to docs/security/ddl_allowlist.json
- Initial fingerprint calculations were incorrect (full statement vs line content)
- Corrected statement fingerprint: 07eb999eb3b91571ec846778c83d596cf56877f6a7d64122e6c9446826b9a710 (line-content only)

### Verification

- Corrected allowlist entry with proper line-content fingerprint and metadata
- Ready to commit changes, clear DRD lockout, and re-run pre_ci.sh

## Session 4 — 2026-04-15T05:45:00Z

### Actions

- After clearing DRD lockout, pre_ci.sh failed at TSK-P1-063 (mutable Git script audit)
- Root cause: Two pilot task verification scripts use git rev-parse HEAD but are not documented in Git mutation surface audit doc
- Missing scripts: verify_tsk_p1_plt_008.sh and verify_tsk_p1_plt_009b.sh
- Both scripts use read-only Git operations (git rev-parse HEAD) for evidence generation
- Applied fix: Added both scripts to docs/audits/GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md with classification:
  - mutates: no (read-only Git operations)
  - contains: no (no Git plumbing scrubbing or repository identity assertion)
  - status: PASS (safe read-only Git usage)

### Verification

- Added audit doc entries for both scripts
- Ready to commit changes, clear DRD lockout, and re-run pre_ci.sh
