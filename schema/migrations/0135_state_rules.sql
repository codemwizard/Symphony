-- Migration 0135: Create state_rules table with rule_priority and deterministic tiebreak
-- Task: TSK-P2-PREAUTH-004-02
-- This migration materialises the state_rules table as per the Wave 4 contract
-- (docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md, section state_rules Schema)

CREATE TABLE public.state_rules (
  state_rule_id           UUID        NOT NULL PRIMARY KEY,
  from_state              TEXT        NOT NULL,
  to_state                TEXT        NOT NULL,
  required_decision_type  TEXT        NOT NULL,
  allowed                 BOOLEAN     NOT NULL,
  rule_priority           INT         NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (from_state, to_state, required_decision_type)
);

CREATE INDEX idx_state_rules_from_priority ON public.state_rules (from_state, rule_priority DESC);
