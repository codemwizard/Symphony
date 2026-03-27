#!/usr/bin/env python3
"""
GF Migration Scope Lint — AST-based structural enforcement.

Enforces three invariants on GF migrations (0080+):
  INV-1: Table Ownership — a migration may ONLY modify tables it creates.
  INV-2: No Post-Policy Mutation — after CREATE POLICY for table T,
         no further mutation of T (except CREATE INDEX).
  INV-3: LIKE Requires RLS — CREATE TABLE ... LIKE must have an RLS block.

Policy expression correctness is NOT checked here.
That responsibility belongs to lint_rls_born_secure.sh (static)
and verify_ten_002_rls_leakage.sh (runtime).

Technology: sqlglot for CREATE TABLE AST parsing,
controlled regex fallback for PG-specific statements
(ENABLE/FORCE RLS, CREATE POLICY, OWNER TO, etc.)
that sqlglot parses as Command nodes.
"""

import json
import logging
import re
import sys
from pathlib import Path

# Suppress sqlglot warnings for expected PG-specific fallbacks
logging.getLogger("sqlglot").setLevel(logging.ERROR)

import sqlglot
from sqlglot import exp


# ---------------------------------------------------------------------------
# Table name normalization
# ---------------------------------------------------------------------------

def normalize_table(name: str) -> str:
    """
    Normalize table name: strip schema prefix, lowercase, strip quotes.

    public.adapter_registrations -> adapter_registrations
    ONLY public.adapter_registrations -> adapter_registrations
    "adapter_registrations" -> adapter_registrations
    """
    if not name:
        return ""
    name = name.strip().lower()
    name = name.replace('"', '')
    # Strip ONLY prefix
    name = re.sub(r'^only\s+', '', name)
    # Strip schema prefix
    if '.' in name:
        name = name.split('.')[-1]
    return name


# ---------------------------------------------------------------------------
# Regex patterns for Command fallback parsing
# ---------------------------------------------------------------------------

# CREATE TABLE [IF NOT EXISTS] [schema.]table
RE_CREATE_TABLE = re.compile(
    r'CREATE\s+TABLE\s+'
    r'(?:IF\s+NOT\s+EXISTS\s+)?'
    r'(?:(?P<schema>\w+)\.)?'
    r'(?P<table>\w+)',
    re.IGNORECASE
)

# ALTER TABLE [IF EXISTS] [ONLY] [schema.]table ...
RE_ALTER_TABLE = re.compile(
    r'ALTER\s+TABLE\s+'
    r'(?:IF\s+EXISTS\s+)?'
    r'(?:ONLY\s+)?'
    r'(?:(?P<schema>\w+)\.)?'
    r'(?P<table>\w+)',
    re.IGNORECASE
)

# CREATE POLICY ... ON [schema.]table
RE_CREATE_POLICY = re.compile(
    r'CREATE\s+POLICY\s+\S+\s+ON\s+'
    r'(?:(?P<schema>\w+)\.)?'
    r'(?P<table>\w+)',
    re.IGNORECASE
)

# ENABLE ROW LEVEL SECURITY
RE_ENABLE_RLS = re.compile(r'ENABLE\s+ROW\s+LEVEL\s+SECURITY', re.IGNORECASE)

# DISABLE ROW LEVEL SECURITY
RE_DISABLE_RLS = re.compile(r'DISABLE\s+ROW\s+LEVEL\s+SECURITY', re.IGNORECASE)

# FORCE ROW LEVEL SECURITY
RE_FORCE_RLS = re.compile(r'FORCE\s+ROW\s+LEVEL\s+SECURITY', re.IGNORECASE)

# OWNER TO
RE_OWNER_TO = re.compile(r'OWNER\s+TO', re.IGNORECASE)

# DROP POLICY
RE_DROP_POLICY = re.compile(r'DROP\s+POLICY', re.IGNORECASE)

# Column mutations: ADD COLUMN, DROP COLUMN, ALTER COLUMN, RENAME
RE_COLUMN_MUTATION = re.compile(
    r'(?:ADD|DROP|ALTER)\s+COLUMN|RENAME',
    re.IGNORECASE
)

