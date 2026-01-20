import { RequestContext } from "../context/requestContext.js";
import { Capability } from "./capabilities.js";
import { authorize, Policy } from "./authorize.js";
import { logger } from "../logging/logger.js";
import path from "path";
import { assertPolicyVersionPinned, readPolicyFile } from "../policy/policyIntegrity.js";
import { DbRole } from "../db/roles.js";

/**
 * Reusable Authorization Guard
 */
export async function requireCapability(
    role: DbRole,
    requestedCapability: Capability,
    currentService: string
) {
    const context = RequestContext.get();

    // Load Active Policy (Simulated for Phase 6.3)
    // In v1, we assume the global policy is at the fixed location
    const policyPath = path.join(".symphony", "policies", "global-policy.v1.json");
    const activePolicy = readPolicyFile<Policy>(policyPath);
    assertPolicyVersionPinned(activePolicy.policyVersion);

    const isAuthorized = await authorize(role, context, requestedCapability, currentService, activePolicy);

    if (!isAuthorized) {
        logger.error({
            requestId: context.requestId,
            subjectId: context.subjectId,
            capability: requestedCapability,
            decision: 'DENY'
        }, "Authorization Failed - Access Denied");
        throw new Error(`Forbidden: Missing capability ${requestedCapability}`);
    }

    logger.info({
        requestId: context.requestId,
        subjectId: context.subjectId,
        capability: requestedCapability,
        decision: 'ALLOW'
    }, "Authorization Successful");
}
