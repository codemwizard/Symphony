import { logger } from "../logging/logger.js";
// This is a production key manager for the Symphony platform.
import { KMSClient, GenerateDataKeyCommand } from "@aws-sdk/client-kms";

/**
 * SYM-37: Cryptographic Governance Gates
 * Standard interface for key derivation and management.
 */
export interface KeyManager {
    /**
     * Derives a purpose-bound key.
     * INV-SEC-02: Keys are purpose-bound (e.g., 'identity/*', 'audit/*').
     */
    deriveKey(purpose: string): Promise<string>;
}

/**
 * INV-SEC-04: Cryptographic Governance Gates
 * Production-grade KeyManager using KMS/HSM Integration for ALL environments.
 * Achieves full Dev/Prod parity by utilizing local-kms in development.
 */
export class SymphonyKeyManager implements KeyManager {
    private client: KMSClient;

    constructor() {
        this.client = new KMSClient({
            ...(process.env.KMS_REGION ? { region: process.env.KMS_REGION } : {}),
            ...(process.env.KMS_ENDPOINT ? { endpoint: process.env.KMS_ENDPOINT } : {}),
            credentials: {
                accessKeyId: process.env.KMS_ACCESS_KEY_ID!,
                secretAccessKey: process.env.KMS_SECRET_ACCESS_KEY!,
            }
        });
    }

    async deriveKey(purpose: string): Promise<string> {
        // SEC-FIX: Read ONLY KMS_KEY_REF, no fallback, fail-closed
        const keyRef = process.env.KMS_KEY_REF;

        if (!keyRef || keyRef.trim() === '') {
            throw new Error("CRITICAL: KMS_KEY_REF is missing (fail-closed).");
        }

        try {
            const command = new GenerateDataKeyCommand({
                KeyId: keyRef.trim(),
                KeySpec: 'AES_256',
                EncryptionContext: {
                    purpose: purpose,
                    service: 'symphony'
                }
            });

            const response = await this.client.send(command);

            if (!response.Plaintext) {
                throw new Error("KMS: Failed to generate data key - Plaintext missing");
            }

            return Buffer.from(response.Plaintext).toString('base64');
        } catch (error: unknown) {
            const err = error as { message?: string; code?: string; stack?: string };
            // SEC-FIX: Correct operation label
            logger.error({
                error: err.message || String(error),
                code: err.code,
                operation: 'deriveKey',
                keyRef: keyRef.substring(0, 20) + '...' // Safe partial for audit
            }, 'KMS key derivation failed');

            // Fail-Closed: Do not fallback.
            throw new Error(`KMS key derivation failed: ${err.message || String(error)}`);
        }
    }
}

// Dev Key Manager moved to separate file to ensure strict separation.

/**
 * Production Key Manager alias.
 * Uses SymphonyKeyManager which integrates with KMS (AWS KMS or local-kms).
 */
export { SymphonyKeyManager as ProductionKeyManager };

/**
 * INV-SEC-02: Logging Discipline
 * Helper to ensure key material NEVER reaches logs.
 */
export const cryptoAudit = {
    logKeyUsage: (purpose: string, keyId: string) => {
        // We only log the purpose and a safe ID/label, never the key.
        logger.info({ purpose, keyId }, "Cryptographic key derivation invoked");
    }
};
