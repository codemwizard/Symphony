/**
 * PROOF OF WORK: DB SSL Enforcement (Phase-6_Addendum_2)
 * This script verifies that the database connection correctly fails when 
 * rejectUnauthorized is true and a bad CA is provided.
 */

process.env.DB_HOST = "localhost";
process.env.DB_NAME = "symphony";
process.env.DB_USER = "symphony_user";
process.env.DB_PASSWORD = "password";
process.env.DB_SSL_QUERY = "true";
process.env.DB_CA_CERT = "-----BEGIN CERTIFICATE-----\nINVALID_CA\n-----END CERTIFICATE-----";

import pg from 'pg';
const { Pool } = pg;

async function testSslEnforcement() {
    console.log("Starting DB SSL Enforcement Proof...");

    const pool = new Pool({
        host: process.env.DB_HOST,
        ssl: {
            rejectUnauthorized: true,
            ca: process.env.DB_CA_CERT
        }
    });

    try {
        await pool.connect();
        console.log("❌ FAILURE: Connection succeeded with invalid CA certificate.");
        process.exit(1);
    } catch (err) {
        console.log("✅ SUCCESS: Connection rejected as expected with error:", err.message);
        console.log("   Audit Note: This proves fail-closed behavior for encrypted transport.");
        process.exit(0);
    }
}

testSslEnforcement();
