import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

/**
 * Symphony Trust Fabric: Certificate Generator (SYM-36)
 * Simulates a Platform CA for mTLS enforcement.
 */
export async function generateServiceCert(params: {
    serviceName: string;
    ou: string;
    env: string;
}) {
    const certDir = path.join(process.cwd(), 'certs', params.serviceName);
    if (!fs.existsSync(certDir)) fs.mkdirSync(certDir, { recursive: true });

    // 1. Generate Key Pair
    const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
    });

    // 2. Create Certificate (Mock/Simulation for development)
    // In production, this would be a CSR sent to the Intermediate CA.
    const certData = {
        subject: `CN=symphony.${params.serviceName}`,
        extensions: {
            subjectAltName: `DNS:service=${params.serviceName},DNS:ou=${params.ou},DNS:env=${params.env}`
        },
        issuer: "CN=Symphony-Platform-Intermediate-CA",
        serial: crypto.randomBytes(8).toString('hex'),
        validFrom: new Date().toISOString(),
        validTo: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
        fingerprint: crypto.createHash('sha256').update(publicKey.export({ format: 'pem', type: 'spki' })).digest('hex')
    };

    // 3. Save to Disk
    fs.writeFileSync(path.join(certDir, 'service.key'), privateKey.export({ format: 'pem', type: 'pkcs8' }));
    fs.writeFileSync(path.join(certDir, 'service.crt'), JSON.stringify(certData, null, 2)); // Using JSON for ease of parsing in this simulation
    fs.writeFileSync(path.join(certDir, 'fingerprint.txt'), certData.fingerprint);

    console.log(`Certificate generated for ${params.serviceName} (OU: ${params.ou})`);
    console.log(`Fingerprint: ${certData.fingerprint}`);
}

import { fileURLToPath } from 'url';

if (process.argv[1] === fileURLToPath(import.meta.url)) {
    const services = [
        { name: 'control-plane', ou: 'OU-01' },
        { name: 'ingest-api', ou: 'OU-02' },
        { name: 'executor-worker', ou: 'OU-05' },
        { name: 'read-api', ou: 'OU-03' }
    ];

    services.forEach(s => {
        generateServiceCert({ serviceName: s.name, ou: s.ou, env: 'dev' });
    });
}
