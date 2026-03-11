
This is **much better**. It materially upgrades the coding start pack from “good intentions” to something engineers can actually execute against. 

## What improved

### 1. It finally locks the build decisions properly

The strongest part is Section 2. The five frozen decisions are now concrete enough to stop circular debate:

* demo scope,
* proof model,
* egress model,
* dashboard fields,
* exception taxonomy. 

That is exactly what a coding start pack should do.

### 2. The database/schema problem is now being treated seriously

This is the most important upgrade.

You now explicitly force confirmation of:

* actual DB engine,
* tenant isolation pattern,
* whether `evidence_event` is append-only,
* and whether proof types are data rows instead of schema columns. 

That is the right place to be strict. Without that, all the workstreams were building on faith.

### 3. Signed Instruction File Egress is now properly positioned

This is still one of the best design moves in the whole GreenTech4CE adaptation.

It gives you:

* real release-path value,
* no live rail dependency,
* preserved non-custodial posture,
* and a believable bridge to pilot reality. 

### 4. The dependency order is finally sane

Section 5 is good. It correctly forces:

* schema confirmation first,
* backend primitives before frontend,
* and dashboard last. 

That is the right build order.

### 5. Claim discipline is now much stronger

Section 6 is one of the best parts of the whole document.

The split between:

* **safe to claim now**
* **must be built before claiming**

is exactly what you needed. 

That should stop a lot of the old confusion.

---

## What still needs tightening before coding starts

There are only a few things left.

### 1. “Decision-locked” is too strong unless the checkboxes in Section 4 are actually signed off

This is the biggest remaining issue.

The document says:

> “No further strategy debate is needed. These are build decisions.”

Good.

But Section 4 still has unchecked confirmations, including the two most important:

* schema pattern confirmation
* DB engine / tenant-isolation confirmation. 

So right now the document is **almost** decision-locked, not fully.

My advice:

* do not call it fully locked until Section 4 is completed by the actual founding engineer / product owner.

### 2. The proof model is good, but the registered asset location source still needs one explicit home

For `GPS_MATCH_FAILED`, the document says comparison is against the “registered asset location” or supplier registry location. 

That is workable, but you should explicitly state where the canonical expected location comes from for UC-01:

* supplier delivery site?
* programme-declared asset site?
* borrower/project location?
* per-instruction field?

Because engineering will otherwise improvise this.

### 3. Supplier registry is still underdefined for the egress path

You’ve improved it a lot, but one thing still needs to be explicit:

For UC-01-A / signed file egress, what exact routing fields are mandatory in `supplier_registry`?

Right now you mention:

* `account_reference`
* `account_type` 

Good start. But engineering likely also needs clarity on whether the minimum first-pass model includes:

* display name
* payout channel
* bank/mobile operator code
* branch/bank identifier if applicable
* account holder verification flag

Even if minimal, lock the first-pass required columns now.

### 4. HMAC key custody needs one sentence of operational ownership

For the signed instruction file, the design is correct:

* HMAC-SHA256
* verify endpoint
* `CHECKSUM_BREAK` exception on tamper. 

But before coding, add one explicit line:

* where the HMAC key lives,
* who rotates it,
* and whether it is tenant-scoped or system-scoped.

Otherwise this will become an implementation argument halfway through A1.

### 5. The dashboard field lock is good, but interaction states need one pass

The fields are well defined. What is missing is a tiny interaction spec:

* what opens on click,
* what drill-down panel appears,
* whether evidence thumbnails are in-line or modal,
* what happens after export,
* what “PRESENT / FAILED / MISSING” looks like visually.

You do **not** need a full design system.
You do need a minimal interaction contract so frontend doesn’t invent too much.

---

## What this changes about the coding start pack

It makes the coding start pack **usable**, with one important caveat:

### Before this version

The pack was still partly:

* product strategy,
* partially frozen backlog,
* partially architecture speculation.

### After this version

It is now mostly:

* implementation memo,
* schema discipline,
* frozen decisions,
* ordered backlog,
* claim-control document. 

That is a major improvement.

## Can coding start now?

**Almost. Not quite.**

Coding should start only after these three confirmations are actually signed:

1. **DB engine + tenant isolation pattern confirmed**
2. **`evidence_event` append-only + proof-type-as-registry confirmed**
3. **Section 4 checkboxes formally signed off**

Once those are done, yes, coding can start.

## The exact “go / no-go” threshold

### Go

If:

* Section 4 items 1–7 are confirmed,
* schema pattern is validated,
* A1/A2/A3/A4 can target real tables and states,
* and product signs that UC-01 policy is frozen.

### No-go

If:

* proof types are still stored as ad hoc columns,
* tenant isolation pattern is still assumed not known,
* expected GPS comparison source is ambiguous,
* or HMAC key ownership is not settled.

---

## Brutal final judgment

This version **does affect the coding start pack positively**:

