#!/usr/bin/env python3
"""
scripts/audit/verify_neutral_schema_ast.py

PURPOSE
-------
AST-based neutral schema verifier for Symphony Phase 0/1 migrations.
Extracts SQL identifiers and checks against sector vocabulary.

USAGE
------
python3 scripts/audit/verify_neutral_schema_ast.py [--fixtures] [--vocabulary FILE]
"""

import argparse
import ast
import json
import os
import re
import sys
import tokenize
from pathlib import Path
from typing import List, Set, Tuple, Dict, Any

# Sector noun vocabulary - will be loaded from YAML file
DEFAULT_VOCABULARY = {
    'plastic', 'plastics', 'credit', 'credits', 'collection', 'collections',
    'recycling', 'recyclables', 'waste', 'plastic_credit', 'plastic_credits',
    'solar', 'solar_energy', 'photovoltaic', 'pv', 'renewable', 'energy',
    'carbon', 'carbon_credit', 'carbon_credits', 'offset', 'offsets',
    'forestry', 'forest', 'tree', 'trees', 'timber', 'wood', 'biomass',
    'mining', 'mine', 'mineral', 'ore', 'extraction', 'quarry',
    'agriculture', 'farm', 'farming', 'crop', 'crops', 'soil', 'irrigation',
    'water', 'hydro', 'hydropower', 'dam', 'reservoir', 'treatment',
    'transport', 'transportation', 'shipping', 'logistics', 'freight',
    'manufacturing', 'factory', 'production', 'industrial', 'processing'
}

class SQLIdentifierExtractor(ast.NodeVisitor):
    """Extract SQL identifiers from Python AST nodes."""
    
    def __init__(self):
        self.identifiers: Set[str] = set()
        self.string_literals: List[Tuple[str, int]] = []  # (value, line)
    
    def visit_Str(self, node):
        """Visit string literals - likely contain SQL."""
        if hasattr(node, 'value'):
            self.string_literals.append((node.value, node.lineno))
        self.generic_visit(node)
    
    def visit_Constant(self, node):
        """Python 3.8+ constant nodes."""
        if isinstance(node.value, str):
            self.string_literals.append((node.value, node.lineno))
        self.generic_visit(node)

def extract_sql_identifiers(sql_text: str) -> Set[str]:
    """Extract identifiers from SQL text using regex patterns."""
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
        matches = re.findall(pattern, sql_text, re.IGNORECASE)
        for match in matches:
            if isinstance(match, tuple):
                identifiers.update(match)
            else:
                identifiers.add(match)
    
    return identifiers

def check_sector_violations(identifiers: Set[str], vocabulary: Set[str]) -> List[Dict[str, Any]]:
    """Check identifiers against sector vocabulary."""
    violations = []
    
    for identifier in identifiers:
        # Check for sector nouns (case-insensitive)
        identifier_lower = identifier.lower()
        for vocab_word in vocabulary:
            if vocab_word.lower() in identifier_lower:
                violations.append({
                    'identifier': identifier,
                    'sector_word': vocab_word,
                    'severity': 'error'
                })
                break
    
    return violations

def analyze_python_file(file_path: Path, vocabulary: Set[str]) -> List[Dict[str, Any]]:
    """Analyze a Python file for SQL content."""
    violations = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Parse Python AST
        tree = ast.parse(content, filename=str(file_path))
        extractor = SQLIdentifierExtractor()
        extractor.visit(tree)
        
        # Extract SQL identifiers from string literals
        all_identifiers = set()
        for sql_text, line_num in extractor.string_literals:
            sql_identifiers = extract_sql_identifiers(sql_text)
            all_identifiers.update(sql_identifiers)
        
        # Check for violations
        file_violations = check_sector_violations(all_identifiers, vocabulary)
        
        # Add file context
        for violation in file_violations:
            violation.update({
                'file': str(file_path),
                'line': line_num
            })
            violations.append(violation)
            
    except Exception as e:
        violations.append({
            'file': str(file_path),
            'error': str(e),
            'severity': 'error'
        })
    
    return violations

