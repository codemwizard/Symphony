import { db } from "./index.js";
import { assertPolicyVersionPinned, readPolicyFile } from "../policy/policyIntegrity.js";

export async function checkPolicyVersion() {
    const file = readPolicyFile<{ policy_version: string }>(".symphony/policies/active-policy.json");
    assertPolicyVersionPinned(file.policy_version);

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
    const file = readPolicyFile<{ policy_version: string }>(".symphony/policies/active-policy.json");
    const activeVersion = file.policy_version;
    assertPolicyVersionPinned(activeVersion);

    if (version !== activeVersion) {
        throw new Error(`Policy version mismatch: expected ${activeVersion}, got ${version}`);
    }
}
