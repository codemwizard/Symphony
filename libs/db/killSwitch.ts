import { db } from "./index.js";

export async function checkKillSwitch() {
    const res = await db.query(
        "SELECT count(*) FROM kill_switches WHERE is_active = true"
    );

    if (Number(res.rows[0].count) > 0) {
        throw new Error("Kill-switch active — service startup blocked");
    }
}