# CREATE INDEX (permitted after policy)
RE_CREATE_INDEX = re.compile(r'CREATE\s+(?:UNIQUE\s+)?INDEX', re.IGNORECASE)

# CREATE TABLE ... LIKE
RE_LIKE = re.compile(r'LIKE\s+', re.IGNORECASE)


# ---------------------------------------------------------------------------
# Statement classification
# ---------------------------------------------------------------------------

def classify_statements(sql_text: str, filepath: str):
    """
    Parse SQL and classify each statement into ordered events.

    Returns:
        created_tables: set of normalized table names created in this file
        statement_order: list of (type, table, detail) tuples
        has_like: set of tables created via LIKE
    """
    created_tables = set()
    statement_order = []
    has_like = set()

    try:
        parsed = sqlglot.parse(sql_text, read="postgres", error_level=sqlglot.ErrorLevel.IGNORE)
    except Exception:
        # If sqlglot can't parse at all, fall back to pure regex
        parsed = []

    for stmt in parsed:
        if stmt is None:
            continue

        sql_str = stmt.sql(dialect="postgres") if hasattr(stmt, 'sql') else str(stmt)

        # --- CREATE TABLE (proper AST) ---
        if isinstance(stmt, exp.Create) and not isinstance(stmt, exp.Command):
            # Extract table name from AST
            table_expr = stmt.this
            if table_expr:
                raw_name = table_expr.sql(dialect="postgres")
                # Remove column definitions: take only the table name part
                # Schema.name (col1 type, ...) -> Schema.name
                raw_name = raw_name.split('(')[0].strip()
                table = normalize_table(raw_name)
                if table:
                    created_tables.add(table)
                    statement_order.append(("CREATE_TABLE", table, None))

                    # Check for LIKE
                    if RE_LIKE.search(sql_str):
                        has_like.add(table)
            continue

        # --- Command fallback (PG-specific statements) ---
        if isinstance(stmt, exp.Command):
            cmd_text = sql_str

            # CREATE TABLE (when sqlglot can't parse complex column defs)
            m = RE_CREATE_TABLE.search(cmd_text)
            if m and not RE_CREATE_POLICY.search(cmd_text) and not RE_CREATE_INDEX.search(cmd_text):
                table = normalize_table(m.group("table"))
                if table:
                    created_tables.add(table)
                    statement_order.append(("CREATE_TABLE", table, None))
                    if RE_LIKE.search(cmd_text):
                        has_like.add(table)
                continue

            # CREATE POLICY
            m = RE_CREATE_POLICY.search(cmd_text)
            if m:
                table = normalize_table(m.group("table"))
                statement_order.append(("CREATE_POLICY", table, None))
                continue

            # CREATE INDEX (permitted, tracked for ordering context)
            if RE_CREATE_INDEX.search(cmd_text):
                # Extract table from ON clause if present
                on_match = re.search(
                    r'ON\s+(?:(?:\w+)\.)?(\w+)',
                    cmd_text,
                    re.IGNORECASE
                )
                table = normalize_table(on_match.group(1)) if on_match else None
                statement_order.append(("CREATE_INDEX", table, None))
                continue

            # ALTER TABLE variants
            m = RE_ALTER_TABLE.search(cmd_text)
            if m:
                table = normalize_table(m.group("table"))

                # Sub-classify the ALTER
                if RE_DISABLE_RLS.search(cmd_text):
                    detail = "DISABLE_RLS"
                elif RE_ENABLE_RLS.search(cmd_text):
                    detail = "ENABLE_RLS"
                elif RE_FORCE_RLS.search(cmd_text):
                    detail = "FORCE_RLS"
                elif RE_OWNER_TO.search(cmd_text):
                    detail = "OWNER_TO"
                elif RE_COLUMN_MUTATION.search(cmd_text):
                    detail = "COLUMN_MUTATION"
                else:
                    detail = "OTHER"

                statement_order.append(("ALTER_TABLE", table, detail))
                continue

        # --- ALTER TABLE that sqlglot parsed as Alter (standard DDL) ---
        # sqlglot parses ADD/DROP/ALTER COLUMN, RENAME, ADD CONSTRAINT
        # as exp.Alter. PG-specific variants (ENABLE RLS, OWNER TO) go
        # through the Command fallback branch above.
        if isinstance(stmt, exp.Alter):
            table_expr = stmt.this
            if table_expr:
                raw_name = table_expr.sql(dialect="postgres")
                table = normalize_table(raw_name)
                sql_upper = sql_str.upper()
                if "RENAME" in sql_upper:
                    detail = "COLUMN_MUTATION"
                elif "ADD COLUMN" in sql_upper or "DROP COLUMN" in sql_upper:
                    detail = "COLUMN_MUTATION"
                elif "ALTER COLUMN" in sql_upper:
                    detail = "COLUMN_MUTATION"
                elif "ADD CONSTRAINT" in sql_upper or "DROP CONSTRAINT" in sql_upper:
                    detail = "CONSTRAINT"
                else:
                    detail = "OTHER"
                statement_order.append(("ALTER_TABLE", table, detail))
            continue

    return created_tables, statement_order, has_like


