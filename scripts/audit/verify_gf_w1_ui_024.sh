#!/bin/bash
set -euo pipefail

# GF-W1-UI-024 Verification Script
# TSK-P1-240 Proof Enforcement: Script evaluates structural rules on DOM/JS to secure the Proof Graph.

echo "{"
echo "  \"task_id\": \"GF-W1-UI-024\","
echo "  \"git_sha\": \"$(git rev-parse HEAD 2>/dev/null || echo 'none')\","
echo "  \"timestamp_utc\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"checks\": ["

PH_PATH="src/supervisory-dashboard/programme-health.html"
ID_PATH="src/supervisory-dashboard/index.html"

# Verification 1: File Existence & Dependencies
if [ ! -f "$PH_PATH" ]; then
    echo "    {\"id\": \"gf_w1_ui_024_01\", \"status\": \"FAIL\", \"detail\": \"programme-health.html not found\"}"
    exit 1
else
    echo "    {\"id\": \"gf_w1_ui_024_01\", \"status\": \"PASS\", \"detail\": \"programme-health.html exists\"},"
fi

# Verification 2: Fonts applied
if grep -q "family=Inter" "$PH_PATH"; then
    echo "    {\"id\": \"gf_w1_ui_024_02\", \"status\": \"PASS\", \"detail\": \"Inter font applied\"},"
else
    echo "    {\"id\": \"gf_w1_ui_024_02\", \"status\": \"FAIL\", \"detail\": \"Inter font missing\"},"
    exit 1
fi

# Verification 3: index.html DOM lacks screen-main
if grep -q 'id="screen-main"' "$ID_PATH"; then
    echo "    {\"id\": \"gf_w1_ui_024_03\", \"status\": \"FAIL\", \"detail\": \"index.html still holds screen-main\"}"
    exit 1
else
    echo "    {\"id\": \"gf_w1_ui_024_03\", \"status\": \"PASS\", \"detail\": \"index.html decoupled from screen-main\"}"
fi

echo "  ],"
echo "  \"observed_paths\": [\"$PH_PATH\", \"$ID_PATH\"],"
echo "  \"observed_hashes\": {"
echo "    \"$PH_PATH\": \"$(sha256sum "$PH_PATH" | awk '{print $1}')\","
echo "    \"$ID_PATH\": \"$(sha256sum "$ID_PATH" | awk '{print $1}')\""
echo "  },"
echo "  \"command_outputs\": \"Validation successful.\","
echo "  \"execution_trace\": \"Executed standalone UI isolation checks.\","
echo "  \"status\": \"completed\""
echo "}"
