/**
 * Symphony Runtime Guards — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Runtime guards operate in-process, not as CI artifacts.
 * They are pre-flight filters, not decision engines.
 *
 * Guard Pipeline:
 * 1. Identity Guard → Reject unauthenticated / non-ACTIVE
 * 2. Authorization Guard → Enforce role-based scope
 * 3. Policy Guard → Enforce sandbox exposure limits
 * 4. Ledger Guard → Structural scope validation
 *
 * INVARIANT SYS-7-1-A:
 * No execution intent may be processed unless an ingress attestation
 * record with a valid sequence ID exists.
 */

// Identity Guard
export type {
    IdentityGuardContext,
    IdentityGuardResult,
    IdentityGuardDenyReason
} from './identityGuard.js';
export { executeIdentityGuard } from './identityGuard.js';

// Authorization Guard
export type {
    AuthorizationGuardContext,
    AuthorizationGuardResult,
    AuthorizationGuardDenyReason
} from './authorizationGuard.js';
export { executeAuthorizationGuard } from './authorizationGuard.js';

// Policy Guard
export type {
    PolicyGuardContext,
    PolicyGuardResult,
    PolicyGuardDenyReason
} from './policyGuard.js';
export { executePolicyGuard } from './policyGuard.js';

// Ledger Guard
export type {
    LedgerGuardContext,
    LedgerGuardResult,
    LedgerGuardDenyReason
} from './ledgerGuard.js';
export { executeLedgerGuard } from './ledgerGuard.js';
