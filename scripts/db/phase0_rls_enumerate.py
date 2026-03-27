#!/usr/bin/env python3
"""
Phase 0: RLS Table Configuration Enumerator
TSK-RLS-ARCH-001 v10.1

Reads schema/rls_tables.yml → populates _rls_table_config → runs hard validation.
Generates 0095_pre_snapshot.sql for rollback.
Populates _preserved_policies for structural preservation.

Usage:
    DATABASE_URL="..." python3 scripts/db/phase0_rls_enumerate.py
"""

import json
import os
import sys
from pathlib import Path

import yaml

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("FATAL: psycopg2 not installed. Install with: pip install psycopg2-binary")
    sys.exit(1)


YAML_PATH = Path(__file__).resolve().parents[2] / "schema" / "rls_tables.yml"
SNAPSHOT_PATH = Path(__file__).resolve().parents[2] / "schema" / "migrations" / "0095_pre_snapshot.sql"


def load_yaml_registry():
    """Load and validate rls_tables.yml"""
    if not YAML_PATH.exists():
        print(f"FATAL: {YAML_PATH} not found")
        sys.exit(1)

    with open(YAML_PATH) as f:
        data = yaml.safe_load(f)

    tables = data.get("tables", [])
    if not tables:
        print("FATAL: No tables defined in rls_tables.yml")
        sys.exit(1)

    # Basic schema validation
    for t in tables:
        if "name" not in t or "type" not in t:
            print(f"FATAL: Table entry missing 'name' or 'type': {t}")
            sys.exit(1)
        if t["type"] not in ("DIRECT", "JOIN", "GLOBAL", "JURISDICTION"):
            print(f"FATAL: Invalid type '{t['type']}' for table '{t['name']}'")
            sys.exit(1)
        if t["type"] == "DIRECT" and "tenant_column" not in t:
            print(f"FATAL: DIRECT table '{t['name']}' missing 'tenant_column'")
            sys.exit(1)
        if t["type"] == "JOIN":
            for field in ("parent", "fk_column", "parent_pk"):
                if field not in t:
                    print(f"FATAL: JOIN table '{t['name']}' missing '{field}'")
                    sys.exit(1)
        if t["type"] == "GLOBAL" and "reason" not in t:
            print(f"FATAL: GLOBAL table '{t['name']}' missing 'reason'")
            sys.exit(1)

    return tables


def get_db_connection():
    """Get database connection from DATABASE_URL"""
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        print("FATAL: DATABASE_URL environment variable not set")
        sys.exit(1)
    return psycopg2.connect(db_url)


def create_infrastructure_tables(cur):
    """Create infrastructure tables if they don't exist"""
    cur.execute("""
        CREATE TABLE IF NOT EXISTS public._rls_table_config (
            table_name TEXT PRIMARY KEY,
            isolation_type TEXT NOT NULL CHECK (isolation_type IN ('DIRECT', 'JOIN', 'GLOBAL', 'JURISDICTION')),
            tenant_column TEXT,
            parent_table TEXT,
            fk_column TEXT,
            parent_pk TEXT,
            loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        CREATE TABLE IF NOT EXISTS public._preserved_policies (
            table_name TEXT NOT NULL,
            policy_name TEXT NOT NULL,
            permissive BOOLEAN NOT NULL,
            cmd TEXT NOT NULL,
            roles TEXT NOT NULL,
            qual_expr TEXT,
            wc_expr TEXT,
            create_sql TEXT NOT NULL,
            PRIMARY KEY (table_name, policy_name)
        );

        CREATE TABLE IF NOT EXISTS public._migration_guards (
            key TEXT PRIMARY KEY,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            skip_guard BOOLEAN NOT NULL DEFAULT false,
            force_override BOOLEAN NOT NULL DEFAULT false
        );

        CREATE TABLE IF NOT EXISTS public._migration_fingerprints (
            migration_key TEXT NOT NULL,
            fingerprint_type TEXT NOT NULL,
            fingerprint_hash TEXT NOT NULL,
            captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            PRIMARY KEY (migration_key, fingerprint_type)
        );

        CREATE TABLE IF NOT EXISTS public._migration_fn_hashes (
            migration_key TEXT NOT NULL,
            function_name TEXT NOT NULL,
            definition_hash TEXT NOT NULL,
            captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            PRIMARY KEY (migration_key, function_name)
        );
    """)


