#!/usr/bin/env python3
"""
Born-Secure RLS Lint — exact template enforcement for GF migrations.

Enforces that every tenant-isolated or jurisdiction-isolated table has
exactly the canonical RLS configuration established in migration 0059:

  ALTER TABLE public.<T> ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.<T> FORCE ROW LEVEL SECURITY;

  CREATE POLICY rls_<isolation_type>_<T> ON public.<T>
    FOR ALL TO PUBLIC
    USING (<isolation_expr>)
    WITH CHECK (<isolation_expr>);

Where <isolation_expr> is EXACTLY one of:
  - tenant_id = public.current_tenant_id_or_null()          [tenant]
  - jurisdiction_code = public.current_jurisdiction_code_or_null()  [jurisdiction]
  - EXISTS (... AND <parent>.tenant_id = public.current_tenant_id_or_null())  [join]

Zero tolerance for drift. No extra predicates. No role-scoped policies.
No AS RESTRICTIVE (blocks all access without a companion PERMISSIVE policy).
No system_full_access. No legacy current_setting().

Technology: regex-based (not sqlglot) because CREATE POLICY, ENABLE/FORCE
RLS are PG-specific commands that sqlglot parses as Command nodes anyway.
"""

import json
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Canonical expression templates (EXACT match after normalization)
# ---------------------------------------------------------------------------

CANONICAL_TENANT_EXPR = "tenant_id = public.current_tenant_id_or_null()"
CANONICAL_JURISDICTION_EXPR = "jurisdiction_code = public.current_jurisdiction_code_or_null()"


def normalize_ws(s: str) -> str:
    """Collapse all whitespace to single spaces and strip."""
    return re.sub(r'\s+', ' ', s).strip()


def normalize_expr(expr: str) -> str:
    """Normalize a SQL expression for comparison: lowercase, collapse ws, strip parens."""
    s = expr.strip().lower()
    s = re.sub(r'\s+', ' ', s)
    # Strip outer parentheses if balanced
    while s.startswith('(') and s.endswith(')'):
        inner = s[1:-1]
        depth = 0
        balanced = True
        for c in inner:
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
            if depth < 0:
                balanced = False
                break
        if balanced and depth == 0:
            s = inner.strip()
        else:
            break
    return s


# ---------------------------------------------------------------------------
# Table extraction
# ---------------------------------------------------------------------------

RE_CREATE_TABLE = re.compile(
    r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?'
    r'(?:public\.)?(\w+)\s*\(',
    re.IGNORECASE
)


def extract_tables(sql: str) -> dict[str, dict]:
    """
    Extract all CREATE TABLE statements and classify their isolation type.

    Returns dict of table_name -> {
        'has_tenant_id': bool,
        'has_jurisdiction_code': bool,
        'isolation_type': 'tenant' | 'jurisdiction' | 'none'
    }
    """
    tables = {}
    for m in RE_CREATE_TABLE.finditer(sql):
        table_name = m.group(1).lower()
        # Get the column block (between parens, up to closing paren)
        start = m.end() - 1  # position of opening paren
        depth = 0
        end = start
        for i in range(start, len(sql)):
            if sql[i] == '(':
                depth += 1
            elif sql[i] == ')':
                depth -= 1
            if depth == 0:
                end = i
                break
        col_block = sql[start:end + 1].lower()
        has_tid = bool(re.search(r'\btenant_id\b', col_block))
        has_jc = bool(re.search(r'\bjurisdiction_code\b', col_block))

        # Classify
        if has_tid:
            iso = 'tenant'
        elif has_jc:
            iso = 'jurisdiction'
        else:
            iso = 'none'

        tables[table_name] = {
            'has_tenant_id': has_tid,
            'has_jurisdiction_code': has_jc,
            'isolation_type': iso,
        }
    return tables


# ---------------------------------------------------------------------------
# RLS statement extraction
# ---------------------------------------------------------------------------

RE_ENABLE_RLS = re.compile(
    r'ALTER\s+TABLE\s+(?:public\.)?(\w+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY',
    re.IGNORECASE
)

RE_FORCE_RLS = re.compile(
    r'ALTER\s+TABLE\s+(?:public\.)?(\w+)\s+FORCE\s+ROW\s+LEVEL\s+SECURITY',
    re.IGNORECASE
)

# Full policy extraction — captures name, table, and full body
RE_CREATE_POLICY = re.compile(
    r'CREATE\s+POLICY\s+(\w+)\s+ON\s+(?:public\.)?(\w+)\s*'
    r'(.*?)\s*;',
    re.IGNORECASE | re.DOTALL
)