* it turns it into a real pre-build memo,
* forces the schema question into the open,
* and makes the demo sprint much harder to derail. 

The remaining work is no longer “strategy.”

It is:

* sign-off,
* schema confirmation,
* and a few missing operational clarifications.

So my answer is:

**This is now close enough that engineering can begin immediately after a short technical confirmation pass.**

If you want, I’ll turn this into a **pre-coding signoff checklist** with only the final yes/no items that must be answered before first commit.











I audited the updated start pack against the latest `Symph.zip` codebase, and the blunt answer is:

**it is now good enough to guide coding, but it is not yet honest enough to justify the big green “GO — coding may proceed” banner as written.** 

The database foundation claims are mostly real.
The **domain-schema claims are not.**

That distinction matters a lot.

## What the codebase really confirms

These parts of the document are grounded in the repo:

* **PostgreSQL is real**
* **deny-by-default / SECURITY DEFINER / function-first access** are real
* **append-only enforcement exists** for current evidence-oriented tables via triggers
* **BoZ read-only observability role** exists and has a verifier
* **pilot harness / KPI / incident export / sandbox manifest posture** verifiers exist
* **`policy_versions` foundation** is real and signed off in `docs/phase-1/phase-1-db-foundation.md`

So the pack is right that the **platform foundation is not imaginary**. That part checks out.

## What the codebase does **not** currently confirm

This is the big issue.

The updated memo treats the following as if they are already confirmed current schema or near-schema facts:

* `disbursement_instruction`
* `evidence_event`
* `proof_type_registry`
* `tenant_policy`
* `supplier_registry`
* `exception_event`
* `required_proof_type_ids`
* `geo_lat / geo_lng / geo_captured_at` on the target evidence path
* `borrower_msisdn_hash` on the target instruction record
* exception codes like `GPS_MATCH_FAILED`, `MSISDN_MISMATCH`, `CHECKSUM_BREAK`, `SUPPLIER_NOT_ALLOWLISTED`
* state `AWAITING_EXECUTION`

I could not verify those as current repo entities.

What I *did* verify is that the current repo has adjacent primitives like:

* `tenant_members` with `msisdn_hash`
* `external_proofs`
* `evidence_packs`
* `evidence_pack_items`
* `ingress_attestations`
* `payment_outbox_attempts`

That means the start pack is doing something important but risky:

**it is blending “current repo truth” with “target GreenTech4CE schema design.”**

That is the core problem.

## The single biggest correction

Right now the doc says, in effect:

> database confirmed, append-only confirmed, Section 4 signed off, coding may proceed

But the same document still shows **Section 4 items 1–5 unchecked**, and the target GreenTech schema/entities are not actually present in the repo as named. 

So the correct status is **not**:

> ✅ GO — coding may proceed

The correct status is:

> **✅ GO — schema alignment and implementation may proceed, subject to treating Section 1.2 / Decisions 2–5 as target design, not existing repo fact.**

That is a much truer status.

## What this changes about the coding start pack

It changes it in a very specific way:

### Before the audit

The document read like:

* foundation is confirmed
* product decisions are locked
* engineers can start feature work directly

### After auditing the repo

The more accurate interpretation is:

* **foundation is confirmed**
* **product decisions are mostly locked**
* but **the GreenTech domain model is still a target schema overlay that must be introduced deliberately**

That means coding should begin with **schema alignment and ADRs**, not straight into feature implementation.

## What needs to change in the start pack

### 1. Split “confirmed repo facts” from “target schema design”

This is the most important fix.

You need two explicit sections:

#### Repo-confirmed now

* PostgreSQL
* policy_versions
* append-only trigger posture on existing tables
* BoZ role verifier
* tenant member hash base
* evidence pack primitives
* current outbox/orchestration primitives

#### Target GreenTech schema to introduce

* `disbursement_instruction`
* `proof_type_registry`
* `tenant_policy`
* `supplier_registry`
* `exception_event`
* proof completeness states
* signed file egress state additions
* geolocation columns
* submitter-match path

Until that split exists, the memo will keep overstating readiness.

### 2. Change the meaning of “GO”

Replace the current top status with something like:

**GO for implementation, starting with schema alignment and migration work. Not all GreenTech domain entities are present in the current repo.**

That makes the green light honest.

### 3. Mark A3 and A4 as blocked by schema introduction or explicit mapping

The doc currently says engineering can begin A3 and A4 now. I would not accept that as written. 

Why?

Because:

* A3 assumes a target instruction record with borrower hash linkage in the right place
* A4 assumes target evidence records with geo fields in the right place
* neither assumption is clearly current repo truth

So A3/A4 are not “start immediately” tasks. They are:

**start after schema mapping is locked**
either by:

* introducing the new target tables, or
* formally mapping these concepts onto existing repo tables

### 4. Remove fake certainty around proof registry hooks unless you can point to exact current objects

