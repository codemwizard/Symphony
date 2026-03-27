# Remediating Invariants DB Rate Limit

## GF-W1-INVAR-DB Implementation Plan

**Goal Description**
Eliminate the unauthorized `postgres:18` DockerHub container rate-limit failures observed in the core `.github/workflows/invariants.yml` pipeline by transferring database initialization to the stable host-bound application directly.

## Proposed Changes
### .github/workflows/invariants.yml
- [MODIFY] Replaced the docker `services` schema block natively.
- [MODIFY] Inserted the `Setup Native PostgreSQL` module as the definitive first step in the `db_verify_invariants` flow to provision port 5432 reliably on the host runner.

## Verification Plan
### Automated Tests
- Syntax verification using PyYAML ensuring the structural parity is unbroken.
- Repository actions logs confirming the successful `sudo systemctl start postgresql.service` execution bypass.
