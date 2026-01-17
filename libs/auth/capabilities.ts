/**
 * Symphony Capability Registry — v1
 * Phase Key: SYM-32
 *
 * Principles:
 * - Capabilities are verbs, not roles
 * - OU-scoped and policy-controlled
 * - Additive-only once locked
 */

export type Capability =
    // Instruction lifecycle (OU-04)
    | 'instruction:submit'
    | 'instruction:read'
    | 'instruction:cancel'

    // Execution lifecycle (OU-05)
    | 'execution:attempt'
    | 'execution:retry'
    | 'execution:abort'

    // Routing & control (OU-03 / OU-01)
    | 'route:configure'
    | 'route:activate'
    | 'route:deactivate'

    // Provider control (OU-02 / OU-07)
    | 'provider:enable'
    | 'provider:disable'
    | 'provider:health:write'

    // Audit & reporting (OU-06)
    | 'audit:read'
    | 'status:read'

    // Policy & platform control (OU-01)
    | 'policy:read'
    | 'policy:activate'
    | 'killswitch:activate'
    | 'killswitch:deactivate'

    // Tenant-scoped User Capabilities (Phase 7B)
    | 'transaction:execute'
    | 'account:read'
    | 'ledger:write';

/**
 * Mapping of capabilities to their owning organizational units.
 * Used for strict boundary assertions.
 */
export const CAPABILITY_OU_MAP: Record<Capability, string> = {
    'instruction:submit': 'ingest-api',
    'instruction:cancel': 'ingest-api',
    'instruction:read': 'read-api',
    'execution:attempt': 'executor-worker',
    'execution:retry': 'executor-worker',
    'execution:abort': 'executor-worker',
    'route:configure': 'control-plane',
    'route:activate': 'control-plane',
    'route:deactivate': 'control-plane',
    'provider:enable': 'control-plane',
    'provider:disable': 'control-plane',
    'provider:health:write': 'control-plane',
    'audit:read': 'read-api',
    'status:read': 'read-api',
    'policy:read': 'control-plane',
    'policy:activate': 'control-plane',
    'killswitch:activate': 'control-plane',
    'killswitch:deactivate': 'control-plane',

    // User Capabilities Mapped to Ingest (Entrypoint)
    'transaction:execute': 'ingest-api',
    'account:read': 'ingest-api',
    'ledger:write': 'ingest-api'
};

/**
 * Restricted capability classes for clients.
 */
export const RESTRICTED_CLIENT_CLASSES = [
    'execution:',
    'route:',
    'provider:',
    'policy:',
    'killswitch:'
];
