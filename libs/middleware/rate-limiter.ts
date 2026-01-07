import { logger } from "../logging/logger.js";

interface Bucket {
    tokens: number;
    lastRefill: number;
}

/**
 * F-1: Rate Limiting Middleware
 * Principal-based token bucket limiter.
 */
export class RateLimiter {
    // In-memory store for Phase 7 (Redis would be Phase 8+)
    private buckets: Map<string, Bucket> = new Map();

    // Configuration
    private readonly capacity: number;
    private readonly refillRate: number; // tokens per second

    constructor(capacity: number = 100, refillRate: number = 10) {
        this.capacity = capacity;
        this.refillRate = refillRate;
    }

    /**
     * Consume a token for the given principal.
     * @returns true if allowed, false if limit exceeded
     */
    checkLimit(principalId: string): boolean {
        const now = Date.now();
        let bucket = this.buckets.get(principalId);

        if (!bucket) {
            bucket = { tokens: this.capacity, lastRefill: now };
            this.buckets.set(principalId, bucket);
        }

        // Refill logic
        const elapsedSeconds = (now - bucket.lastRefill) / 1000;
        if (elapsedSeconds > 0) {
            const newTokens = Math.floor(elapsedSeconds * this.refillRate);
            if (newTokens > 0) {
                bucket.tokens = Math.min(this.capacity, bucket.tokens + newTokens);
                bucket.lastRefill = now;
            }
        }

        // Consume logic
        if (bucket.tokens >= 1) {
            bucket.tokens -= 1;
            return true;
        } else {
            logger.warn({ principalId }, "OperationalSafety: Rate limit exceeded");
            return false;
        }
    }
}

// Singleton instance with default Phase 7 execution limits
// 50 TPS burst, 10 TPS sustained
export const executionRateLimiter = new RateLimiter(50, 10);