def populate_config(cur, tables):
    """Populate _rls_table_config from YAML"""
    cur.execute("DELETE FROM public._rls_table_config;")

    for t in tables:
        cur.execute("""
            INSERT INTO public._rls_table_config
                (table_name, isolation_type, tenant_column, parent_table, fk_column, parent_pk)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (table_name) DO UPDATE SET
                isolation_type = EXCLUDED.isolation_type,
                tenant_column = EXCLUDED.tenant_column,
                parent_table = EXCLUDED.parent_table,
                fk_column = EXCLUDED.fk_column,
                parent_pk = EXCLUDED.parent_pk,
                loaded_at = now();
        """, (
            t["name"],
            t["type"],
            t.get("tenant_column"),
            t.get("parent"),
            t.get("fk_column"),
            t.get("parent_pk"),
        ))

    count = cur.rowcount
    print(f"  Loaded {len(tables)} tables into _rls_table_config")


def run_hard_validation(cur, tables):
    """Run all Phase 0 hard validation checks"""
    failures = []

    # 1. FK must exist for JOIN tables
    cur.execute("""
        SELECT c.table_name FROM _rls_table_config c
        WHERE c.isolation_type = 'JOIN'
          AND NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
              ON tc.constraint_name = kcu.constraint_name
              AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
              ON tc.constraint_name = ccu.constraint_name
              AND tc.table_schema = ccu.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
              AND tc.table_schema = 'public'
              AND tc.table_name = c.table_name
              AND kcu.column_name = c.fk_column
              AND ccu.table_name = c.parent_table
          );
    """)
    for row in cur.fetchall():
        failures.append(f"FK missing: JOIN table '{row[0]}' has no FK to declared parent")

    # 2. FK column must be NOT NULL
    cur.execute("""
        SELECT c.table_name, c.fk_column FROM _rls_table_config c
        WHERE c.isolation_type = 'JOIN'
          AND EXISTS (
            SELECT 1 FROM information_schema.columns col
            WHERE col.table_schema = 'public'
              AND col.table_name = c.table_name
              AND col.column_name = c.fk_column
              AND col.is_nullable = 'YES'
          );
    """)
    for row in cur.fetchall():
        failures.append(f"Nullable FK: JOIN table '{row[0]}' column '{row[1]}' is nullable — isolation bypass risk")

    # 3. FK must be NOT DEFERRABLE
    cur.execute("""
        SELECT c.table_name, tc.constraint_name FROM _rls_table_config c
        JOIN information_schema.table_constraints tc
          ON tc.table_name = c.table_name
          AND tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public'
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
          AND kcu.column_name = c.fk_column
        WHERE c.isolation_type = 'JOIN'
          AND tc.is_deferrable = 'YES';
    """)
    for row in cur.fetchall():
        failures.append(f"Deferrable FK: JOIN table '{row[0]}' constraint '{row[1]}' is deferrable — consistency window")

    # 4. Parent must be DIRECT
    cur.execute("""
        SELECT c.table_name, c.parent_table FROM _rls_table_config c
        WHERE c.isolation_type = 'JOIN'
          AND c.parent_table NOT IN (
            SELECT table_name FROM _rls_table_config WHERE isolation_type = 'DIRECT'
          );
    """)
    for row in cur.fetchall():
        failures.append(f"Parent not DIRECT: JOIN table '{row[0]}' parent '{row[1]}' is not type DIRECT")

    # 5. Parent must have tenant_column
    cur.execute("""
        SELECT c.table_name, c.parent_table FROM _rls_table_config c
        WHERE c.isolation_type = 'JOIN'
          AND NOT EXISTS (
            SELECT 1 FROM information_schema.columns col
            WHERE col.table_schema = 'public'
              AND col.table_name = c.parent_table
              AND col.column_name = (
                SELECT p.tenant_column FROM _rls_table_config p
                WHERE p.table_name = c.parent_table
              )
          );
    """)
    for row in cur.fetchall():
        failures.append(f"Parent tenant column missing: JOIN table '{row[0]}' parent '{row[1]}'")

    # 6. Partition check (must return 0)
    cur.execute("""
        SELECT relname FROM pg_class
        WHERE relkind = 'p'
          AND relnamespace = 'public'::regnamespace
          AND relname IN (
            SELECT table_name FROM _rls_table_config
            WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          );
    """)
    for row in cur.fetchall():
        failures.append(f"Partitioned table: '{row[0]}' is partitioned — needs special handling")

    # 7. Inheritance check
    cur.execute("""
        SELECT c.relname FROM pg_inherits i
        JOIN pg_class c ON c.oid = i.inhrelid
        WHERE c.relnamespace = 'public'::regnamespace
          AND c.relname IN (
            SELECT table_name FROM _rls_table_config
            WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          );
    """)
    for row in cur.fetchall():
        failures.append(f"Inherited table: '{row[0]}' uses inheritance — needs special handling")

    # 8. Coverage check: tables with tenant_id not in config
    cur.execute("""
        SELECT c.relname FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind = 'r'
          AND c.relname NOT LIKE '\\_%%'
          AND EXISTS (
            SELECT 1 FROM pg_attribute a
            WHERE a.attrelid = c.oid
              AND a.attname = 'tenant_id'
              AND NOT a.attisdropped
          )
          AND c.relname NOT IN (SELECT table_name FROM _rls_table_config);
    """)
    for row in cur.fetchall():
        failures.append(f"COVERAGE GAP: table '{row[0]}' has tenant_id but is not in rls_tables.yml")

    return failures


