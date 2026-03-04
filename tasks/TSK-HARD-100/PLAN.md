# TSK-HARD-100 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-100

- task_id: TSK-HARD-100
- title: Anti-abuse controls and retraction safety
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-042]
- goal: Implement rate limiting on all high-risk operator and automated actions.
  Implement safe retraction paths for reversible hardening actions. Rate limit
  breaches produce evidence artifacts and block further attempts. Retraction
  actions require secondary approval and produce immutable evidence artifacts.
  Scope must be confirmed in EXEC_LOG.md before implementation begins.
- required_deliverables:
  - anti-abuse control taxonomy document at
    docs/programs/symphony-hardening/ANTI_ABUSE_CONTROLS.md
  - rate limiting per controlled action type
  - rate limit breach evidence artifacts
  - retraction workflow with secondary approval
  - retraction evidence artifacts (immutable)
  - tasks/TSK-HARD-100/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_100.json
- verifier_command: bash scripts/audit/verify_tsk_hard_100.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_100.json
- schema_path: evidence/schemas/hardening/tsk_hard_100.schema.json
- acceptance_assertions:
  - EXEC_LOG.md confirms scope of controlled action types before implementation
    begins; any scope change requires a DECISION_LOG.md entry
  - ANTI_ABUSE_CONTROLS.md exists and documents: controlled_action_types[],
    rate_limit_per_action (requests per window), window_duration,
    breach_action (block and evidence), retraction_eligible_actions[]
  - rate limiting applied to at minimum: adjustment submission, adjustment
    approval, circuit breaker override, erasure request, legal hold activation,
    DR bundle access request
  - rate limit configuration loaded from policy metadata (not hardcoded)
  - rate limit breach: further attempts blocked for remainder of window;
    breach evidence artifact produced containing: action_type, actor_id,
    breach_timestamp, limit_threshold, observed_count, window_duration,
    outcome: RATE_LIMITED
  - retraction of a hardening action (e.g. legal hold removal, circuit breaker
    resume, flag disable) requires: secondary approval from distinct operator
    role, justification text, produces retraction evidence artifact
  - retraction evidence artifact is immutable once created: P7101-equivalent
    trigger blocks UPDATE/DELETE on retraction records
  - [METADATA GOVERNANCE] rate limits and window durations loaded from versioned
    policy config; activation produces evidence artifact; signed when available;
    unsigned_reason if not; in-place edits to active version blocked; runtime
    references policy_version_id
  - negative-path test: exceeding rate limit on any controlled action blocks
    further attempts and produces breach evidence artifact
  - negative-path test: retraction without secondary approval is blocked and
    produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - rate limiting absent from any controlled action type => FAIL_CLOSED
  - rate limit hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - retraction requires no secondary approval => FAIL_CLOSED
  - retraction evidence artifact mutable => FAIL_CLOSED
  - rate limit breach produces no evidence artifact => FAIL
  - scope not confirmed in EXEC_LOG.md before implementation => FAIL_REVIEW
  - negative-path tests absent => FAIL

---
