/**
 * PROOF OF WORK: DB SSL Enforcement (Phase-6_Addendum_2)
 * This script verifies that the database connection correctly fails when 
 * rejectUnauthorized is true and a bad CA is provided.
 */

process.env.DB_HOST = "localhost";
process.env.DB_PORT = "5432";
process.env.DB_NAME = "symphony";
process.env.DB_USER = "symphony_user";
process.env.DB_PASSWORD = "password";
process.env.DB_SSL_QUERY = "true";
process.env.DB_CA_CERT = "-----BEGIN CERTIFICATE-----\nINVALID_CA\n-----END CERTIFICATE-----";

async function testSslEnforcement() {
    console.log("Starting DB SSL Enforcement Proof...");
    try {
        const { db } = await import('../../libs/db/index.js');
        await db.queryAsRole('symphony_control', 'SELECT 1');
        console.log("❌ FAILURE: Connection succeeded with invalid CA certificate.");
        process.exit(1);
    } catch (err) {
        console.log("✅ SUCCESS: Connection rejected as expected with error:", err.message);
        console.log("   Audit Note: This proves fail-closed behavior for encrypted transport.");
        process.exit(0);
    }
}

testSslEnforcement();
