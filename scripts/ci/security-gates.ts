import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '../../');

interface SecurityViolation {
    file: string;
    line: number;
    description: string;
    criticality: 'CRITICAL' | 'HIGH' | 'MEDIUM';
}

const violations: SecurityViolation[] = [];

// 1. Check for local-KMS endpoints in production-likely files
function checkLocalKMS(filePath: string, content: string) {
    if (content.includes('http://localhost:8080') && !filePath.includes('test') && !filePath.includes('DevelopmentKeyManager')) {
        const lines = content.split('\n');
        lines.forEach((line, index) => {
            if (line.includes('http://localhost:8080')) {
                violations.push({
                    file: filePath,
                    line: index + 1,
                    description: 'Local-KMS endpoint (localhost:8080) detected in potential production path',
                    criticality: 'CRITICAL'
                });
            }
        });
    }
}

// 2. Check for DevelopmentKeyManager usage outside of specialized paths
function checkDevKeyManager(filePath: string, content: string) {
    const isSpecializedPath = [
        'keyManager.ts',
        'dev-key-manager.ts',
        'test',
        'bootstrap',
        'scripts' + path.sep
    ].some(p => filePath.includes(p) || filePath.includes(p.replace(/\\/g, '/')));
    if (content.includes('DevelopmentKeyManager') && !isSpecializedPath) {
        const lines = content.split('\n');
        lines.forEach((line, index) => {
            if (line.includes('DevelopmentKeyManager') && !line.includes('import')) {
                violations.push({
                    file: filePath,
                    line: index + 1,
                    description: 'DevelopmentKeyManager usage detected in production-critical path',
                    criticality: 'CRITICAL'
                });
            }
        });
    }
}

// 3. Check for default DB credentials placeholders
function checkDefaultDBCreds(filePath: string, content: string) {
    if (filePath.endsWith('.env') || filePath.endsWith('.example')) {
        const matches = content.match(/DB_PASSWORD=(password|admin|123456)/i);
        if (matches) {
            violations.push({
                file: filePath,
                line: content.split('\n').findIndex(l => l.includes(matches[0])) + 1,
                description: 'Default or weak DB password detected in environment configuration',
                criticality: 'HIGH'
            });
        }
    }
}

// 4. Check for PHASE environment variable usage/gating
function checkPhaseGating(filePath: string, content: string) {
    const isExecutionPath = filePath.includes('services/') || filePath.includes('libs/ledger/');
    if (isExecutionPath && content.includes('Phase7') && !content.includes('process.env.PHASE')) {
        violations.push({
            file: filePath,
            line: 1,
            description: 'Phase-7 logic detected without explicit PHASE environment gating',
            criticality: 'HIGH'
        });
    }
}

function scanDir(dir: string) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory()) {
            if (file === 'node_modules' || file === '.git' || file === 'dist' || file === '_Legacy_V1') continue;
            scanDir(fullPath);
        } else if ((file.endsWith('.ts') || file.endsWith('.js') || file.endsWith('.env.example')) && file !== 'security-gates.ts') {
            const content = fs.readFileSync(fullPath, 'utf8');
            const relativePath = path.relative(rootDir, fullPath);

            checkLocalKMS(relativePath, content);
            checkDevKeyManager(relativePath, content);
            checkDefaultDBCreds(relativePath, content);
            checkPhaseGating(relativePath, content);
        }
    }
}

console.log('🚀 Starting Symphony Security Gate Analysis...');
scanDir(rootDir);

if (violations.length > 0) {
    console.error('\n❌ SECURITY VIOLATIONS DETECTED:');
    violations.forEach(v => {
        console.error(`[${v.criticality}] ${v.file}:${v.line} - ${v.description}`);
    });
    console.error('\nTotal Violations:', violations.length);
    process.exit(1);
} else {
    console.log('\n✅ No security gate violations detected.');
}