def analyze_sql_file(file_path: Path, vocabulary: Set[str]) -> List[Dict[str, Any]]:
    """Analyze a pure SQL file."""
    violations = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract identifiers
        identifiers = extract_sql_identifiers(content)
        
        # Check for violations
        file_violations = check_sector_violations(identifiers, vocabulary)
        
        # Add file context
        for violation in file_violations:
            violation.update({
                'file': str(file_path),
                'line': 0  # SQL files don't have line numbers in this simple parser
            })
            violations.append(violation)
            
    except Exception as e:
        violations.append({
            'file': str(file_path),
            'error': str(e),
            'severity': 'error'
        })
    
    return violations

def load_vocabulary(vocabulary_file: Path) -> Set[str]:
    """Load sector vocabulary from YAML file."""
    try:
        import yaml
        with open(vocabulary_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        vocabulary = set()
        if 'sector_nouns' in data:
            vocabulary.update(data['sector_nouns'])
        if 'allowed_structural_keys' in data:
            # These are allowed keys, not violations
            pass
        
        return vocabulary
        
    except Exception as e:
        print(f"Warning: Could not load vocabulary from {vocabulary_file}: {e}", file=sys.stderr)
        return DEFAULT_VOCABULARY

def run_fixtures() -> bool:
    """Run self-test fixtures."""
    fixtures_dir = Path(__file__).parent / "fixtures" / "ast"
    
    if not fixtures_dir.exists():
        print(f"Fixtures directory not found: {fixtures_dir}", file=sys.stderr)
        return False
    
    # Test bad SQL file
    bad_sql_file = fixtures_dir / "bad_quoted_table.sql"
    if bad_sql_file.exists():
        violations = analyze_sql_file(bad_sql_file, DEFAULT_VOCABULARY)
        if violations:
            print("✅ Fixture test passed: Detected sector noun violations")
            return True
        else:
            print("❌ Fixture test failed: Should have detected violations")
            return False
    
    print("⚠️  No fixtures found")
    return True

def main():
    parser = argparse.ArgumentParser(description="Verify neutral schema AST")
    parser.add_argument("--fixtures", action="store_true", help="Run self-test fixtures")
    parser.add_argument("--vocabulary", type=str, help="Path to sector vocabulary YAML file")
    parser.add_argument("paths", nargs="*", help="Files or directories to analyze")
    
    args = parser.parse_args()
    
    if args.fixtures:
        success = run_fixtures()
        sys.exit(0 if success else 1)
    
    # Load vocabulary
    vocabulary = DEFAULT_VOCABULARY
    if args.vocabulary:
        vocabulary_file = Path(args.vocabulary)
        if vocabulary_file.exists():
            vocabulary = load_vocabulary(vocabulary_file)
        else:
            print(f"Warning: Vocabulary file not found: {vocabulary_file}", file=sys.stderr)
    
    # Default paths if none provided
    if not args.paths:
        args.paths = ["schema/migrations"]
    
    all_violations = []
    
    for path_str in args.paths:
        path = Path(path_str)
        
        if path.is_file():
            if path.suffix == '.py':
                all_violations.extend(analyze_python_file(path, vocabulary))
            elif path.suffix in ['.sql', '.up.sql', '.down.sql']:
                all_violations.extend(analyze_sql_file(path, vocabulary))
        elif path.is_dir():
            # Recursively analyze relevant files
            for file_path in path.rglob('*'):
                if file_path.is_file() and file_path.suffix in ['.py', '.sql', '.up.sql', '.down.sql']:
                    if file_path.suffix == '.py':
                        all_violations.extend(analyze_python_file(file_path, vocabulary))
                    else:
                        all_violations.extend(analyze_sql_file(file_path, vocabulary))
    
    # Output results
    if all_violations:
        print("❌ Sector noun violations found:")
        for violation in all_violations:
            if 'error' in violation:
                print(f"  ERROR in {violation['file']}: {violation['error']}")
            else:
                print(f"  {violation['file']}:{violation.get('line', '?')} - "
                      f"Identifier '{violation['identifier']}' contains sector word '{violation['sector_word']}'")
        sys.exit(1)
    else:
        print("✅ No sector noun violations found")
        sys.exit(0)

if __name__ == "__main__":
    main()
