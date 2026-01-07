import { RequestContext } from "../context/requestContext.js";
import { Capability } from "./capabilities.js";
import { authorize, Policy } from "./authorize.js";
import { logger } from "../logging/logger.js";
import fs from "fs";
import path from "path";

/**
 * Reusable Authorization Guard
 */
export async function requireCapability(
    requestedCapability: Capability,
    currentService: string
) {
    const context = RequestContext.get();

    // Load Active Policy (Simulated for Phase 6.3)
    // In v1, we assume the global policy is at the fixed location
    const policyPath = path.join(".symphony", "policies", "global-policy.v1.json");
    const activePolicy: Policy = JSON.parse(fs.readFileSync(policyPath, "utf-8"));

    const isAuthorized = await authorize(context, requestedCapability, currentService, activePolicy);

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