def parse_policy(body: str) -> dict:
    """Parse a CREATE POLICY body into structured components."""
    result = {
        'is_restrictive': False,
        'operation': None,
        'role': None,
        'using_expr': None,
        'with_check_expr': None,
        'raw_body': body.strip(),
    }

    body_norm = normalize_ws(body)

    # AS RESTRICTIVE / AS PERMISSIVE
    if re.search(r'\bAS\s+RESTRICTIVE\b', body_norm, re.IGNORECASE):
        result['is_restrictive'] = True

    # FOR ALL / FOR SELECT / etc
    op_match = re.search(r'\bFOR\s+(ALL|SELECT|INSERT|UPDATE|DELETE)\b', body_norm, re.IGNORECASE)
    if op_match:
        result['operation'] = op_match.group(1).upper()

    # TO <role>
    to_match = re.search(r'\bTO\s+(\w+)\b', body_norm, re.IGNORECASE)
    if to_match:
        result['role'] = to_match.group(1).lower()

    # USING clause — find the expression inside USING(...)
    # Handle nested parentheses (for EXISTS subqueries)
    using_match = re.search(r'\bUSING\s*\(', body, re.IGNORECASE)
    if using_match:
        start = using_match.end()
        result['using_expr'] = _extract_balanced_parens(body, start)

    # WITH CHECK clause
    wc_match = re.search(r'\bWITH\s+CHECK\s*\(', body, re.IGNORECASE)
    if wc_match:
        start = wc_match.end()
        result['with_check_expr'] = _extract_balanced_parens(body, start)

    return result


def _extract_balanced_parens(text: str, start: int) -> str | None:
    """Extract content from start position until balanced closing paren."""
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
        i += 1
    if depth == 0:
        return text[start:i - 1].strip()
    return None


# ---------------------------------------------------------------------------
# Violation checks
# ---------------------------------------------------------------------------

def check_table(
    table: str,
    table_info: dict,
    enable_tables: set,
    force_tables: set,
    policies: dict,
    filepath: str,
) -> list[dict]:
    """Check a single table for born-secure compliance."""
    violations = []
    iso_type = table_info['isolation_type']

    if iso_type == 'none':
        # Tables without tenant_id or jurisdiction_code are not isolation targets
        return violations

    # --- ENABLE RLS ---
    if table not in enable_tables:
        violations.append({
            'type': 'MISSING_ENABLE_RLS',
            'table': table,
            'file': filepath,
            'message': f"Table '{table}' has {iso_type} isolation but missing ENABLE ROW LEVEL SECURITY",
        })

    # --- FORCE RLS ---
    if table not in force_tables:
        violations.append({
            'type': 'MISSING_FORCE_RLS',
            'table': table,
            'file': filepath,
            'message': f"Table '{table}' missing FORCE ROW LEVEL SECURITY",
        })

    # --- Policy count ---
    table_policies = policies.get(table, [])
    if len(table_policies) == 0:
        violations.append({
            'type': 'BORN_SECURE_VIOLATION',
            'table': table,
            'file': filepath,
            'message': f"Table '{table}' has no RLS policy",
        })
        return violations

    if len(table_policies) > 1:
        names = [p['name'] for p in table_policies]
        violations.append({
            'type': 'WRONG_POLICY_COUNT',
            'table': table,
            'file': filepath,
            'message': f"Table '{table}' has {len(table_policies)} policies (must be exactly 1): {names}",
        })

    # Check each policy (reports on all — even if count is wrong)
    for pol in table_policies:
        name = pol['name']
        parsed = pol['parsed']

        # --- system_full_access ---
        if 'system_full_access' in name.lower():
            violations.append({
                'type': 'SYSTEM_FULL_ACCESS_PRESENT',
                'table': table,
                'file': filepath,
                'message': f"Policy '{name}' is a system_full_access bypass — must be deleted",
            })
            continue  # Don't check structure of a policy that should be deleted

        # --- USING (true) ---
        if parsed['using_expr'] is not None:
            using_norm = normalize_expr(parsed['using_expr'])
            if using_norm == 'true':
                violations.append({
                    'type': 'USING_TRUE_POLICY',
                    'table': table,
                    'file': filepath,
                    'message': f"Policy '{name}' has USING (true) — unconditional access bypass",
                })
                continue

        # --- Must NOT be AS RESTRICTIVE (blocks all access without companion PERMISSIVE) ---
        if parsed['is_restrictive']:
            violations.append({
                'type': 'IS_RESTRICTIVE',
                'table': table,
                'file': filepath,
                'message': f"Policy '{name}' is AS RESTRICTIVE — blocks all access without a companion PERMISSIVE policy. Remove AS RESTRICTIVE.",
            })

        # --- FOR ALL ---
        if parsed['operation'] != 'ALL':
            violations.append({
                'type': 'NOT_FOR_ALL',
                'table': table,
                'file': filepath,
                'message': f"Policy '{name}' is FOR {parsed['operation']} not FOR ALL",
            })

        # --- TO PUBLIC ---
        if parsed['role'] != 'public':
            violations.append({
                'type': 'ROLE_SCOPED_POLICY',
                'table': table,
                'file': filepath,
                'message': f"Policy '{name}' targets TO {parsed['role']} — must be TO PUBLIC",
            })

        # --- USING expression exact match ---
        if parsed['using_expr'] is not None:
            using_norm = normalize_expr(parsed['using_expr'])
            expected = _expected_expr(iso_type)
            if not _expr_matches(using_norm, expected, iso_type):
                violations.append({
                    'type': 'WRONG_USING_EXPRESSION',
                    'table': table,
                    'file': filepath,
                    'message': (
                        f"Policy '{name}' USING expression does not match canonical template. "
                        f"Expected: {expected}. Got: {using_norm[:120]}"
                    ),
                })
        else:
            violations.append({
                'type': 'WRONG_USING_EXPRESSION',
                'table': table,
                'file': filepath,
                'message': f"Policy '{name}' has no USING clause",
            })

        # --- WITH CHECK expression ---
        if parsed['with_check_expr'] is not None:
            wc_norm = normalize_expr(parsed['with_check_expr'])
            expected = _expected_expr(iso_type)
            if not _expr_matches(wc_norm, expected, iso_type):
                violations.append({
                    'type': 'WRONG_WITH_CHECK',
                    'table': table,
                    'file': filepath,
                    'message': (
                        f"Policy '{name}' WITH CHECK does not match canonical template. "
                        f"Expected: {expected}. Got: {wc_norm[:120]}"
                    ),
                })
        else:
            violations.append({
                'type': 'WRONG_WITH_CHECK',
                'table': table,
                'file': filepath,
                'message': f"Policy '{name}' has no WITH CHECK clause",
            })

    return violations


