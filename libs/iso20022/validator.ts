import { z } from "zod";
import { logger } from "../logging/logger.js";
import { ErrorSanitizer } from "../errors/sanitizer.js";

/**
 * SYM-ISO-001: ISO-20022 Basic Message Schema
 * Focuses on 'pacs.008' (Financial Institution to Financial Institution Customer Credit Transfer)
 */
export const Pacs008Schema = z.object({
    GrpHdr: z.object({
        MsgId: z.string().min(1).max(35),
        CreDtTm: z.string().datetime(),
        NbOfTxs: z.string().regex(/^\d+$/).transform(n => parseInt(n)),
        SttlmInf: z.object({
            SttlmMtd: z.enum(['INDA', 'INGA', 'COVE', 'CLRG'])
        })
    }),
    CdtTrfTxInf: z.array(z.object({
        PmtId: z.object({
            EndToEndId: z.string().max(35),
            TxId: z.string().max(35)
        }),
        IntrBkSttlmAmt: z.object({
            Amount: z.number().positive(), // D-2: Positive amounts
            Currency: z.string().length(3).regex(/^[A-Z]{3}$/)
        }),
        ChrgBr: z.enum(['DEBT', 'CRED', 'SHAR', 'SLEV']),
        Cdtr: z.object({
            Nm: z.string().max(140)
        }),
        CdtrAcct: z.object({
            Id: z.object({
                IBAN: z.string().optional(),
                Othr: z.object({ Id: z.string() }).optional()
            })
        })
    }))
});

/**
 * SYM-ISO-002: pacs.002 (Payment Status Report)
 */
export const Pacs002Schema = z.object({
    GrpHdr: z.object({
        MsgId: z.string().max(35),
        CreDtTm: z.string().datetime()
    }),
    OrgnlGrpInfAndSts: z.object({
        OrgnlMsgId: z.string().max(35),
        OrgnlMsgNmId: z.literal('pacs.008'),
        GrpSts: z.enum(['ACCP', 'RJCT', 'PDNG'])
    }),
    TxInfAndSts: z.array(z.object({
        OrgnlEndToEndId: z.string().max(35),
        TxSts: z.enum(['ACCP', 'RJCT', 'PDNG']),
        StsRsnInf: z.object({
            Rsn: z.object({
                Cd: z.string().max(4)
            }).optional()
        }).optional()
    })).optional()
});

/**
 * SYM-ISO-003: camt.053 (Bank to Customer Statement)
 */
export const Camt053Schema = z.object({
    GrpHdr: z.object({
        MsgId: z.string().max(35),
        CreDtTm: z.string().datetime()
    }),
    Stmt: z.object({
        Id: z.string().max(35),
        ElctrncSeqNb: z.number(),
        CreDtTm: z.string().datetime(),
        Bal: z.array(z.object({
            Tp: z.object({
                CdOrPrtry: z.object({
                    Cd: z.enum(['OPBD', 'CLBD', 'PRCD']) // Opening, Closing, Previously Closed
                })
            }),
            Amt: z.object({
                Amount: z.number(),
                Currency: z.string().length(3)
            }),
            CdtDbtInd: z.enum(['CRDT', 'DBIT']),
            Dt: z.object({
                Dt: z.string().regex(/^\d{4}-\d{2}-\d{2}$/)
            })
        }))
    })
});

export type Pacs008Message = z.infer<typeof Pacs008Schema>;
export type Pacs002Message = z.infer<typeof Pacs002Schema>;
export type Camt053Message = z.infer<typeof Camt053Schema>;

export type Iso20022Message = Pacs008Message | Pacs002Message | Camt053Message;

export class Iso20022Validator {
    /**
     * D-1: Structural Message Validation
     */
    static validateSchema(message: unknown, type: 'pacs.008' | 'pacs.002' | 'camt.053' = 'pacs.008'): Iso20022Message {
        try {
            switch (type) {
                case 'pacs.008': return Pacs008Schema.parse(message);
                case 'pacs.002': return Pacs002Schema.parse(message);
                case 'camt.053': return Camt053Schema.parse(message);
                default: throw new Error(`Unsupported message type: ${type}`);
            }
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            const errorDetails = error instanceof z.ZodError ? error.issues : errorMessage;
            logger.error({ errors: errorDetails, type }, "ISO-20022: Schema validation failed");
            throw ErrorSanitizer.sanitize(error, "ISO20022:SchemaValidation");
        }
    }

    /**
     * D-2: Semantic Execution Validation
     * Only applies to pacs.008 (Execution Instructions)
     */
    static validateSemantics(message: Iso20022Message): boolean {
        // We only enforce strict execution semantics on pacs.008
        // Other types are informational in this phase
        const isPacs008 = (msg: unknown): msg is Pacs008Message =>
            typeof msg === 'object' && msg !== null && 'CdtTrfTxInf' in msg;

        if (!isPacs008(message)) {
            return true;
        }

        // 1. Verify currency consistency (D-2)
        const currencies = new Set(message.CdtTrfTxInf.map(tx => tx.IntrBkSttlmAmt.Currency));
        if (currencies.size > 1) {
            logger.warn("ISO-20022: Semantic failure - Multi-currency batch not supported in Phase 7");
            return false;
        }

        // 2. Verify TxId uniqueness within message (D-2)
        const txIds = message.CdtTrfTxInf.map(tx => tx.PmtId.TxId);
        if (new Set(txIds).size !== txIds.length) {
            logger.warn("ISO-20022: Semantic failure - Duplicate TxIds in batch");
            return false;
        }

        // 3. Verify Constraints (D-2: Positive amounts is handled by Zod schema, but double check logic here if needed)
        // Zod .positive() handles "Amount must be > 0"

        return true;
    }
}
