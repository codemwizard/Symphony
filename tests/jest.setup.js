// Mock critical environment variables for Unit Tests
// This prevents ConfigGuard from crashing the process during module load

process.env.DB_HOST = 'localhost';
process.env.DB_PORT = '5432';
process.env.DB_USER = process.env.DB_USER || (process.env.CI ? 'symphony' : 'test_user');
process.env.DB_PASSWORD = process.env.DB_PASSWORD || (process.env.CI ? 'symphony' : 'test_password');
process.env.DB_NAME = process.env.DB_NAME || (process.env.CI ? 'symphony' : 'test_db');

process.env.KMS_KEY_ID = 'alias/test-key';
process.env.KMS_ENDPOINT = 'http://localhost:4566';
process.env.AWS_REGION = 'us-east-1';

// Suppress logs during tests unless verbose
if (!process.env.VERBOSE) {
    // console.log = jest.fn();
    // console.info = jest.fn();
    // console.warn = jest.fn();
    // console.error = jest.fn();
}
