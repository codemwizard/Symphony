# Supervisory UI Source Of Truth

Status: Canonical
Owner: Operations / Product Architecture
Applies to: GreenTech4CE pilot-demo supervisory shell

## Purpose

This document defines the canonical supervisory UI shell for Phase-1 demo scope and freezes the per-surface backing-mode matrix before implementation.

## Canonical Shell

- Canonical target shell: the v3 supervisory shell derived from `symphony-ui-wire-pack-v2.zip`
- Primary route: `GET /pilot-demo/supervisory`
- Legacy route: `GET /pilot-demo/supervisory-legacy` only when `SYMPHONY_ENABLE_LEGACY_SUPERVISORY_UI=1`
- Outside `pilot-demo`: both routes must return `404`
- Existing thin shell is retired from normal demo navigation and available only for explicit debug access

## Non-Canonical Assumptions Rejected

- `/api/v1` is not a valid API base in this repo
- browser use of raw `instruction_file_path` is not valid
- unsupported-claim copy using forbidden settlement-language substrings is not allowed
- silent static fallback for `LIVE` surfaces is not allowed

## Backing Mode Rules

- `LIVE`: use live backend data only; if live calls fail under healthy conditions, show explicit unavailable/error state
- `HYBRID`: may use demo/evidence fallback only when visibly labeled `Demo-backed fallback active`
- `DEMO_BACKED`: intentionally demo/scripted and visibly labeled
- `LIVE_FROM_EVIDENCE`: derived from real evidence artifacts instead of direct runtime APIs

## Per-Surface Matrix

| Surface | Mode | Notes |
|---|---|---|
| Programme summary | LIVE | Uses reveal API |
| Timeline | LIVE | Uses reveal API |
| Evidence completeness | LIVE | Uses reveal API |
| Exception log | LIVE | Uses reveal API |
| Evidence-link issue | LIVE | Operator action only |
| Signed instruction generate | LIVE | Real backend contract |
| Signed instruction verify | LIVE | Browser-safe `instruction_file_ref` wrapper required |
| Supplier policy lookup | LIVE | Real backend contract |
| Detail / drill-down | LIVE | Requires detail route |
| Export | LIVE | Requires synchronous export route |
| Ack / interrupt state | LIVE | Requires read-model/API projection |
| SIM-swap | DEMO_BACKED | Phase-1 decision; future task required for LIVE |
| Pilot success panel | LIVE_FROM_EVIDENCE | Derived from demo gate evidence |

## Prerequisite Posture

The following are existing capabilities/artifacts that must be revalidated against the new shell and contract mapping:

- `TSK-P1-DEMO-008`
- `TSK-P1-DEMO-009`
- `TSK-P1-DEMO-010`
- `TSK-P1-DEMO-011`

They are not treated as proof that the new shell is already integrated.

## Compatibility Requirements

The new shell must preserve or alias these DEMO-008 verifier IDs:

- `programme-summary-panel`
- `timeline-panel`
- `evidence-completeness-panel`
- `exception-log-panel`
- `export-trigger`
- `raw-artifact-drilldown`

## Privileged Action Rule

Privileged operator actions must keep admin credentials server-side.

- The browser must not receive `SYMPHONY_UI_ADMIN_API_KEY` or any equivalent admin secret in bootstrap context.
- The browser must not send `x-admin-api-key`.
- Any privileged supervisory/operator action needed by the shell must flow through same-origin pilot-demo proxy routes implemented server-side.
