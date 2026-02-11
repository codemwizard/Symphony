# AI-Agent Workflow and Role Plan v2

This file mirrors `ai_agent_workflow_and_role_plan_v_2.md` and acts as the canonical Phase-1 contract referenced by tasks, plans, and verifiers.

## Purpose and Non-Negotiables

Symphony uses AI agents to accelerate delivery without weakening regulatory guarantees.

Non-negotiable principles:
- Invariants are first-class contractual objects
- Phase discipline is strict and irreversible
- Evidence is mandatory, append-only, and reproducible
- CI and pre-CI parity is enforced
- AI agents are constrained actors, not autonomous authorities

No AI agent may:
- invent or rename invariant IDs
- bypass a control plane
- weaken an existing invariant
- merge regulated changes without human approval

## Phase Discipline

(abbreviated provenance of Phase-0/1/2 authority; see linked document for full table)

## Invariant Authority Matrix

Control planes own invariants; evidence is the only proof.

## AI Agent Roles

Detailed descriptions for DB/Schema, Runtime, Security, Compliance, Evidence & Audit, and Human Approver roles (see root document for full text).

## Workflow Lifecycle

1. Task Declaration
2. Agent Execution within authority
3. Verifier Integration
4. CI/pre-CI enforcement
5. Human Approval when required
6. Merge/contract update

## Remediation Trace Lifecycle

Every failure must open a remediation trace linking failure signatures, fixes, and evidence.

## Stop Conditions & Escalation

Agents must halt if invariants unclear, phase boundary threatened, no evidence, missing approvals, or control-plane conflicts arise.

## Governance

Prompt/model hash and human approval are recorded before gate passes.

## Operational Enhancements

Allowed optimizations (timeouts, retries) must not weaken evidence semantics.
