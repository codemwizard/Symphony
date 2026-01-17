-- Phase-7B: Outbox Status View
-- Exposes the state of the transactional outbox in supervisor terms.
--
-- Counts: Pending, Dispatched, Failed (DLQ), Retry counts and aging
-- 
-- Supervisors can detect backlog or failure patterns.
-- Data aligns exactly with outbox records.

CREATE OR REPLACE VIEW supervisor_outbox_status AS
SELECT
    '7B.1.0' AS view_version,
    NOW() AS generated_at,
    
    -- Status Counts
    (SELECT COUNT(*) FROM payment_outbox WHERE status = 'PENDING') AS pending_count,
    (SELECT COUNT(*) FROM payment_outbox WHERE status = 'IN_FLIGHT') AS in_flight_count,
    (SELECT COUNT(*) FROM payment_outbox WHERE status = 'SUCCESS') AS success_count,
    (SELECT COUNT(*) FROM payment_outbox WHERE status = 'FAILED') AS failed_count,
    (SELECT COUNT(*) FROM payment_outbox WHERE status = 'RECOVERING') AS recovering_count,
    
    -- DLQ Analysis (status = FAILED)
    (SELECT COUNT(*) FROM payment_outbox WHERE status = 'FAILED' AND retry_count >= 5) AS dlq_count,
    
    -- Retry Distribution
    (SELECT COUNT(*) FROM payment_outbox WHERE retry_count = 0) AS retry_0,
    (SELECT COUNT(*) FROM payment_outbox WHERE retry_count = 1) AS retry_1,
    (SELECT COUNT(*) FROM payment_outbox WHERE retry_count = 2) AS retry_2,
    (SELECT COUNT(*) FROM payment_outbox WHERE retry_count = 3) AS retry_3,
    (SELECT COUNT(*) FROM payment_outbox WHERE retry_count = 4) AS retry_4,
    (SELECT COUNT(*) FROM payment_outbox WHERE retry_count >= 5) AS retry_5_plus,
    
    -- Aging Analysis
    (
        SELECT COUNT(*) 
        FROM payment_outbox 
        WHERE status NOT IN ('SUCCESS', 'FAILED') 
          AND created_at < NOW() - INTERVAL '1 minute'
    ) AS stale_1m,
    
    (
        SELECT COUNT(*) 
        FROM payment_outbox 
        WHERE status NOT IN ('SUCCESS', 'FAILED') 
          AND created_at < NOW() - INTERVAL '5 minutes'
    ) AS stale_5m,
    
    (
        SELECT COUNT(*) 
        FROM payment_outbox 
        WHERE status NOT IN ('SUCCESS', 'FAILED') 
          AND created_at < NOW() - INTERVAL '1 hour'
    ) AS stale_1h,
    
    -- Oldest Non-Terminal Record
    (
        SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::INTEGER
        FROM payment_outbox
        WHERE status NOT IN ('SUCCESS', 'FAILED')
    ) AS oldest_pending_age_seconds,
    
    -- Throughput (Last Hour)
    (
        SELECT COUNT(*) 
        FROM payment_outbox 
        WHERE status = 'SUCCESS' 
          AND updated_at >= NOW() - INTERVAL '1 hour'
    ) AS success_last_hour,
    
    (
        SELECT COUNT(*) 
        FROM payment_outbox 
        WHERE status = 'FAILED' 
          AND updated_at >= NOW() - INTERVAL '1 hour'
    ) AS failed_last_hour;

COMMENT ON VIEW supervisor_outbox_status IS 
    'Phase-7B: Read-only supervisor view for transactional outbox status, retry distribution, and aging analysis.';
