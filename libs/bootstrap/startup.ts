import { checkPolicyVersion } from "../db/policy.js";
import { checkKillSwitch } from "../db/killSwitch.js";
import { logger } from "../logging/logger.js";
import { enforceAuditImmutability } from "../audit/immutability.js";
import { enforceMtlsConfig } from "./mtls-guard.js";
import { db, DbRole } from "../db/index.js";

export async function bootstrap(serviceName: string, role: DbRole) {
    logger.info({ serviceName }, "Bootstrapping service");

    enforceAuditImmutability();
    enforceMtlsConfig();

    await db.probeRoles();
    await checkPolicyVersion(role);
    await checkKillSwitch(role);

    logger.info({ serviceName }, "Startup checks passed");
}
