async function runPersistenceProof() {
    console.log("--- STARTING ROBUST PERSISTENCE PROOF (CRIT-SEC-001) ---");
    try {
        const { db } = await import('../../libs/db/index.js');
        await db.withRoleClient('symphony_control', async (client) => {
            const testId = `audit_proof_${Date.now()}`;
            const timestamp = new Date().toISOString();

            console.log(`Step 1: Writing evidence directly to audit_log... (Value: ${testId})`);
            await client.query(
                `INSERT INTO audit_log (id, actor, action, metadata, created_at) 
                 VALUES ($1, $2, $3, $4, $5)`,
                [testId, 'ROBUST_PROVER', 'PERSISTENCE_VERIFY', { proof: testId, timestamp }, timestamp]
            );

            console.log("Step 2: Verification Query...");
            const result = await client.query(
                "SELECT metadata->>'proof' as proof FROM audit_log WHERE id = $1",
                [testId]
            );

            const row = result.rows[0];
            if (row && row.proof === testId) {
                console.log("✅ SUCCESS: Persistence reality verified. PostgreSQL substrate active.");
            } else {
                console.error("❌ FAILURE: Data not recovered.");
                process.exit(1);
            }
        });
    } catch (err) {
        console.error("CRITICAL PROOF ERROR:", err);
        process.exit(1);
    }
    console.log("--- PROOF COMPLETE ---");
    process.exit(0);
}

runPersistenceProof();
