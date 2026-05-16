# Phase 3 Opened-Phase Artifact Classification

This document records how existing `docs/plans/phase3/**` and
`evidence/phase3/**` artifacts must be interpreted after Phase 3 opening.

## Classification Rules

- `admissible_opened_phase_activation`
  Phase 3 activation artifacts created after formal opening and backed by their
  declared verifiers. This class is limited to `TSK-P3-ACT-001` through
  `TSK-P3-ACT-005`, including the classification manifest and this summary.

- `historical_planning_only`
  Artifacts retained for audit, planning lineage, or remediation context. These
  files are not opened-phase delivery proof and must not be cited as if they
  prove runtime Phase 3 implementation.

- `regenerate_required`
  Legacy runtime-adjacent artifacts that may describe relevant work, but cannot
  be treated as opened-phase implementation proof unless they are regenerated
  under the opened Phase 3 task, verifier, and evidence regime.

## Practical Handling

- Activation artifacts:
  `TSK-P3-ACT-001` through `TSK-P3-ACT-005` plans, logs, and evidence are
  admissible as opened-phase activation proof.

- Remediation and cleanup artifacts:
  `REM-*`, `TSK-P3-CLEAN-*`, `TSK-P3-GOV-*`, and `TSK-P3-PRE-*` artifacts
  remain historical planning context only.

- Legacy runtime-adjacent artifacts:
  `TSK-P3-W1-*`, `TSK-P3-W8-*`, and related evidence files are
  `regenerate_required`. They must be recreated through the current opened-phase
  task pack and verifier process before any implementation claim may rely on
  them.

## Default Rule

If a future file appears in `docs/plans/phase3/**` or `evidence/phase3/**` and
is not covered by the machine-readable manifest, it is non-admissible until
classified.