def _expected_expr(iso_type: str) -> str:
    """Return the canonical USING expression for the given isolation type."""
    if iso_type == 'tenant':
        return CANONICAL_TENANT_EXPR
    elif iso_type == 'jurisdiction':
        return CANONICAL_JURISDICTION_EXPR
    return ""


def _expr_matches(actual: str, expected: str, iso_type: str) -> bool:
    """
    Check if actual expression matches the expected canonical template.

    For tenant/jurisdiction: exact string match after normalization.
    For JOIN-based (EXISTS): must contain the canonical function call
    inside an EXISTS subquery. We check for structural markers.
    """
    actual_clean = normalize_expr(actual)
    expected_clean = normalize_expr(expected)

    # Direct column match (tenant_id or jurisdiction_code)
    if actual_clean == expected_clean:
        return True

    # JOIN-based: EXISTS subquery that references the canonical function
    if iso_type == 'tenant' and actual_clean.startswith('exists'):
        # Must contain the canonical function call
        if 'public.current_tenant_id_or_null()' in actual_clean:
            return True

    return False


# ---------------------------------------------------------------------------
# File-level lint
# ---------------------------------------------------------------------------

def lint_file(filepath: str) -> list[dict]:
    """Run born-secure checks on a single migration file."""
    sql = Path(filepath).read_text()

    # Extract tables and their isolation types
    tables = extract_tables(sql)

    # Extract ENABLE RLS tables
    enable_tables = {m.group(1).lower() for m in RE_ENABLE_RLS.finditer(sql)}

    # Extract FORCE RLS tables
    force_tables = {m.group(1).lower() for m in RE_FORCE_RLS.finditer(sql)}

    # Extract all policies, grouped by target table
    policies: dict[str, list] = {}
    for m in RE_CREATE_POLICY.finditer(sql):
        pol_name = m.group(1)
        pol_table = m.group(2).lower()
        pol_body = m.group(3)
        parsed = parse_policy(pol_body)

        if pol_table not in policies:
            policies[pol_table] = []
        policies[pol_table].append({
            'name': pol_name,
            'parsed': parsed,
        })

    # Check all tables with isolation columns
    violations = []
    for table, info in tables.items():
        violations.extend(
            check_table(table, info, enable_tables, force_tables, policies, filepath)
        )

    # Also check for policies on tables NOT created in this file
    # (cross-table contamination)
    for pol_table, pols in policies.items():
        if pol_table not in tables:
            # Policy targets a table not created in this migration
            # This is caught by scope lint, not us — skip
            pass

    return violations


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print("Usage: lint_rls_born_secure.py <sql_file> [sql_file ...]", file=sys.stderr)
        sys.exit(2)

    all_violations = []

    for filepath in sys.argv[1:]:
        p = Path(filepath)
        if not p.exists():
            print(f"ERROR: File not found: {filepath}", file=sys.stderr)
            sys.exit(2)
        all_violations.extend(lint_file(filepath))

    if all_violations:
        output = {
            "status": "FAIL",
            "violation_count": len(all_violations),
            "violations": all_violations,
        }
        print(json.dumps(output, indent=2))
        sys.exit(1)
    else:
        output = {"status": "PASS", "violation_count": 0, "violations": []}
        print(json.dumps(output, indent=2))
        sys.exit(0)


if __name__ == "__main__":
    main()
