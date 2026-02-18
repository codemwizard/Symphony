Coding standards:
- Prefer simple, verifiable designs. Avoid cleverness.
- No dynamic SQL in SECURITY DEFINER functions unless formally proven safe.
- All authZ decisions must be explicit and testable.
- No shared secrets in code; all secrets via vault/secure env + rotation plan.
- Enforce idempotency, replay protection, and deterministic state transitions.
- All logs must be structured and tamper-evident where required.
