-- Migration: 0210_p3_lineage_access_control.sql
-- Task: TSK-P3-SUPPORT-SEC-001
-- Description: Establish the shared access-control and privilege model for
--              Phase 3 lineage persistence surfaces.

REVOKE ALL ON TABLE public.p3_dependency_nodes FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.p3_dependency_edges FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.p3_authority_lineage FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.p3_policy_artifacts FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.p3_lineage_continuity_anchors FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;

REVOKE ALL ON TABLE public.p3_typed_dependency_adjacency FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.p3_policy_authority_lineage_projection FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.p3_lineage_persistence_manifest FROM
    symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;

REVOKE ALL ON FUNCTION public.p3_collect_upstream_dependencies(uuid) FROM
    PUBLIC, symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON FUNCTION public.p3_collect_policy_authority_lineage(uuid) FROM
    PUBLIC, symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON FUNCTION public.p3_deny_lineage_mutation() FROM
    PUBLIC, symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;

GRANT SELECT, INSERT ON TABLE public.p3_dependency_nodes TO symphony_executor, symphony_control;
GRANT SELECT, INSERT ON TABLE public.p3_dependency_edges TO symphony_executor, symphony_control;
GRANT SELECT, INSERT ON TABLE public.p3_authority_lineage TO symphony_executor, symphony_control;
GRANT SELECT, INSERT ON TABLE public.p3_policy_artifacts TO symphony_executor, symphony_control;
GRANT SELECT, INSERT ON TABLE public.p3_lineage_continuity_anchors TO symphony_executor, symphony_control;

GRANT SELECT ON TABLE public.p3_dependency_nodes TO symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.p3_dependency_edges TO symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.p3_authority_lineage TO symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.p3_policy_artifacts TO symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.p3_lineage_continuity_anchors TO symphony_readonly, symphony_auditor;

GRANT SELECT ON TABLE public.p3_typed_dependency_adjacency TO
    symphony_executor, symphony_control, symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.p3_policy_authority_lineage_projection TO
    symphony_executor, symphony_control, symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.p3_lineage_persistence_manifest TO
    symphony_executor, symphony_control, symphony_readonly, symphony_auditor;

GRANT EXECUTE ON FUNCTION public.p3_collect_upstream_dependencies(uuid) TO
    symphony_executor, symphony_control, symphony_readonly, symphony_auditor;
GRANT EXECUTE ON FUNCTION public.p3_collect_policy_authority_lineage(uuid) TO
    symphony_executor, symphony_control, symphony_readonly, symphony_auditor;

COMMENT ON FUNCTION public.p3_collect_upstream_dependencies(uuid) IS
    'Deterministic recursive traversal primitive for replay-authoritative Phase 3 typed upstream dependency closure. Granted to runtime writers and verifier-read roles only.';

COMMENT ON FUNCTION public.p3_collect_policy_authority_lineage(uuid) IS
    'Deterministic authority-lineage traversal for a single Phase 3 policy artifact. Granted to runtime writers and verifier-read roles only.';
