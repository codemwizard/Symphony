import fs from 'fs';
import path from 'path';

if (process.env.PHASE === '7') {
    const targetFile = path.resolve(process.cwd(), 'libs/crypto/keyManager.ts');
    const content = fs.readFileSync(targetFile, 'utf8');

    // Check for DevelopmentKeyManager usage or existence if appropriate for Phase 7
    // The prompt says "if /DevelopmentKeyManager/.test(content)"
    // Note: if the class is exported but not used in prod runtime, it might still trigger this if the check is simple regex.
    // The user's prompt implies Phase 7 should NOT have DevelopmentKeyManager at all or likely refactored out.
    // We will follow the prompt's logic exactly.

    if (/DevelopmentKeyManager/.test(content)) {
        console.error('ERROR: PHASE-7 VIOLATION: DevelopmentKeyManager referenced in codebase');
        process.exit(1);
    }
    console.log('✓ Phase 7 gate passed (DevelopmentKeyManager check)');
} else {
    console.log('✓ Phase gate skipped (Not Phase 7)');
}
