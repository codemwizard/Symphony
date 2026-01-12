import { bootstrap } from "../../../libs/bootstrap/startup.js";
import { logger, getContextLogger } from "../../../libs/logging/logger.js";
import { ProductionKeyManager, KeyManager } from "../../../libs/crypto/keyManager.js";
import { ConfigGuard, CRYPTO_CONFIG_REQUIREMENTS } from "../../../libs/bootstrap/config-guard.js";
import { ErrorSanitizer } from "../../../libs/errors/sanitizer.js";
import { createValidator } from "../../../libs/validation/zod-middleware.js";
import { IdentityEnvelopeSchema, IngestRequestSchema } from "../../../libs/validation/schema.js";
import { Iso20022Validator } from "../../../libs/iso20022/validator.js";
import { db } from "../../../libs/db/index.js";
import { verifyIdentity } from "../../../libs/context/verifyIdentity.js";
import { RequestContext } from "../../../libs/context/requestContext.js";
import { IdentityEnvelopeV1 } from "../../../libs/context/identity.js";
import { requireCapability } from "../../../libs/auth/requireCapability.js";
import { auditLogger } from "../../../libs/audit/logger.js";


async function main() {
    db.setRole("symphony_ingest");
    await bootstrap("ingest-api");

    // CRIT-SEC-003: Fail-Closed Security Configuration
    ConfigGuard.enforce(CRYPTO_CONFIG_REQUIREMENTS);

    logger.info("Ingest API initialized (OU-04)");

    // Dependency Injection for KeyManager (Phase 6.3)
    const keyManager: KeyManager = new ProductionKeyManager();

    // Simulated Request Flow
    async function onInstructionReceived(envelope: IdentityEnvelopeV1) {
        try {
            // Phase 6.3: Refactored to use KeyManager injection
            // HIGH-SEC-002: Input Validation (Zod)
            const validateEnvelope = createValidator(IdentityEnvelopeSchema);
            validateEnvelope(envelope, "IngestAPI:Identity");

            const context = await verifyIdentity(envelope, "ingest-api", keyManager);
            RequestContext.set(context);

            // Phase 6.3: Authorization
            await requireCapability('instruction:submit', 'ingest-api');

            // Phase 6.5: Audit
            await auditLogger.log({
                type: 'IDENTITY_VERIFY',
                context,
                decision: 'ALLOW'
            });

            await auditLogger.log({
                type: 'INSTRUCTION_SUBMIT',
                context,
                decision: 'EXECUTED'
            });

            const ctxLogger = getContextLogger(context);
            ctxLogger.info("Instruction received from verified and authorized subject");

            // HIGH-SEC-002: Instruction Payload Validation (Zod)
            // In a real implementation, 'payload' would be part of the request body
            const mockPayload = {
                client_request_id: envelope.requestId,
                instruction_type: 'payment_transfer',
                payload: {
                    amount: '100.00',
                    currency: 'USD',
                    debtorAccount: '01ARR8B258838B25C6D735D1F6', // Mock ULID
                    creditorAccount: '01ARR8B258838B25C6D735D1F7',
                }
            };

            const validatePayload = createValidator(IngestRequestSchema);
            const validRequest = validatePayload(mockPayload, "IngestAPI:InstructionPayload");

            // HIGH-SEC-001: ISO-20022 Compliance Hook
            Iso20022Validator.validateSchema({
                CdtTrfTxInf: [{
                    PmtId: { TxId: validRequest.client_request_id },
                    IntrBkSttlmAmt: {
                        Amount: parseFloat(validRequest.payload.amount),
                        Currency: validRequest.payload.currency
                    },
                }],
            }, 'pacs.008');


            // Process instruction...
        } catch (err) {
            // HIGH-SEC-003: Prevent information disclosure
            throw ErrorSanitizer.sanitize(err, "IngestAPI:InstructionHandler");
        } finally {
            RequestContext.clear();
        }
    }
}

main().catch(err => {
    logger.fatal(err);
    process.exit(1);
});