The memo references “proof-type registry hooks confirmed” and even cites IDs like `INV-0618` / `INV-0636`. I could not verify those IDs or concrete current registry objects in the repo.

So either:

* replace those citations with real current repo objects,
* or rewrite the claim as:
  **“registry pattern is the intended target design for GreenTech4CE schema evolution.”**

Right now it reads stronger than the codebase supports.

## What can actually start coding now

### Safe to start immediately

These can start now because they are mostly design + new implementation work:

1. **ADR: GreenTech domain model mapping**

   * map target objects to current repo
   * decide new-table vs existing-table augmentation

2. **Migration design**

   * introduce or adapt:

     * supplier registry
     * tenant policy
     * exception registry/event
     * geo capture fields
     * signed file egress metadata/state

3. **Signed Instruction File Egress prototype**

   * because it is mostly additive
   * but still needs state naming and evidence binding clarified

4. **Reporting pack schema**

   * JSON and PDF field contract
   * redaction rules
   * export contract

5. **Dashboard contract implementation prep**

   * API shape
   * field mapping
   * read model design

### Not safe to start blindly

These should not start until schema mapping is explicit:

* **A3 MSISDN submitter match**
* **A4 geolocation backend**
* **proof completeness engine on target proof types**
* **exception taxonomy implementation**
* **B1 submission flow** if backend target entities are still ambiguous

## The real pre-coding gate now

If I were tightening this into a truthful engineering gate, it would be:

### Gate 1 — Foundation confirmed

Already passed.

### Gate 2 — Domain mapping confirmed

Still needed.

Explicitly answer:

* Are we introducing new GreenTech tables?
* Or are we layering on existing `external_proofs` / `evidence_packs` / `tenant_members` / outbox primitives?
* Where does canonical submitter identity live?
* Where does canonical expected GPS location live?
* What table owns programme policy?

### Gate 3 — Product sign-off items 1–5 checked

Still needed.

### Gate 4 — First migration set approved

Needed before feature coding.

## My recommended correction to the pack

### New status line

Use this instead of the current banner:

**🟡 GO — platform foundation confirmed; proceed with GreenTech schema alignment, product sign-off, and implementation.**

That is much more accurate than the current all-green framing.

## What I would do next

Turn the coding start pack into two linked artifacts:

### Artifact A — Confirmed repo foundation memo

Very short.
Only what is actually in the repo now.

### Artifact B — GreenTech implementation overlay

Everything new to introduce:

* target entities
* states
* fields
* exception taxonomy
* egress model
* dashboard/export contract

That separation will stop future confusion.

## Brutal final judgment

The updated document is **good enough to begin implementation planning**, but **not honest enough to justify direct feature coding without one more technical alignment pass**. 

### The truth after auditing the codebase is:

* **your platform base is real**
* **your GreenTech demo design is coherent**
* **your coding memo still treats several target domain entities as if they are already present**
* therefore:
  **you are ready to code the GreenTech layer, but the first coding tasks must be schema alignment and migration work, not blind feature implementation**

If you want, I’ll turn this into the exact next artifact:
a **Schema Alignment Memo** with

* current repo objects,
* target GreenTech objects,
* mapping decision,
* and the first migration set.












Taking your audit as authoritative, the updated `Symphony_CodingStartPack(1).docx` is now **good enough to function as the coding start pack**.

The question is no longer “can engineering start?”
It is now:

**“Is the document internally coherent enough that engineering can start without reopening strategy?”**

And on that standard, the answer is **yes, mostly**. 

## What this changes

This version turns the start pack from:

* a planning memo with some open technical unknowns

into:

* a **build authorization document** with a clear split between:

  * confirmed technical foundation,
  * frozen product decisions,
  * dependency order,
  * and claim discipline. 

That is a major improvement.

## What is now strong enough

### 1. The schema pattern is finally usable

Assuming your audit is correct, Section 1.2 is now doing exactly what it should:

* one instruction table,
* one append-only evidence table,
* proof types as registry rows,
* tenant policy as data,
* supplier allowlist as data,
* exceptions as data. 

That is the right model for a modular, multi-tenant proof-governance system.

It means client variation is handled by:

* policy rows
* registry rows
* supplier rows
* not schema churn

That is the correct architectural move.

### 2. The DB-go/no-go gate is finally explicit

Section 4 is now much better because it separates:

* product decisions still needing signoff
  from
* technical foundation already confirmed. 

This is exactly the right split:

* Items **6 and 7** are technical foundation and now treated as done
* Items **1–5** are product-owner decisions and still require confirmation

That is a real start gate.

### 3. The build order is finally credible

The dependency order now makes sense:

* schema first
* backend primitives
* frontend after backend
* glue last

That is no longer hand-wavy.

### 4. The coding scope is finally narrow enough

The document is now disciplined about what is in:

