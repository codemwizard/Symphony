#!/bin/bash

psql -c "
SELECT COUNT(*) FROM state_transitions st
LEFT JOIN policy_decisions pd
ON st.policy_decision_id = pd.policy_decision_id
WHERE pd.policy_decision_id IS NULL;
" | grep -q "0" || exit 1

echo "INV-AUTH-TRANSITION-BINDING-01 PASS"