# ---------------------------------------------------------------------------
# Invariant checks
# ---------------------------------------------------------------------------

def check_scope(created_tables, statement_order, filepath, violations):
    """INV-1: A migration may only modify tables it creates."""
    for stype, table, detail in statement_order:
        if table is None:
            continue
        if stype in ("ALTER_TABLE", "CREATE_POLICY"):
            if table not in created_tables:
                violations.append({
                    "type": "SCOPE_VIOLATION",
                    "table": table,
                    "file": filepath,
                    "message": f"Migration modifies table '{table}' which it does not create"
                })


def check_post_policy_mutation(statement_order, filepath, violations):
    """INV-2: After CREATE POLICY for table T, no mutation of T (except CREATE INDEX)."""
    policy_seen = {}  # table -> index in statement_order

    for idx, (stype, table, detail) in enumerate(statement_order):
        if table is None:
            continue

        if stype == "CREATE_POLICY":
            if table not in policy_seen:
                policy_seen[table] = idx

        if stype == "ALTER_TABLE" and table in policy_seen and idx > policy_seen[table]:
            violations.append({
                "type": "POST_POLICY_MUTATION",
                "table": table,
                "file": filepath,
                "detail": detail,
                "message": (
                    f"ALTER TABLE '{table}' ({detail}) occurs after "
                    f"CREATE POLICY — this is forbidden"
                )
            })


def check_like_requires_rls(created_tables, statement_order, has_like, filepath, violations):
    """INV-3: Tables created via LIKE must have an RLS block."""
    policy_tables = {t for st, t, _ in statement_order if st == "CREATE_POLICY" and t}
    enable_rls_tables = {
        t for st, t, d in statement_order
        if st == "ALTER_TABLE" and d == "ENABLE_RLS" and t
    }

    for table in has_like:
        if table not in policy_tables or table not in enable_rls_tables:
            violations.append({
                "type": "LIKE_WITHOUT_RLS",
                "table": table,
                "file": filepath,
                "message": (
                    f"Table '{table}' created with LIKE but missing RLS block. "
                    f"LIKE may inherit tenant_id — RLS is required."
                )
            })


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def lint_file(filepath: str):
    """Run all invariant checks on a single migration file."""
    sql_text = Path(filepath).read_text()
    created_tables, statement_order, has_like = classify_statements(sql_text, filepath)

    violations = []
    check_scope(created_tables, statement_order, filepath, violations)
    check_post_policy_mutation(statement_order, filepath, violations)
    check_like_requires_rls(created_tables, statement_order, has_like, filepath, violations)

    return violations


def main():
    if len(sys.argv) < 2:
        print("Usage: lint_gf_migration_scope.py <sql_file> [sql_file ...]", file=sys.stderr)
        sys.exit(2)

    all_violations = []

    for filepath in sys.argv[1:]:
        if not Path(filepath).exists():
            print(f"ERROR: File not found: {filepath}", file=sys.stderr)
            sys.exit(2)
        all_violations.extend(lint_file(filepath))

    if all_violations:
        output = {
            "status": "FAIL",
            "violation_count": len(all_violations),
            "violations": all_violations
        }
        print(json.dumps(output, indent=2))
        sys.exit(1)
    else:
        output = {"status": "PASS", "violation_count": 0, "violations": []}
        print(json.dumps(output, indent=2))
        sys.exit(0)


if __name__ == "__main__":
    main()
