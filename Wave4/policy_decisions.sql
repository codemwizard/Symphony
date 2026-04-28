CREATE TABLE policy_decisions (
    policy_decision_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    execution_id UUID NOT NULL
        REFERENCES execution_records(execution_id),

    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,

    decision_type TEXT NOT NULL,
    authority_scope TEXT NOT NULL,
    declared_by UUID NOT NULL,

    decision_hash TEXT NOT NULL,
    signature TEXT NOT NULL,
    signed_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE (execution_id, decision_type)
);