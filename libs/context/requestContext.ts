import { ValidatedIdentityContext } from "./identity";

/**
 * Request Context Container
 * Immutable storage for the verified identity.
 */
export class RequestContext {
    private static _current: ValidatedIdentityContext | null = null;

    public static set(context: ValidatedIdentityContext) {
        if (this._current) throw new Error("Context already initialized and is immutable");
        this._current = context;
    }

    public static get(): ValidatedIdentityContext {
        if (!this._current) throw new Error("Context not initialized - No Anonymous Execution permitted");
        return this._current;
    }

    public static clear() {
        this._current = null;
    }
}
