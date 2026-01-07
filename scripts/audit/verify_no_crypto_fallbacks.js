import fs from 'fs';
import path from 'path';

const forbidden = [
    /dev-secret/i,
    /default.*key/i,
    /process\.env\.DEV_ROOT_KEY\s*\|\|/i,
];

// Target file
const targetFile = path.resolve(process.cwd(), 'libs/crypto/keyManager.ts');

if (!fs.existsSync(targetFile)) {
    console.error(`Target file not found: ${targetFile}`);
    process.exit(1);
}

const content = fs.readFileSync(targetFile, 'utf8');

for (const pattern of forbidden) {
    if (pattern.test(content)) {
        console.error(`ERROR: FORBIDDEN CRYPTO FALLBACK: ${pattern}`);
        process.exit(1);
    }
}

console.log('✓ No cryptographic fallback secrets detected');
