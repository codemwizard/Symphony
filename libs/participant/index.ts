/**
 * Symphony Participant Library — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Public exports for participant identity module.
 */

// Types
export type {
    Participant,
    ResolvedParticipant,
    ParticipantRole,
    ParticipantStatus,
    SandboxLimits,
    LedgerScope,
    ParticipantResolutionResult,
    ParticipantResolutionFailure
} from './participant.js';

// Repository
export {
    findByFingerprint,
    findById,
    isParticipantActive
} from './repository.js';

// Resolver
export type { ParticipantResolutionContext } from './resolver.js';
export { resolveParticipant } from './resolver.js';
