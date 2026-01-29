Structural change evidence map

Source: detect.json (matches recorded by structural-change detector)

Each entry shows the precise added line that triggered a match.

1. .cursor/rules/01-hard-constraints.md
   - Type: security
   - Change: + - SECURITY DEFINER functions must harden: `SET search_path = pg_catalog, public`.

2. .cursor/rules/01-hard-constraints.md
   - Type: security
   - Change: + - Runtime roles are NOLOGIN templates; app uses SET ROLE.

3. .cursor/rules/03-security-contract.md
   - Type: security
   - Change: + - weaken DB grants / roles / SECURITY DEFINER posture

4. .cursor/rules/03-security-contract.md
   - Type: security
   - Change: + - introduce dynamic SQL in SECURITY DEFINER without explicit justification and review

5. .github/codex/prompts/security_review.md
   - Type: security
   - Change: + - SECURITY DEFINER functions must keep: `SET search_path = pg_catalog, public`.

6. .github/codex/prompts/security_review.md
   - Type: security
   - Change: + - SECURITY DEFINER without safe `search_path`.

7. .github/codex/prompts/security_review.md
   - Type: security
   - Change: + - Dynamic SQL in SECURITY DEFINER without clear justification.

8. AGENTS.md
   - Type: security
   - Change: + - SECURITY DEFINER functions must harden: `SET search_path = pg_catalog, public`.

9. AGENTS.md
   - Type: security
   - Change: + - Revoke-first privilege posture; runtime roles must not regain CREATE on schemas.

10. AGENTS.md
   - Type: security
   - Change: + Never: broaden privileges, weaken SECURITY DEFINER hardening, add runtime DDL.

11. docs/security/SECURITY_MANIFEST.yml
   - Type: security
   - Change: + title: "SECURITY DEFINER functions must set safe search_path"

12. docs/security/SECURITY_MANIFEST.yml
   - Type: security
   - Change: + - "schema/migrations/* (revoke-first posture)"

13. scripts/security/lint_privilege_grants.sh
   - Type: security
   - Change: + if grep -Eqi "GRANT\s+CREATE\s+ON\s+SCHEMA\s+public\s+TO\s+(PUBLIC|symphony_)" "$file"; then

14. scripts/security/lint_privilege_grants.sh
   - Type: security
   - Change: + echo "ERROR: $file appears to grant CREATE on schema public to PUBLIC/runtime role"

15. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + echo "==> Checking SECURITY DEFINER function hardening (search_path) in migrations"

16. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + # Heuristic: only treat SECURITY DEFINER as a hardening requirement when it appears

17. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + # Fast path: if no SECURITY DEFINER anywhere, skip.

18. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + grep -q "SECURITY DEFINER" "$file" || continue

19. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + # Find line numbers where SECURITY DEFINER appears.

20. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + # Only enforce if context suggests this SECURITY DEFINER is in a function definition/change.

21. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + # This catches: "... SECURITY DEFINER SET search_path = pg_catalog, public"

22. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + if ! echo "$near" | grep -q "SET search_path = pg_catalog, public"; then

23. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + echo "ERROR: $file:$lineno has SECURITY DEFINER near CREATE/ALTER FUNCTION without safe search_path"

24. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + done < <(grep -n "SECURITY DEFINER" "$file" || true)

25. scripts/security/lint_sql_injection.sh
   - Type: security
   - Change: + echo "✅ SECURITY DEFINER hardening looks OK"
