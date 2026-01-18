import { db } from "./index.js";
import { assertPolicyVersionPinned, readPolicyFile } from "../policy/policyIntegrity.js";

type ActivePolicyFile = {
    policy_version?: string;
    policyVersion?: string;
};

function readActivePolicyVersion(): string {
    const file = readPolicyFile<ActivePolicyFile>(".symphony/policies/active-policy.json");
    const policyVersion = file.policy_version ?? file.policyVersion;
    if (!policyVersion) {
        throw new Error("Active policy file missing policy_version.");
    }
    assertPolicyVersionPinned(policyVersion);
    return policyVersion;
}

export async function checkPolicyVersion() {
    const policyVersion = readActivePolicyVersion();

    const res = await db.query(
        "SELECT version FROM policy_versions WHERE is_active = true"
    );

    if (res.rows[0].version !== policyVersion) {
        throw new Error("Policy version mismatch");
    }
}

/**
 * Validates that the provided policy version matches the currently active policy.
 * Used by Identity Verification to prevent stale/legacy policy usage.
 */
export async function validatePolicyVersion(version: string): Promise<void> {
    const activeVersion = readActivePolicyVersion();

    if (version !== activeVersion) {
        throw new Error(`Policy version mismatch: expected ${activeVersion}, got ${version}`);
    }
}
