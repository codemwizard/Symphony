const crypto = require('crypto');

// Mock Components
const ALLOWED_ISSUERS = {
    'control-plane': ['client', 'ingest-api'],
    'ingest-api': ['client'],
    'executor-worker': ['control-plane'],
    'read-api': ['executor-worker'],
};

function verifySignature(envelope, secret) {
    const dataToSign = JSON.stringify({
        version: envelope.version,
        requestId: envelope.requestId,
        issuedAt: envelope.issuedAt,
        issuerService: envelope.issuerService,
        subjectType: envelope.subjectType,
        subjectId: envelope.subjectId,
        tenantId: envelope.tenantId,
        policyVersion: envelope.policyVersion,
        roles: envelope.roles,
    });

    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(dataToSign)
        .digest('hex');

    return envelope.signature === expectedSignature;
}

function verifyDirectionalTrust(currentService, issuerService, subjectType) {
    const allowed = ALLOWED_ISSUERS[currentService];
    if (!allowed) return false;
    if (allowed.includes(issuerService)) return true;
    if (subjectType === 'client' && allowed.includes('client')) return true;
    return false;
}

async function runTest() {
    // aligning with DevelopmentKeyManager logic
    const rootKey = process.env.DEV_ROOT_KEY || 'symphony-dev-root';
    const secret = crypto.createHash('sha256').update(rootKey + ":identity/hmac").digest('base64');
    console.log("Starting Phase 6.2 Identity Verification Tests (Key Derived)...");

    // Test 1: Valid Client -> Ingest Request
    const validEnvelope = {
        version: 'v1',
        requestId: 'req-123',
        issuedAt: new Date().toISOString(),
        issuerService: 'client',
        subjectType: 'client',
        subjectId: 'client-888',
        tenantId: 'tenant-001',
        policyVersion: 'v1.0.0',
        roles: ['user'],
    };

    // Sign it
    validEnvelope.signature = crypto
        .createHmac('sha256', secret)
        .update(JSON.stringify(validEnvelope))
        .digest('hex');

    console.log("Test 1: Normal Client -> Ingest Request");
    if (verifySignature(validEnvelope, secret) && verifyDirectionalTrust('ingest-api', 'client', 'client')) {
        console.log("✅ Passed.");
    } else {
        console.error("❌ Failed.");
    }

    // Test 2: Invalid Signature
    console.log("Test 2: Invalid Signature Rejection");
    const tampered = { ...validEnvelope, signature: 'bad-sig' };
    if (!verifySignature(tampered, secret)) {
        console.log("✅ Correctly rejected invalid signature.");
    } else {
        console.error("❌ Failed to reject invalid signature.");
    }

    // Test 3: Directional Trust Violation (Executor -> Control Plane)
    console.log("Test 3: Directional Trust Violation (Executor -> Control Plane)");
    if (!verifyDirectionalTrust('control-plane', 'executor-worker', 'service')) {
        console.log("✅ Correctly blocked backward OU call.");
    } else {
        console.error("❌ Failed to block unauthorized OU interaction.");
    }

    // Test 4: Valid Service -> Service (Control -> Executor)
    console.log("Test 4: Valid Service -> Service (Control -> Executor)");
    if (verifyDirectionalTrust('executor-worker', 'control-plane', 'service')) {
        console.log("✅ Passed.");
    } else {
        console.error("❌ Failed to allow valid forward OU call.");
    }

    console.log("Verification Complete.");
}

runTest();
