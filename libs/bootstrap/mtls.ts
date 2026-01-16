import https from 'https';

/**
 * INV-SEC-03: mTLS Primitives (Phase-6_Addendum_2)
 * Centralized utility for creating hardened HTTPS/mTLS options.
 */

export const MtlsGate = {
    /**
     * Returns server options for enforcing mTLS.
     */
    getServerOptions: () => {
        return {
            key: process.env.MTLS_SERVICE_KEY,
            cert: process.env.MTLS_SERVICE_CERT,
            ca: process.env.MTLS_CA_CERT,
            requestCert: true,
            rejectUnauthorized: true // FAIL-CLOSED
        };
    },

    /**
     * Returns an HTTPS agent for outbound mTLS calls.
     */
    getAgent: () => {
        return new https.Agent({
            key: process.env.MTLS_SERVICE_KEY,
            cert: process.env.MTLS_SERVICE_CERT,
            ca: process.env.MTLS_CA_CERT,
            rejectUnauthorized: true // FAIL-CLOSED
        });
    }
};
