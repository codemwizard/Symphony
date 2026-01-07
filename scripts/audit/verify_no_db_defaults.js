import fs from 'fs';
import path from 'path';

const forbiddenPatterns = [
    /process\.env\.DB_HOST\s*\|\|/g,
    /process\.env\.DB_PORT\s*\|\|/g,
    /process\.env\.DB_USER\s*\|\|/g,
    /process\.env\.DB_PASSWORD\s*\|\|/g,
];

function scan(dir) {
    if (!fs.existsSync(dir)) {
        console.warn(`Directory not found: ${dir}`);
        return;
    }

    for (const file of fs.readdirSync(dir)) {
        const full = path.join(dir, file);
        if (fs.statSync(full).isDirectory()) {
            scan(full);
        } else if (file.endsWith('.ts')) {
            const content = fs.readFileSync(full, 'utf8');
            forbiddenPatterns.forEach((pattern) => {
                if (pattern.test(content)) {
                    console.error(`ERROR: FORBIDDEN DB DEFAULT: ${pattern} found in ${full}`);
                    process.exit(1);
                }
            });
        }
    }
}

// Ensure we are running from project root or adjust path
const libsDir = path.resolve(process.cwd(), 'libs');
scan(libsDir);
console.log('✓ No DB fallback defaults detected');