def capture_preserved_policies(cur):
    """Capture non-isolation policies for structural preservation"""
    # Get all existing policies on target tables
    cur.execute("""
        SELECT c.relname, p.polname, p.polpermissive,
               CASE p.polcmd
                 WHEN 'r' THEN 'SELECT'
                 WHEN 'a' THEN 'INSERT'
                 WHEN 'w' THEN 'UPDATE'
                 WHEN 'd' THEN 'DELETE'
                 WHEN '*' THEN 'ALL'
               END as cmd,
               pg_get_expr(p.polqual, p.polrelid) as qual,
               pg_get_expr(p.polwithcheck, p.polrelid) as wc,
               array_to_string(ARRAY(
                 SELECT rolname FROM pg_roles
                 WHERE oid = ANY(p.polroles)
               ), ',') as roles
        FROM pg_policy p
        JOIN pg_class c ON c.oid = p.polrelid
        WHERE c.relnamespace = 'public'::regnamespace
          AND c.relname IN (
            SELECT table_name FROM _rls_table_config
            WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          );
    """)

    policies = cur.fetchall()
    preserved_count = 0

    cur.execute("DELETE FROM public._preserved_policies;")

    for pol in policies:
        table_name, pol_name, permissive, cmd, qual, wc, roles = pol

        # Isolation policies (generated by 0059 or GF migrations) — NOT preserved
        is_isolation = (
            pol_name.startswith("rls_tenant_isolation_") or
            pol_name.startswith("rls_iso_") or
            pol_name.startswith("rls_base_")
        )

        if not is_isolation:
            # Non-isolation policy — preserve structurally
            perm_str = "PERMISSIVE" if permissive else "RESTRICTIVE"
            roles_str = roles if roles else "PUBLIC"

            using_clause = f" USING ({qual})" if qual else ""
            wc_clause = f" WITH CHECK ({wc})" if wc else ""

            create_sql = (
                f"CREATE POLICY {pol_name} ON public.{table_name} "
                f"AS {perm_str} FOR {cmd} TO {roles_str}"
                f"{using_clause}{wc_clause};"
            )

            cur.execute("""
                INSERT INTO public._preserved_policies
                    (table_name, policy_name, permissive, cmd, roles, qual_expr, wc_expr, create_sql)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (table_name, policy_name) DO UPDATE SET
                    create_sql = EXCLUDED.create_sql;
            """, (table_name, pol_name, permissive, cmd, roles_str, qual, wc, create_sql))
            preserved_count += 1

    return preserved_count, len(policies)


