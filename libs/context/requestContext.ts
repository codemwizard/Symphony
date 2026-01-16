import { AsyncLocalStorage } from 'node:async_hooks';
import { ValidatedIdentityContext } from "./identity.js";
import { logger } from "../logging/logger.js";

/**
 * Request Context Container
 * AsyncLocalStorage-backed for concurrent request isolation.
 * 
 * CRITICAL: Only the request boundary (ingress middleware) should call run().
 * All downstream code should only call get().
 */

const storage = new AsyncLocalStorage<ValidatedIdentityContext>();

export class RequestContext {
    /**
     * Establish identity scope for request/job lifecycle.
     * MUST be called at the earliest ingress boundary.
     * Supports both sync and async functions.
     */
    public static run<T>(
        context: ValidatedIdentityContext,
        fn: () => Promise<T> | T
    ): Promise<T> | T {
        return storage.run(Object.freeze(context), fn);
    }

    /**
     * Get current identity context.
     * FAIL-CLOSED: Throws if called outside run() scope.
     */
    public static get(): ValidatedIdentityContext {
        const ctx = storage.getStore();
        if (!ctx) {
            throw new Error("MISSING_REQUEST_CONTEXT: No identity scope established - execution denied");
        }
        return ctx;
    }

    /**
     * @deprecated ALS scope ends naturally when run() callback completes.
     * This method is a no-op and will be removed in Phase-8.
     */
    public static clear(): void {
        logger.warn({ component: 'RequestContext' }, "clear() is deprecated with AsyncLocalStorage");
    }

    /**
     * @deprecated Use run() at request boundary instead.
     * This method throws to prevent accidental usage.
     */
    public static set(_context: ValidatedIdentityContext): void {
        void _context;
        throw new Error("RequestContext.set() is deprecated. Use RequestContext.run() at request boundary.");
    }
}

