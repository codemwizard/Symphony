-- Migration: 0206_phase3_invariant_registry_seed.sql
-- Task: TSK-P3-GOV-002
-- Description: Seed INV-301 through INV-310 into invariant_registry at roadmap status.
--              Source: docs/PHASE3/PHASE3_INVARIANT_REGISTER.md (Authority-Rank 8)
--              Addresses Gap 5 from SYMPHONY_GROUND_TRUTH_REMEDIATION_REPORT.md
--
-- Note: invariant_registry (migration 0163) is append-only.
--       is_blocking = FALSE means roadmap status — not yet enforcement.
--       Promotion to is_blocking = TRUE requires human authorization and
--       a valid checksum of the verifier script.
--       Placeholder checksum is used until verifier scripts exist.

-- Placeholder checksum: SHA-256 of 'ROADMAP_PLACEHOLDER_<invariant_id>'
-- Must be replaced with actual verifier script hash on promotion.

INSERT INTO public.invariant_registry
    (invariant_id, verifier_type, severity, execution_layer, is_blocking, checksum, description)
VALUES
    ('INV-301', 'regulatory_sovereignty_partitioning',   'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Legitimacy engine enforces regulator-specific rule sets independently; no cross-regime equivalence is asserted'),

    ('INV-302', 'typed_dependency_graph',                'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Every decision record declares its typed upstream dependencies; the dependency graph is machine-traversable'),

    ('INV-303', 'recursive_legitimacy_engine',           'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Any decision with an illegitimate ancestor is blocked; legitimacy is evaluated recursively upward'),

    ('INV-304', 'contradiction_detection',               'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Direct, temporal, and authority-based contradictions are mechanically blocked; contradiction records are append-only'),

    ('INV-305', 'cross_system_evidence_continuity',      'CRITICAL', 'CI',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Evidence records traversing internal system boundaries preserve complete provenance lineage and remain replay-survivable'),

    ('INV-306', 'failure_composition_engine',            'HIGH',     'CI',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'All rejections produce structured, traversable failure records; failure records are append-only constitutional evidence'),

    ('INV-307', 'authority_scope_engine',                'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Every authority claim is scoped to its declared resource; delegation is traceable through the dependency graph'),

    ('INV-308', 'conflict_of_interest_enforcement',      'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Submitters cannot be verifiers for the same decision or asset; enforcement is at DB layer'),

    ('INV-309', 'spatial_legality_dnsh_gates',           'CRITICAL', 'DB',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Spatial legality and DNSH enforcement apply to all decision types, not only project registration'),

    ('INV-310', 'dwell_time_forensic_enforcement',       'HIGH',     'CI',
     false, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'Temporal anomalies in decision timelines are mechanically detected and enforced');

-- Verification query (for CI gate):
-- SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%';
-- Expected: 10
