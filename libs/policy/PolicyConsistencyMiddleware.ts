/**
 * Phase-7R: Policy Consistency Middleware
 * 
 * This module implements distributed policy enforcement by embedding
 * policy_scope and policy_version in access tokens, with real-time
 * version validation against the global policy state.
 * 
 * Principle: Trust identity, not topology.
 * Every service re-validates policy even for trusted internal requests.
 * 
 * @see PHASE-7R-implementation_plan.md Section "Policy Consistency"
 */

import { Request, Response, NextFunction } from 'express';
import { Pool } from 'pg';
import pino from 'pino';

import crypto from 'crypto';

const logger = pino({ name: 'PolicyConsistency' });

/**
 * Canonicalize policy version string for semantic comparison.
 * Removes trailing whitespace, newlines, and normalizes Unicode.
 * This does NOT weaken the invariant - it enforces semantic identity.
 */
function canonicalPolicyVersion(version: string): string {
    return version.trim().normalize('NFKC');
}

/**
 * Hash a string for debug logging (proves byte-level identity)
 */
function hashForDebug(value: string): string {
    return crypto.createHash('sha256').update(value).digest('hex').substring(0, 16);
}

// Configuration
const POLICY_CACHE_TTL_MS = 5000; // 5 seconds cache for performance
const POLICY_STALE_THRESHOLD_MS = 60000; // 60 seconds before hard fail

/**
 * Policy claims embedded in JWT/mTLS identity
 */
export interface PolicyClaims {
    policyVersion: string;
    policyScope: string;
    participantId: string;
    capabilities: string[];
    issuedAt: number;
    expiresAt: number;
}

/**
 * Global policy state
 */
export interface GlobalPolicyState {
    activeVersion: string;
    activatedAt: Date;
    scopes: Map<string, PolicyScope>;
}

/**
 * Policy scope definition
 */
export interface PolicyScope {
    scopeId: string;
    maxTransactionAmount: number;
    allowedOperations: string[];
    dailyLimit: number;
    hourlyLimit: number;
}

/**
 * Error thrown when policy validation fails
 */
export class PolicyViolationError extends Error {
    readonly code: string;
    readonly statusCode: number;

    constructor(code: string, message: string, statusCode = 403) {
        super(message);
        this.name = 'PolicyViolationError';
        this.code = code;
        this.statusCode = statusCode;
    }
}

/**
 * Cached policy state
 */
let cachedPolicyState: GlobalPolicyState | null = null;
let policyCacheTime: number = 0;

/**
 * Policy Consistency Service
 * 
 * Validates that token policy claims match current global policy.
 */
export class PolicyConsistencyService {
    constructor(
        private readonly pool: Pool
    ) { }

    /**
     * Get current global policy state (cached)
     */
    public async getGlobalPolicyState(): Promise<GlobalPolicyState> {
        const now = Date.now();

        if (cachedPolicyState && (now - policyCacheTime) < POLICY_CACHE_TTL_MS) {
            return cachedPolicyState;
        }

        const result = await this.pool.query(`
            SELECT 
                version,
                activated_at
            FROM policy_versions
            WHERE status = 'ACTIVE'
            ORDER BY activated_at DESC
            LIMIT 1;
        `);

        if (result.rows.length === 0) {
            throw new PolicyViolationError(
                'NO_ACTIVE_POLICY',
                'No active policy version found',
                500
            );
        }

        const row = result.rows[0];

        // Load scopes
        const scopesResult = await this.pool.query(`
            SELECT *
            FROM policy_scopes
            WHERE policy_version = $1;
        `, [row.version]);

        const scopes = new Map<string, PolicyScope>();
        for (const scope of scopesResult.rows) {
            scopes.set(scope.scope_id, {
                scopeId: scope.scope_id,
                maxTransactionAmount: scope.max_transaction_amount,
                allowedOperations: scope.allowed_operations,
                dailyLimit: scope.daily_limit,
                hourlyLimit: scope.hourly_limit
            });
        }

        cachedPolicyState = {
            activeVersion: row.version,
            activatedAt: row.activated_at,
            scopes
        };
        policyCacheTime = now;

        return cachedPolicyState;
    }

