# Compliance Map

## Mapping table
| Framework | Requirement / Control | Control Plane | Gate IDs | Enforcement points | Evidence artifacts |
|---|---|---|---|---|---|
| ISO 20022 | Message integrity + attestation hooks | Integrity | INT-G08, INT-G11, INT-G12 | Ingress attestation + routing/batching docs | proxy_resolution_invariant.json, routing_fallback.json, batching_rules.json |
| ISO 20022 | Reversal-only finality workflow (camt.056) | Integrity | INT-G25 | Instruction finality invariant + reversal source enforcement | instruction_finality_invariant.json, instruction_finality_runtime.json |
| ISO 20022 | Ingress instruction traceability and deterministic lookup posture | Integrity | INT-G33 | Ingress hot-path index verifier for tenant/instruction/correlation query paths | ingress_hotpath_indexes.json |
| ISO 20022 | Canonical message model + validation | Integrity | INT-G07 | Phase-0 implementation plan gate | phase0_impl_plan.json |
| ISO 27001/27002 | Access control, least privilege | Security | SEC-G01, SEC-G02, SEC-G03 | Revoke-first grants, SECURITY DEFINER hardening | core_boundary.json, ddl_lock_risk.json, security_definer_dynamic_sql.json |
| ISO 27001/27002 | Privilege regression prevention | Security | SEC-G01 | Multiline-safe lint for forbidden `GRANT CREATE ON SCHEMA public` posture | security_privilege_grants.json |
| ISO 27001/27002 | Secure configuration | Security | SEC-G09 | Infra/workflow config lint | security_secure_config_lint.json |
| ISO 27001/27002 | Secure SDLC / Change control | Integrity | INT-G01, INT-G02, INT-G03 | Evidence schema + contract gates | evidence_validation.json, task_evidence_contract.json, phase0_contract.json |
| ISO 27001/27002 | Change evidence determinism | Integrity | INT-G20 | Canonical git diff helper used by gate scripts and CI prep jobs | git_diff_semantics.json, ci_order.json |
| ISO 27001/27002 | Local/CI DB migration parity | Integrity | INT-G20 | Pre-CI runs a CI-user migration parity probe on a fresh database before full local gate execution | git_diff_semantics.json, ci_order.json |
| ISO 27001/27002 | Dependency governance | Security | SEC-G08 | .NET dependency audit | security_dotnet_deps_audit.json |
| PCI DSS v4.0 | Secure development + vuln mgmt | Security | SEC-G07, SEC-G08, SEC-G10 | Secrets scan + dependency audit + insecure pattern lint | security_secrets_scan.json, security_dotnet_deps_audit.json, security_insecure_patterns.json |
| PCI DSS v4.0 | Access control and key mgmt | Security | SEC-G05 | OpenBao AppRole smoke test | openbao_smoke.json |
| PCI DSS v4.0 | Change control / DDL governance | Security | SEC-G02, SEC-G04 | DDL lock-risk lint + allowlist governance | ddl_lock_risk.json, ddl_allowlist_governance.json |
| NIST CSF / NIST 800-53 | Availability / resource protection (DB timeouts) | Integrity | INT-G32 | DB timeout posture verifier for lock/statement/idle-in-tx bounds | db_timeout_posture.json |
| NIST CSF / NIST 800-53 | Configuration management | Security | SEC-G09 | Secure config lint | security_secure_config_lint.json |
| NIST CSF / NIST 800-53 | Access control + least privilege | Security | SEC-G01, SEC-G03 | Core boundary + SECURITY DEFINER lint | core_boundary.json, security_definer_dynamic_sql.json |
| NIST CSF / NIST 800-53 | Integrity & auditability | Integrity | INT-G01, INT-G05, INT-G06 | Evidence schema + baseline governance | evidence_validation.json, baseline_governance.json, rebaseline_decision.json |
| NIST CSF / NIST 800-53 | Transaction integrity / non-repudiation | Integrity | INT-G25 | Final instruction mutation block + compensating reversal records only | instruction_finality_invariant.json, instruction_finality_runtime.json |
| OWASP ASVS 4.0+ | Input validation + injection prevention | Security | SEC-G10, SEC-G03 | Insecure pattern lint + SECURITY DEFINER lint | security_insecure_patterns.json, security_definer_dynamic_sql.json |
| OWASP ASVS 4.0+ | Secrets management | Security | SEC-G07, SEC-G05 | Secrets scan + OpenBao smoke | security_secrets_scan.json, openbao_smoke.json |
| Zero Trust | Continuous verification (policy) | Integrity | INT-G02, INT-G03 | Evidence contract + phase0 contract | task_evidence_contract.json, phase0_contract.json |
| Zero Trust | Continuous verification (security) | Security | SEC-G06 | CI toolchain pinned | ci_toolchain.json |

## Notes
- Control-plane gates (SEC/INT) are the authoritative enforcement points for Phase-0.
- Evidence artifacts are the proof objects; mapping does not imply production readiness.
- Where controls are roadmap-only, evidence will be document-based (Phase-0).
- Security privilege posture remains fail-closed even when SQL grant statements are wrapped across multiple lines.
