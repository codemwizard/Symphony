# ADR-0008: Proxy/Alias Resolution Strategy (Phase‑0 Roadmap)

## Status
Roadmap (Phase‑0 declaration)

## Context
Some instructions arrive with **proxy identifiers** (aliases) such as MSISDN, TPIN, or program‑specific member references. Before dispatch, the system must resolve these proxies to a concrete participant/account in a **durable, auditable** way, without storing raw PII.

## Decision
Phase‑0 declares the invariant and design hooks:

- **Resolve point:** proxy/alias resolution is required **before dispatch** (fail‑closed if unresolved).
- **Durable record:** each resolution produces an append‑only record containing only **hashes and identifiers**.
- **No raw PII:** only hashed proxy values are stored.
- **Evidence:** a static verifier confirms invariant declaration + ADR + schema hook docs.

## Consequences
- Phase‑0 does **not** implement runtime resolution, only the invariant and schema hooks.
- Phase‑1/2 will wire resolution into the ingest/outbox path and emit runtime evidence.

## Fail‑Closed Rule
If a proxy resolution is required and **no valid resolution exists**, the instruction must **not** be dispatched.

## Required Fields (Roadmap)
The durable proxy resolution record must include:
- `instruction_id`
- `alias_type`
- `alias_hash` (salted)
- `resolved_participant_ref`
- `resolution_source`
- `resolved_at`
- `expires_at` (if applicable)
- `evidence_hash` (hash of response payload)

## Links
- Schema design: `docs/architecture/schema/proxy_resolution_schema.md`
