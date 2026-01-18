import { z } from 'zod';

// Shared base schema fields
const BaseEnvelopeSchema = z.object({
    version: z.literal('v1'),
    requestId: z.string().min(1),
    issuedAt: z.string().datetime(),
    issuerService: z.string().min(1),
    subjectId: z.string().min(1),
    tenantId: z.string().min(1),
    policyVersion: z.string().min(1),
    roles: z.array(z.string()).default([]),
    signature: z.string().min(1),
});

// Variant 1: Client (External, no mTLS principal)
export const ClientEnvelopeSchema = BaseEnvelopeSchema.extend({
    subjectType: z.literal('client'),
    trustTier: z.literal('external'),
    // certFingerprint explicitly absent/forbidden by strict() + no definition
}).strict();

// Variant 2: Service (Internal, mTLS mandatory)
export const ServiceEnvelopeSchema = BaseEnvelopeSchema.extend({
    subjectType: z.literal('service'),
    trustTier: z.literal('internal'),
    certFingerprint: z.string().min(1), // Mandatory for service
}).strict();

// Variant 3: User (Tenant-anchored, no mTLS)
export const UserEnvelopeSchema = BaseEnvelopeSchema.extend({
    subjectType: z.literal('user'),
    trustTier: z.literal('user'),
    participantId: z.string().min(1),
    participantRole: z.enum(['BANK', 'PSP', 'OPERATOR', 'SUPERVISOR']), // Checking against enum values, not type reference for portability
    participantStatus: z.enum(['ACTIVE', 'SUSPENDED', 'REVOKED']),
}).strict().superRefine((val, ctx) => {
    // Explicitly forbid certFingerprint if it somehow leaks in
    if ('certFingerprint' in val) {
        ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: 'certFingerprint forbidden for user'
        });
    }
});

// Discriminated Union
export const IdentityEnvelopeV1Schema = z.discriminatedUnion('subjectType', [
    ClientEnvelopeSchema,
    ServiceEnvelopeSchema,
    UserEnvelopeSchema,
]);

export type IdentityEnvelopeV1 = z.infer<typeof IdentityEnvelopeV1Schema>;
