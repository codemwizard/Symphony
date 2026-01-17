-- INV-EXEC-01: Idempotency
INSERT INTO instructions (id, client_id, client_request_id, status)
VALUES ('i1', 'c1', 'req-1', 'RECEIVED');

-- Must fail
INSERT INTO instructions (id, client_id, client_request_id, status)
VALUES ('i2', 'c1', 'req-1', 'RECEIVED');

-- INV-EXEC-02: Terminal immutability
UPDATE instructions SET status = 'PROCESSING'
WHERE status IN ('COMPLETED', 'FAILED');

-- INV-EXEC-03: Attempts append-only
DELETE FROM transaction_attempts;

-- INV-EXEC-04: Invalid retry
INSERT INTO transaction_attempts (instruction_id, status)
VALUES ('i1', 'SUCCESS');

INSERT INTO transaction_attempts (instruction_id, status)
VALUES ('i1', 'RETRY');

-- INV-EXEC-05: Audit immutability
DELETE FROM audit_log;
