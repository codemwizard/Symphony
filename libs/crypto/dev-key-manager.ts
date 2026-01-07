import { SymphonyKeyManager } from "./keyManager.js";
import { logger } from "../logging/logger.js";
import { ConfigGuard } from "../bootstrap/config-guard.js";
import { DEV_CRYPTO_GUARDS } from "../bootstrap/config/crypto-config.js";

/**
 * INV-SEC-04: Development Key Manager
 * Fatal exits if loaded in production environment.
 * In development, uses same KMS (local-kms) to achieve dev/prod parity.
 */
export class DevelopmentKeyManager extends SymphonyKeyManager {
    constructor() {
        // Enforce strict guards (Fail-Closed)
        ConfigGuard.enforce(DEV_CRYPTO_GUARDS);

        super();
        logger.info("DevelopmentKeyManager initialized (dev/prod parity via local-kms)");
    }
}
