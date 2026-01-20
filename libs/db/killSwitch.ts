import { db } from "./index.js";
import { DbRole } from "./roles.js";

export async function checkKillSwitch(role: DbRole) {
    const res = await db.queryAsRole<{ count: string }>(
        role,
        "SELECT count(*) FROM kill_switches WHERE is_active = true"
    );

    const row = res.rows[0];
    if (row && Number(row.count) > 0) {
        throw new Error("Kill-switch active — service startup blocked");
    }
}
