# Symphony Financial DNA — Architectural Lock-In

**Phase**: Phase-6-Ad
**Key**: SYM-37
**Status**: 🔒 LOCKED

## Overview
This document formalizes the fundamental financial primitives that govern the Symphony Ledger. These rules are non-negotiable and must be enforced by all implementations in Phase 7 and beyond.

---

## 1. Zero-Sum Continuous Proof (INV-FIN-01)
The Symphony Ledger is founded on the principle of absolute mathematical integrity.
- **Requirement**: The system MUST be able to produce a continuous proof that `Sum(All Ledger Accounts) == 0` at any point in time.
- **Enforcement**: Phase 7 must include a "Ledger Auditor" service that performs real-time or near-real-time verification of the zero-sum invariant.
- **Anchor**: All system-internal obligations must be anchored to a `PROGRAM_CLEARING` or `VENDOR_SETTLEMENT` account.

## 2. Posting Idempotency (INV-FIN-05)
To ensure reliability across retries and BCDR events, ledger postings must be strictly idempotent.
- **Requirement**: A financial posting identified by a specific transaction/attempt reference MUST NOT create additional ledger entries if re-processed or replayed.
- **Enforcement**: Database-level unique constraints and "ignore on conflict" logic must be applied to the ledger entry tables.

## 3. Currency Explicitness (INV-FIN-06)
Symphony is a multi-currency, cross-border platform.
- **Requirement**: Every financial amount field in the schema MUST be associated with an explicit ISO 4217 (3-letter) currency code.
- **FX Linkage**: Any movement involving multiple currencies MUST be represented as separate debit/credit pairs (one pair per currency) linked by a single immutable FX Reference ID.
- **Implicit Prohibition**: Any code assuming a "default currency" is a violation of this invariant.

## 4. Ledger Structural Prohibitions
- **Ban on Balance Columns**: It is strictly forbidden to store account balances as simple scalar columns in a `wallets` table. Balances must ALWAYS be derived from the sum of immutable ledger entries.
- **Ban on Self-Netting**: A ledger entry where `DebitAccountId == CreditAccountId` must be rejected at the schema level.

---
**Sign-Off**: This document constitutes the "Financial DNA" of the Symphony platform. No Phase 7 implementation may deviate from these structural laws.
