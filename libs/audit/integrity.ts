import { AuditRecordV1 } from "./schema.js";
import crypto from "crypto";
import fs from "fs";
import path from "path";

/**
 * Audit Integrity Verifier
 * Validates the cryptographic chain of audit records.
 */
export function verifyAuditChain(auditFilePath: string): {
    valid: boolean;
    violationIndex?: number;
    reason?: string
} {
    if (!fs.existsSync(auditFilePath)) {
        return { valid: true }; // No logs to verify
    }

    const lines = fs.readFileSync(auditFilePath, "utf8").trim().split("\n");
    let lastHash = "0".repeat(64); // Initial Genesis Hash

    for (let i = 0; i < lines.length; i++) {
        try {
            const record = JSON.parse(lines[i]) as AuditRecordV1;

            // Verify prevHash link
            if (record.integrity.prevHash !== lastHash) {
                return {
                    valid: false,
                    violationIndex: i,
                    reason: `Chain broken at record ${i}: prevHash mismatch. Expected ${lastHash}, found ${record.integrity.prevHash}`
                };
            }

            // Verify record hash
            const recordCopy = { ...record };
            const actualHash = record.integrity.hash;

            // Remove integrity field to reconstruct the content that was hashed
            const { integrity, ...contentsOnly } = record;
            const computedHash = crypto.createHash("sha256")
                .update(JSON.stringify(contentsOnly) + record.integrity.prevHash)
                .digest("hex");

            if (computedHash !== actualHash) {
                return {
                    valid: false,
                    violationIndex: i,
                    reason: `Integrity violation at record ${i}: hash mismatch. Computed ${computedHash}, found ${actualHash}`
                };
            }

            lastHash = actualHash;
        } catch (e) {
            return {
                valid: false,
                violationIndex: i,
                reason: `Format error at record ${i}: ${eval(e as any).message}`
            };
        }
    }

    return { valid: true };
}
