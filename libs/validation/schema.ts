import { z } from 'zod';

/**
 * HIGH-SEC-002: Input Validation Framework
 * Central schema definitions for all system inputs.
 */

// --- Identity Schemas ---

// [DELETED] IdentityEnvelopeSchema - Use IdentityEnvelopeV1Schema from identitySchema.ts
// This legacy schema is strictly removed to prevent unsafe validation.

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
