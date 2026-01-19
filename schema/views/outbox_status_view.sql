-- Phase-7B: Outbox Status View (Option 2A)
-- Exposes the state of the hot pending queue and append-only attempts log.

CREATE OR REPLACE VIEW supervisor_outbox_status AS
WITH latest_attempts AS (
    SELECT DISTINCT ON (outbox_id)
        outbox_id,
        state,
        attempt_no,
        claimed_at,
        completed_at,
        created_at
    FROM payment_outbox_attempts
    ORDER BY outbox_id, claimed_at DESC
)
SELECT
    '7B.2.0' AS view_version,
    NOW() AS generated_at,

    -- Pending counts
    (SELECT COUNT(*) FROM payment_outbox_pending) AS pending_count,
    (SELECT COUNT(*) FROM payment_outbox_pending WHERE next_attempt_at <= NOW()) AS due_pending_count,

    -- Latest attempt state counts
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHING') AS dispatching_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHED') AS dispatched_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED') AS failed_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'RETRYABLE') AS retryable_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'ZOMBIE_REQUEUE') AS zombie_requeue_count,

    -- DLQ heuristic (attempt_no >= 5 and terminal)
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED' AND attempt_no >= 5) AS dlq_count,

    -- Attempt distribution (latest attempt_no)
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 1) AS attempt_1,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 2) AS attempt_2,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 3) AS attempt_3,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 4) AS attempt_4,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no >= 5) AS attempt_5_plus,

    -- Aging analysis
    (
        SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::INTEGER
        FROM payment_outbox_pending
    ) AS oldest_pending_age_seconds,

    -- Stuck dispatching count
    (
        SELECT COUNT(*)
        FROM latest_attempts
        WHERE state = 'DISPATCHING'
          AND claimed_at < NOW() - INTERVAL '120 seconds'
    ) AS stuck_dispatching_count,

    -- Throughput (last hour)
    (
        SELECT COUNT(*)
        FROM payment_outbox_attempts
        WHERE state = 'DISPATCHED'
          AND completed_at >= NOW() - INTERVAL '1 hour'
    ) AS dispatched_last_hour,

    (
        SELECT COUNT(*)
        FROM payment_outbox_attempts
        WHERE state = 'FAILED'
          AND completed_at >= NOW() - INTERVAL '1 hour'
    ) AS failed_last_hour;

COMMENT ON VIEW supervisor_outbox_status IS
    'Phase-7B Option 2A: Supervisor view for pending depth, attempt states, aging, and dispatch throughput.';
