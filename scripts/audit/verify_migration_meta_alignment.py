#!/usr/bin/env python3
"""
scripts/audit/verify_migration_meta_alignment.py

PURPOSE
-------
Verify that migration .meta.yml files align with actual SQL migrations.
Ensures all declared identifiers actually exist and no undeclared identifiers are present.
"""

import argparse
import os
import re
import sys
import yaml
from pathlib import Path
from typing import List, Set, Dict, Any

def extract_sql_identifiers(sql_content: str) -> Set[str]:
    """Extract identifiers from SQL content."""
    identifiers = set()
    
    # SQL identifier patterns
    patterns = [
        r'CREATE\s+(?:TABLE|VIEW|INDEX|TYPE|FUNCTION)\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:["\']?)(\w+)',
        r'ALTER\s+TABLE\s+(?:["\']?)(\w+)\s+ADD\s+(?:COLUMN\s+)?(?:["\']?)(\w+)',
        r'CONSTRAINT\s+(?:["\']?)(\w+)',
        r'ENUM\s*\([^)]*\)',  # Extract enum values
        r'["\'](\w+)["\']',  # Quoted identifiers
        r'\b(\w+)\s*\(',  # Function names
        r'\b(\w+)\s*\.',  # Table.column references
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, sql_content, re.IGNORECASE)
        for match in matches:
            if isinstance(match, tuple):
                identifiers.update(match)
            else:
                identifiers.add(match)
    
    return identifiers

def load_meta_file(meta_path: Path) -> Dict[str, Any]:
    """Load and validate meta.yml file."""
    try:
        with open(meta_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        return {
            'error': f"Could not load {meta_path}: {e}",
            'file': str(meta_path)
        }

def check_meta_alignment(meta_path: Path, sql_path: Path) -> List[Dict[str, Any]]:
    """Check alignment between meta.yml and corresponding SQL file."""
    violations = []
    
    # Load meta file
    meta_data = load_meta_file(meta_path)
    if 'error' in meta_data:
        violations.append(meta_data)
        return violations
    
    # Check SQL file exists
    if not sql_path.exists():
        violations.append({
            'file': str(meta_path),
            'error': f"SQL file not found: {sql_path}",
            'severity': 'error'
        })
        return violations
    
    # Extract identifiers from meta file
    declared_identifiers = set(meta_data.get('introduces_identifiers', []))
    
    # Extract identifiers from SQL file
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    actual_identifiers = extract_sql_identifiers(sql_content)
    
    # Check for missing identifiers (declared but not in SQL)
    missing_identifiers = declared_identifiers - actual_identifiers
    for identifier in missing_identifiers:
        violations.append({
            'file': str(meta_path),
            'error': f"Declared identifier '{identifier}' not found in SQL",
            'severity': 'error',
            'missing_identifier': identifier
        })
    
    # Check for undeclared identifiers (in SQL but not declared)
    undeclared_identifiers = actual_identifiers - declared_identifiers
    for identifier in undeclared_identifiers:
        violations.append({
            'file': str(meta_path),
            'error': f"SQL identifier '{identifier}' not declared in meta.yml",
            'severity': 'warning',
            'undeclared_identifier': identifier
        })
    
    # Special check: if touches_core_schema is true, require second_pilot_justification
    if meta_data.get('touches_core_schema', False) and not meta_data.get('second_pilot_justification_required', False):
        if 'second_pilot_test' not in meta_data.get('second_pilot_test', {}):
            violations.append({
                'file': str(meta_path),
                'error': "Core schema touch requires second_pilot_justification_required=true or second_pilot_test justification",
                'severity': 'error'
            })
    
    return violations

def find_migration_pairs(directory: Path) -> List[tuple]:
    """Find matching .meta.yml and .sql file pairs."""
    pairs = []
    
    # Find all meta files
    for meta_file in directory.glob('*.meta.yml'):
        # Extract migration number from filename
        match = re.match(r'(\d{4})_(.+)\.meta\.yml', meta_file.name)
        if not match:
            continue
        
        migration_num = match.group(1)
        migration_name = match.group(2)
        
        # Look for corresponding SQL file
        sql_pattern = f"{migration_num}_{migration_name}.sql"
        sql_file = directory / sql_pattern
        
        if sql_file.exists():
            pairs.append((meta_file, sql_file))
        else:
            # Try common variations
            for suffix in ['.up.sql', '.down.sql', '_up.sql', '_down.sql']:
                sql_variant = directory / f"{migration_num}_{migration_name}{suffix}"
                if sql_variant.exists():
                    pairs.append((meta_file, sql_variant))
                    break
    
    return pairs

def main():
    parser = argparse.ArgumentParser(description="Verify migration meta alignment")
    parser.add_argument("directory", nargs="?", default="schema/migrations", help="Directory containing migrations")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    migrations_dir = Path(args.directory)
    if not migrations_dir.exists():
        print(f"Error: Directory not found: {migrations_dir}", file=sys.stderr)
        sys.exit(1)
    
    all_violations = []
    migration_pairs = find_migration_pairs(migrations_dir)
    
    for meta_file, sql_file in migration_pairs:
        violations = check_meta_alignment(meta_file, sql_file)
        all_violations.extend(violations)
    
    # Output results
    if all_violations:
        print("❌ Migration meta alignment violations found:")
        for violation in all_violations:
            if args.verbose:
                print(f"  {violation['file']}: {violation['error']}")
            else:
                if violation['severity'] == 'error':
                    print(f"  ERROR in {violation['file']}: {violation['error']}")
                else:
                    print(f"  WARNING in {violation['file']}: {violation['error']}")
        sys.exit(1)
    else:
        print("✅ All migration meta files are properly aligned")
        sys.exit(0)

if __name__ == "__main__":
    main()