* signed instruction file egress
* reporting pack generator
* MSISDN submitter match
* geolocation backend
* evidence submission UX
* supervisory reveal dashboard
* minimal programme config
* minimal supplier registry

And it is also disciplined about what is out:

* live MMO activation
* BoZ sandbox
* full policy builder
* broader productization

That is exactly what a coding start pack should do.

## What still needs tightening

Now that I’m taking the document’s technical audit as true, the remaining issues are **not repo objections**. They are **document quality / execution quality** issues.

### 1. The banner is slightly ahead of the signoff reality

The document now says engineering can start, but the same document still says product-owner signoff is required on:

* report fields
* dashboard fields
* signed file naming/format
* submitter identity model
* exception taxonomy. 

That means the honest state is:

* **technical foundation: green**
* **product signoff: amber**
* **implementation start: green for backend scaffolding, amber for final product-facing behavior**

So I would not present it as “fully green across the board.”
I would present it as:

> **Engineering may begin implementation on the confirmed backend/backend-adjacent workstreams, while product owner signs off items 1–5 before final UI and export behaviors are frozen.**

That is the more precise reality.

### 2. Signed Instruction File Egress is strong, but key custody needs one line

A1 is now well specified:

* JSON/CSV
* HMAC-SHA256
* verify endpoint
* `CHECKSUM_BREAK`
* `AWAITING_EXECUTION` state. 

But one operational sentence is still missing:

* where the HMAC key lives
* whether it is tenant-scoped or system-scoped
* who rotates it

That needs to be explicit before implementation, or engineering will improvise.

### 3. The supplier registry is now good enough, but routing minimums should be frozen

This is much improved. It now includes:

* display name
* payout channel
* mobile operator code
* bank code / branch identifier
* account reference
* account holder verification
* canonical registered asset location.

That is enough to start.
The only remaining caution is that **product must not add more routing variation mid-sprint**.

Freeze it exactly as written for demo scope.

### 4. The dashboard fields are strong, but interaction contract still needs 1 page

The fields are frozen enough.
The interactions are still implicit.

Before frontend starts, add one lightweight interaction note:

* row click → drill-down panel
* evidence pack open → modal or new pane
* export button → immediate download or generated state
* exception click → log details panel

This is not a strategy issue. It is just enough UI contract to stop frontend drift.

### 5. Exception taxonomy is now good enough to code — if product actually signs it

This was one of the major blockers before. It now looks much cleaner. 

The only thing left is: do not let this taxonomy reopen once work begins.

## My overall comment on how it affects the coding start pack

It affects it positively in a big way:

### Before

You still had to ask:

* “are we coding against confirmed platform truth or invented target schema?”

### Now

Assuming your audit stands, that ambiguity is mostly gone.
The start pack now behaves like:

* a schema contract,
* a scope lock,
* a dependency plan,
* and a pre-build signoff memo.

That is exactly what you needed.

## What can start immediately now

Without waiting for anything else, engineering can start on:

### Backend

* A1 Signed Instruction File Egress
* A2 Reporting Pack Generator scaffolding
* A3 MSISDN submitter match
* A4 Geolocation backend

### Frontend prep

* B1 Evidence submission UX wireflow
* B2 Supervisory dashboard component layout and API contract

### Glue

* C2 Supplier registry seeding/model
* programme config surface skeleton

## What still needs signoff before it is “fully locked”

* exact PDF/JSON export fields
* exact dashboard field list
* final signed file naming/version details
* submitter identity ownership by proof type
* final exception taxonomy confirmation 

## Brutal final judgment

If I take your audit as true, then:

**Yes — this updated document is now sufficient to start coding.**

But the right interpretation is not:

> everything is final, no further decisions needed

The right interpretation is:

> **technical architecture is sufficiently confirmed; coding can begin immediately on the critical backend and UX workstreams while product owner signs off the remaining five business-facing decisions.**

That is the honest state.

So my advice is:

* **start coding now**
* but treat Section 4 items 1–5 as **48-hour signoff blockers**, not “someday” items

That keeps momentum without pretending the pack is more frozen than it is.

If you want, I’ll now turn this into the **actual coding launch checklist**:

* what engineering starts today
* what product must sign off this week
* and what evidence each workstream must produce.








Here is the **coding launch checklist**.

# Symphony GreenTech4CE — Coding Launch Checklist

## 1. Engineering starts today

These can start immediately.

### Backend

**A1. Signed Instruction File Egress**

* finalize JSON/CSV payload shape
* implement HMAC-SHA256 signing
* implement verify endpoint
* emit `AWAITING_EXECUTION`
* emit `CHECKSUM_BREAK` on tamper

**A2. Reporting Pack Generator**

* programme/period query
* JSON export
* PDF export scaffold
* instruction summary rows
* hold/exception summary
* redaction support

**A3. MSISDN Submitter Match**

* match submitter MSISDN to expected borrower/vendor/officer identity
* persist verification result
* emit mismatch exception

