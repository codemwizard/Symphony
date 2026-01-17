/**
 * Symphony Instruction State Client — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Client for querying and commanding .NET instruction state.
 *
 * REGULATORY GUARANTEE:
 * Transition requests are advisory commands; the .NET Financial Core
 * may reject them if invariant conditions are not met.
 *
 * This respects the hybrid architecture boundary:
 * - Node.js queries state
 * - Node.js requests transitions
 * - .NET decides and enforces
 */

import { logger } from '../logging/logger.js';

/**
 * Instruction state as reported by .NET Financial Core.
 */
export type InstructionState =
    | 'RECEIVED'
    | 'AUTHORIZED'
    | 'EXECUTING'
    | 'COMPLETED'    // Terminal
    | 'FAILED';      // Terminal

/**
 * Terminal states (irreversible).
 */
// const _TERMINAL_STATES: readonly InstructionState[] = ['COMPLETED', 'FAILED'];

/**
 * Instruction state response from .NET.
 */
export interface InstructionStateResponse {
    readonly instructionId: string;
    readonly state: InstructionState;
    readonly isTerminal: boolean;
    readonly updatedAt: string;
}

/**
 * Transition request to .NET.
 */
export interface TransitionRequest {
    readonly instructionId: string;
    readonly targetState: 'COMPLETED' | 'FAILED';
    readonly reason?: string;
}

/**
 * Transition response from .NET.
 */
export interface TransitionResponse {
    readonly accepted: boolean;
    readonly instructionId: string;
    readonly newState?: InstructionState;
    readonly rejectionReason?: string;
}

/**
 * Get current instruction state from .NET Financial Core.
 */
export async function getInstructionState(instructionId: string): Promise<InstructionStateResponse> {
    // TODO: Replace with actual .NET API call
    // This is a placeholder for the hybrid architecture integration

    logger.debug({ instructionId }, 'Querying instruction state from .NET');

    // Placeholder: In production, this calls .NET Financial Core API
    const response = await callDotNetApi<InstructionStateResponse>(
        `/instructions/${instructionId}/state`,
        'GET'
    );

    return response;
}

/**
 * Check if instruction is in terminal state.
 */
export async function isTerminal(instructionId: string): Promise<boolean> {
    const stateResponse = await getInstructionState(instructionId);
    return stateResponse.isTerminal;
}

/**
 * Request state transition to .NET Financial Core.
 *
 * IMPORTANT: Transition requests are advisory commands.
 * The .NET Financial Core may reject them if invariant conditions are not met.
 */
export async function requestTransition(
    instructionId: string,
    targetState: 'COMPLETED' | 'FAILED',
    reason?: string
): Promise<TransitionResponse> {
    logger.info({
        instructionId,
        targetState,
        reason
    }, 'Requesting instruction transition to .NET');

    const request: TransitionRequest = {
        instructionId,
        targetState,
        ...(reason ? { reason } : {})
    };

    // Advisory command to .NET
    const response = await callDotNetApi<TransitionResponse>(
        `/instructions/${instructionId}/transition`,
        'POST',
        request
    );

    if (!response.accepted) {
        logger.warn({
            instructionId,
            targetState,
            rejectionReason: response.rejectionReason
        }, '.NET rejected transition request');
    }

    return response;
}

/**
 * Placeholder for .NET API calls.
 * In production, this would use HTTP client with proper auth.
 */
async function callDotNetApi<T>(
    endpoint: string,
    method: 'GET' | 'POST',
    _body?: unknown
): Promise<T> {
    const baseUrl = process.env.DOTNET_CORE_URL ?? 'http://localhost:5000';
    const url = `${baseUrl}${endpoint}`;

    // Placeholder implementation
    // In production: actual HTTP call with mTLS, correlation IDs, etc.
    logger.debug({ url, method }, 'Calling .NET Financial Core API');

    // For now, throw to indicate integration point
    throw new Error(
        `[INTEGRATION POINT] .NET API call required: ${method} ${url}. ` +
        'Implement actual HTTP client for production.'
    );
}
