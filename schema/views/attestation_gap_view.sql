-- Phase-7B: Attestation Gap View
-- Exposes a read-only metric indicating ingress-to-execution completeness.
-- 
-- Metric: Attested but not executed within threshold
-- Time Windows: Last hour, Last 24 hours
--
-- NOTE: Thresholds are observational only and do not affect execution.

-- View Version: 7B.1.0
-- Generated At: Runtime (via view_version and generated_at columns)

CREATE OR REPLACE VIEW supervisor_attestation_gap AS
SELECT
    '7B.1.0' AS view_version,
    NOW() AS generated_at,
    
    -- Last Hour Metrics
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
    ) AS total_attested_1h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
          AND execution_completed = TRUE
    ) AS total_executed_1h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
          AND execution_started = FALSE
    ) AS gap_not_started_1h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
          AND execution_started = TRUE
          AND execution_completed = FALSE
    ) AS gap_in_progress_1h,
    
    -- Last 24 Hours Metrics
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
    ) AS total_attested_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND execution_completed = TRUE
    ) AS total_executed_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND execution_started = FALSE
    ) AS gap_not_started_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND execution_started = TRUE
          AND execution_completed = FALSE
    ) AS gap_in_progress_24h,
    
    -- Terminal Status Breakdown (24h)
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND terminal_status = 'SUCCESS'
    ) AS success_count_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND terminal_status = 'FAILED'
    ) AS failed_count_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND terminal_status = 'REPAIRED'
    ) AS repaired_count_24h;

COMMENT ON VIEW supervisor_attestation_gap IS 
    'Phase-7B: Read-only supervisor view for attestation-to-execution completeness. Thresholds are observational only.';
