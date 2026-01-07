import { logger } from "../logging/logger.js";

interface RateLimitConfig {
    windowMs: number;
    maxRequests: number;
}

const counters = new Map<string, { count: number; resetTime: number }>();

/**
 * SYM-OPS-001: Rate Limiting Middleware
 * Protects against DoS and Resource Exhaustion.
 */
export async function rateLimit(principal: string, config: RateLimitConfig = { windowMs: 60000, maxRequests: 100 }): Promise<boolean> {
    const now = Date.now();
    const state = counters.get(principal) || { count: 0, resetTime: now + config.windowMs };

    if (now > state.resetTime) {
        state.count = 1;
        state.resetTime = now + config.windowMs;
    } else {
        state.count++;
    }

    counters.set(principal, state);

    if (state.count > config.maxRequests) {
        logger.warn({ principal, count: state.count }, "RateLimit: Limit exceeded");
        return false;
    }

    return true;
}
