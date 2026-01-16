/**
 * ISO-20022 SCAFFOLDING: mapping.ts
 * Structural alignment with global financial standards.
 * NOTE: This is for schema alignment only. No network integration occurs in Phase 7.
 */

import { Pacs008Message } from "./validator.js";

/**
 * Internal Execution Instruction
 * The pure internal representation of a value transfer.
 */
export interface InternalInstruction {
    id: string; // Mapped from EndToEndId
    reference: string; // Mapped from TxId
    amount: number;
    currency: string;
    debtorAccount: string;
    creditorAccount: string;
    executionDate: string;
}

export interface Iso20022Envelope {
    messageType: 'pacs.008' | 'pacs.002' | 'camt.053';
    messageId: string;
    creationDateTime: string;
    debtor: {
        accountId: string;
        agent?: string;
    };
    creditor: {
        accountId: string;
        agent?: string;
    };
    amount: {
        value: string;
        currency: string;
    };
}

/**
 * D-4: Deterministic Mapping Stub
 * Maps ISO-20022 messages to internal instructions deterministically.
 * Pure functions only. No side effects. No versioning logic.
 */
export const Iso20022Mapper = {
    /**
     * Map Internal Instruction -> OUTBOUND pacs.008 Envelope
     */
    mapToIso: (instruction: unknown): Iso20022Envelope => {
        const instr = instruction as {
            id: string;
            amount: number;
            currency: string;
            creditorAccount: string;
            debtorAccount: string;
            remittanceInfo?: string;
            createdAt: string; // Assuming createdAt is part of the instruction for mapping
            debtorId: string; // Assuming debtorId is part of the instruction for mapping
            creditorId: string; // Assuming creditorId is part of the instruction for mapping
        };
        // STRICT: Instruction must have all fields. No generation of IDs or Dates here.
        if (!instr.createdAt) throw new Error("Mapping failure: Missing deterministic timestamp");

        return {
            messageType: 'pacs.008',
            messageId: instr.id,
            creationDateTime: instr.createdAt,
            debtor: {
                accountId: instr.debtorId
            },
            creditor: {
                accountId: instr.creditorId
            },
            amount: {
                value: instr.amount.toString(),
                currency: instr.currency
            }
        };
    },

    /**
     * Map INBOUND pacs.008 -> Internal Instruction
     */
    fromPacs008: (message: Pacs008Message): InternalInstruction[] => {
        return message.CdtTrfTxInf.map(tx => ({
            id: tx.PmtId.EndToEndId,
            reference: tx.PmtId.TxId,
            amount: tx.IntrBkSttlmAmt.Amount,
            currency: tx.IntrBkSttlmAmt.Currency,
            debtorAccount: "UNKNOWN_IN_PHASE_7", // pacs.008 Debtor is at Group Header or separate, simplified for Phase 7 stub
            creditorAccount: tx.CdtrAcct.Id.IBAN || tx.CdtrAcct.Id.Othr?.Id || "UNKNOWN",
            executionDate: message.GrpHdr.CreDtTm
        }));
    }
};
