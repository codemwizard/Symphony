import { z } from 'zod';

/**
 * HIGH-SEC-002: Input Validation Framework
 * Central schema definitions for all system inputs.
 */

// --- Identity Schemas ---

export const IdentityEnvelopeSchema = z.object({
    version: z.literal('v1'),
    requestId: z.string().uuid(),
    issuedAt: z.string().datetime(), // ISO 8601
    issuerService: z.enum(['client', 'control-plane', 'ingest-api', 'executor-worker', 'read-api']),
    subjectType: z.enum(['client', 'service', 'user']),
    subjectId: z.string().min(1).max(128), // ULID or UUID
    tenantId: z.string().min(1).max(64),
    policyVersion: z.string().regex(/^v\d+\.\d+\.\d+$/),
    roles: z.array(z.string()).min(1),
    signature: z.string().regex(/^[a-f0-9]{64}$/), // SHA-256 Hex
    trustTier: z.enum(['external', 'internal']),
    // Phase 6.4 mTLS addendum
    certFingerprint: z.string().optional(),

    // Phase 7.1: Participant Identity
    participantId: z.string().optional(),
    participantRole: z.enum(['BANK', 'PSP', 'OPERATOR', 'SUPERVISOR']).optional(),
    participantStatus: z.enum(['ACTIVE', 'SUSPENDED', 'REVOKED']).optional(),
});

// --- Financial Schemas ---

export const MoneySchema = z.object({
    amount: z.string().regex(/^-?\d+(\.\d{1,18})?$/), // Decimal string
    currency: z.string().length(3).regex(/^[A-Z]{3}$/), // ISO 4217
});

export const InstructionSchema = z.object({
    params: z.object({
        amount: MoneySchema.shape.amount,
        currency: MoneySchema.shape.currency,
        debtorAccount: z.string().ulid(),
        creditorAccount: z.string().ulid(),
        description: z.string().max(255).optional(),
    }),
});

// --- API Request Schemas ---

export const IngestRequestSchema = z.object({
    client_request_id: z.string().uuid(),
    instruction_type: z.enum(['payment_transfer', 'account_adjustment']),
    payload: InstructionSchema.shape.params,
});
