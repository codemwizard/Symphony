import { db } from "./index.js";
import { DbRole } from "./roles.js";

export async function checkKillSwitch(role: DbRole) {
    const res = await db.queryAsRole(
        role,
        "SELECT count(*) FROM kill_switches WHERE is_active = true"
    );

    if (Number(res.rows[0].count) > 0) {
        throw new Error("Kill-switch active — service startup blocked");
    }
}