    /**
     * Validate policy claims against current global state
     */
    public async validatePolicyClaims(claims: PolicyClaims): Promise<void> {
        const globalState = await this.getGlobalPolicyState();

        // Check 1: Version match (canonical comparison for Phase-7R)
        const canonicalTokenVersion = canonicalPolicyVersion(claims.policyVersion);
        const canonicalGlobalVersion = canonicalPolicyVersion(globalState.activeVersion);

        if (canonicalTokenVersion !== canonicalGlobalVersion) {
            logger.warn({
                event: 'POLICY_VERSION_MISMATCH',
                tokenVersion: claims.policyVersion,
                globalVersion: globalState.activeVersion,
                tokenHash: hashForDebug(claims.policyVersion),
                globalHash: hashForDebug(globalState.activeVersion),
                participantId: claims.participantId
            });

            throw new PolicyViolationError(
                'POLICY_VERSION_STALE',
                `Token policy version ${claims.policyVersion} does not match active version ${globalState.activeVersion}. Re-authentication required.`,
                401
            );
        }

        // Check 2: Scope exists
        const scope = globalState.scopes.get(claims.policyScope);
        if (!scope) {
            throw new PolicyViolationError(
                'POLICY_SCOPE_INVALID',
                `Policy scope ${claims.policyScope} is not recognized`,
                403
            );
        }

        // Check 3: Token not expired
        if (claims.expiresAt < Date.now()) {
            throw new PolicyViolationError(
                'TOKEN_EXPIRED',
                'Access token has expired',
                401
            );
        }

        // Check 4: Token not too stale (issued too long ago)
        const tokenAge = Date.now() - claims.issuedAt;
        if (tokenAge > POLICY_STALE_THRESHOLD_MS * 60) { // 1 hour max age
            throw new PolicyViolationError(
                'TOKEN_TOO_OLD',
                'Access token is too old, please re-authenticate',
                401
            );
        }

        logger.debug({
            event: 'POLICY_VALIDATED',
            participantId: claims.participantId,
            policyVersion: claims.policyVersion,
            scope: claims.policyScope
        });
    }

    /**
     * Check if an operation is allowed by policy scope
     */
    public async isOperationAllowed(
        claims: PolicyClaims,
        operation: string,
        amount?: number
    ): Promise<boolean> {
        const globalState = await this.getGlobalPolicyState();
        const scope = globalState.scopes.get(claims.policyScope);

        if (!scope) {
            return false;
        }

        // Check operation allowed
        if (!scope.allowedOperations.includes(operation)) {
            logger.warn({
                event: 'OPERATION_NOT_ALLOWED',
                operation,
                participantId: claims.participantId,
                scope: claims.policyScope
            });
            return false;
        }

        // Check amount limit
        if (amount !== undefined && amount > scope.maxTransactionAmount) {
            logger.warn({
                event: 'AMOUNT_EXCEEDS_LIMIT',
                amount,
                limit: scope.maxTransactionAmount,
                participantId: claims.participantId
            });
            return false;
        }

        return true;
    }

    /**
     * Invalidate policy cache (for immediate propagation)
     */
    public invalidateCache(): void {
        cachedPolicyState = null;
        policyCacheTime = 0;
        logger.info({ event: 'POLICY_CACHE_INVALIDATED' });
    }
}

/**
 * Express Middleware Factory
 * 
 * Creates middleware that validates policy claims on every request.
 */
export function createPolicyConsistencyMiddleware(pool: Pool) {
    const service = new PolicyConsistencyService(pool);

    return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
        try {
            // Extract policy claims from request (attached by auth middleware)
            const claims = (req as { policyClaims?: PolicyClaims }).policyClaims;

            if (!claims) {
                // Skip for unauthenticated routes
                return next();
            }

            // Validate policy consistency
            await service.validatePolicyClaims(claims);

            // Attach scope for downstream use
            const globalState = await service.getGlobalPolicyState();
            (req as { policyScope?: PolicyScope }).policyScope =
                globalState.scopes.get(claims.policyScope);

            next();
        } catch (error) {
            next(error);
        }
    };
}

/**
 * Create policy claims for JWT embedding
 */
export function createPolicyClaims(
    participantId: string,
    policyVersion: string,
    policyScope: string,
    capabilities: string[],
    ttlSeconds: number = 3600
): PolicyClaims {
    const now = Date.now();

    return {
        participantId,
        policyVersion,
        policyScope,
        capabilities,
        issuedAt: now,
        expiresAt: now + (ttlSeconds * 1000)
    };
}

export { PolicyConsistencyService };
