Implementation proposal: CI diagnostics for structural-change failures

Goal
- Print precise, audit-grade evidence (changed files + structural matches) into workflow logs when structural changes are detected.

Scope
- Workflow: `.github/workflows/invariants.yml`
- Optional script enhancement: `scripts/audit/enforce_change_rule.sh` (if you approve)

Plan
1) Add two diagnostic steps immediately after the detector step (and before the change rule gate):
   - “Show changed files (diagnostic)”: prints diff range and `git diff --name-only "$RANGE"`.
   - “Show structural detection evidence (diagnostic)”: prints `detect.json` and a summarized list of matches.
2) Guard the diagnostics with the same `if:` condition as the gate (non-schedule, structural_change == true) so logs are concise.
3) (Optional) Add GitHub Actions annotations for top matches if we can surface line numbers; otherwise print file + diff line only.

Notes
- No policy changes; only logging to improve accountability.
- Uses existing artifacts: `/tmp/invariants_ai/pr.diff` and `/tmp/invariants_ai/detect.json`.

If approved, I will implement steps 1–2 in `.github/workflows/invariants.yml`. For step 3, I’ll ask again once we confirm whether line numbers are available in `detect.json`.