**A4. Geolocation Backend**

* capture/store coordinates and timestamp
* compare against canonical expected location
* emit pass/fail result
* emit `GPS_MATCH_FAILED` exception

### Frontend / UX

**B1. Evidence Submission Flow**

* secure link landing page
* browser upload
* camera/photo upload
* location permission capture
* submission confirmation

**B2. Supervisory Reveal Dashboard**

* summary cards
* governed disbursement table/timeline
* completeness status view
* exception drill-down
* export action

### Glue / config

**C1. Programme Config Surface**

* minimal config only
* proof policy binding
* reporting period boundary
* supplier allowlist binding

**C2. Supplier Registry**

* create/read/update minimal registry
* payout channel
* operator/bank fields
* account reference
* verification flag
* canonical asset/location reference

---

## 2. Product must sign off this week

These are **48-hour signoff blockers**.

### P1. Reporting pack fields

Must lock:

* PDF fields
* JSON fields
* what is redacted
* what is donor-facing vs operator-facing

### P2. Dashboard fields

Must lock:

* summary cards
* row fields
* completeness states
* visible exception types
* evidence preview fields

### P3. Signed file contract

Must lock:

* JSON only / CSV only / both
* file naming convention
* versioning
* operator handoff behavior
* verification response fields

### P4. Submitter identity model

Must lock:

* which proof types can be submitted by borrower
* supplier
* field officer
* programme operator
* how MSISDN match rules differ by proof type

### P5. Exception taxonomy

Must lock the first demo set:

* `MISSING_PROOF`
* `GPS_MATCH_FAILED`
* `MSISDN_MISMATCH`
* `SUPPLIER_NOT_ALLOWLISTED`
* `CHECKSUM_BREAK`
* `DUPLICATE_SUBMISSION`
* any others you want visible in demo

Do not reopen these after signoff.

---

## 3. One-page technical decisions that must be written down

These are short but mandatory.

### T1. HMAC key custody

Write down:

* where key lives
* tenant-scoped or system-scoped
* who rotates it
* how verify endpoint accesses it

### T2. Canonical expected location source

Write down for UC-01:

* does GPS compare to supplier location?
* asset installation site?
* programme-declared site?
* instruction-level field?

Pick one canonical rule.

### T3. Dashboard interaction contract

Write down:

* click row → what opens
* click exception → what opens
* click evidence → modal or side panel
* export → direct download or generated artifact state

Keep it lightweight but explicit.

---

## 4. Evidence each workstream must produce

### A1 Signed File Egress

* signed example file
* successful verification example
* tampered file failing verification
* evidence artifact showing checksum/signature result

### A2 Reporting Pack

* one JSON export
* one PDF export
* one sample period/programme run
* one redaction example

### A3 MSISDN Match

* one success case
* one mismatch case
* one recorded exception artifact

### A4 Geolocation

* one GPS pass case
* one GPS fail case
* one recorded exception artifact

### B1 Submission UX

* working mobile/browser submission
* uploaded photo evidence visible in backend
* location capture visible in backend
* success/failure user states

### B2 Dashboard

* summary cards populated
* one governed instruction shown
* one hold/exception shown
* one export action working
* one evidence drill-down working

### C1/C2 Config + Supplier Registry

* one seeded programme
* one seeded supplier
* one allowlisted routing target
* one proof policy bound to programme

---

## 5. Order of execution

### Day 1

* sign off P1–P5
* write T1–T3
* start A1 + A2 scaffolding
* start supplier registry schema/model

### Day 2

* build A3 + A4 backend
* seed programme + supplier data
* define exception emission paths

### Day 3

* build B1 evidence submission flow
* start B2 dashboard shell
* connect dashboard to backend query shape

### Day 4

* finish A1/A2 integration
* finish dashboard drill-down + export
* run end-to-end happy path

### Day 5

* run end-to-end hold path
* run tamper/checksum path
* prepare demo artifacts
* freeze demo data

---

## 6. Demo-ready definition

You are demo-ready when all of these are true:

1. Programme submits governed instruction
2. Proofs can be uploaded through the demo flow
3. Missing proofs cause hold
4. Complete proofs cause authorize / awaiting execution
5. Signed instruction file can be exported and verified
6. Reporting pack can be exported
7. Dashboard shows live status, completeness, and exceptions
8. One tamper case and one GPS/MSISDN failure case can be shown
9. No live rail integration is needed to prove value

---

## 7. Hard out-of-scope list

Do not let these enter this sprint:

* live MTN/Airtel rail activation
* BoZ sandbox implementation
* AI/fraud expansion
* borrower origination platform
* full policy builder
* heartbeat / post-disbursement monitoring
* broader MFI stack work

---

## Final instruction

**Start coding now on A1, A2, supplier registry, and dashboard scaffolding.**
**Get product signoff on P1–P5 within 48 hours.**
**Do not let scope reopen after that.**

