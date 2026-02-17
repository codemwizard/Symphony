# Governance Rollout Plan: Operation Total Recall

## Executive Summary
This specific plan outlines the stage-by-stage implementation of the **AI Secure Coding Constitution** defined in `TotalRecall.txt`. The goal is to transition the Platform from "Implementation" mode to "Regulated Governance" mode.

## Stage 1: Policy Foundation (The "Law")
**Objective:** Define the non-negotiable rules of engagement before writing more code.
**Timeline:** Immediate

1.  **Establish Policy Repository**
    *   Create dedicated git repo: `org-security-policies`.
    *   Migrate `TotalRecall.txt` content into a formal PDF/Markdown `Secure_Coding_Policy_v1.0.md`.
    *   **Deliverable:** Versioned Policy Artifact signed off by "Security".

2.  **Define Architecture Decisions Records (ADRs)**
    *   Document the "Tooling Standards" (Pino, Slonik, Zod) as immutable ADRs.
    *   **Deliverable:** `/docs/adr/001-logging-standard.md`, `/docs/adr/002-db-access.md`.

## Stage 2: The "Iron Gate" (CI/CD Enforcement)
**Objective:** Automate the policy so deviations cause build failures, not arguments.
**Timeline:** Week 1

1.  **TypeScript Hardening**
    *   Update `tsconfig.json` to enable `strict`, `noImplicitAny`, `exactOptionalPropertyTypes`.
    *   **Action:** Run `tsc` and fix all resulting errors (already partially done).

2.  **Linter Implementation**
    *   Install `eslint` with `@typescript-eslint/recommended-requiring-type-checking`.
    *   Config Custom Rules matching Policy:
        *   `no-console`: Error (Stop Ship).
        *   `no-restricted-syntax`: Ban `pool.query` with template literals (SQLi prevention).
    *   **Deliverable:** `.eslintrc.js` that fails CI on policy violations.

3.  **Dependency Lockdown**
    *   Implement `npm audit` check in the build pipeline.
    *   **Action:** Fail build if High/Critical vulnerabilities exist.

## Stage 3: Identity & Architecture (The "Border Wall")
**Objective:** Implement the Canonical Identity Model to secure the "Trusted Subsystem" flaw.
**Timeline:** Weeks 2-3

1.  **Edge Gateway Deployment**
    *   Deploy the "Trust Boundary" (Gateway/Reverse Proxy).
    *   Move `apiKeyMiddleware` from App to Gateway.

2.  **Token Architecture Implementation**
    *   Implement JWT minting (Identity Provider logic).
    *   Update Platform API to validate JWTs (`Subject` + `Claims`) instead of header trust.
    *   **Deliverable:** Functional `security_architecture_model.md` implementation.

## Stage 4: AI & Testing Guardrails (The "Safety Net")
**Objective:** Bind AI generation to strict verification standards.
**Timeline:** Ongoing

1.  **AI Linting**
    *   Create `ai_lint_rules.md` (as referenced in Policy).
    *   **Rule:** "AI must confirm tests exist or halt."

2.  **Testing Infrastructure**
    *   Ensure Unit, Integration, and Security tests frameworks are active (`vitest`).
    *   **Action:** AI must generate tests for all new Features in this phase.

## Summary Checklist
- [ ] **Stage 1:** Policy Repo Created & Signed Off
- [ ] **Stage 2:** `tsconfig` & `eslint` enforcing "No Any" / "No Console"
- [ ] **Stage 3:** Gateway & JWT Auth Implemented (Removes IDOR risk)
- [ ] **Stage 4:** Coverage thresholds enforced in CI