def generate_snapshot(cur):
    """Generate 0095_pre_snapshot.sql for rollback"""
    cur.execute("""
        SELECT c.relname, p.polname, p.polpermissive,
               CASE p.polcmd
                 WHEN 'r' THEN 'SELECT'
                 WHEN 'a' THEN 'INSERT'
                 WHEN 'w' THEN 'UPDATE'
                 WHEN 'd' THEN 'DELETE'
                 WHEN '*' THEN 'ALL'
               END as cmd,
               pg_get_expr(p.polqual, p.polrelid) as qual,
               pg_get_expr(p.polwithcheck, p.polrelid) as wc,
               array_to_string(ARRAY(
                 SELECT rolname FROM pg_roles
                 WHERE oid = ANY(p.polroles)
               ), ',') as roles
        FROM pg_policy p
        JOIN pg_class c ON c.oid = p.polrelid
        WHERE c.relnamespace = 'public'::regnamespace
          AND c.relname IN (
            SELECT table_name FROM _rls_table_config
            WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          )
        ORDER BY c.relname, p.polname;
    """)

    policies = cur.fetchall()

    with open(SNAPSHOT_PATH, "w") as f:
        f.write("-- RLS Pre-Migration Snapshot (auto-generated by phase0_rls_enumerate.py)\n")
        f.write("-- Purpose: audit + rollback ONLY. NOT a correctness validator.\n")
        f.write(f"-- Generated: {os.popen('date -u +%FT%TZ').read().strip()}\n")
        f.write(f"-- Policies captured: {len(policies)}\n\n")

        f.write("BEGIN;\n\n")

        for pol in policies:
            table_name, pol_name, permissive, cmd, qual, wc, roles = pol
            perm_str = "PERMISSIVE" if permissive else "RESTRICTIVE"
            roles_str = roles if roles else "PUBLIC"

            using_clause = f"\n    USING ({qual})" if qual else ""
            wc_clause = f"\n    WITH CHECK ({wc})" if wc else ""

            f.write(f"CREATE POLICY {pol_name} ON public.{table_name}\n")
            f.write(f"    AS {perm_str} FOR {cmd} TO {roles_str}")
            f.write(f"{using_clause}{wc_clause};\n\n")

        f.write("COMMIT;\n")

    print(f"  Snapshot written to {SNAPSHOT_PATH} ({len(policies)} policies)")


def store_fingerprint(cur):
    """Store pre-migration fingerprint (audit only, never blocks)"""
    cur.execute("""
        INSERT INTO _migration_fingerprints (migration_key, fingerprint_type, fingerprint_hash)
        VALUES ('0095_rls_dual_policy', 'pre_migration',
          (SELECT md5(string_agg(
            format('%%s:%%s:%%s:%%s',
              c.relname, p.polpermissive, p.polcmd,
              coalesce(pg_get_expr(p.polqual, p.polrelid), '')),
            '|' ORDER BY c.relname, p.polname
          )) FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
          WHERE c.relnamespace = 'public'::regnamespace
            AND c.relname IN (
              SELECT table_name FROM _rls_table_config
              WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
            ))
        )
        ON CONFLICT (migration_key, fingerprint_type) DO UPDATE
          SET fingerprint_hash = EXCLUDED.fingerprint_hash,
              captured_at = now();
    """)


def store_function_hash(cur):
    """Store function definition hash (advisory, not blocking)"""
    cur.execute("""
        SELECT p.oid FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'current_tenant_id_or_null';
    """)
    row = cur.fetchone()
    if row:
        cur.execute("""
            INSERT INTO _migration_fn_hashes (migration_key, function_name, definition_hash)
            VALUES ('0095_rls_dual_policy', 'current_tenant_id_or_null',
              md5(pg_get_functiondef(%s::oid))
            )
            ON CONFLICT (migration_key, function_name) DO UPDATE
              SET definition_hash = EXCLUDED.definition_hash,
                  captured_at = now();
        """, (row[0],))
        print("  Function hash stored for current_tenant_id_or_null()")
    else:
        print("  WARNING: current_tenant_id_or_null() not found — skipping fn hash")


