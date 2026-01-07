import { logger } from '../logging/logger.js';

export type GuardRule =
    | { type: 'required'; name: string; sensitive?: boolean }
    | { type: 'forbidIf'; name: string; when: () => boolean; message: string }
    | { type: 'assert'; check: () => boolean; message: string };

/**
 * CRIT-SEC-002: Hardened Configuration Guard
 * Enforces strict "Fail-Closed" policy.
 * No defaults. No missing values. No unsafe patterns.
 */
export class ConfigGuard {
    static enforce(rules: GuardRule[]) {
        const errors: string[] = [];

        for (const rule of rules) {
            try {
                switch (rule.type) {
                    case 'required': {
                        const value = process.env[rule.name];
                        if (!value || value.trim() === '') {
                            errors.push(`FATAL CONFIG: Required env var ${rule.name} is missing`);
                        }
                        break;
                    }

                    case 'forbidIf': {
                        if (rule.when()) {
                            errors.push(`FATAL CONFIG: ${rule.message} (Rule: ${rule.name})`);
                        }
                        break;
                    }

                    case 'assert': {
                        if (!rule.check()) {
                            errors.push(`FATAL CONFIG: ${rule.message}`);
                        }
                        break;
                    }
                }
            } catch (err: any) {
                errors.push(`Check failed for rule: ${err.message}`);
            }
        }

        if (errors.length > 0) {
            // Log structure for machine parsing + human readability
            logger.fatal({
                errors,
                remediation: "Check environment variables. No defaults allowed."
            }, "Configuration Guard Violation");

            // Immediate fatal exit
            process.exit(1);
        }

        logger.info("Configuration guard passed.");
    }
}
