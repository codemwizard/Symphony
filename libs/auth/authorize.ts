import { ValidatedIdentityContext } from "../context/identity.js";
import { Capability, CAPABILITY_OU_MAP, RESTRICTED_CLIENT_CLASSES } from "./capabilities.js";
import { logger } from "../logging/logger.js";
import { auditLogger } from "../audit/logger.js";

export interface Policy {
    policyVersion: string;
    mode?: 'EMERGENCY_LOCKDOWN' | 'NORMAL';
    capabilities: {
        service?: Record<string, string[]>;
        client?: Record<string, string[]>;
        user?: Record<string, string[]>; // Added user capabilities
    };
}

const TENANT_SCOPED_CAPABILITIES: Capability[] = [
    'transaction:execute',
    'account:read',
    'ledger:write'
];

/**
 * Authorization Engine
 * Enforces the 4 critical architectural guards + Tenant Boundary (Guard 5).
 */
export async function authorize(
    context: ValidatedIdentityContext,
    requestedCapability: Capability,
    currentService: string,
    activePolicy: Policy,
    resourceTenantId?: string
): Promise<boolean> {

    const { subjectId, subjectType, policyVersion } = context;

    // Guard 1: Emergency Lockdown Short-Circuit
    if (activePolicy.mode === 'EMERGENCY_LOCKDOWN') {
        const reason = "EMERGENCY_LOCKDOWN active - evaluating recovery path only";
        logger.warn({ requestId: context.requestId }, reason);
        const allowed = (activePolicy.capabilities.service?.[currentService] || []) as Capability[];
        const isAllowed = allowed.includes(requestedCapability);

        await auditLogger.log({
            type: isAllowed ? 'AUTHZ_ALLOW' : 'AUTHZ_DENY',
            context,
            action: { capability: requestedCapability },
            decision: isAllowed ? 'ALLOW' : 'DENY',
            reason
        });

        return isAllowed;
    }

    // Guard 2: OU Boundary Assertion
    const owningOU = CAPABILITY_OU_MAP[requestedCapability];
    if (owningOU !== currentService) {
        const reason = "OU Boundary Violation: Service attempted to exercise capability it does not own";
        logger.error({ requestedCapability, currentService, owningOU }, reason);

        await auditLogger.log({
            type: 'AUTHZ_DENY',
            context,
            action: { capability: requestedCapability },
            decision: 'DENY',
            reason
        });

        return false; // Hard Deny
    }

    // Guard 3: Client Restriction Invariant
    if (subjectType === 'client') {
        const isRestricted = RESTRICTED_CLIENT_CLASSES.some(prefix => requestedCapability.startsWith(prefix));
        if (isRestricted) {
            const reason = "Client Restriction Violation: Client attempted execution-class activity";
            logger.error({ subjectId, requestedCapability }, reason);

            await auditLogger.log({
                type: 'AUTHZ_DENY',
                context,
                action: { capability: requestedCapability },
                decision: 'DENY',
                reason
            });

            return false; // Hard Deny
        }
    }

    // Guard 4: Provider Isolation
    if (requestedCapability === 'provider:health:write' && subjectType === 'client') {
        const reason = "Provider Isolation Violation: Client attempted health-poisoning activity";
        logger.error({ subjectId }, reason);

        await auditLogger.log({
            type: 'AUTHZ_DENY',
            context,
            action: { capability: requestedCapability },
            decision: 'DENY',
            reason
        });

        return false; // Hard Deny
    }

    // Normal Entitlement Check Chain
    // Link 1: Service Boundary Gate
    const serviceAllowed = (activePolicy.capabilities.service?.[currentService] || []) as Capability[];
    if (!serviceAllowed.includes(requestedCapability)) return false;

    // Link 2: Actor Permission (Subject Type)
    if (subjectType === 'client') {
        const clientAllowed = (activePolicy.capabilities.client?.['default'] || []) as Capability[];
        if (!clientAllowed.includes(requestedCapability)) return false;
    } else if (subjectType === 'user') {
        const userAllowed = (activePolicy.capabilities.user?.['default'] || []) as Capability[];
        if (!userAllowed.includes(requestedCapability)) {
            await auditLogger.log({
                type: 'AUTHZ_DENY',
                context,
                action: { capability: requestedCapability },
                decision: 'DENY',
                reason: 'CAPABILITY_NOT_ALLOWED'
            });
            return false;
        }

        // Guard 5: Tenant Boundary Enforcement
        if (TENANT_SCOPED_CAPABILITIES.includes(requestedCapability)) {
            if (!resourceTenantId) {
                await auditLogger.log({
                    type: 'AUTHZ_DENY',
                    context,
                    reason: 'TENANT_CONTEXT_MISSING',
                    decision: 'DENY'
                });
                return false;
            }
            if (context.participantId !== resourceTenantId) {
                await auditLogger.log({
                    type: 'AUTHZ_DENY',
                    context,
                    reason: 'CROSS_TENANT_ACCESS_DENIED',
                    decision: 'DENY'
                    // metadata: { ... } - AuditLogger schema V1 doesn't support free-form metadata in log params yet, must rely on reason or action resource.
                    // If we strictly follow AuditRecordV1, we can't add random fields. We'll simplify.
                });
                return false;
            }
        }
    }

    // Link 3: Policy Version Parity
    if (policyVersion !== activePolicy.policyVersion) {
        const reason = "Policy Version Mismatch during Authorization";
        logger.error({ contextVersion: policyVersion, policyVersion: activePolicy.policyVersion }, reason);

        await auditLogger.log({
            type: 'AUTHZ_DENY',
            context,
            action: { capability: requestedCapability },
            decision: 'DENY',
            reason
        });

        return false;
    }

    // Final Success Audit
    await auditLogger.log({
        type: 'AUTHZ_ALLOW',
        context,
        action: { capability: requestedCapability },
        decision: 'ALLOW'
    });

    return true;
}