def get_traffic_tiers(cur):
    """Classify tables by write volume for lock ordering"""
    cur.execute("""
        SELECT relname,
          n_tup_ins + n_tup_upd + n_tup_del AS write_volume
        FROM pg_stat_user_tables
        WHERE schemaname = 'public'
          AND relname IN (
            SELECT table_name FROM _rls_table_config
            WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          )
        ORDER BY write_volume DESC;
    """)
    tiers = cur.fetchall()
    if tiers:
        print("\n  Traffic tiers (for lock ordering):")
        for name, vol in tiers:
            tier = "HIGH" if vol > 10000 else ("MEDIUM" if vol > 100 else "LOW")
            print(f"    {name}: {vol} writes ({tier})")
    return tiers


def main():
    print("=" * 70)
    print("Phase 0: RLS Table Configuration Enumerator")
    print("TSK-RLS-ARCH-001 v10.1")
    print("=" * 70)

    # Step 1: Load YAML
    print("\n[1/7] Loading rls_tables.yml...")
    all_tables = load_yaml_registry()

    # Filter out tables that don't exist yet (exists: false)
    tables = [t for t in all_tables if t.get("exists", True) is not False]
    future_tables = [t for t in all_tables if t.get("exists", True) is False]

    direct = [t for t in tables if t["type"] == "DIRECT"]
    join = [t for t in tables if t["type"] == "JOIN"]
    glob = [t for t in tables if t["type"] == "GLOBAL"]
    juris = [t for t in tables if t["type"] == "JURISDICTION"]
    print(f"  Found: {len(direct)} DIRECT, {len(join)} JOIN, {len(glob)} GLOBAL, {len(juris)} JURISDICTION")
    if future_tables:
        print(f"  Skipped: {len(future_tables)} tables marked exists: false (unapplied migrations)")

    # Step 2: Connect to DB
    print("\n[2/7] Connecting to database...")
    conn = get_db_connection()
    conn.autocommit = False
    cur = conn.cursor()

    try:
        # Step 3: Create infrastructure + populate
        print("\n[3/7] Creating infrastructure tables and populating config...")
        create_infrastructure_tables(cur)
        populate_config(cur, tables)

        # Step 4: Hard validation
        print("\n[4/7] Running hard validation...")
        failures = run_hard_validation(cur, tables)
        if failures:
            print("\n  ❌ VALIDATION FAILURES:")
            for f in failures:
                print(f"    - {f}")
            conn.rollback()
            print("\n  ABORTED. Fix validation failures and re-run.")
            sys.exit(1)
        else:
            print("  ✅ All validation checks passed")

        # Step 5: Capture preserved policies
        print("\n[5/7] Capturing preserved policies (structural snapshot)...")
        preserved, total = capture_preserved_policies(cur)
        print(f"  {preserved} non-isolation policies preserved out of {total} total")

        # Step 6: Generate snapshot + fingerprint
        print("\n[6/7] Generating pre-migration snapshot and storing fingerprint...")
        generate_snapshot(cur)
        store_fingerprint(cur)
        store_function_hash(cur)

        # Step 7: Traffic tiers
        print("\n[7/7] Classifying traffic tiers...")
        get_traffic_tiers(cur)

        # Commit
        conn.commit()

        print("\n" + "=" * 70)
        print("Phase 0 COMPLETE")
        print(f"  Config: {len(tables)} tables in _rls_table_config")
        print(f"  Preserved: {preserved} non-isolation policies")
        print(f"  Snapshot: {SNAPSHOT_PATH}")
        print("  Ready for Phase 1 migration")
        print("=" * 70)

    except Exception as e:
        conn.rollback()
        print(f"\n  FATAL: {e}")
        sys.exit(1)
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
