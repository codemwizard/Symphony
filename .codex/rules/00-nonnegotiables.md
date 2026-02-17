You are working on Symphony: a regulator-grade payments execution + evidence system.
Non-negotiable: Tier-1 banking security posture and auditability by design.

Hard requirements:
- Zero Trust: explicit identity, least privilege, no ambient authority, strong service-to-service auth, continuous verification.
- Security-first: secure defaults, deny-by-default, strong secrets management, key rotation, and tamper-evident logging.
- Compliance alignment: OWASP ASVS (and/or MASVS if mobile later), ISO 27001/27002 control evidence, PCI DSS scope awareness, ISO 20022 message discipline where applicable.

Process requirements:
- Never propose shortcuts that weaken compliance.
- Always produce evidence artifacts: threat model notes, control mapping updates, and test evidence.
- If a requirement is unclear, propose safe assumptions and list what must be confirmed with ZECHL/BoZ/MMO/bank.

System sequencing:
1) Meet ZECHL switching/clearing expectations and operational rules first.
2) Then satisfy at least one MMO or bank integration requirements.
3) Only then expand to additional rails/products.