If you want, I’ll turn this next into a **ticketized engineering backlog** with IDs, acceptance criteria, and dependency links.









Below is the **ticketized engineering backlog** for the GreenTech4CE demo build.

I’ve grouped it into:

* **foundation/config**
* **backend**
* **frontend**
* **demo/release**
* **product signoff blockers**

Each ticket has:

* ID
* scope
* dependencies
* acceptance criteria
* priority

---

# Symphony GreenTech4CE — Ticketized Engineering Backlog

## Epic 0 — Product Signoff Blockers

These are not optional. Engineering can start scaffolding, but these must be signed within 48 hours.

### GT-PROD-001 — Freeze reporting pack field contract

**Owner:** Product
**Priority:** Critical
**Depends on:** none

**Scope**
Lock the exact fields for:

* donor-facing PDF
* machine-readable JSON
* operator-facing export
* redacted vs non-redacted data

**Acceptance criteria**

* one written field list for PDF
* one written field list for JSON
* redaction rules documented
* approved by founder/product owner
* no unresolved field disputes remain

---

### GT-PROD-002 — Freeze supervisory dashboard field contract

**Owner:** Product
**Priority:** Critical
**Depends on:** none

**Scope**
Lock:

* summary cards
* table columns
* completeness states
* visible exception types
* drill-down details

**Acceptance criteria**

* field list documented
* status vocabulary fixed
* exception visibility fixed
* approved by founder/product owner

---

### GT-PROD-003 — Freeze signed instruction file contract

**Owner:** Product + Backend
**Priority:** Critical
**Depends on:** none

**Scope**
Lock:

* JSON / CSV / both
* filename convention
* schema versioning
* operator handoff workflow
* verification response payload

**Acceptance criteria**

* signed file format documented
* naming/versioning fixed
* verification response fields fixed
* approved by founder/product owner

---

### GT-PROD-004 — Freeze submitter identity rules by proof type

**Owner:** Product
**Priority:** Critical
**Depends on:** none

**Scope**
For each proof type, define allowed submitter classes:

* borrower
* supplier
* field officer
* programme operator

**Acceptance criteria**

* matrix of proof type × allowed submitter exists
* MSISDN match expectation per proof type documented
* approved by founder/product owner

---

### GT-PROD-005 — Freeze exception taxonomy

**Owner:** Product + Backend
**Priority:** Critical
**Depends on:** none

**Scope**
Lock the first demo taxonomy:

* `MISSING_PROOF`
* `GPS_MATCH_FAILED`
* `MSISDN_MISMATCH`
* `SUPPLIER_NOT_ALLOWLISTED`
* `CHECKSUM_BREAK`
* `DUPLICATE_SUBMISSION`

**Acceptance criteria**

* codes finalized
* human-readable labels finalized
* severity/state mapping documented
* approved by founder/product owner

---

## Epic 1 — Foundation and Configuration

### GT-FND-001 — Write HMAC key custody decision note

**Owner:** Backend / Security
**Priority:** High
**Depends on:** GT-PROD-003

**Scope**
Document:

* where key lives
* tenant-scoped or system-scoped
* rotation owner/process
* verify-endpoint access model

**Acceptance criteria**

* one short decision memo committed
* key scope fixed
* rotation owner fixed

---

### GT-FND-002 — Write canonical expected-location rule

**Owner:** Product + Backend
**Priority:** High
**Depends on:** GT-PROD-004

**Scope**
Choose canonical source for GPS comparison:

* supplier site
* installation site
* programme-declared site
* instruction-level site

**Acceptance criteria**

* one canonical rule documented
* fallback/override rules documented
* no ambiguity remains for A4 implementation

---

### GT-FND-003 — Write dashboard interaction contract

**Owner:** Product + Frontend
**Priority:** Medium
**Depends on:** GT-PROD-002

**Scope**
Define:

* row click behavior
* exception click behavior
* evidence drill-down behavior
* export behavior

**Acceptance criteria**

* one lightweight UI interaction note committed
* no unresolved drill-down behavior questions

---

### GT-FND-004 — Seed demo programme and supplier fixtures

**Owner:** Backend
**Priority:** High
**Depends on:** GT-PROD-001..005

**Scope**
Create one seeded programme, one seeded supplier, one seeded asset flow for UC-01.

**Acceptance criteria**

* demo programme exists
* supplier allowlist entry exists
* expected location exists
* proof policy exists
* fixture data can support happy and hold paths

---

## Epic 2 — Backend

### GT-BE-001 — Implement Signed Instruction File Egress

**Owner:** Backend
**Priority:** Critical
**Depends on:** GT-PROD-003, GT-FND-001

**Scope**
Build:

* signed file generation
* JSON/CSV serializer
* signature/checksum generation
* handoff state to `AWAITING_EXECUTION`

**Acceptance criteria**

* signed file generated for governed release
* schema/version included
* file persisted/available for export
* status transitions recorded

