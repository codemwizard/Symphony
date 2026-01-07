/**
 * Symphony Standalone Authorization Verification
 * Replicates logic from libs/auth/authorize.ts for CI verification.
 */

const CAPABILITY_OU_MAP = {
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
    'killswitch:deactivate': 'control-plane'
};

const RESTRICTED_CLIENT_CLASSES = [
    'execution:',
    'route:',
    'provider:',
    'policy:',
    'killswitch:'
];

/**
 * Replicated authorize function
 */
function authorize(context, requestedCapability, currentService, activePolicy) {
    const { subjectType, policyVersion } = context;

    // Guard 1: Emergency Lockdown Short-Circuit
    if (activePolicy.mode === 'EMERGENCY_LOCKDOWN') {
        const allowed = activePolicy.capabilities.service?.[currentService] || [];
        return allowed.includes(requestedCapability);
    }

    // Guard 2: OU Boundary Assertion
    const owningOU = CAPABILITY_OU_MAP[requestedCapability];
    if (owningOU !== currentService) return false;

    // Guard 3: Client Restriction Invariant
    if (subjectType === 'client') {
        const isRestricted = RESTRICTED_CLIENT_CLASSES.some(prefix => requestedCapability.startsWith(prefix));
        if (isRestricted) return false;
    }

    // Guard 4: Provider Isolation
    if (requestedCapability === 'provider:health:write' && subjectType === 'client') return false;

    // Normal Entitlement Check Chain
    const serviceAllowed = activePolicy.capabilities.service?.[currentService] || [];
    if (!serviceAllowed.includes(requestedCapability)) return false;

    if (subjectType === 'client') {
        const clientAllowed = activePolicy.capabilities.client?.['default'] || [];
        if (!clientAllowed.includes(requestedCapability)) return false;
    }

    if (policyVersion !== activePolicy.policyVersion) return false;

    return true;
}

const mockGlobalPolicy = {
    policyVersion: "1.0.0",
    mode: "NORMAL",
    capabilities: {
        service: {
            "control-plane": ["route:configure", "killswitch:deactivate", "provider:health:write"],
            "executor-worker": ["execution:attempt"],
            "ingest-api": ["instruction:submit", "instruction:cancel"],
            "read-api": ["instruction:read"]
        },
        client: {
            "default": ["instruction:submit", "instruction:read", "instruction:cancel"]
        }
    }
};

const mockEmergencyPolicy = {
    policyVersion: "1.0.0",
    mode: "EMERGENCY_LOCKDOWN",
    capabilities: {
        service: {
            "control-plane": ["killswitch:deactivate"]
        }
    }
};

async function runTests() {
    console.log("--- Starting Phase 6.3 Authorization Verification ---");

    const commonContext = {
        subjectType: "client",
        policyVersion: "1.0.0"
    };

    const results = [
        { name: "Test 1 (Positive Client Submit)", actual: authorize(commonContext, 'instruction:submit', 'ingest-api', mockGlobalPolicy), expected: true },
        { name: "Test 2 (OU Boundary Violation)", actual: authorize(commonContext, 'execution:attempt', 'ingest-api', mockGlobalPolicy), expected: false },
        { name: "Test 3 (Client Execution Restriction)", actual: authorize(commonContext, 'execution:attempt', 'executor-worker', mockGlobalPolicy), expected: false },
        { name: "Test 4 (Provider Isolation)", actual: authorize(commonContext, 'provider:health:write', 'control-plane', mockGlobalPolicy), expected: false },
        { name: "Test 5 (Emergency Lockdown - Block Ingest)", actual: authorize({ ...commonContext, subjectType: 'service' }, 'instruction:submit', 'ingest-api', mockEmergencyPolicy), expected: false },
        { name: "Test 6 (Emergency Lockdown - Allow Recovery)", actual: authorize({ ...commonContext, subjectType: 'service' }, 'killswitch:deactivate', 'control-plane', mockEmergencyPolicy), expected: true },
        { name: "Test 7 (Policy Version Mismatch)", actual: authorize({ ...commonContext, policyVersion: "2.0.0" }, 'instruction:submit', 'ingest-api', mockGlobalPolicy), expected: false }
    ];

    results.forEach(r => {
        console.log(`${r.name}: ${r.actual === r.expected ? "PASS" : "FAIL"}`);
    });

    if (results.some(r => r.actual !== r.expected)) process.exit(1);
}

runTests();
