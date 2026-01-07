import { checkPolicyVersion } from "../db/policy.js";
import { checkKillSwitch } from "../db/killSwitch.js";
import { logger } from "../logging/logger.js";

export async function bootstrap(serviceName: string) {
    logger.info({ serviceName }, "Bootstrapping service");

    await checkPolicyVersion();
    await checkKillSwitch();

    logger.info({ serviceName }, "Startup checks passed");
}
