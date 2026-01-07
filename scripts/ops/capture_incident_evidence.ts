import crypto from "crypto";
import { IncidentSignal } from "../../libs/incident/taxonomy";
import { logger } from "../../libs/logging/logger";

/**
 * Symphony Incident Evidence Capture
 * Automatically packages forensic evidence for regulator review.
 */
export async function captureIncidentEvidence(signal: IncidentSignal, auditLogPath: string, outputPath: string) {
    console.log(`--- Automated Evidence Capture Initiated [Incident: ${signal.id}] ---`);

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const bundleDir = path.join(outputPath, `incident-evidence-${signal.class}-${timestamp}`);
    fs.mkdirSync(bundleDir, { recursive: true });

    // 1. Capture Incident Metadata
    const metadata = {
        incidentId: signal.id,
        class: signal.class,
        severity: signal.severity,
        detectedAt: signal.timestamp,
        source: signal.source,
        details: signal.details,
        materiality: signal.materiality,
        regulatorAck: signal.regulatorAck || {
            regulatorId: "PENDING",
            ackId: "PENDING",
            timestamp: "PENDING",
            followUpRequired: false
        }
    };
    fs.writeFileSync(path.join(bundleDir, "incident-report.json"), JSON.stringify(metadata, null, 2));

    // 2. Snapshot Audit Logs (Non-bypassable evidence)
    if (fs.existsSync(auditLogPath)) {
        const targetLogPath = path.join(bundleDir, "forensic-audit.jsonl");
        fs.copyFileSync(auditLogPath, targetLogPath);
    } else {
        logger.warn("Audit log missing during evidence capture!");
    }

    // 3. Generate Manifest & Signature
    const manifest = {
        bundleVersion: "v1.0.0",
        capturedAt: new Date().toISOString(),
        incidentId: signal.id,
        fileHashes: {
            "incident-report.json": crypto.createHash("sha256").update(fs.readFileSync(path.join(bundleDir, "incident-report.json"))).digest("hex"),
            "forensic-audit.jsonl": fs.existsSync(path.join(bundleDir, "forensic-audit.jsonl"))
                ? crypto.createHash("sha256").update(fs.readFileSync(path.join(bundleDir, "forensic-audit.jsonl"))).digest("hex")
                : "MISSING"
        }
    };

    const manifestPath = path.join(bundleDir, "manifest.json");
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

    // Mock signing (Phase 6.6)
    const bundleHash = crypto.createHash("sha256").update(JSON.stringify(manifest)).digest("hex");
    fs.writeFileSync(path.join(bundleDir, "bundle-signature.sha256"), bundleHash);

    console.log(`--- Evidence Bundle Sealed: ${bundleDir} ---`);
    return bundleDir;
}

// Standalone execution script support
if (require.main === module) {
    const mockSignal: IncidentSignal = {
        id: "manual-" + crypto.randomUUID(),
        class: "SEC-1" as any,
        severity: "CRITICAL" as any,
        source: "manual-trigger",
        timestamp: new Date().toISOString(),
        details: "Manual forensic capture requested"
    };
    const auditPath = path.join(process.cwd(), "logs", "audit.jsonl");
    const exportPath = path.join(process.cwd(), "exports", "incidents");
    captureIncidentEvidence(mockSignal, auditPath, exportPath).catch(console.error);
}
