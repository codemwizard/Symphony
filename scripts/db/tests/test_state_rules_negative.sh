#!/usr/bin/env bash
set -e

# Negative test harness for TSK-P2-PREAUTH-004-02: state_rules table
# This script exercises three contracted negative test paths:
# N1: Insert without required_decision_type - expect SQLSTATE 23502 (NOT NULL violation)
# N2: Duplicate (from_state, to_state, required_decision_type) - expect SQLSTATE 23505 (UNIQUE violation)
# N3: Insert with rule_priority = -1 - expect SUCCESS (negative priorities are valid for explicit deny rules)

echo "Running negative tests for state_rules table..."

# N1: Test NOT NULL constraint on required_decision_type
echo "N1: Testing NOT NULL constraint on required_decision_type..."
N1_RESULT=$(psql -v ON_ERROR_STOP=1 -t -c "
  INSERT INTO public.state_rules (state_rule_id, from_state, to_state, required_decision_type, allowed, rule_priority)
  VALUES (gen_random_uuid(), 'state_a', 'state_b', NULL, true, 0);" 2>&1 || echo "EXPECTED_FAILURE")
if echo "$N1_RESULT" | grep -q "23502"; then
  echo "N1: PASS - NOT NULL violation correctly raised"
else
  echo "N1: FAIL - Expected SQLSTATE 23502, got: $N1_RESULT"
  exit 1
fi

# N2: Test UNIQUE constraint on (from_state, to_state, required_decision_type)
echo "N2: Testing UNIQUE constraint on (from_state, to_state, required_decision_type)..."
psql -v ON_ERROR_STOP=1 -c "
  INSERT INTO public.state_rules (state_rule_id, from_state, to_state, required_decision_type, allowed, rule_priority)
  VALUES (gen_random_uuid(), 'state_x', 'state_y', 'decision_type_a', true, 0);" > /dev/null 2>&1
N2_RESULT=$(psql -v ON_ERROR_STOP=1 -t -c "
  INSERT INTO public.state_rules (state_rule_id, from_state, to_state, required_decision_type, allowed, rule_priority)
  VALUES (gen_random_uuid(), 'state_x', 'state_y', 'decision_type_a', true, 0);" 2>&1 || echo "EXPECTED_FAILURE")
if echo "$N2_RESULT" | grep -q "23505"; then
  echo "N2: PASS - UNIQUE violation correctly raised"
else
  echo "N2: FAIL - Expected SQLSTATE 23505, got: $N2_RESULT"
  exit 1
fi

# N3: Test that negative rule_priority values are accepted (no CHECK constraint)
echo "N3: Testing that negative rule_priority is accepted..."
N3_RESULT=$(psql -v ON_ERROR_STOP=1 -t -c "
  INSERT INTO public.state_rules (state_rule_id, from_state, to_state, required_decision_type, allowed, rule_priority)
  VALUES (gen_random_uuid(), 'state_m', 'state_n', 'decision_type_b', false, -1)
  RETURNING rule_priority;" 2>&1)
if echo "$N3_RESULT" | grep -q "\-1"; then
  echo "N3: PASS - Negative priority accepted (CHECK (rule_priority >= 0) correctly absent)"
else
  echo "N3: FAIL - Expected row with rule_priority=-1, got: $N3_RESULT"
  exit 1
fi

echo "All negative tests passed"
