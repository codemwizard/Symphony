CREATE TABLE state_rules (
    from_state TEXT NOT NULL,
    to_state TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    required_decision_type TEXT NOT NULL,
    allowed BOOLEAN NOT NULL,
    rule_priority INT NOT NULL DEFAULT 0,

    UNIQUE(entity_type, from_state, to_state)
);