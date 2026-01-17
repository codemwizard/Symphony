import { db } from "./index.js";
import fs from "fs";

export async function checkPolicyVersion() {
    const file = JSON.parse(
        fs.readFileSync(".symphony/policies/active-policy.json", "utf-8")
    );

    const res = await db.query(
        "SELECT version FROM policy_versions WHERE is_active = true"
    );

    if (res.rows[0].version !== file.policy_version) {
        throw new Error("Policy version mismatch");
    }
}

/**
 * Validates that the provided policy version matches the currently active policy.
 * Used by Identity Verification to prevent stale/legacy policy usage.
 */
export async function validatePolicyVersion(version: string): Promise<void> {
    // In a real high-throughput scenario, this should be cached.
    // For Phase 7R, we read from the authoritative file source.
    let activeVersion: string;
    try {
        const file = JSON.parse(
            fs.readFileSync(".symphony/policies/active-policy.json", "utf-8")
        );
        activeVersion = file.policy_version;
    } catch {
        // Fail-safe: If policy file is missing/corrupt, deny access.
        throw new Error("Active policy configuration missing");
    }

    if (version !== activeVersion) {
        throw new Error(`Policy version mismatch: expected ${activeVersion}, got ${version}`);
    }
}
