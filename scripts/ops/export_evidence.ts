import fs from "fs";
import path from "path";
import crypto from "crypto";

/**
 * Symphony Evidence Extraction Tool
 * Regulator-ready standalone evidence generator.
 */
async function exportEvidence(auditLogPath: string, outputPath: string) {
    if (!fs.existsSync(auditLogPath)) {
        console.error("No audit log found at " + auditLogPath);
        process.exit(1);
    }

    console.log("--- Symphony Evidence Extraction Started ---");
    console.log("Target Log: " + auditLogPath);

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const bundleDir = path.join(outputPath, `evidence-bundle-${timestamp}`);
    fs.mkdirSync(bundleDir, { recursive: true });

    // 1. Copy Audit Logs
    const targetLogPath = path.join(bundleDir, "audit.jsonl");
    fs.copyFileSync(auditLogPath, targetLogPath);

    // 2. Generate Manifest
    const lines = fs.readFileSync(auditLogPath, "utf8").trim().split("\n");
    const recordCount = lines.length;
    const lastLine = JSON.parse(lines[recordCount - 1]!);

    const manifest = {
        exportVersion: "v1.0.0",
        extractedAt: new Date().toISOString(),
        recordCount,
        lastHash: lastLine.integrity?.hash,
        environmentId: process.env.SYMPHONY_ENV || "production"
    };

    const manifestPath = path.join(bundleDir, "manifest.json");
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

    // 3. Sign the Manifest (Mock Sign for Phase 6.5)
    const manifestHash = crypto.createHash("sha256")
        .update(JSON.stringify(manifest))
        .digest("hex");

    fs.writeFileSync(path.join(bundleDir, "signature.sha256"), manifestHash);

    console.log("--- Extraction Complete ---");
    console.log("Evidence Bundle: " + bundleDir);
    console.log("Records Extracted: " + recordCount);
}

// Standalone Execution
const auditPath = path.join(process.cwd(), "logs", "audit.jsonl");
const exportPath = path.join(process.cwd(), "exports");
exportEvidence(auditPath, exportPath).catch(console.error);
