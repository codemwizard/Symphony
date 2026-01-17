import { bootstrap } from "../../../libs/bootstrap/startup.js";
import { logger } from "../../../libs/logging/logger.js";
import { db } from "../../../libs/db/index.js";


async function main() {
    db.setRole("symphony_ingest");
    await bootstrap("ingest-api");

    logger.info("Ingest API initialized");
}

main().catch(err => {
    logger.fatal(err);
    process.exit(1);
});
