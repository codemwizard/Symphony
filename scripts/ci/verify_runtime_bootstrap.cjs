const fs = require('fs');
const path = require('path');

// Mock components to test the logic
const mockDb = {
    policyVersion: 'v1.0.0',
    killSwitchCount: '0',
    async queryAsRole(_role, text) {
        if (text.includes("policy_versions")) return { rows: [{ version: this.policyVersion }] };
        if (text.includes("kill_switches")) return { rows: [{ count: this.killSwitchCount }] };
        return { rows: [] };
    }
};

async function checkPolicyVersion(db, role, policyFilePath) {
    const file = JSON.parse(fs.readFileSync(policyFilePath, "utf-8"));
    const res = await db.queryAsRole(role, "SELECT version FROM policy_versions WHERE is_active = true");
    if (res.rows[0].version !== file.policy_version) {
        throw new Error("Policy version mismatch");
    }
}

async function checkKillSwitch(db, role) {
    const res = await db.queryAsRole(role, "SELECT count(*) FROM kill_switches WHERE is_active = true");
    if (Number(res.rows[0].count) > 0) {
        throw new Error("Kill-switch active — service startup blocked");
    }
}

async function runTest() {
    const policyPath = path.join('.symphony', 'policies', 'active-policy.json');

    console.log("Starting Phase 6.1 Verification...");

    // Test 1: Nominal Case
    try {
        mockDb.policyVersion = 'v1.0.0';
        mockDb.killSwitchCount = '0';
        await checkPolicyVersion(mockDb, 'symphony_control', policyPath);
        await checkKillSwitch(mockDb, 'symphony_control');
        console.log("✅ Nominal startup passed.");
    } catch (e) {
        console.error("❌ Nominal startup failed:", e.message);
    }

    // Test 2: Policy Mismatch
    try {
        mockDb.policyVersion = 'v0.9.0'; // Drifted
        await checkPolicyVersion(mockDb, 'symphony_control', policyPath);
        console.error("❌ Policy mismatch check failed (should have thrown)");
    } catch (e) {
        if (e.message === "Policy version mismatch") {
            console.log("✅ Policy mismatch correctly blocked startup.");
        } else {
            console.error("❌ Unexpected error in policy mismatch test:", e.message);
        }
    }

    // Test 3: Active Kill-Switch
    try {
        mockDb.policyVersion = 'v1.0.0';
        mockDb.killSwitchCount = '1'; // Triggered
        await checkKillSwitch(mockDb, 'symphony_control');
        console.error("❌ Kill-switch check failed (should have thrown)");
    } catch (e) {
        if (e.message === "Kill-switch active — service startup blocked") {
            console.log("✅ Kill-switch correctly blocked startup.");
        } else {
            console.error("❌ Unexpected error in kill-switch test:", e.message);
        }
    }
}

runTest();
