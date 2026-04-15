# GF-W1-UI-024-walkthrough_Extract_Programme_Health

## Changes Made
- Duplicated `index.html` to `programme-health.html` within `src/supervisory-dashboard/`.
- Modified `programme-health.html` by importing the required typography elements (`Inter` and `JetBrains Mono`) from `example.html` and altering the CSS definitions to enforce `.header` and `.kpi-ribbon` usage logic (using `Symphony-redesign.md` tokens).
- Adjusted tab links in `programme-health.html` to execute `window.location.href='index.html#...'` for seamlessly migrating between the external Programme Health tab and the internal `index.html` Monitoring Report SPA functionality.
- Removed all other tabs (`screen-report`, `screen-onboarding`, `screen-s6`) from the DOM in `programme-health.html`.
- Updated `index.html` to replace the "Programme Health" internal JS toggle with an external link out to the new `programme-health.html`, and stripped the obsolete `screen-main` logic to avoid double-loading.
- Implemented hash-routing in `index.html` so external link-backs from `programme-health.html` (e.g. via `#report`) instantly toggle the correct screen.

## What Was Tested
- Validation that the tab toggling syntax functions correctly using `<a href>` and `location.href`.
- Structural isolation: The `programmeHealth.html` file works as a standalone implementation of the dashboard fetch behavior without crashing due to missing divs.
- `index.html` falls back to the "Monitoring Report" on initial loads natively while properly delegating the operator user out directly back to Dashboard if they click "Programme Health".

## Validation Results
- The new Programme Health page renders with strict adherence to `100vh` boundaries, the `Inter` and `JetBrains` typesetting, and the correct `--bright`/`--amber` token mapping for data bounds.
