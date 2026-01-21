/**
 * Phase-7R: Policy Consistency Middleware (Production-Safe)
 * 
 * This module implements distributed policy enforcement by embedding
 * policy_scope and policy_version in access tokens, with real-time
 * version validation against the global policy state.
 * 
 * PRODUCTION FEATURES:
 * - Version Windows: ACTIVE, GRACE (migration), RETIRED states
 * - Grace Period: Prevents "Thunderous Logout" on policy updates
 * - Clock Skew Tolerance: Handles distributed system time drift
 * - Response Headers: Allows frontend graceful re-authentication
 * 
 * Principle: Trust identity, not topology.
 * Every service re-validates policy even for trusted internal requests.
 * 
 * @see PHASE-7R-implementation_plan.md Section "Policy Consistency"
 */

import { Request, Response, NextFunction } from 'express';
import pino from 'pino';
import crypto from 'crypto';
import { KeyManager, SymphonyKeyManager } from '../crypto/keyManager.js';
import { db, DbRole } from '../db/index.js';

const logger = pino({ name: 'PolicyConsistency' });
const keyManager: KeyManager = new SymphonyKeyManager();
let claimsKeyPromise: Promise<Buffer> | null = null;

// =============================================================================
// CONFIGURATION
// =============================================================================

/** Cache TTL for policy state (production: use Redis/Pub-Sub instead) */
const POLICY_CACHE_TTL_MS = 5000;

/** Grace period for version transitions (prevents Thunderous Logout) */
const POLICY_GRACE_PERIOD_MS = 5 * 60 * 1000; // 5 minutes

/** Clock skew tolerance for token expiry checks */
const CLOCK_SKEW_TOLERANCE_MS = 60 * 1000; // 60 seconds

/** Maximum token age before requiring re-authentication */
const MAX_TOKEN_AGE_MS = 60 * 60 * 1000; // 1 hour

// =============================================================================
// HELPERS
// =============================================================================

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

// =============================================================================
// TYPES
// =============================================================================

/**
 * Policy version status for version windows
 */
export type PolicyVersionStatus = 'ACTIVE' | 'GRACE' | 'RETIRED';

/**
 * Policy version with status
 */
export interface PolicyVersionInfo {
    version: string;
    status: PolicyVersionStatus;
    activatedAt: Date;
    gracePeriodEndsAt: Date | null;
}

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
 * Global policy state with version windows
 */
export interface GlobalPolicyState {
    activeVersion: string;
    activatedAt: Date;
    acceptedVersions: Set<string>;  // Versions in ACTIVE or GRACE status
    graceVersions: Set<string>;     // Versions in GRACE status only
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
 * Validation result with metadata
 */
export interface PolicyValidationResult {
    valid: boolean;
    inGracePeriod: boolean;
    requiresReauth: boolean;
    activeVersion: string;
    tokenVersion: string;
}

/**
 * Error thrown when policy validation fails
 */
export class PolicyViolationError extends Error {
    readonly code: string;
    readonly statusCode: number;
    readonly headers: Record<string, string>;

    constructor(
        code: string,
        message: string,
        statusCode = 403,
        headers: Record<string, string> = {}
    ) {
        super(message);
        this.name = 'PolicyViolationError';
        this.code = code;
        this.statusCode = statusCode;
        this.headers = headers;
    }
}

// =============================================================================
// CACHED STATE
// =============================================================================

let cachedPolicyState: GlobalPolicyState | null = null;
let policyCacheTime: number = 0;

// =============================================================================
// SERVICE
// =============================================================================

/**
 * Policy Consistency Service (Production-Safe)
 * 
 * Validates that token policy claims match current global policy.
 * Supports version windows to prevent Thunderous Logout.
 */
export class PolicyConsistencyService {
    constructor(
        private readonly role: DbRole,
        private readonly dbClient = db,
        private readonly gracePeriodMs: number = POLICY_GRACE_PERIOD_MS
    ) { }

