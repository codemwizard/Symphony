/* global console */
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";

function readJson(filePath) {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function fail(msg) {
    console.error(`❌ ${msg}`);
    process.exit(1);
}

const root = process.cwd();
const schemaPath = path.resolve(root, "schemas/evidence-bundle.schema.json");
const dataPath = path.resolve(root, "evidence-bundle.json");

if (!fs.existsSync(schemaPath)) fail(`Missing schema: ${schemaPath}`);
if (!fs.existsSync(dataPath)) fail(`Missing evidence bundle: ${dataPath}`);

const schema = readJson(schemaPath);
const data = readJson(dataPath);

const ajv = new Ajv2020({ allErrors: true, strict: true });
addFormats(ajv);

const validate = ajv.compile(schema);
const ok = validate(data);

if (!ok) {
    console.error("❌ Evidence bundle schema validation failed.");
    for (const err of validate.errors ?? []) {
        console.error(`- ${err.instancePath || "/"}: ${err.message}`);
    }
    process.exit(1);
}

console.log("✅ Evidence bundle validated (Ajv 2020 + ajv-formats v3).");
