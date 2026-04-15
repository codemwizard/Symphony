# Worker Token Issuance Tab — Requirements

## Context

The supervisory dashboard currently has 3 tabs but the pilot demo requires 5 tabs. This spec addresses the missing "Worker Token Issuance" tab (Tab 4), which provides supervisors with the ability to generate time-limited, GPS-bound evidence-link tokens for waste collectors at Chunga Dumpsite. This functionality is demonstrated in Act 2.1-2.2 of the pilot demo video script.

The tab enables supervisors to issue worker tokens on demand without requiring workers to have direct access to the supervisory dashboard. Tokens are cryptographically signed, time-limited (5 minutes), and GPS-bound to prevent misuse.

---

## Requirement 1 — Worker Token Issuance Interface

### User Story
As a programme supervisor, I want a dedicated tab in the supervisory dashboard to generate worker collection tokens by entering a worker's phone number, so I can enable field workers to submit evidence without giving them dashboard access.

### Acceptance Criteria

**1.1** WHEN the "Worker Token Issuance" tab is selected THEN it SHALL display a form with:
- Programme context (name, location)
- Worker phone number input field (format: +260XXXXXXXXX)
- "Request Collection Token" button
- Token result display area (initially empty)

**1.2** WHEN a valid phone number is entered and "Request Collection Token" is clicked THEN it SHALL call `POST /pilot-demo/api/evidence-links/issue` with:
```json
{
  "worker_id": "worker-chunga-001",
  "msisdn": "+260971100001",
  "program_id": "PGM-ZAMBIA-GRN-001"
}
```

**1.3** WHEN the token is successfully issued THEN the result area SHALL display:
- Worker ID (e.g., "worker-chunga-001")
- Token expiry time (5 minutes from issuance)
- GPS coordinates embedded in token (e.g., "-15.4167, 28.2833")
- Max distance radius (250 meters)
- Full worker landing page URL with token in hash fragment

**1.4** WHEN the token issuance fails THEN an inline error message SHALL display the failure reason (e.g., "Worker not registered", "Invalid phone number format", "Programme not active").

**1.5** The worker landing page URL SHALL be copyable via a "Copy Link" button that copies the full URL to clipboard.

**1.6** The tab SHALL display a list of recently issued tokens (last 10) showing:
- Worker ID
- Issuance timestamp
- Expiry status (ACTIVE / EXPIRED)
- Token usage status (UNUSED / USED)

**1.7** All content SHALL fit within one viewport (no scrollbar on the main content area).

---

## Requirement 2 — Worker Registry Integration

### User Story
As a programme supervisor, I want the token issuance form to validate worker phone numbers against the registered worker list, so I can only issue tokens to authorized waste collectors.

### Acceptance Criteria

**2.1** WHEN the phone number input field loses focus THEN it SHALL call `GET /pilot-demo/api/workers/lookup?msisdn={phone}` to validate the worker exists.

**2.2** WHEN the worker is found THEN the form SHALL display:
- Worker ID (e.g., "worker-chunga-001")
- Registered GPS coordinates as neighbourhood label (e.g., "Chunga Dumpsite, Lusaka")
- Supplier type badge ("WASTE_COLLECTOR")
- Registration status (ACTIVE / INACTIVE)

**2.3** WHEN the worker is not found THEN the form SHALL display an amber warning: "Worker not registered. Contact programme administrator to register this worker."

**2.4** WHEN the worker is found but supplier_type is not "WASTE_COLLECTOR" THEN the form SHALL display a red error: "Invalid supplier type. Only WASTE_COLLECTOR can receive collection tokens."

**2.5** WHEN the worker is found but status is INACTIVE THEN the form SHALL display a red error: "Worker is inactive. Cannot issue token."

**2.6** The "Request Collection Token" button SHALL be disabled until a valid, active WASTE_COLLECTOR worker is confirmed.

---

## Requirement 3 — Token Security Display

### User Story
As a programme supervisor, I want to see the security properties of issued tokens, so I can verify that tokens are properly time-limited and GPS-bound.

### Acceptance Criteria

**3.1** WHEN a token is issued THEN the security properties panel SHALL display:
- Token type: "Evidence-Link Token (Time-Limited, GPS-Bound)"
- Cryptographic signature algorithm: "HMAC-SHA256"
- Token TTL: "5 minutes" with countdown timer
- GPS lock: Neighbourhood label (never raw coordinates)
- GPS radius: "250 meters"
- Programme scope: Programme ID

**3.2** WHEN the token expires (5 minutes elapsed) THEN the countdown timer SHALL show "EXPIRED" in red and the token URL SHALL be marked as invalid.

**3.3** WHEN the token is used (worker submits evidence) THEN the token status SHALL update to "USED" and display the submission timestamp.

**3.4** The security properties panel SHALL include a warning: "⚠ Token is single-use. After first submission, token becomes invalid."

---

## Requirement 4 — Bulk Token Issuance (Optional)

### User Story
As a programme supervisor, I want to issue tokens to multiple workers at once, so I can prepare for a scheduled collection day without issuing tokens one by one.

### Acceptance Criteria

**4.1** WHEN the "Bulk Issue" button is clicked THEN a modal SHALL appear with:
- Textarea for comma-separated phone numbers
- "Issue All Tokens" button
- Progress indicator

**4.2** WHEN "Issue All Tokens" is clicked THEN it SHALL call `POST /pilot-demo/api/evidence-links/issue` for each phone number sequentially.

**4.3** WHEN all tokens are issued THEN a summary SHALL display:
- Total requested: N
- Successfully issued: M
- Failed: N - M
- Download link for CSV file with all issued token URLs

**4.4** WHEN any token issuance fails THEN the failure SHALL be logged in the summary with the phone number and error reason.

---

## Requirement 5 — Token Revocation

### User Story
As a programme supervisor, I want to revoke an issued token before it expires, so I can prevent misuse if a worker's phone is lost or stolen.

### Acceptance Criteria

**5.1** WHEN a token in the recent tokens list is clicked THEN a detail panel SHALL appear with a "Revoke Token" button.

**5.2** WHEN "Revoke Token" is clicked THEN a confirmation dialog SHALL appear: "Revoke token for {worker_id}? This action cannot be undone."

**5.3** WHEN revocation is confirmed THEN it SHALL call `DELETE /pilot-demo/api/evidence-links/revoke/{token_id}` and update the token status to "REVOKED".

**5.4** WHEN a revoked token is used THEN the worker landing page SHALL display: "Token has been revoked. Contact your supervisor for a new token."

**5.5** Revoked tokens SHALL remain in the recent tokens list with status "REVOKED" and a red badge.

---

## Requirement 6 — End-to-End Verification

### User Story
As a technical lead, I want a self-test that confirms the token issuance → worker submission → supervisory reveal cycle works correctly.

### Acceptance Criteria

**6.1** A self-test script SHALL issue a token via the API, verify HTTP 200, then use the token to submit a WEIGHBRIDGE_RECORD, then verify the submission appears in the supervisory reveal endpoint.

**6.2** The test SHALL confirm the token expires after 5 minutes by attempting to use an expired token and verifying HTTP 401 or 403.

**6.3** The test SHALL confirm the token is single-use by attempting to use the same token twice and verifying the second attempt fails.

**6.4** The test SHALL confirm GPS validation by submitting with coordinates outside the 250m radius and verifying rejection.

**6.5** The test SHALL exit 0 only when all four checks pass: token issued, submission accepted, expiry enforced, single-use enforced, GPS validated.
