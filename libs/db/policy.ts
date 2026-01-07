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
