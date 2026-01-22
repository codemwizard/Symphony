-- Balance View (Derived, Non-Authoritative)
-- If this view is wrong, the ledger is wrong — not the view.
-- Balance checks are performed as read-only queries over this view
-- and do not introduce additional state.
CREATE VIEW account_balances AS
SELECT
    account_id,
    currency,
    SUM(
        CASE direction
            WHEN 'C' THEN amount
            WHEN 'D' THEN -amount
        END
    ) AS balance
FROM ledger_entries
GROUP BY account_id, currency;

COMMENT ON VIEW account_balances IS 'Derived balance. Non-authoritative. Computed from ledger. Phase 7.3.';
