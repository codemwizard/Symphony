/**
 * PROOF OF WORK: Bootstrap Config Guard (CRIT-SEC-002 / CRIT-SEC-003)
 * This script attempts to initialize the DB without required environment variables.
 * Expected Result: Process exits with code 1 and logs a FATAL error.
 */

// Mocking process.env to trigger failure
process.env.DB_HOST = "localhost";
process.env.DB_NAME = "symphony";
// DB_USER and DB_PASSWORD are missing

import('../../libs/db/index.js').then(() => {
    console.log("❌ FAILURE: Config guard did not stop initialization.");
}).catch(err => {
    console.log("✅ SUCCESS: Config guard stopped initialization with error:", err.message);
});
