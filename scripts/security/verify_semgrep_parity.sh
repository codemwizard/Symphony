#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

PARITY_FILE="security/semgrep/parity.yml"
RULES_FILE="security/semgrep/rules.yml"
TESTS_ROOT="security/semgrep/tests"
LANG_VERIFIER="scripts/audit/verify_semgrep_languages.sh"

hr() { echo "------------------------------------------------------------"; }
die() { echo "ERROR: $*" >&2; exit 1; }

[[ -f "$PARITY_FILE" ]] || die "Missing parity file: $PARITY_FILE"
[[ -f "$RULES_FILE"  ]] || die "Missing rules file:  $RULES_FILE"
[[ -f "$LANG_VERIFIER" ]] || die "Existing semgrep-language verifier not found at: $LANG_VERIFIER"

echo "==> Verifying Semgrep cross-language parity + fixtures + per-class triggering"
echo "PARITY: $PARITY_FILE"
echo "RULES:  $RULES_FILE"
echo "TESTS:  $TESTS_ROOT"
echo "LANG_VERIFIER: $LANG_VERIFIER"
hr

echo "==> Running existing language verifier"
bash "$LANG_VERIFIER"
hr

python3 - <<'PY'
import json
import subprocess
import sys
from pathlib import Path
import yaml  # type: ignore

PARITY = Path("security/semgrep/parity.yml")
RULES  = Path("security/semgrep/rules.yml")
TESTS_ROOT = Path("security/semgrep/tests")

LANGS = {
    "python": {"exts": [".py"]},
    "csharp": {"exts": [".cs"]},
}
REQ_FIELDS = ("csharp_rule_ids", "python_rule_ids")

def eprint(*a):
    print(*a, file=sys.stderr)

def load_yaml(p: Path):
    try:
        return yaml.safe_load(p.read_text(encoding="utf-8"))
    except Exception as ex:
        raise SystemExit(f"ERROR: Failed to parse YAML {p}: {ex}")

parity = load_yaml(PARITY)
rules  = load_yaml(RULES)

# ---- Collect rule IDs from rules.yml ----
rule_ids = set()

