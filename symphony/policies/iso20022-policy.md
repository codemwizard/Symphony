# Symphony Compliance Policy: ISO-20022 Financial Messaging

**ID:** POL-CMP-001
**Status:** DRAFT (Foundation)
**Effective Date:** January 5, 2026

## 1. Objective
To ensure all financial fund movements on the Symphony Ledger adhere to international messaging standards (ISO-20022), enabling global interoperability and regulatory compliance.

## 2. Standards Adoption
Symphony adopts the ISO-20022:2013 standard for the following business areas:
- **Payments (pacs)**: Interbank settlement and clearing.
- **Cash Management (camt)**: Reporting and status updates.
- **Payments Initiation (pain)**: Customer-to-bank instructions.

## 3. Enforcement Mechanisms
1.  **Ingress Validation**: All financial instructions entering `ingest-api` must be mappable to a canonical ISO-20022 structure.
2.  **Kernel Guard**: The Double-Entry Engine (Phase 7) will reject movements that do not carry an ISO-20022 message identifier.
3.  **Audit Trail**: The `ISO20022Validator` (libs/iso20022) must log a compliance hash for every valid message processed.

## 4. Implementation Schedule
- **Phase 6**: Framework & Interface establishment (COMPLETED).
- **Phase 7**: Schema enforcement for `pacs.008` (Settlement).
- **Phase 8**: Full support for customer credit transfers.
