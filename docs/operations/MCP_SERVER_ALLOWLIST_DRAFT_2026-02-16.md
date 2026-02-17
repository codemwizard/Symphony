# MCP Server Allowlist (Draft)

Date: 2026-02-16
Status: Draft for review
Scope: Symphony Phase-1 agentic workflow

## Purpose
Define a practical, free, and safety-screened MCP server baseline for the three Phase-1 agent roles:
- Architect Agent
- Implementer Agent
- Requirements and Policy Integrity Agent

This draft prefers official or widely recognized servers, and defaults to read-only usage where possible.

## Selection Criteria
- Free to run (open-source self-hosted or free hosted access tier).
- Maintained by official orgs or well-known vendors.
- Clear security posture and controllable permissions.
- Useful to Phase-1 execution without expanding scope.

## Recommended Server List

1. `@modelcontextprotocol/server-filesystem`
- Maintainer: MCP steering group reference server (`modelcontextprotocol/servers`)
- Main use: Controlled file read/write within scoped project roots.
- Why include: Core local context access for plans, tasks, policy docs, and evidence files.
- Safety profile: Restrict roots to workspace paths only; never mount home or system-wide paths.
- Cost: Free (self-hosted).
- Agent mapping: Architect, Implementer, Requirements/Policy.

2. `mcp-server-git`
- Maintainer: MCP steering group reference server (`modelcontextprotocol/servers`)
- Main use: Git history/diff/log context for parity and policy audits.
- Why include: Supports deterministic review of changed files, commits, and blame context.
- Safety profile: Read-only operations by policy; no branch mutation tooling enabled.
- Cost: Free (self-hosted).
- Agent mapping: Architect, Implementer, Requirements/Policy.

3. `mcp-server-time`
- Maintainer: MCP steering group reference server (`modelcontextprotocol/servers`)
- Main use: Reliable UTC/timezone conversion for logs and evidence timestamps.
- Why include: Supports deterministic timestamp normalization in artifacts.
- Safety profile: Low risk utility server.
- Cost: Free (self-hosted).
- Agent mapping: Implementer, Requirements/Policy.

4. `@modelcontextprotocol/server-memory`
- Maintainer: MCP steering group reference server (`modelcontextprotocol/servers`)
- Main use: Structured memory/knowledge graph for bounded project facts.
- Why include: Helps maintain continuity across long-running tasks.
- Safety profile: Keep data scoped to project; no secrets; retention policy required.
- Cost: Free (self-hosted).
- Agent mapping: Architect, Requirements/Policy.

5. `github/github-mcp-server`
- Maintainer: GitHub (official server)
- Main use: Repository/PR/issue/workflow context from GitHub.
- Why include: Strong integration for CI and task-flow visibility.
- Safety profile: Start in read-only mode/toolsets; PAT scopes minimal; prefer repository read and workflow read.
- Cost: Free server; API usage depends on GitHub plan and token scopes.
- Agent mapping: Architect, Implementer, Requirements/Policy.

## Servers to Avoid by Default
- Archived reference servers from `modelcontextprotocol/servers-archived` for production workflows.
- Any server without active maintenance, security policy, or permission controls.
- High-risk execution servers that can mutate infrastructure or secrets unless separately approved.

## Wiring Recommendation by Agent Role

1. Architect Agent (design and planning)
- Primary servers: `filesystem`, `git`, `github`, optional `memory`.
- Mode: Read-mostly.

2. Implementer Agent (code and verifier wiring)
- Primary servers: `filesystem`, `git`, `github`, `time`.
- Mode: Controlled write in workspace only; no external mutation via MCP.

3. Requirements and Policy Integrity Agent (advisory governance role)
- Primary servers: `filesystem`, `git`, `time`, optional `memory`, optional `github`.
- Mode: Strictly read-only; cannot execute or mutate code.

## Safety Guardrails (Mandatory)
- Use MCP Registry and official repos as trust anchors.
- Pin server versions in config; avoid floating latest in production.
- Enforce per-server allowlists and least-privilege tokens.
- Log all MCP calls for auditability where host supports it.
- Require source citation (`url`, `retrieved_at_utc`, `purpose`) for external research tasks.

## Source Anchors
- MCP Registry: https://registry.modelcontextprotocol.io/
- MCP reference servers and security warning: https://github.com/modelcontextprotocol/servers
- GitHub official MCP server: https://github.com/github/github-mcp-server

## Notes
- The `modelcontextprotocol/servers` repository states its reference servers are educational examples, not production-ready by default. Use hardening controls above before production usage.
- A pinned baseline config is now tracked via `TSK-P1-031` and stored at `mcp.json`.
- Operational connectivity and policy validation is tracked via `TSK-P1-032`.
- AGNI scope update: `fetch` is removed from Phase-1 baseline and not allowlisted.