def collect_ids(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "id" and isinstance(v, str) and v.strip():
                rule_ids.add(v.strip())
            collect_ids(v)
    elif isinstance(node, list):
        for it in node:
            collect_ids(it)

if isinstance(rules, dict) and isinstance(rules.get("rules"), list):
    for r in rules["rules"]:
        if isinstance(r, dict) and isinstance(r.get("id"), str) and r["id"].strip():
            rule_ids.add(r["id"].strip())
        else:
            collect_ids(r)
else:
    collect_ids(rules)

if not rule_ids:
    raise SystemExit("ERROR: No Semgrep rule IDs found in security/semgrep/rules.yml")

# ---- Validate parity.yml structure ----
if not isinstance(parity, dict):
    raise SystemExit("ERROR: parity.yml must be a mapping/object")

version = parity.get("version")
if version != 1:
    raise SystemExit(f"ERROR: parity.yml version must be 1 (got {version!r})")

classes = parity.get("classes")
if not isinstance(classes, dict) or not classes:
    raise SystemExit("ERROR: parity.yml must contain non-empty 'classes' mapping")

errors = []
warnings = []
seen_in_parity = {}

def normalize_rule_list(val, path):
    if val is None:
        errors.append(f"{path} missing")
        return []
    if isinstance(val, str):
        val = [val]
    if not isinstance(val, list):
        errors.append(f"{path} must be a list of strings")
        return []
    out = []
    for i, x in enumerate(val):
        if not isinstance(x, str) or not x.strip():
            errors.append(f"{path}[{i}] must be a non-empty string")
            continue
        out.append(x.strip())
    return out

def find_test_files(d: Path, exts):
    if not d.exists() or not d.is_dir():
        return []
    files = []
    for ext in exts:
        files.extend(list(d.rglob(f"*{ext}")))
    return files

def run_semgrep(target_dir: Path) -> dict:
    cmd = ["semgrep", "--config", str(RULES), "--json", "--metrics", "off", str(target_dir)]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        raise SystemExit("ERROR: semgrep is not installed or not on PATH")
    if p.returncode not in (0, 1, 2):
        eprint(p.stdout)
        eprint(p.stderr)
        raise SystemExit(f"ERROR: semgrep failed with code {p.returncode} for {target_dir}")
    try:
        return json.loads(p.stdout or "{}")
    except Exception as ex:
        eprint("STDERR:", p.stderr)
        raise SystemExit(f"ERROR: Failed to parse semgrep JSON for {target_dir}: {ex}")

for cls_name, cls_def in classes.items():
    if not isinstance(cls_name, str) or not cls_name.strip():
        errors.append("classes keys must be non-empty strings")
        continue
    if not isinstance(cls_def, dict):
        errors.append(f"classes.{cls_name} must be a mapping/object")
        continue

    for f in REQ_FIELDS:
        if f not in cls_def:
            errors.append(f"classes.{cls_name} missing required field: {f}")

    csharp_ids = normalize_rule_list(cls_def.get("csharp_rule_ids"), f"classes.{cls_name}.csharp_rule_ids")
    python_ids = normalize_rule_list(cls_def.get("python_rule_ids"), f"classes.{cls_name}.python_rule_ids")

    if not csharp_ids:
        errors.append(f"classes.{cls_name}.csharp_rule_ids must be non-empty (parity requires coverage)")
    if not python_ids:
        errors.append(f"classes.{cls_name}.python_rule_ids must be non-empty (parity requires coverage)")

    for lang, ids in (("csharp", csharp_ids), ("python", python_ids)):
        for rid in ids:
            key = (lang, rid)
            if key in seen_in_parity:
                errors.append(
                    f"Duplicate rule ID in parity.yml: {rid} listed in both "
                    f"classes.{seen_in_parity[key]} and classes.{cls_name} for {lang}"
                )
            else:
                seen_in_parity[key] = cls_name

            if rid not in rule_ids:
                errors.append(
                    f"Unknown Semgrep rule ID in parity.yml: {rid} "
                    f"(listed in classes.{cls_name}.{lang}_rule_ids but not found in {RULES})"
                )

    for lang_key, expected_ids in (("python", set(python_ids)), ("csharp", set(csharp_ids))):
        dir_path = TESTS_ROOT / cls_name / lang_key
        test_files = find_test_files(dir_path, LANGS[lang_key]["exts"])
        if not test_files:
            errors.append(f"Missing fixtures: expected at least one {LANGS[lang_key]['exts']} file under {dir_path}")
            continue

        out = run_semgrep(dir_path)
        results = out.get("results", [])
        found_ids = {r.get("check_id") for r in results if isinstance(r, dict) and r.get("check_id")}

        triggered = sorted(found_ids & expected_ids)
        if not triggered:
            some = sorted(found_ids)[:8]
            errors.append(
                f"No expected rules triggered for class '{cls_name}' lang '{lang_key}' in {dir_path}. "
                f"Expected one of: {sorted(expected_ids)}. "
                f"Triggered check_ids (first 8): {some}"
            )

referenced_ids = {rid for (_, rid) in seen_in_parity.keys()}
unused_ids = sorted(rule_ids - referenced_ids)
if unused_ids:
    warnings.append(
        f"{len(unused_ids)} rule ID(s) exist in rules.yml but are not referenced in parity.yml. "
        f"Consider mapping them to a class: e.g. {', '.join(unused_ids[:8])}"
        + (" ..." if len(unused_ids) > 8 else "")
    )

if warnings:
    eprint("WARNINGS:")
    for w in warnings:
        eprint(f"  - {w}")
    eprint("")

if errors:
    eprint("PARITY/FIXTURE/TRIGGER CHECK FAILED:")
    for err in errors:
        eprint(f"  - {err}")
    raise SystemExit(1)

print("✅ Semgrep parity + fixtures + per-class triggering PASSED")
print(f"  Classes checked: {len(classes)}")
print(f"  Rule IDs in rules.yml: {len(rule_ids)}")
print(f"  Rule IDs referenced by parity.yml: {len(referenced_ids)}")
PY

hr
echo "Done."
