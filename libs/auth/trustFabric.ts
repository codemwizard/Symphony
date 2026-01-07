/**
 * Symphony Trust Fabric Registry (SYM-36)
 * Maps cryptographic cert fingerprints to Service and OU identity.
 */

export interface ServiceCertificateClaims {
    serviceName: string;
    ou: string;
    env: string;
    fingerprint: string;
}

export class TrustFabric {
    // In production, this would be a DB table or a signed manifest.
    // For Phase 6.4 we use a hardcoded registry for development.
    private static REGISTRY: Record<string, ServiceCertificateClaims> = {
        // Fingerprints generated in Step 1
        '116cb5d4e5a05b0f9e2993a44fc11f02c9fef2837b65d7959865dc3f30779917': {
            serviceName: 'control-plane',
            ou: 'OU-01',
            env: 'dev',
            fingerprint: '116cb5d4e5a05b0f9e2993a44fc11f02c9fef2837b65d7959865dc3f30779917'
        },
        '873b517bfeb0cc2acbcac619150eedef1832b49d4ffe8e317ebaf45d517c6f5a': {
            serviceName: 'ingest-api',
            ou: 'OU-02',
            env: 'dev',
            fingerprint: '873b517bfeb0cc2acbcac619150eedef1832b49d4ffe8e317ebaf45d517c6f5a'
        },
        'beb181278551bb4c80da8f4e32ab7178155494cf385bc7914cb4d7be899e63e2': {
            serviceName: 'executor-worker',
            ou: 'OU-05',
            env: 'dev',
            fingerprint: 'beb181278551bb4c80da8f4e32ab7178155494cf385bc7914cb4d7be899e63e2'
        },
        '93cce430faa8108fcd969d07be1e63032b243cd8ceb7cbeaec0100449b723137': {
            serviceName: 'read-api',
            ou: 'OU-03',
            env: 'dev',
            fingerprint: '93cce430faa8108fcd969d07be1e63032b243cd8ceb7cbeaec0100449b723137'
        }
    };

    private static REVOCATION_LIST: Set<string> = new Set();

    static resolveIdentity(fingerprint: string): ServiceCertificateClaims | null {
        if (this.REVOCATION_LIST.has(fingerprint)) return null;
        return this.REGISTRY[fingerprint] || null;
    }

    static revoke(fingerprint: string) {
        this.REVOCATION_LIST.add(fingerprint);
    }
}
