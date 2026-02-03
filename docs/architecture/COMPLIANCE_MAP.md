# Compliance Map

## Mapping table
| Framework | Requirement / Control | Component(s) | Enforcement points | Evidence artifacts |
|---|---|---|---|---|
| ISO 20022 | Canonical message model + validation | Ingest, Orchestration, Adapter | Schema validation, contract tests | Validation reports, test logs |
| ISO 20022 | Mapping discipline and versioning | Policy Service, Contracts | Policy bundle version pinning | Policy bundle checksum logs |
| ISO 27001/27002 | Access control, least privilege | DB roles, Service Mesh | Revoke-first grants, mTLS auth | CI gate logs, access audit logs |
| ISO 27001/27002 | Change management | Policy Service, CI | Promotion workflow, checksum gates | Promotion logs, approvals |
| PCI DSS | Segmentation and tokenization | PCI Zone, Adapter | Network policies, tokenization service | Segmentation config, token logs |
| PCI DSS | Logging and monitoring | Evidence/Audit | Immutable audit logs | Audit bundles, retention logs |
| OWASP ASVS 5.0 | Input validation | Edge Gateway, Ingest | OpenAPI validation, schema tests | API validation logs |
| OWASP ASVS 5.0 | AuthN/Z and session security | Gateway, Services | mTLS, JWT, RBAC | Auth logs, config evidence |
| Zero Trust | Continuous verification | Service Mesh | mTLS, service identity | mTLS cert inventory |
| Zero Trust | Least privilege | DB, Service roles | Role-based access, stored procs | Privilege audit reports |

## Notes
- Controls map to enforcement points in CI and runtime policy checks.
- Evidence artifacts must be immutable and retained per retention policy.
