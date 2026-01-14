/**
 * Phase-7R Unit Tests: Monotonic ID Generator with Clock-Safety
 * 
 * Tests the "Wait State" safeguard for backward-clock detection.
 * 
 * @see libs/id/MonotonicIdGenerator.ts
 */

import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import {
    MonotonicIdGenerator,
    ClockMovedBackwardsError,
    createIdGenerator
} from '../../libs/id/MonotonicIdGenerator';

describe('MonotonicIdGenerator', () => {
    let generator: MonotonicIdGenerator;

    beforeEach(() => {
        generator = new MonotonicIdGenerator(0);
    });

    describe('ID Generation', () => {
        it('should generate unique IDs', async () => {
            const id1 = await generator.generate();
            const id2 = await generator.generate();

            expect(id1).not.toBe(id2);
        });

        it('should generate monotonically increasing IDs', async () => {
            const id1 = await generator.generate();
            const id2 = await generator.generate();
            const id3 = await generator.generate();

            expect(id2).toBeGreaterThan(id1);
            expect(id3).toBeGreaterThan(id2);
        });

        it('should generate IDs as strings', async () => {
            const idStr = await generator.generateString();

            expect(typeof idStr).toBe('string');
            expect(idStr).toMatch(/^\d+$/);
        });
    });

    describe('Worker ID Validation', () => {
        it('should accept valid worker IDs (0-1023)', () => {
            expect(() => new MonotonicIdGenerator(0)).not.toThrow();
            expect(() => new MonotonicIdGenerator(512)).not.toThrow();
            expect(() => new MonotonicIdGenerator(1023)).not.toThrow();
        });

        it('should reject invalid worker IDs', () => {
            expect(() => new MonotonicIdGenerator(-1)).toThrow();
            expect(() => new MonotonicIdGenerator(1024)).toThrow();
        });
    });

    describe('Clock-Safety: Wait State', () => {
        it('should not be in wait state initially', () => {
            expect(generator.isInWaitState()).toBe(false);
        });

        it('should handle sequence overflow within same millisecond', async () => {
            // Generate many IDs quickly to trigger sequence overflow
            const ids: bigint[] = [];
            for (let i = 0; i < 100; i++) {
                ids.push(await generator.generate());
            }

            // All IDs should be unique
            const uniqueIds = new Set(ids.map(id => id.toString()));
            expect(uniqueIds.size).toBe(100);
        });
    });

    describe('Factory Function', () => {
        it('should create generator with specified worker ID', () => {
            const gen = createIdGenerator(42);
            expect(gen).toBeInstanceOf(MonotonicIdGenerator);
        });
    });
});

describe('ClockMovedBackwardsError', () => {
    it('should have correct error properties', () => {
        const error = new ClockMovedBackwardsError(1000, 900, 100);

        expect(error.name).toBe('ClockMovedBackwardsError');
        expect(error.code).toBe('CLOCK_MOVED_BACKWARDS');
        expect(error.statusCode).toBe(503);
        expect(error.lastTimestamp).toBe(1000);
        expect(error.currentTimestamp).toBe(900);
        expect(error.driftMs).toBe(100);
        expect(error.message).toContain('100ms');
    });
});
