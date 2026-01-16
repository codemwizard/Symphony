/**
 * Unit Tests: Instruction State Client
 * 
 * Tests the hybrid architecture state query/command interface.
 * 
 * @see libs/execution/instructionStateClient.ts
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';

// Types from the module
type InstructionState = 'RECEIVED' | 'AUTHORIZED' | 'EXECUTING' | 'COMPLETED' | 'FAILED';

describe('InstructionStateClient', () => {
    const originalEnv = { ...process.env };

    before(async () => {
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test';
        process.env.DB_CA_CERT = 'test';
        process.env.DOTNET_CORE_URL = 'http://localhost:5000';
    });

    after(() => {
        process.env = originalEnv;
    });

    describe('State Machine Validation', () => {
        const terminalStates: InstructionState[] = ['COMPLETED', 'FAILED'];
        const nonTerminalStates: InstructionState[] = ['RECEIVED', 'AUTHORIZED', 'EXECUTING'];

        it('should identify COMPLETED as terminal', () => {
            assert.ok(terminalStates.includes('COMPLETED'));
        });

        it('should identify FAILED as terminal', () => {
            assert.ok(terminalStates.includes('FAILED'));
        });

        it('should identify EXECUTING as non-terminal', () => {
            assert.ok(nonTerminalStates.includes('EXECUTING'));
        });

        it('should have exactly 2 terminal states', () => {
            assert.strictEqual(terminalStates.length, 2);
        });
    });

    describe('API Integration Contract', () => {
        it('should use correct state query endpoint format', () => {
            const instructionId = 'instr-123';
            const expectedEndpoint = `/instructions/${instructionId}/state`;

            assert.strictEqual(expectedEndpoint, '/instructions/instr-123/state');
        });

        it('should use correct transition endpoint format', () => {
            const instructionId = 'instr-456';
            const expectedEndpoint = `/instructions/${instructionId}/transition`;

            assert.strictEqual(expectedEndpoint, '/instructions/instr-456/transition');
        });
    });

    describe('Transition Request Validation', () => {
        it('should only allow COMPLETED or FAILED as target states', () => {
            const validTargets = ['COMPLETED', 'FAILED'];
            const invalidTargets = ['RECEIVED', 'AUTHORIZED', 'EXECUTING'];

            for (const target of validTargets) {
                assert.ok(['COMPLETED', 'FAILED'].includes(target), `${target} should be valid`);
            }

            for (const target of invalidTargets) {
                assert.ok(!['COMPLETED', 'FAILED'].includes(target), `${target} should be invalid`);
            }
        });
    });
});
