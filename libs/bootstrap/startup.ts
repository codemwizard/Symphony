import { checkPolicyVersion } from "../db/policy.js";
import { checkKillSwitch } from "../db/killSwitch.js";
import { logger } from "../logging/logger.js";
import { enforceAuditImmutability } from "../audit/immutability.js";
import { enforceMtlsConfig } from "./mtls-guard.js";

export async function bootstrap(serviceName: string) {
    logger.info({ serviceName }, "Bootstrapping service");

    enforceAuditImmutability();
    enforceMtlsConfig();

    await checkPolicyVersion();
    await checkKillSwitch();

    logger.info({ serviceName }, "Startup checks passed");
}
