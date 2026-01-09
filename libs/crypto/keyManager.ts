import crypto from "crypto";
import { logger } from "../logging/logger.js";
// This is a production key manager for the Symphony platform.
import { KMSClient, GenerateDataKeyCommand, DecryptCommand } from "@aws-sdk/client-kms";

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
            region: process.env.KMS_REGION,
            endpoint: process.env.KMS_ENDPOINT,
            credentials: {
                accessKeyId: process.env.KMS_ACCESS_KEY_ID!,
                secretAccessKey: process.env.KMS_SECRET_ACCESS_KEY!,
            }
        });
    }

    async deriveKey(purpose: string): Promise<string> {
        try {
            // Mapping purpose to KeyId. 
            // In a real scenario, this would be more sophisticated or use Aliases.
            // For now, we assume a single Master Key or Alias available in the local KMS.
            // Using 'alias/symphony-root' as a default if not configured.
            const keyId = process.env.KMS_KEY_ID || 'alias/symphony-root';

            const command = new GenerateDataKeyCommand({
                KeyId: keyId,
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
        } catch (error: any) {
            logger.error({
                error: error.message,
                code: error.code,
                purpose
            }, "KMS derivation failed");

            // Fail-Closed: Do not fallback.
            throw new Error(`SymphonyKeyManager: KMS derivation failed for purpose '${purpose}': ${error.message}`);
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
