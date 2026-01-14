-- Phase-7B: Revocation Window Visibility View
-- Exposes certificate TTL and revocation posture.
--
-- Scope:
-- - Maximum certificate age
-- - Active vs revoked counts
-- - Revocation propagation window
--
-- Acceptance Criteria:
-- - Supervisor can verify kill-switch effectiveness
-- - No key material exposed

CREATE OR REPLACE VIEW supervisor_revocation_status AS
SELECT
    '7B.1.0' AS view_version,
    NOW() AS generated_at,
    
    -- Certificate Counts
    (SELECT COUNT(*) FROM participant_certificates WHERE revoked = FALSE AND expires_at > NOW()) AS active_count,
    (SELECT COUNT(*) FROM participant_certificates WHERE revoked = TRUE) AS revoked_count,
    (SELECT COUNT(*) FROM participant_certificates WHERE expires_at <= NOW()) AS expired_count,
    
    -- TTL Analysis
    (
        SELECT EXTRACT(EPOCH FROM MAX(expires_at - issued_at)) / 3600
        FROM participant_certificates
        WHERE revoked = FALSE AND expires_at > NOW()
    )::NUMERIC(10,2) AS max_ttl_hours,
    
    (
        SELECT EXTRACT(EPOCH FROM AVG(expires_at - issued_at)) / 3600
        FROM participant_certificates
        WHERE revoked = FALSE AND expires_at > NOW()
    )::NUMERIC(10,2) AS avg_ttl_hours,
    
    -- Kill-Switch Metrics
    (
        SELECT COUNT(*)
        FROM participant_certificates
        WHERE revoked = TRUE
          AND revoked_at >= NOW() - INTERVAL '24 hours'
    ) AS revoked_last_24h,
    
    -- Renewal Window
    (
        SELECT COUNT(*)
        FROM participant_certificates
        WHERE revoked = FALSE
          AND expires_at > NOW()
          AND expires_at <= NOW() + INTERVAL '30 minutes'
    ) AS expiring_within_30m,
    
    -- Worst-Case Revocation Window
    -- Calculated as: max_ttl_hours * 3600 + policy_propagation_seconds (60)
    (
        SELECT COALESCE(
            (EXTRACT(EPOCH FROM MAX(expires_at - issued_at)) + 60)::INTEGER,
            14460  -- Default: 4h + 60s
        )
        FROM participant_certificates
        WHERE revoked = FALSE AND expires_at > NOW()
    ) AS worst_case_revocation_seconds,
    
    -- Certificate Health by Participant (Top 10 by Active Certs)
    (
        SELECT json_agg(participant_stats)
        FROM (
            SELECT 
                participant_id,
                COUNT(*) FILTER (WHERE revoked = FALSE AND expires_at > NOW()) AS active,
                COUNT(*) FILTER (WHERE revoked = TRUE) AS revoked
            FROM participant_certificates
            GROUP BY participant_id
            ORDER BY active DESC
            LIMIT 10
        ) participant_stats
    ) AS top_participants_by_certs;

COMMENT ON VIEW supervisor_revocation_status IS 
    'Phase-7B: Read-only supervisor view for certificate TTL, revocation posture, and kill-switch effectiveness. No key material exposed.';