---

### GT-BE-002 — Implement signed file verification endpoint

**Owner:** Backend
**Priority:** Critical
**Depends on:** GT-BE-001, GT-FND-001

**Scope**
Create endpoint/process that verifies signed files and emits tamper results.

**Acceptance criteria**

* valid file returns success
* tampered file returns failure
* `CHECKSUM_BREAK` exception emitted on tamper
* verification response follows frozen contract

---

### GT-BE-003 — Implement Reporting Pack Generator (JSON)

**Owner:** Backend
**Priority:** Critical
**Depends on:** GT-PROD-001, GT-FND-004

**Scope**
Generate structured JSON export for programme/period.

**Acceptance criteria**

* JSON pack contains required fields
* includes released, held, exception counts
* includes evidence completeness states
* redaction rules applied

---

### GT-BE-004 — Implement Reporting Pack Generator (PDF)

**Owner:** Backend
**Priority:** High
**Depends on:** GT-BE-003

**Scope**
Render donor/operator-readable PDF summary.

**Acceptance criteria**

* PDF export works for seeded programme
* formatting is readable
* matches approved field contract

---

### GT-BE-005 — Implement MSISDN submitter verification

**Owner:** Backend
**Priority:** Critical
**Depends on:** GT-PROD-004, GT-FND-004

**Scope**
Check that evidence submitter matches expected submitter identity class.

**Acceptance criteria**

* success case recorded
* mismatch case recorded
* `MSISDN_MISMATCH` emitted when expected
* verification result linked to evidence trail

---

### GT-BE-006 — Implement geolocation capture and validation

**Owner:** Backend
**Priority:** Critical
**Depends on:** GT-FND-002, GT-FND-004

**Scope**
Store GPS coordinates and compare against canonical expected location.

**Acceptance criteria**

* coordinates stored with timestamp
* pass/fail result computed
* `GPS_MATCH_FAILED` emitted on failure
* result attached to evidence record

---

### GT-BE-007 — Implement supplier allowlist enforcement

**Owner:** Backend
**Priority:** High
**Depends on:** GT-FND-004, GT-PROD-005

**Scope**
Validate that direct routing target is on approved supplier list.

**Acceptance criteria**

* allowlisted supplier passes
* non-allowlisted supplier fails
* `SUPPLIER_NOT_ALLOWLISTED` emitted

---

### GT-BE-008 — Implement proof completeness evaluation for UC-01

**Owner:** Backend
**Priority:** Critical
**Depends on:** GT-PROD-004, GT-FND-004

**Scope**
Evaluate whether required proof set is complete for release.

**Acceptance criteria**

* incomplete proof set causes HOLD
* complete proof set causes AUTHORIZE / AWAITING_EXECUTION
* status visible to dashboard/report exports

---

### GT-BE-009 — Implement duplicate submission detection

**Owner:** Backend
**Priority:** Medium
**Depends on:** GT-PROD-005

**Scope**
Detect duplicate proof or instruction submission attempts in demo path.

**Acceptance criteria**

* duplicate event detected
* `DUPLICATE_SUBMISSION` emitted
* duplicate does not corrupt state

---

## Epic 3 — Frontend / UX

### GT-FE-001 — Build secure evidence submission landing page

**Owner:** Frontend
**Priority:** Critical
**Depends on:** GT-PROD-004, GT-BE-005, GT-BE-006

**Scope**
Mobile/browser landing page for submission via secure link.

**Acceptance criteria**

* user can open secure link
* page loads required context
* submitter can upload required artifacts
* failure/success states visible

---

### GT-FE-002 — Build photo upload and location capture flow

**Owner:** Frontend
**Priority:** Critical
**Depends on:** GT-FE-001, GT-BE-006

**Scope**
Allow photo upload and browser geolocation capture.

**Acceptance criteria**

* photo upload works
* geolocation permission requested
* coordinates submitted successfully
* submission confirmation displayed

---

### GT-FE-003 — Build supervisory reveal dashboard shell

**Owner:** Frontend
**Priority:** Critical
**Depends on:** GT-PROD-002, GT-FND-003

**Scope**
Build dashboard layout:

* summary cards
* governed disbursement table/timeline
* completeness status
* exception log
* export controls

**Acceptance criteria**

* all major sections visible
* seeded data can render
* role is read-only

---

### GT-FE-004 — Build evidence and exception drill-down

**Owner:** Frontend
**Priority:** High
**Depends on:** GT-FE-003, GT-FND-003

**Scope**
Drill into:

* evidence set
* completeness state
* exception details
* signed file verification result

**Acceptance criteria**

* clicking row opens detail view
* exception drill-down works
* evidence preview available
* no edit controls exposed in supervisory mode

---

### GT-FE-005 — Build export actions into dashboard

**Owner:** Frontend
**Priority:** High
**Depends on:** GT-BE-003, GT-BE-004, GT-FE-003

