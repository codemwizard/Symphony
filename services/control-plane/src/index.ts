import { bootstrap } from "../../../libs/bootstrap/startup.js";
import { logger, getContextLogger } from "../../../libs/logging/logger.js";
import { ProductionKeyManager, KeyManager } from "../../../libs/crypto/keyManager.js";
import { ConfigGuard, CRYPTO_CONFIG_REQUIREMENTS } from "../../../libs/bootstrap/config-guard.js";
import { ErrorSanitizer } from "../../../libs/errors/sanitizer.js";
import { createValidator } from "../../../libs/validation/zod-middleware.js";
import { IdentityEnvelopeV1Schema } from "../../../libs/validation/identitySchema.js";
import { IdentityEnvelopeV1Schema } from "../../../libs/validation/identitySchema.js";
import { db } from "../../../libs/db/index.js";
import { verifyIdentity } from "../../../libs/context/verifyIdentity.js";
import { RequestContext } from "../../../libs/context/requestContext.js";
import { IdentityEnvelopeV1 } from "../../../libs/context/identity.js";
import { requireCapability } from "../../../libs/auth/requireCapability.js";
import { auditLogger } from "../../../libs/audit/logger.js";


async function main() {
    db.setRole("symphony_control");
    await bootstrap("control-plane");

    // CRIT-SEC-003: Fail-Closed Security Configuration
    ConfigGuard.enforce(CRYPTO_CONFIG_REQUIREMENTS);

    logger.info("Control Plane initialized (OU-01 / OU-03)");

    // Dependency Injection for KeyManager (Phase 6.3)
    const keyManager: KeyManager = new ProductionKeyManager();

    // Simulated Request Handler
    async function _handleRequest(envelope: IdentityEnvelopeV1) {
        // HIGH-SEC-002: Input Validation (Zod)
        const validateEnvelope = createValidator(IdentityEnvelopeV1Schema);
        const validateEnvelope = createValidator(IdentityEnvelopeV1Schema);
        validateEnvelope(envelope, "ControlPlane:Identity");

        const context = await verifyIdentity(envelope, "control-plane", keyManager);

        // SEC-7R-FIX: Use AsyncLocalStorage run() for request-scoped context
        return RequestContext.run(context, async () => {
            try {
                // Phase 6.3: Authorization
                await requireCapability('route:configure', 'control-plane');

                // Phase 6.5: Audit
                await auditLogger.log({
                    type: 'IDENTITY_VERIFY',
                    context,
                    decision: 'ALLOW'
                });

                const ctxLogger = getContextLogger(context);
                ctxLogger.info("Processing request under verified context and authorized capability");

                // Handler logic here...
            } catch (err) {
                // HIGH-SEC-003: Prevent information disclosure
                throw ErrorSanitizer.sanitize(err, "ControlPlane:RequestHandler");
            }
        });
    }
}

main().catch(err => {
    logger.fatal(err);
    process.exit(1);
});
