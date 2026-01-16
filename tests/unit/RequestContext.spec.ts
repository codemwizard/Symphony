import { describe, it } from 'node:test';
import assert from 'node:assert';
import { RequestContext } from '../../libs/context/requestContext.js';
import { ValidatedIdentityContext } from '../../libs/context/identity.js';

const mockContextA: ValidatedIdentityContext = {
    version: 'v1',
    requestId: 'req-A',
    issuedAt: new Date().toISOString(),
    issuerService: 'client',
    subjectType: 'client',
    subjectId: 'user-A',
    tenantId: 'tenant-1',
    policyVersion: 'v1',
    roles: [],
    trustTier: 'external',
    signature: 'sig-A'
};

const mockContextB: ValidatedIdentityContext = {
    ...mockContextA,
    requestId: 'req-B',
    subjectId: 'user-B',
    signature: 'sig-B'
};

describe('RequestContext', () => {
    it('should throw when accessing context outside run()', () => {
        assert.throws(() => RequestContext.get(), /MISSING_REQUEST_CONTEXT/);
    });

    it('should return context inside run()', () => {
        const result = RequestContext.run(mockContextA, () => {
            const ctx = RequestContext.get();
            assert.deepStrictEqual(ctx, mockContextA);
            return 'success';
        });
        assert.strictEqual(result, 'success');
    });

    it('should maintain isolation between concurrent async requests', async () => {
        // Run two parallel async flows with delays to interleave execution
        const flowA = RequestContext.run(mockContextA, async () => {
            assert.deepStrictEqual(RequestContext.get(), mockContextA);
            await new Promise(resolve => setTimeout(resolve, 50));
            // Check again after await
            assert.deepStrictEqual(RequestContext.get(), mockContextA);
            return 'A';
        });

        const flowB = RequestContext.run(mockContextB, async () => {
            assert.deepStrictEqual(RequestContext.get(), mockContextB);
            await new Promise(resolve => setTimeout(resolve, 20));
            // Check again after await
            assert.deepStrictEqual(RequestContext.get(), mockContextB);
            return 'B';
        });

        const [resA, resB] = await Promise.all([flowA, flowB]);
        assert.strictEqual(resA, 'A');
        assert.strictEqual(resB, 'B');
    });

    it('should forbid set() usage', () => {
        assert.throws(() => RequestContext.set(mockContextA), /deprecated/);
    });
});