    /**
     * Get current global policy state with version windows (cached)
     */
    public async getGlobalPolicyState(): Promise<GlobalPolicyState> {
        const now = Date.now();

        if (cachedPolicyState && (now - policyCacheTime) < POLICY_CACHE_TTL_MS) {
            return cachedPolicyState;
        }

        // Fetch all versions with their status
        const result = await this.dbClient.queryAsRole(
            this.role,
            `
            SELECT 
                id AS version,
                status,
                activated_at,
                CASE 
                    WHEN status = 'GRACE' THEN activated_at + interval '${this.gracePeriodMs / 1000} seconds'
                    ELSE NULL 
                END AS grace_period_ends_at
            FROM policy_versions
            WHERE status IN ('ACTIVE', 'GRACE')
            ORDER BY activated_at DESC;
        `
        );

        if (result.rows.length === 0) {
            throw new PolicyViolationError(
                'NO_ACTIVE_POLICY',
                'No active policy version found',
                500
            );
        }

        // Build version sets
        const acceptedVersions = new Set<string>();
        const graceVersions = new Set<string>();
        let activeVersion = '';
        let activatedAt = new Date();

        for (const row of result.rows) {
            const canonicalVersion = canonicalPolicyVersion(row.version);
            acceptedVersions.add(canonicalVersion);

            if (row.status === 'ACTIVE') {
                activeVersion = canonicalVersion;
                activatedAt = row.activated_at;
            } else if (row.status === 'GRACE') {
                graceVersions.add(canonicalVersion);
            }
        }

        // Load scopes for active version
        const scopesResult = await this.dbClient.queryAsRole(
            this.role,
            `
            SELECT *
            FROM policy_scopes
            WHERE policy_version = $1;
        `,
            [activeVersion]
        );

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
            activeVersion,
            activatedAt,
            acceptedVersions,
            graceVersions,
            scopes
        };
        policyCacheTime = now;

        logger.info({
            event: 'POLICY_STATE_REFRESHED',
            activeVersion,
            acceptedCount: acceptedVersions.size,
            graceCount: graceVersions.size
        });

        return cachedPolicyState;
    }

    /**
     * Check if a version is accepted (ACTIVE or GRACE)
     */
    public async isVersionAccepted(version: string): Promise<PolicyValidationResult> {
        const globalState = await this.getGlobalPolicyState();
        const canonicalVersion = canonicalPolicyVersion(version);

        const inGracePeriod = globalState.graceVersions.has(canonicalVersion);
        const valid = globalState.acceptedVersions.has(canonicalVersion);
        const requiresReauth = !valid || inGracePeriod;

        return {
            valid,
            inGracePeriod,
            requiresReauth,
            activeVersion: globalState.activeVersion,
            tokenVersion: canonicalVersion
        };
    }

