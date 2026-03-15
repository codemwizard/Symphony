# Offline Evidence Capture and Deferred Submission Requirements

**Document type:** Product design brief / implementation guidance  
**Location:** `docs/product/greentech4ce/OFFLINE_EVIDENCE_CAPTURE_AND_DEFERRED_SUBMISSION_REQUIREMENTS.md`  
**Status:** Draft — non-canonical  
**Owner:** GreenTech4CE product workstream  
**Last reviewed:** 2026-03-14

---

## 1. Purpose and Positioning

This document describes a possible **client-onboarding extension** for Symphony: offline evidence capture on a phone or tablet, with deferred submission once connectivity returns.

This document is **not** a canonical truth source. It is a delivery-oriented design brief intended to help implementation teams converge on a practical first version. Canonical backend truth remains the code, verifiers, and existing security/identity boundaries already implemented in the repo.

This capability is intended to reduce friction for low-connectivity field environments where a user must capture proof at a site that may have weak or no mobile data coverage.

### 1.1 What this capability is

It is strictly limited to:

- offline evidence capture on the device
- local deferred storage of the pending submission
- online submission when connectivity returns
- server-side validation at receipt time

### 1.2 What this capability is not

It must not be used to imply or implement:

- offline transaction execution
- offline settlement or finality
- offline supervisory approval
- offline policy evaluation
- offline fund release or disbursement
- full offline Symphony operation

Any implementation that crosses those boundaries is out of scope and must be rejected.

---

## 2. Current Repo Truth

### 2.1 Capabilities that already exist

The repo already provides:

- `POST /v1/evidence-links/issue`
- `POST /v1/evidence-links/submit`
- tokenised evidence-link issuance and validation
- backend GPS validation logic
- tenant/programme-scoped submission checks
- expiry handling for evidence-link tokens
- invalid-token handling for evidence-link tokens

Current backend truth relevant to this brief:

- expired secure links already return `LINK_TOKEN_EXPIRED`
- invalid or tampered secure links already return `LINK_TOKEN_INVALID`
- GPS-required failures already return `GPS_REQUIRED`
- GPS mismatch already returns `GPS_MATCH_FAILED`

### 2.2 Capabilities that do not exist

The repo does **not** currently provide:

- a field PWA
- a web manifest for a field capture app
- a service worker for field capture
- IndexedDB queueing for deferred submissions
- browser-side camera capture flow for field evidence
- browser-side geolocation capture flow for field evidence
- multipart photo submission support on the evidence-link submit route
- duplicate submission handling for deferred/mobile replay

So the backend evidence-link flow exists, but the offline/mobile capture path does not.

---

## 3. Target Capability

The first implementation should be a **demo-deliverable field PWA** that proves the model works without over-engineering it.

The field flow is:

1. operator issues a scoped evidence link
2. field user opens a link on a phone
3. PWA captures photo and GPS
4. if offline, the PWA stores the pending submission locally
5. once online, the PWA submits the evidence to Symphony
6. backend performs all authoritative validation at receipt time

This first version is explicitly a **deferred submission capability**, not a general offline platform.

---

## 4. Backend Requirements and API Contract

### 4.1 Authentication and token model

The first version must reuse the existing evidence-link token flow.

Authentication for deferred submission remains:

- `Authorization: Bearer <token>`
- or `x-evidence-link-token: <token>`

The first demo implementation may deliver the token in the URL because that is the easiest path to prove the PWA works. For the demo, this is acceptable only if all of the following are true:

- token is short-lived
- token is single-purpose
- token is scoped to one evidence submission context
- token carries no admin or broader tenant privilege
- PWA extracts the token immediately on load and removes it from the visible URL using `history.replaceState`

This brief does **not** require a new auth system for the field app.

### 4.2 Submission transport

The first implementation must use **multipart/form-data**.

The backend submission contract should be extended or wrapped so the PWA can submit:

- `artifact_type`
- `photo` binary part
- `latitude` when required
- `longitude` when required
- `gps_accuracy_metres` when GPS is present
- `client_capture_timestamp`
- `offline_origin`
- optional debugging metadata such as `app_version` and `device_os`

The first version should not use:

- presigned upload URLs
- base64 photo bodies

Those can remain future enhancements if needed.

### 4.3 Authoritative backend validation

The backend remains authoritative for all of the following:

- token validity
- token expiry
- tenant and programme scope
- proof-type acceptance
- GPS threshold evaluation
- duplicate submission outcome
- authoritative receipt time

The client device is only an input-capture surface.

### 4.4 Duplicate handling for the demo-first version

The first version should use the simplest useful duplicate rule.

For this implementation, a deferred submission is treated as a duplicate when the backend determines that the same submission context already contains a recorded proof for the same proof type.

In practical terms, the duplicate check for v1 should be based on:

- tenant / programme / instruction scope from the secure link
- proof type / artifact type already recorded

Response semantics for v1:

- first valid submission: `202 accepted`
- later submission of the same proof type in the same secure-link context: `200 duplicate-already-recorded`

This is explicitly a **demo-first duplicate model**.

It is not the same thing as a stronger long-term persisted idempotency-key design. If stronger replay semantics are needed later, that should be a follow-on hardening step.

### 4.5 Required backend work

Minimum backend work required:

- extend `POST /v1/evidence-links/submit` to accept multipart photo upload
- persist uploaded photo or artifact reference under the existing evidence-link flow
- preserve current secure-link expiry and invalid-token semantics
- preserve current GPS-required and GPS-mismatch semantics
- add duplicate proof-type detection for the secure-link submission context
- record enough metadata to distinguish:
  - accepted first proof
  - duplicate-already-recorded proof
- record:
  - `client_capture_timestamp`
  - `server_receipt_timestamp`
  - `offline_origin`
  - `gps_accuracy_metres` when present
- add self-test or verifier coverage for:
  - expired token submission
  - invalid token submission
  - GPS required
  - GPS mismatch
  - multipart upload success
  - duplicate proof replay

---

## 5. Minimum PWA Requirements for a Symphony Field App

The first version should be a **minimum viable field PWA**, not a full mobile platform.

### 5.1 Required client capabilities

The PWA must include:

- web app manifest
- service worker
- IndexedDB queue for pending submissions
- camera/photo capture path
- geolocation capture path
- online/offline detection
- visible submission queue states
- sync on reconnect
- foreground sync on app open

### 5.2 Camera capture

For the demo, the easiest reliable path should be preferred.

Required rule:

- support file-input camera capture as the baseline path
- allow `getUserMedia` if implemented, but do not make it mandatory for v1

Why:

- file input is the easiest cross-platform path
- it is more reliable on iOS for a first delivery
- it proves the PWA flow without overcommitting to a more complex camera UX

### 5.3 Geolocation capture

The PWA should use the browser Geolocation API and capture:

- `latitude`
- `longitude`
- `accuracy`
- capture timestamp

The PWA may warn on poor accuracy, but backend validation remains authoritative.

### 5.4 Local queue and sync

The PWA must:

- queue pending submissions in IndexedDB when offline
- retry when the app returns online
- trigger sync on app open when online
- support Android background sync where available
- not assume iOS background sync exists

Required visible queue states:

- captured offline
- queued
- submitting
- submitted
- rejected
- expired

### 5.5 Secrets and credentials

The PWA must never contain:

- admin credentials
- tenant-wide API keys
- service tokens
- evidence-signing keys

The only credential allowed on-device is the scoped evidence-link token for the current submission context.

### 5.6 Local encryption posture

For the first demo version, local encryption-at-rest for queued blobs should be described as a **hardening enhancement**, not a blocker, unless security explicitly decides to require it before implementation.

The brief should still state the expectation clearly:

- queued device data contains sensitive submission material
- stronger local protection may be required before broader rollout

But the first demo should not be blocked on an under-specified local key lifecycle model.

---

## 6. Security and Identity Boundaries

This capability must preserve the repo’s existing separation of identity domains.

Field/mobile capture identity is separate from:

- internal service or mesh identity
- evidence-signing identity

Evidence signing remains server-side. The mobile client does not sign evidence and does not hold signing authority.

Deferred submission does not bypass:

- tenant scope enforcement
- programme scope enforcement
- token validation
- expiry checks
- GPS validation

Proof acceptance is always decided by the backend at receipt time.

If the user captured valid-looking proof while offline but the token is expired or the policy context is no longer acceptable at submission time, the backend rejection stands.

---

## 7. Demo-Oriented Failure Modes

The first implementation must handle at least these cases:

- no network during capture → queue locally
- user opens app later with connectivity → sync queued submission
- expired token on replay → reject with current backend expiry behavior
- invalid or tampered token → reject with current backend invalid-token behavior
- GPS required but missing → reject with existing GPS-required behavior
- GPS mismatch → reject with existing GPS-mismatch behavior
- same proof type submitted twice → second response is `duplicate-already-recorded`
- iOS app reopened after offline period → foreground sync submits queued items
- no admin or broad credentials in client bundle/storage

The client must not present queued evidence as “accepted” until the backend confirms receipt.

---

## 8. Acceptance Criteria

This capability is acceptable for the first demo implementation when all of the following are true:

- operator can issue a secure evidence link using the existing backend flow
- field user can open the PWA from the tokenised URL on a phone
- PWA extracts the token and clears it from the visible URL
- user can capture a photo on phone
- user can capture GPS on phone
- if offline, the submission is queued locally
- once online, the PWA submits the queued item successfully
- backend returns `202 accepted` for the first valid proof
- backend returns `200 duplicate-already-recorded` for replay of the same proof type in the same secure-link context
- expired tokens are rejected using the current backend expiry model
- invalid tokens are rejected using the current backend invalid-token model
- GPS-required and GPS-mismatch failures still come from backend validation
- no admin or tenant-wide secrets appear in the PWA code or device storage

---

## 9. Open Items

These decisions remain open and should be resolved before implementation starts:

- exact multipart field names for the photo and metadata parts
- maximum photo size for the demo
- whether backend stores photo binary directly or converts immediately to an artifact reference
- whether GPS accuracy threshold should be programme-configurable in the first version or fixed for the demo
- whether local queue encryption is mandatory for the first demo or deferred to hardening
- exact user-visible wording for expired-token and duplicate states

---

## 10. Final Note

This document is intentionally pragmatic.

It is not trying to define the final production-grade offline architecture. It defines the smallest coherent version that can be delivered quickly to prove that a Symphony field PWA can:

- open from a scoped evidence link
- capture photo + GPS on a phone
- work through a short offline period
- submit later when online
- preserve server-side validation and fail-closed execution boundaries
