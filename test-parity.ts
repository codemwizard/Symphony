/* eslint-disable no-console */

import { SymphonyKeyManager } from './libs/crypto/keyManager.js';

async function testKMS() {
    process.env.KMS_ENDPOINT = 'http://localhost:8080';
    process.env.KMS_REGION = 'us-east-1';
    process.env.KMS_KEY_ID = 'alias/symphony-root';
    process.env.KMS_ACCESS_KEY_ID = 'local';
    process.env.KMS_SECRET_ACCESS_KEY = 'local';

    const mgr = new SymphonyKeyManager();
    console.log("Attempting to derive key via SymphonyKeyManager...");
    try {
        const key = await mgr.deriveKey('parity/refactor');
        console.log("SUCCESS: Key derived:", key);
    } catch (e: unknown) {
        console.error("FAILURE:", (e instanceof Error) ? e.message : String(e));
    }
}

testKMS();
