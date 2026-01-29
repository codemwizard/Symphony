import json
import subprocess
import sys
import tempfile
import textwrap
import unittest
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # scripts/audit
DETECTOR = ROOT / "detect_structural_changes.py"
EXCEPTION_GEN = ROOT / "auto_create_exception_from_detect.py"


def run_detector(diff_text: str):
    diff_text = textwrap.dedent(diff_text)
    with tempfile.NamedTemporaryFile("w+", delete=False) as tf:
        tf.write(diff_text)
        tf.flush()
        with tempfile.NamedTemporaryFile("w+", delete=False) as out:
            out_path = out.name
        subprocess.check_call([sys.executable, str(DETECTOR), "--diff-file", tf.name, "--out", out_path])
        return json.loads(Path(out_path).read_text())


class TestDetectStructuralChanges(unittest.TestCase):
    def test_detects_security_and_reason_metadata(self):
        diff = """
        diff --git a/schema/migrations/0001_init.sql b/schema/migrations/0001_init.sql
        +++ b/schema/migrations/0001_init.sql
        @@ -1 +1 @@
        +GRANT SELECT ON users TO app_read;
        """
        data = run_detector(diff)
        self.assertTrue(data["structural_change"])
        self.assertIn("security", data["reason_types"])
        self.assertEqual(data["primary_reason"], "security")
        self.assertTrue(data["matched_files"])
        self.assertGreaterEqual(data["match_counts"]["security"], 1)

    def test_docs_keyword_is_not_structural(self):
        diff = """
        diff --git a/docs/notes.md b/docs/notes.md
        +++ b/docs/notes.md
        @@ -1 +1 @@
        +GRANT SELECT ON users TO app_read;
        """
        data = run_detector(diff)
        self.assertFalse(data["structural_change"])
        self.assertEqual(data["reason_types"], [])
        self.assertEqual(data["primary_reason"], "other")
        self.assertEqual(data["matched_files"], [])
        self.assertEqual(data["match_counts"], {})

    def test_non_structural_has_default_metadata(self):
        diff = """
        diff --git a/README.md b/README.md
        +++ b/README.md
        @@ -1 +1 @@
        -hello
        +hello world
        """
        data = run_detector(diff)
        self.assertFalse(data["structural_change"])
        self.assertEqual(data["reason_types"], [])
        self.assertEqual(data["primary_reason"], "other")
        self.assertEqual(data["matched_files"], [])
        self.assertEqual(data["match_counts"], {})

    def test_auto_exception_generator_uses_primary_reason(self):
        detect = {
            "structural_change": True,
            "confidence_hint": 0.9,
            "primary_reason": "security",
            "reason_types": ["security"],
            "matched_files": ["docs/notes.md"],
            "matches": [
                {
                    "type": "security",
                    "file": "docs/notes.md",
                    "sign": "+",
                    "line": "GRANT SELECT ON users TO app_read;",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            detect_path = tmp_path / "detect.json"
            detect_path.write_text(json.dumps(detect), encoding="utf-8")

            result = subprocess.check_output(
                [sys.executable, str(EXCEPTION_GEN), "--detect", str(detect_path), "--inv-scope", "change-rule"],
                cwd=tmp_path,
                text=True,
            ).strip()

            created = tmp_path / result
            self.assertTrue(created.exists())

            today = date.today().isoformat()
            self.assertIn(f"exception_change-rule_security_{today}", created.name)

            content = created.read_text(encoding="utf-8")
            self.assertIn("# Exception: security structural change without invariants linkage", content)
            self.assertIn("Matched files:", content)
            self.assertIn("docs/notes.md", content)


if __name__ == "__main__":
    unittest.main()
