/*
 * Wave 8 Crypto Extension for PostgreSQL
 * Provides Ed25519 signature verification for Wave 8 cryptographic enforcement
 * 
 * This extension exports ed25519_verify(message bytea, sig bytea, pubkey bytea) returns boolean
 * Uses libsodium for cryptographic operations
 * 
 * Task: TSK-P2-W8-SEC-002
 * Purpose: PostgreSQL native Ed25519 verification primitive
 */

#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "varatt.h"
#include "sodium.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(ed25519_verify);

/*
 * ed25519_verify(message bytea, sig bytea, pubkey bytea) returns boolean
 * 
 * Verifies an Ed25519 signature against a message and public key
 * 
 * Parameters:
 *   message: The message bytes that were signed (bytea)
 *   sig: The 64-byte Ed25519 signature (bytea)
 *   pubkey: The 32-byte Ed25519 public key (bytea)
 * 
 * Returns:
 *   true if signature is valid, false otherwise
 * 
 * SQLSTATE errors:
 *   XX000 on internal crypto library error
 *   22023 on invalid input format
 */
Datum
ed25519_verify(PG_FUNCTION_ARGS)
{
    Datum message_datum;
    Datum sig_datum;
    Datum pubkey_datum;
    struct varlena *message_data;
    struct varlena *sig_data;
    struct varlena *pubkey_data;
    size_t message_len;
    size_t sig_len;
    size_t pubkey_len;
    int result;
    
    /* Extract parameters */
    if (PG_ARGISNULL(0) || PG_ARGISNULL(1) || PG_ARGISNULL(2)) {
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("message, signature, and public key cannot be NULL")));
    }
    
    message_datum = PG_GETARG_DATUM(0);
    sig_datum = PG_GETARG_DATUM(1);
    pubkey_datum = PG_GETARG_DATUM(2);
    
    message_data = (struct varlena *) PG_DETOAST_DATUM(message_datum);
    sig_data = (struct varlena *) PG_DETOAST_DATUM(sig_datum);
    pubkey_data = (struct varlena *) PG_DETOAST_DATUM(pubkey_datum);
    
    message_len = VARSIZE(message_data) - VARHDRSZ;
    sig_len = VARSIZE(sig_data) - VARHDRSZ;
    pubkey_len = VARSIZE(pubkey_data) - VARHDRSZ;
    
    if (sig_len != crypto_sign_ed25519_BYTES) {
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
            errmsg("Invalid signature length: expected %zu, got %zu", 
                   (size_t)crypto_sign_ed25519_BYTES, sig_len)));
    }
    
    if (pubkey_len != crypto_sign_ed25519_PUBLICKEYBYTES) {
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
            errmsg("Invalid public key length: expected %zu, got %zu", 
                   (size_t)crypto_sign_ed25519_PUBLICKEYBYTES, pubkey_len)));
    }
    
    result = crypto_sign_verify_detached(
        (const unsigned char *) VARDATA(sig_data),
        (const unsigned char *) VARDATA(message_data),
        message_len,
        (const unsigned char *) VARDATA(pubkey_data)
    );
    
    if (result < 0) {
        /* libsodium error */
        ereport(ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                 errmsg("Ed25519 verification failed: libsodium error")));
    }
    
    /* Return result (0 = success, -1 = failure) */
    PG_RETURN_BOOL(result == 0);
}

/*
 * Extension initialization function
 */
void
_PG_init(void)
{
    /* Initialize libsodium if not already initialized */
    if (sodium_init() < 0) {
        ereport(ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                 errmsg("failed to initialize libsodium")));
    }
}
