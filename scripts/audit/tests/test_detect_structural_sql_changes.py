import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # scripts/audit
DETECTOR = ROOT / "detect_structural_sql_changes.py"

def run_detector(diff_text: str):
    with tempfile.NamedTemporaryFile("w+", delete=False) as tf:
        tf.write(diff_text)
        tf.flush()
        with tempfile.NamedTemporaryFile("w+", delete=False) as out:
            out_path = out.name
        subprocess.check_call([sys.executable, str(DETECTOR), "--diff-file", tf.name, "--out", out_path])
        return json.loads(Path(out_path).read_text())

def test_detects_create_table():
    diff = """
diff --git a/schema/migrations/0001_init.sql b/schema/migrations/0001_init.sql
+++ b/schema/migrations/0001_init.sql
@@ -0,0 +1,3 @@
+CREATE TABLE users (id bigserial primary key);
"""
    data = run_detector(diff)
    assert data["structural_change"] is True
    assert data["matches"]

def test_ignores_non_sql_changes():
    diff = """
diff --git a/README.md b/README.md
+++ b/README.md
@@ -1 +1 @@
-hello
+hello world
"""
    data = run_detector(diff)
    assert data["structural_change"] is False

def test_detects_add_constraint():
    diff = """
diff --git a/schema/migrations/0002.sql b/schema/migrations/0002.sql
+++ b/schema/migrations/0002.sql
@@ -1 +1 @@
+ALTER TABLE t ADD CONSTRAINT c CHECK (x > 0);
"""
    data = run_detector(diff)
    assert data["structural_change"] is True