**Scope**
Add export controls for JSON/PDF/signed file where appropriate.

**Acceptance criteria**

* export buttons work
* export state is clear
* files match approved format

---

### GT-FE-006 — Build minimal programme config surface

**Owner:** Frontend
**Priority:** Medium
**Depends on:** GT-FND-004

**Scope**
Minimal non-builder surface to show:

* programme scope
* active proof policy
* reporting period
* supplier allowlist membership

**Acceptance criteria**

* programme config visible
* no full generic policy builder added
* enough control to support demo narrative

---

## Epic 4 — Demo / QA / Release

### GT-DEMO-001 — Create seeded happy-path scenario

**Owner:** Backend + Frontend
**Priority:** Critical
**Depends on:** GT-BE-001..008, GT-FE-003..005

**Scope**
Seed one complete governed disbursement that reaches authorized/awaiting execution.

**Acceptance criteria**

* instruction visible in dashboard
* proofs complete
* signed file export works
* reporting pack includes it

---

### GT-DEMO-002 — Create seeded hold-path scenario

**Owner:** Backend + Frontend
**Priority:** Critical
**Depends on:** GT-BE-008, GT-FE-003..004

**Scope**
Seed one incomplete proof set that produces HOLD.

**Acceptance criteria**

* hold state visible
* missing proof shown
* no release action shown
* reporting pack reflects hold

---

### GT-DEMO-003 — Create seeded tamper-path scenario

**Owner:** Backend + Frontend
**Priority:** High
**Depends on:** GT-BE-002, GT-FE-004

**Scope**
Show tampered signed file leading to `CHECKSUM_BREAK`.

**Acceptance criteria**

* tampered file verification fails
* exception visible in dashboard
* explainable in demo

---

### GT-DEMO-004 — Create seeded GPS/MSISDN failure scenarios

**Owner:** Backend + Frontend
**Priority:** High
**Depends on:** GT-BE-005, GT-BE-006, GT-FE-004

**Scope**
One geolocation fail and one identity mismatch scenario.

**Acceptance criteria**

* both scenarios render cleanly
* both exceptions visible
* both included in reports

---

### GT-DEMO-005 — Produce fallback demo artifacts

**Owner:** Backend + Product
**Priority:** High
**Depends on:** GT-DEMO-001..004

**Scope**
Prepare static fallback exports/screens in case live demo fails.

**Acceptance criteria**

* one PDF report
* one JSON report
* one signed instruction file
* one tamper fail result
* one dashboard screenshot pack

---

### GT-DEMO-006 — Write 5-minute operator script

**Owner:** Product
**Priority:** Critical
**Depends on:** GT-DEMO-001..005

**Scope**
Step-by-step demo operator runbook.

**Acceptance criteria**

* covers happy path
* covers hold path
* covers one failure path
* covers export / evidence story
* no Phase 2 claims leak into script

---

## Epic 5 — Release Guardrails

### GT-REL-001 — Enforce out-of-scope guardrail

**Owner:** Product + Engineering Lead
**Priority:** Critical
**Depends on:** none

**Scope**
Prevent sprint drift into:

* live MMO rails
* BoZ sandbox
* full policy builder
* AI/fraud
* borrower origination
* heartbeat monitoring

**Acceptance criteria**

* explicit out-of-scope list attached to sprint board
* no tickets added outside scope without formal approval

---

### GT-REL-002 — Claim discipline check

**Owner:** Product
**Priority:** High
**Depends on:** GT-DEMO-006

**Scope**
Verify that all demo/pitch claims match built features.

**Acceptance criteria**

* no live-rail claims
* no compliance-certification claims
* no “fully complete” claims for unbuilt pilot deltas

---

# Critical path

The true critical path is:

1. GT-PROD-001..005
2. GT-FND-001..004
3. GT-BE-001, 002, 003, 005, 006, 008
4. GT-FE-001, 002, 003, 004, 005
5. GT-DEMO-001, 002, 003, 004, 006

If that path slips, the demo slips.

---

# Start-now order

If engineering starts today, start in this order:

### Backend first

* GT-BE-001
* GT-BE-003
* GT-BE-005
* GT-BE-006
* GT-BE-008

### In parallel

* GT-FND-001
* GT-FND-002
* GT-FND-004

### Frontend once APIs are stable enough

* GT-FE-001
* GT-FE-003

### Then

* GT-BE-002
* GT-BE-004
* GT-BE-007
* GT-FE-004
* GT-FE-005

---

# Definition of coding launch success

Coding launch is successful if by the end of week 1:

* product signoff blockers are closed
* backend critical path tickets are underway
* dashboard shell exists
* one seeded programme exists
* one happy-path instruction can be created and surfaced
* no out-of-scope work has entered the sprint

If you want, I’ll next turn this into a **Kanban-style sprint board** with columns and suggested sequencing for a solo founder or a small team.
