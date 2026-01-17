/**
 * Phase 7 Compliance Tests
 * Verifies controls D-1 through D-4 (ISO-20022 Execution integrity)
 * 
 * Run with: npm test
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';
import { Iso20022Validator } from '../libs/iso20022/validator.js';
import { Iso20022Mapper } from '../libs/iso20022/mapping.js';


describe('D. ISO-20022 Execution Control', () => {


    // Valid pacs.008 Payload Stub
    const validPacs008 = {
        GrpHdr: {
            MsgId: "MSG001",
            CreDtTm: "2026-01-01T12:00:00Z",
            NbOfTxs: "1",
            SttlmInf: { SttlmMtd: "CLRG" }
        },
        CdtTrfTxInf: [{
            PmtId: { EndToEndId: "E2E001", TxId: "TX001" },
            IntrBkSttlmAmt: { Amount: 100.00, Currency: "USD" },
            ChrgBr: "DEBT",
            Cdtr: { Nm: "Creditor Name" },
            CdtrAcct: { Id: { IBAN: "US123456" } }
        }]
    };

    describe('D-1 Structural Validation', () => {
        it('should accept valid pacs.008 message', () => {
            const result = Iso20022Validator.validateSchema(validPacs008, 'pacs.008');
            assert.ok(result);
        });

        it('should reject malformed schema (missing field)', () => {
            const malformed = { ...validPacs008, GrpHdr: { ...validPacs008.GrpHdr } };
            // @ts-ignore
            delete malformed.GrpHdr.MsgId;

            assert.throws(() => {
                Iso20022Validator.validateSchema(malformed, 'pacs.008');
            }, /ISO20022:SchemaValidation/);
        });

        it('should accept valid pacs.002 message', () => {
            const pacs002 = {
                GrpHdr: { MsgId: "STS001", CreDtTm: "2026-01-01T12:00:00Z" },
                OrgnlGrpInfAndSts: {
                    OrgnlMsgId: "MSG001",
                    OrgnlMsgNmId: "pacs.008",
                    GrpSts: "ACCP"
                }
            };
            const result = Iso20022Validator.validateSchema(pacs002, 'pacs.002');
            assert.ok(result);
        });
    });

    describe('D-2 Semantic Execution Validation', () => {
        it('should enforce positive amounts (Schema Level)', () => {
            const negativeMsg = JSON.parse(JSON.stringify(validPacs008));
            negativeMsg.CdtTrfTxInf[0].IntrBkSttlmAmt.Amount = -50.00;

            assert.throws(() => {
                Iso20022Validator.validateSchema(negativeMsg, 'pacs.008');
            }, /ISO20022:SchemaValidation/);
        });

        it('should enforce currency consistency', () => {
            const mixedMsg = JSON.parse(JSON.stringify(validPacs008));
            mixedMsg.CdtTrfTxInf.push({
                PmtId: { EndToEndId: "E2E002", TxId: "TX002" },
                IntrBkSttlmAmt: { Amount: 50.00, Currency: "EUR" }, // Different currency
                ChrgBr: "DEBT",
                Cdtr: { Nm: "Creditor 2" },
                CdtrAcct: { Id: { IBAN: "EU123456" } }
            });

            // Cast to proper type for usage
            const typedMsg = Iso20022Validator.validateSchema(mixedMsg, 'pacs.008');

            const isValid = Iso20022Validator.validateSemantics(typedMsg);
            assert.strictEqual(isValid, false, "Should fail semantic validation for mixed currencies");
        });

        it('should enforce instruction uniqueness', () => {
            const duplicateMsg = JSON.parse(JSON.stringify(validPacs008));
            duplicateMsg.CdtTrfTxInf.push(JSON.parse(JSON.stringify(duplicateMsg.CdtTrfTxInf[0]))); // Duplicate Input

            const typedMsg = Iso20022Validator.validateSchema(duplicateMsg, 'pacs.008');

            const isValid = Iso20022Validator.validateSemantics(typedMsg);
            assert.strictEqual(isValid, false, "Should fail semantic validation for duplicate TxIds");
        });
    });

    describe('D-4 Deterministic Mapping', () => {
        it('should map inbound pacs.008 deterministically', () => {
            // @ts-ignore
            const mapped = Iso20022Mapper.fromPacs008(validPacs008);

            assert.strictEqual(mapped.length, 1);
            assert.strictEqual(mapped[0].id, "E2E001");
            assert.strictEqual(mapped[0].amount, 100.00);
            assert.strictEqual(mapped[0].executionDate, "2026-01-01T12:00:00Z");
        });

        it('should fail outbound mapping if non-deterministic (missing date)', () => {
            const instruction = {
                id: "INST001",
                amount: 100,
                debtorId: "D1",
                creditorId: "C1",
                currency: "USD"
                // Missing createdAt
            };

            assert.throws(() => {
                Iso20022Mapper.mapToIso(instruction);
            }, /Missing deterministic timestamp/);
        });
    });
});
