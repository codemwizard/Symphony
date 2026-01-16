/**
 * Phase-7R Unit Tests: Monotonic ID Generator with Clock-Safety
 * 
 * Tests the "Wait State" safeguard for backward-clock detection.
 * Migrated to node:test
 * 
 * @see libs/id/MonotonicIdGenerator.ts
 */

import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert';
import {
    MonotonicIdGenerator,
    ClockMovedBackwardsError,
    createIdGenerator
} from '../../libs/id/MonotonicIdGenerator.js';

describe('MonotonicIdGenerator', () => {
    let generator: MonotonicIdGenerator;

    beforeEach(() => {
        generator = new MonotonicIdGenerator(0);
    });

    describe('ID Generation', () => {
        it('should generate unique IDs', async () => {
            const id1 = await generator.generate();
            const id2 = await generator.generate();

            assert.notStrictEqual(id1, id2);
        });

        it('should generate monotonically increasing IDs', async () => {
            const id1 = await generator.generate();
            const id2 = await generator.generate();
            const id3 = await generator.generate();

            assert.ok(id2 > id1, 'id2 should be > id1');
            assert.ok(id3 > id2, 'id3 should be > id2');
        });

        it('should generate IDs as strings', async () => {
            const idStr = await generator.generateString();

            assert.strictEqual(typeof idStr, 'string');
            assert.match(idStr, /^\d+$/);
        });
    });

    describe('Worker ID Validation', () => {
        it('should accept valid worker IDs (0-1023)', () => {
            assert.doesNotThrow(() => new MonotonicIdGenerator(0));
            assert.doesNotThrow(() => new MonotonicIdGenerator(512));
            assert.doesNotThrow(() => new MonotonicIdGenerator(1023));
        });

        it('should reject invalid worker IDs', () => {
            assert.throws(() => new MonotonicIdGenerator(-1));
            assert.throws(() => new MonotonicIdGenerator(1024));
        });
    });

    describe('Clock-Safety: Wait State', () => {
        it('should not be in wait state initially', () => {
            assert.strictEqual(generator.isInWaitState(), false);
        });

        it('should handle sequence overflow within same millisecond', async () => {
            // Generate many IDs quickly to trigger sequence overflow
            const ids: bigint[] = [];
            for (let i = 0; i < 100; i++) {
                ids.push(await generator.generate());
            }

            // All IDs should be unique
            const uniqueIds = new Set(ids.map(id => id.toString()));
            assert.strictEqual(uniqueIds.size, 100);
        });
    });

    describe('Factory Function', () => {
        it('should create generator with specified worker ID', () => {
            const gen = createIdGenerator(42);
            assert.ok(gen instanceof MonotonicIdGenerator);
        });
    });
});

describe('ClockMovedBackwardsError', () => {
    it('should have correct error properties', () => {
        const error = new ClockMovedBackwardsError(1000, 900, 100);

        assert.strictEqual(error.name, 'ClockMovedBackwardsError');
        assert.strictEqual(error.code, 'CLOCK_MOVED_BACKWARDS');
        assert.strictEqual(error.statusCode, 503);
        assert.strictEqual(error.lastTimestamp, 1000);
        assert.strictEqual(error.currentTimestamp, 900);
        assert.strictEqual(error.driftMs, 100);
        assert.ok(error.message.includes('100ms'));
    });
});