    /**
     * Validate policy claims against current global state (Production-Safe)
     */
    public async validatePolicyClaims(claims: PolicyClaims): Promise<PolicyValidationResult> {
        const globalState = await this.getGlobalPolicyState();
        const now = Date.now();

        // Check 1: Version acceptance (with grace period support)
        const versionResult = await this.isVersionAccepted(claims.policyVersion);

        if (!versionResult.valid) {
            logger.warn({
                event: 'POLICY_VERSION_REJECTED',
                tokenVersion: claims.policyVersion,
                activeVersion: globalState.activeVersion,
                tokenHash: hashForDebug(claims.policyVersion),
                activeHash: hashForDebug(globalState.activeVersion),
                participantId: claims.participantId,
                acceptedVersions: Array.from(globalState.acceptedVersions)
            });

            throw new PolicyViolationError(
                'POLICY_VERSION_STALE',
                `Token policy version ${claims.policyVersion} is not accepted. Active: ${globalState.activeVersion}. Re-authentication required.`,
                401,
                {
                    'X-Policy-Update': 'required',
                    'X-Policy-Active-Version': globalState.activeVersion
                }
            );
        }

        // Log grace period usage for monitoring
        if (versionResult.inGracePeriod) {
            logger.info({
                event: 'POLICY_VERSION_IN_GRACE',
                tokenVersion: claims.policyVersion,
                activeVersion: globalState.activeVersion,
                participantId: claims.participantId
            });
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

        // Check 3: Token not expired (with clock skew tolerance)
        if (claims.expiresAt < (now - CLOCK_SKEW_TOLERANCE_MS)) {
            throw new PolicyViolationError(
                'TOKEN_EXPIRED',
                'Access token has expired',
                401,
                { 'X-Policy-Update': 'token-expired' }
            );
        }

        // Check 4: Token not too old
        const tokenAge = now - claims.issuedAt;
        if (tokenAge > MAX_TOKEN_AGE_MS) {
            throw new PolicyViolationError(
                'TOKEN_TOO_OLD',
                'Access token is too old, please re-authenticate',
                401,
                { 'X-Policy-Update': 'token-stale' }
            );
        }

        logger.debug({
            event: 'POLICY_VALIDATED',
            participantId: claims.participantId,
            policyVersion: claims.policyVersion,
            scope: claims.policyScope,
            inGracePeriod: versionResult.inGracePeriod
        });

        return versionResult;
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

        if (!scope.allowedOperations.includes(operation)) {
            logger.warn({
                event: 'OPERATION_NOT_ALLOWED',
                operation,
                participantId: claims.participantId,
                scope: claims.policyScope
            });
            return false;
        }

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
     * Invalidate policy cache (for immediate propagation / emergency revocation)
     */
    public invalidateCache(): void {
        cachedPolicyState = null;
        policyCacheTime = 0;
        logger.info({ event: 'POLICY_CACHE_INVALIDATED' });
    }

    /**
     * Force immediate revocation (disables grace period)
     * Use for emergency scenarios only.
     */
    public async forceImmediateRevocation(version: string): Promise<void> {
        await this.dbClient.queryAsRole(
            this.role,
            `
            UPDATE policy_versions 
            SET status = 'RETIRED' 
            WHERE id = $1 AND status IN ('ACTIVE', 'GRACE');
        `,
            [version]
        );

        this.invalidateCache();

        logger.warn({
            event: 'EMERGENCY_REVOCATION',
            version,
            message: 'Policy version immediately retired, all tokens will be invalidated'
        });
    }
}

// =============================================================================
// MIDDLEWARE
// =============================================================================

/**
 * Express Middleware Factory (Production-Safe)
 * 
 * Creates middleware that validates policy claims on every request.
 * Adds response headers when re-authentication is recommended.
 */
export function createPolicyConsistencyMiddleware(
    role: DbRole,
    options: { gracePeriodMs?: number } = {},
    dbClient = db
) {
    const service = new PolicyConsistencyService(role, dbClient, options.gracePeriodMs);

    return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
        try {
            const claims = (req as { policyClaims?: PolicyClaims }).policyClaims;

            if (!claims) {
                return next();
            }

            const signatureHeader = req.headers['x-policy-claims-signature'];
            if (!signatureHeader || typeof signatureHeader !== 'string') {
                throw new PolicyViolationError(
                    'POLICY_CLAIMS_UNSIGNED',
                    'Policy claims signature is required',
                    401
                );
            }

            await verifyPolicyClaimsSignature(claims, signatureHeader);

            const result = await service.validatePolicyClaims(claims);

            // Add headers to signal frontend about policy state
            if (result.inGracePeriod) {
                res.setHeader('X-Policy-Update', 'recommended');
                res.setHeader('X-Policy-Active-Version', result.activeVersion);
            }

            // Attach scope for downstream use
            const globalState = await service.getGlobalPolicyState();
            (req as { policyScope?: PolicyScope | undefined }).policyScope =
                globalState.scopes.get(claims.policyScope);

            next();
        } catch (error) {
            if (error instanceof PolicyViolationError) {
                // Add custom headers for frontend handling
                for (const [key, value] of Object.entries(error.headers)) {
                    res.setHeader(key, value);
                }
            }
            next(error);
        }
    };
}

// =============================================================================
// UTILITIES
// =============================================================================

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

function stableStringify(value: unknown): string {
    if (value === null || value === undefined) {
        return JSON.stringify(value);
    }

    if (typeof value !== 'object') {
        return JSON.stringify(value);
    }

    if (Array.isArray(value)) {
        return `[${value.map(item => stableStringify(item)).join(',')}]`;
    }

    const record = value as Record<string, unknown>;
    const keys = Object.keys(record).sort();
    const entries = keys.map(key => `"${key}":${stableStringify(record[key])}`);
    return `{${entries.join(',')}}`;
}

async function getClaimsKey(): Promise<Buffer> {
    if (!claimsKeyPromise) {
        claimsKeyPromise = keyManager
            .deriveKey('policy/claims')
            .then(key => Buffer.from(key, 'base64'));
    }

    return claimsKeyPromise;
}

export async function signPolicyClaims(claims: PolicyClaims): Promise<string> {
    const key = await getClaimsKey();
    const payload = stableStringify(claims);
    return crypto.createHmac('sha256', key).update(payload).digest('hex');
}

async function verifyPolicyClaimsSignature(claims: PolicyClaims, signature: string): Promise<void> {
    if (!/^[a-f0-9]{64}$/i.test(signature)) {
        throw new PolicyViolationError(
            'POLICY_CLAIMS_SIGNATURE_INVALID',
            'Policy claims signature format is invalid',
            401
        );
    }

    const expected = await signPolicyClaims(claims);
    const expectedBuffer = Buffer.from(expected, 'hex');
    const providedBuffer = Buffer.from(signature.toLowerCase(), 'hex');

    if (
        expectedBuffer.length !== providedBuffer.length ||
        !crypto.timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
        throw new PolicyViolationError(
            'POLICY_CLAIMS_SIGNATURE_INVALID',
            'Policy claims signature verification failed',
            401
        );
    }
}
