/** @type {import('ts-jest').JestConfigWithTsJest} */
export default {
    preset: 'ts-jest',
    testEnvironment: 'node',
    transform: {
        '^.+\\.tsx?$': ['ts-jest', {
            useESM: true,
        }],
    },
    extensionsToTreatAsEsm: ['.ts'],
    moduleNameMapper: {
        '^(\\.{1,2}/.*)\\.js$': '$1',
    },
    moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
    roots: ['<rootDir>'],
    testMatch: ['**/tests/*.test.ts'],
    setupFiles: ['<rootDir>/tests/jest.setup.js'],
    testPathIgnorePatterns: ['/node_modules/', '/tests/unit/'],
    verbose: true,
    bail: 1 // Stop on first failure
};
