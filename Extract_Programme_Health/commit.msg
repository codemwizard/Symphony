Extract_Programme_Health

# GF-W1-UI-024-task_Extract_Programme_Health

- `[x]` Task 1: Create `programme-health.html`
  - `[x]` Scaffold HTML using `example.html` typesetting (Inter, JetBrains Mono, structural CSS).
  - `[x]` Integrate `Symphony-redesign.md` token system for strictly controlled status colors (`--bright`, `--amber`, `--red`).
  - `[x]` Transplant the complete "Programme Health" markup (TopBar, Navigation, KPI Row, Activity Table, and Drill-down Slideout) from `index.html`.
  - `[x]` Port over formatting functions, Haversine calc, and data fetching functions specific to reveal (`initDashboard()`).
- `[x]` Task 2: Modify `index.html`
  - `[x]` Remove the `<div id="screen-main">` section corresponding to Programme Health.
  - `[x]` Change the "Programme Health" tab logic to use `href="programme-health.html"` rather than `onclick="switchTab(this)"`.
  - `[x]` Remove JS logic exclusively tied to the old tab (like Timeline population). Keep logic for Monitoring / Onboarding intact.
- `[x]` Task 3: Setup Navigation
  - `[x]` Ensure links in `programme-health.html` for "Monitoring Report" and "Onboarding" point back to `index.html` (e.g. `index.html#report`).
  - `[x]` Ensure operator session is properly instantiated on page load in `programme-health.html`.
- `[/]` Task 4: Store Documents in Phase Directory
  - `[ ]` Create directory `Extract_Programme_Health`.
  - `[ ]` Save `GF-W1-UI-024-implementation_plan_Extract_Programme_Health.md`.
  - `[ ]` Save `GF-W1-UI-024-task_Extract_Programme_Health.md`.
  - `[ ]` Save `GF-W1-UI-024-walkthrough_Extract_Programme_Health.md`.

## Unit Tests / Verification
- [x] Manual test: Open `programme-health.html` and verify the CSS / data fetch.
- [x] Navigate to `index.html#report` and ensure back+forth tab switching behaves like SPA / Navigation hybrid perfectly.
- [ ] Run E2E script `verify_ui_e2e.sh` if applicable.
