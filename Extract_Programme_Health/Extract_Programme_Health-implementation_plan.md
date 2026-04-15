# Goal Description

Extract the "Programme Health" tab from `src/supervisory-dashboard/index.html` into a new standalone page `src/supervisory-dashboard/programme-health.html` with page navigation. Ensure the new page maintains full functionality (fetching API data, polling, rendering activity timeline, instruction detail slide-out) while applying the typography and theme of `example.html` mapped onto the design principles from `Symphony-redesign.md` (e.g., 100vh constraint, precise financial signaling). 

**Phase Key**: GF-W1-UI-024
**Phase Name**: Extract_Programme_Health

## User Review Required

> [!WARNING]
> **Page Navigation & Single-Page Transition**: By extracting the first tab into a standalone HTML file (`programme-health.html`), we move away from a pure single-page application (SPA) model for these tabs. We will introduce explicit page navigation links `<a href="...">` in the top header or tab-bar region for both files to seamlessly move between the "Monitoring Report & Onboarding" (in `index.html`) and the new "Programme Health" page. The operator session cookies will persist across both.

## Proposed Changes

### UI & Layout Adjustments

#### [NEW] [programme-health.html](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/src/supervisory-dashboard/programme-health.html)
- **Creation**: Create the new `programme-health.html` file using standard HTML5 boilerplate.
- **Typesetting (example.html)**: Include the fonts `Inter` and `JetBrains Mono` from `example.html`. Use the example's CSS mappings where applicable (like `.header` and `.kpi-ribbon`), but adopt the `Symphony-redesign.md` tokens for strict trust signals (`--bright`, `--amber`, `--red` mapping to green/amber/red financial indicators).
- **Layout Restraints**: Ensure the entire view fits within the screen height (`100vh`) with `overflow: hidden` on the body, adding scrolling only to specific internal containers like the activity table.
- **Component Migration**: 
  - Move the Top Bar and Page Navigation over.
  - Move the "Programme Health" layout (KPI row, Disbursement status card, Activity table bounds, Drill-down panel wrapper).
  - Migrate all the associated JavaScript logic responsible for data population, such as `initDashboard()` which fetches from `GET /pilot-demo/api/reveal/{programId}`, Haversine distance calculations, and rendering logic for exceptions and evidence completeness.

#### [MODIFY] [index.html](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/src/supervisory-dashboard/index.html)
- **DOM Cleanup**: Remove the HTML markup for `<div id="screen-main">` (the Programme Health tab contents).
- **Navigation Update**: Modify the existing Tab Bar. Change the "Programme Health" tab from triggering an internal JavaScript `switchTab('main')` function to a standard strict `href="programme-health.html"` anchor link. Add the same link structure to `programme-health.html` pointing back to `index.html`.
- **Logic Cleanup**: Strip out the javascript functions that exclusively served the Programme Health tab (e.g., the specific Timeline table drawing and Slide-out drill functions) since those will now live in the new file. Keep `initDashboard` equivalent logic for the Monitoring Report if needed, or rely strictly on the `updateDashboard()` equivalent.

### Required Actions inside `Extract_Programme_Health` directory

As per the operational rules, I will also create local copies of the final execution documents:
- `GF-W1-UI-024-implementation_plan_Extract_Programme_Health.md`
- `GF-W1-UI-024-task_Extract_Programme_Health.md`
- `GF-W1-UI-024-walkthrough_Extract_Programme_Health.md`
These will be created within a new `Extract_Programme_Health` directory in the repository during execution.

## Open Questions

> [!IMPORTANT]
> 1. **Default Route**: Should we configure the backend to serve `programme-health.html` by default when calling `GET /pilot-demo/supervisory/`, and serve `index.html` from a different sub-path? Or should they just be sibling files accessed via `supervisory/index.html` and `supervisory/programme-health.html`?
> 2. **Typesetting Merge**: `example.html` uses different color hex codes (e.g., `--bg: #05080a; --accent: #2ea043;`) than the canonical `Symphony-redesign.md` tokens (`--bg: #050c08; --bright: #3db85a;`). I will default to `example.html`'s typography (Inter/JetBrains) but prioritize `Symphony-redesign.md`'s exact financial color tokens. Is this the right approach?

## Verification Plan

### Automated Tests
- Since this is purely a frontend HTML refactor, no backend tests need to be modified unless the serving routes change.

### Manual Verification
- Open `programme-health.html` in the browser or via the `verify_ui_e2e.sh` environment.
- Confirm fonts (`Inter`, `JetBrains Mono`) and standard spacing map to `example.html`.
- Confirm the layout never vertically scrolls past 100vh.
- Confirm the page automatically fetches `/pilot-demo/api/reveal/{programId}` and renders the activity table correctly.
- Test navigation: clicking between the new "Programme Health" tab and the "Monitoring Report" tab correctly navigates between `programme-health.html` and `index.html` seamlessly and preserves data/session layout.
