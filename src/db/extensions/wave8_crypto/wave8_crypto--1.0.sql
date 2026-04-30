-- Wave 8 Crypto Extension SQL Binding
-- Binds the C function ed25519_verify to SQL callable surface
-- Task: TSK-P2-W8-SEC-002

/* Adjust this setting to control where the objects get created.
SET search_path = public;
*/

CREATE OR REPLACE FUNCTION ed25519_verify(message bytea, sig bytea, pubkey bytea)
RETURNS boolean
AS 'MODULE_PATHNAME', 'ed25519_verify'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

COMMENT ON FUNCTION ed25519_verify(bytea, bytea, bytea) IS
    'Ed25519 signature verification function. Verifies a 64-byte Ed25519 signature against a message and 32-byte public key. Returns true if valid, false otherwise. Implemented via libsodium in wave8_crypto extension.';
