import crypto from "crypto";
import fs from "fs";
import path from "path";

interface PolicyHashManifest {
    activePolicyVersion: string;
    hashes: Record<string, string>;
}

const POLICY_HASH_PATH = path.resolve(process.cwd(), ".symphony", "policies", "policy-hashes.json");
let cachedManifest: PolicyHashManifest | null = null;

function normalizePolicyPath(policyPath: string): string {
    return policyPath.replace(/\\/g, "/");
}

function loadManifest(): PolicyHashManifest {
    if (cachedManifest) {
        return cachedManifest;
    }

    if (!fs.existsSync(POLICY_HASH_PATH)) {
        throw new Error("Policy hash manifest missing. Integrity checks cannot proceed.");
    }

    const raw = JSON.parse(fs.readFileSync(POLICY_HASH_PATH, "utf-8")) as PolicyHashManifest;
    if (!raw.activePolicyVersion || !raw.hashes) {
        throw new Error("Policy hash manifest is malformed.");
    }

    cachedManifest = raw;
    return raw;
}

function computeHash(filePath: string): string {
    const contents = fs.readFileSync(filePath);
    return crypto.createHash("sha256").update(contents).digest("hex");
}

export function readPolicyFile<T>(policyPath: string): T {
    const manifest = loadManifest();
    const normalizedPath = normalizePolicyPath(policyPath);
    const expectedHash = manifest.hashes[normalizedPath];

    if (!expectedHash) {
        throw new Error(`Policy hash missing for ${normalizedPath}. Integrity checks failed.`);
    }

    const absolutePath = path.resolve(process.cwd(), policyPath);
    if (!fs.existsSync(absolutePath)) {
        throw new Error(`Policy file missing at ${normalizedPath}. Integrity checks failed.`);
    }

    const actualHash = computeHash(absolutePath);
    if (actualHash !== expectedHash) {
        throw new Error(`Policy hash mismatch for ${normalizedPath}. Integrity checks failed.`);
    }

    return JSON.parse(fs.readFileSync(absolutePath, "utf-8")) as T;
}

export function assertPolicyVersionPinned(policyVersion: string): void {
    const manifest = loadManifest();
    if (manifest.activePolicyVersion !== policyVersion) {
        throw new Error(
            `Policy version mismatch. Expected ${manifest.activePolicyVersion}, got ${policyVersion}.`
        );
    }
}
