using System.Text.Json;

record InstructionStatusProjection(
    string instruction_id,
    string tenant_id,
    string participant_id,
    string rail_type,
    string status,
    string attestation_id,
    string outbox_id,
    string payload_hash,
    long amount_minor,
    string currency_code,
    string? correlation_id,
    string as_of_utc,
    string projection_version
);

record EvidencePack(
    string api_version,
    string schema_version,
    string instruction_id,
    string tenant_id,
    string attestation_id,
    string outbox_id,
    string payload_hash,
    string? signature_hash,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref,
    string written_at_utc,
    object[] timeline,
    string as_of_utc,
    string projection_version
);

record EscrowSummaryProjection(
    string escrow_id,
    string tenant_id,
    string? program_id,
    string state,
    long authorized_amount_minor,
    string currency_code,
    string as_of_utc,
    string projection_version
);

record ProgramMemberSummaryProjection(
    string tenant_id,
    string program_id,
    long active_member_count,
    long verified_member_count,
    string as_of_utc,
    string projection_version
);

record RegulatoryIncidentCaseProjection(
    string incident_id,
    string tenant_id,
    string incident_type,
    string detected_at,
    string description,
    string severity,
    string status,
    string? reported_to_boz_at,
    string? boz_reference,
    string created_at,
    JsonElement timeline,
    string as_of_utc,
    string projection_version
);
