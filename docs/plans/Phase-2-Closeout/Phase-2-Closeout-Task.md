Phase-2-Closeout

- Resolved invariant drift by reverting duplicate and fabricated metadata from INVARIANTS_MANIFEST.yml
- Fixed shell expression evaluation and stdout redirection corruption in verify_phase2_contract.sh and pre_ci.sh
- Handled SIGPIPE stability in scripts/db/lint_migrations.sh for CI convergence
- Corrected false-positive overclaim detection in admissibility verifier
- Excluded incidental local evidence churn per EVIDENCE_CHURN_CLEANUP_POLICY.md
- Unit Tests:
  - run scripts/audit/check_docs_match_manifest.py (Passed)
  - run scripts/dev/pre_ci.sh (Passed Phase 0 and Phase 1 gates)
  - run scripts/db/lint_migrations.sh (Passed without SIGPIPE)
