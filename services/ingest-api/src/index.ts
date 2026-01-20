import { bootstrap } from "../../../libs/bootstrap/startup.js";
import { logger } from "../../../libs/logging/logger.js";
import { DbRole } from "../../../libs/db/roles.js";


async function main() {
    const role: DbRole = "symphony_ingest";
    await bootstrap("ingest-api", role);

    logger.info("Ingest API initialized");
}

main().catch(err => {
    logger.fatal(err);
    process.exit(1);
});
