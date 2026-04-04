# Symphony Pilot-Demo Video Script

## Overview

This document provides a comprehensive walkthrough of the Symphony pilot-demo for video demonstration purposes. It covers the complete end-to-end functionality across all demo scenarios.

**Demo Duration**: 15-20 minutes  
**Target Audience**: Stakeholders, investors, integration partners, regulators  
**Demo Profile**: `pilot-demo` (Phase 1)

---

## Demo Narrative Arc

The demo tells the story of **evidence-backed green finance disbursement** through three interconnected scenarios:

1. **Onboarding & Provisioning** - Setting up a green finance programme
2. **PWRM0001 Waste Collection** - Field workers submitting evidence
3. **Supervisory Oversight** - Operators monitoring and reporting

**Key Message**: Symphony provides non-custodial, evidence-backed control for green finance disbursements without holding funds or requiring regulatory licensing.

---

## Pre-Demo Setup (Off-Camera)

### Environment Preparation

```bash
# 1. Start backend service
cd services/ledger-api/dotnet
dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj

# 2. Start frontend server (separate terminal)
cd src
python3 -m http.server 8080

# 3. Verify services
curl http://localhost:5000/health
curl http://localhost:8080/supervisory-dashboard/
```

### Browser Setup

- Open Chrome/Firefox in incognito mode (clean state)
- Navigate to: `http://localhost:8080/supervisory-dashboard/`
- Verify dashboard loads
- Have worker landing page ready in second tab: `http://localhost:8080/recipient-landing/`

### Screen Recording Settings

- Resolution: 1920x1080 minimum
- Frame rate: 30fps
- Capture browser window only (hide OS chrome)
- Enable cursor highlighting
- Prepare smooth transitions between tabs

---

## Act 1: Introduction & Onboarding (3-4 minutes)

### Scene 1.1: Opening Statement

**[Camera on Supervisory Dashboard - Overview]**

> "Welcome to Symphony, a non-custodial evidence and control layer for green finance disbursements. Today we'll demonstrate how Symphony enables transparent, auditable, and evidence-backed financing for climate projects—without holding funds or requiring payment licenses."

**Visual**: Dashboard showing empty state with "0 tenants" and "0 programmes"

**Key Points to Emphasize**:
- Non-custodial architecture (no funds held)
- Evidence-first approach (proof before payment)
- Regulatory compliance by design

### Scene 1.2: Tenant Onboarding

**[Navigate to Onboarding Tab]**

> "Let's start by onboarding a financial institution. In this demo, we're working with Zambia Green MFI, a microfinance institution focused on waste management and circular economy projects."

**Actions**:
1. Click "Onboarding" tab
2. Show empty tenant registry
3. Click "Seed Demo Tenant" button

**Visual**: Watch as system creates:
- Tenant: `Zambia Green MFI`
- Programme: `PGM-ZAMBIA-GRN-001`
- Policy binding: `green_eq_v1`
- Status changes: CREATED → ACTIVE

**Narration**:
> "Symphony provisions the tenant, creates a programme for plastic waste collection at Chunga Dumpsite in Lusaka, and binds the green equipment policy. The programme is now active and ready to accept evidence submissions."

**Pause on**: Onboarding status showing:
- Active Tenants: 1
- Active Programmes: 1
- Bound Policies: 1

### Scene 1.3: Programme Overview

**[Navigate to Supervisory Dashboard Tab]**

> "Now let's look at the programme dashboard. This is where operators monitor evidence submissions, track completeness, and generate reports."

**Visual**: Dashboard showing:
- Programme: Chunga Dumpsite — PWRM0001 Plastic Collection
- Evidence Submissions: 0 (initially)
- Timeline Events: 0
- Exceptions: 0

**Key Points**:
- Real-time evidence tracking
- Exception monitoring
- Audit trail preservation

---

## Act 2: Field Operations - Worker Submissions (5-6 minutes)

### Scene 2.1: Worker Context

**[Switch to Worker Landing Page Tab]**

> "Now let's see the field worker experience. Waste collectors at Chunga Dumpsite use this mobile-optimized interface to submit evidence of their plastic collection activities."

**Visual**: Worker landing page showing:
- Programme: Chunga Dumpsite
- Location: Lusaka, Zambia
- Phone number input field

**Narration**:
> "Workers identify themselves using their mobile phone number. Symphony issues a time-limited, GPS-bound evidence-link token that ensures submissions are authentic and location-verified."

### Scene 2.2: First Worker Submission

**Actions**:
1. Enter phone number: `+260971100001`
2. Click "Request Collection Token"
3. Show token issuance confirmation

**Visual**: Token issued with:
- Worker ID: worker-chunga-001
- Expiry: 5 minutes
- GPS coordinates: -15.4167, 28.2833
- Max distance: 250 meters

**Narration**:
> "The token is cryptographically signed and includes the worker's registered GPS coordinates. Any submission outside the 250-meter radius will be rejected."

### Scene 2.3: Weighbridge Record Submission

**Actions**:
1. Select plastic type: `PET`
2. Enter gross weight: `12.5` kg
3. Enter tare weight: `0.1` kg
4. Net weight auto-calculates: `12.4` kg
5. Click "Submit Weighbridge Record"

**Visual**: Submission success with:
- Artifact type: WEIGHBRIDGE_RECORD
- Plastic type: PET
- Net weight: 12.4 kg (backend-computed)
- GPS match: PASS
- Sequence number: 0

**Narration**:
> "The backend recomputes the net weight from gross minus tare to eliminate browser rounding errors. GPS coordinates are captured via the Geolocation API—not EXIF metadata—ensuring authenticity. The submission is appended to the tamper-evident evidence chain."

### Scene 2.4: Second Worker Submission

**Actions**:
1. Enter phone number: `+260971100002`
2. Request token for worker-chunga-002
3. Submit weighbridge record:
   - Plastic type: `HDPE`
   - Gross: `8.2` kg
   - Tare: `0.1` kg
   - Net: `8.1` kg

**Visual**: Second submission recorded with sequence number 1

**Narration**:
> "Each submission receives a monotonically increasing sequence number. This enables 'latest wins' conflict resolution when multiple submissions exist for the same collection instruction."

### Scene 2.5: Additional Proof Types (Optional)

**[If time permits, demonstrate other proof types]**

**Actions**:
1. Submit COLLECTION_PHOTO (field photo)
2. Submit QUALITY_AUDIT_RECORD (audit documentation)
3. Submit TRANSFER_MANIFEST (offtake transfer)

**Narration**:
> "PWRM0001 requires four proof types for complete evidence: weighbridge record, collection photo, quality audit, and transfer manifest. Incomplete submissions are flagged but preserved in the audit trail."

---

## Act 3: Supervisory Oversight & Reporting (6-8 minutes)

### Scene 3.1: Evidence Tracking

**[Switch back to Supervisory Dashboard]**

**Visual**: Dashboard now shows:
- Evidence Submissions: 2
- Timeline Events: 2
- Collection Programme: Active

**Narration**:
> "Back in the supervisory dashboard, we see the evidence submissions have been recorded. Let's drill down into the details."

**Actions**:
1. Scroll to Timeline table
2. Show two instruction rows with WEIGHBRIDGE_RECORD entries

**Visual**: Timeline showing:
- CHG-2026-00001: worker-chunga-001, PET, 12.4 kg
- CHG-2026-00002: worker-chunga-002, HDPE, 8.1 kg

### Scene 3.2: Instruction Drill-Down

**Actions**:
1. Click first timeline row
2. Slide-out panel opens

**Visual**: Instruction detail showing:
- Canonical proof rows with artifact types
- Raw artifacts with GPS coordinates
- Structured payload (plastic type, weights, collector ID)
- Submission timestamps

**Narration**:
> "Each instruction has a complete audit trail. We see the canonical proof interpretation, raw artifact metadata, and structured payload data. GPS coordinates are verified against the worker's registered location. All data is append-only and tamper-evident."

**Key Points**:
- Proof status: PRESENT/MISSING/FAILED
- GPS validation results
- MSISDN submitter matching
- Sequence number for conflict resolution

### Scene 3.3: Monitoring Report Generation

**[Close drill-down panel]**

**Actions**:
1. Click "Generate PWRM0001 Monitoring Report" button
2. Wait for generation (1-2 seconds)

**Visual**: Report downloads as JSON file, summary cards appear:
- Total Collections: 2
- Total Weight: 20.5 kg (12.4 + 8.1)

**Narration**:
> "The monitoring report aggregates all collection data for the programme. Notice the total weight is exactly 20.5 kilograms—computed using decimal arithmetic to avoid floating-point errors. This report is suitable for regulatory submission and impact verification."

**Actions**:
1. Open downloaded JSON file in text editor (picture-in-picture)
2. Highlight key fields:
   - `program_id`: PGM-ZAMBIA-GRN-001
   - `total_collections`: 2
   - `complete_collections`: 0 (missing other proof types)
   - `incomplete_collections`: 2
   - `proof_completeness_rate`: 0.0
   - `plastic_totals_kg`: { PET: 12.4, HDPE: 8.1, TOTAL: 20.5 }
   - `zgft_waste_sector_alignment`: { pollution_prevention: true, circular_economy: true }

**Narration**:
> "The report includes programme-level aggregates, plastic type breakdowns, and ZGFT waste sector alignment declarations. The proof completeness rate is zero because we only submitted weighbridge records—the other three proof types are missing."

### Scene 3.4: Evidence Completeness View

**[Close JSON file, return to dashboard]**

**Actions**:
1. Scroll to Evidence Completeness card
2. Show proof type status

**Visual**: Evidence completeness showing:
- WEIGHBRIDGE_RECORD: PRESENT (2 submissions)
- COLLECTION_PHOTO: MISSING
- QUALITY_AUDIT_RECORD: MISSING
- TRANSFER_MANIFEST: MISSING

**Narration**:
> "The evidence completeness panel shows which proof types are present and which are missing. This gives operators immediate visibility into submission gaps and enables proactive follow-up with field workers."

### Scene 3.5: Exception Monitoring

**Actions**:
1. Scroll to Exception Log table
2. Show empty state (no exceptions in this demo)

**Narration**:
> "The exception log tracks policy violations, GPS mismatches, SIM-swap flags, and other anomalies. In this demo, all submissions passed validation, so the exception log is empty. In production, operators would see flagged instructions here for manual review."

### Scene 3.6: Latest-Wins Demonstration (Advanced)

**[Optional: Demonstrate conflict resolution]**

**Actions**:
1. Return to worker landing page
2. Submit another weighbridge record for CHG-2026-00001 (same instruction ID)
   - Plastic type: `PP`
   - Gross: `15.0` kg
   - Tare: `0.2` kg
   - Net: `14.8` kg
3. Return to dashboard
4. Regenerate monitoring report

**Visual**: Report now shows:
- Total Collections: 2 (still 2, not 3)
- Plastic totals: { PET: 0, HDPE: 8.1, PP: 14.8, TOTAL: 22.9 }

**Narration**:
> "Notice the total collections count is still 2, not 3. Symphony's 'latest wins' logic uses sequence numbers to resolve conflicts. The newer PP submission (sequence 2) replaced the original PET submission (sequence 0) for instruction CHG-2026-00001. This prevents double-counting while preserving the complete audit trail."

---

## Act 4: Architecture & Compliance (3-4 minutes)

### Scene 4.1: Non-Custodial Posture

**[Navigate to Pilot Success Criteria tab]**

**Visual**: Pilot success criteria panel showing:
- Technical criteria (evidence trail, GPS, tenant isolation)
- Operational criteria (proof submission, dashboard access)
- Regulatory criteria (non-custodial, no settlement claims)

**Narration**:
> "Symphony's architecture is designed for regulatory compliance from the ground up. Let's look at the pilot success criteria that validate our non-custodial posture."

**Actions**:
1. Highlight "Non-custodial posture maintained" criterion (PASS)
2. Highlight "No settlement-rail claim" criterion (PASS)

**Narration**:
> "Symphony never holds funds. We provide evidence and control, but the actual disbursement happens through licensed financial channels. This keeps us outside payment regulation while enabling transparent, auditable green finance."

### Scene 4.2: Evidence Preservation

**Actions**:
1. Scroll to "Evidence trail append-only" criterion
2. Scroll to "PII decoupled" criterion

**Narration**:
> "All evidence is append-only and tamper-evident. Personal identifiable information is decoupled from the audit trail, so evidence survives data purge requests while maintaining compliance with privacy regulations."

### Scene 4.3: Tenant Isolation

**Actions**:
1. Highlight "Tenant isolation enforced at DB layer" criterion

**Narration**:
> "Multi-tenancy is enforced at the database layer with row-level security. Cross-tenant data leakage is prevented by design, not by application logic. This is critical for financial institutions operating in regulated environments."

---

## Act 5: Closing & Next Steps (2-3 minutes)

### Scene 5.1: Demo Recap

**[Return to Supervisory Dashboard overview]**

**Visual**: Dashboard showing final state:
- Programme active
- Evidence submissions recorded
- Monitoring report generated
- Audit trail complete

**Narration**:
> "In this demo, we've seen the complete Symphony workflow: tenant onboarding, field worker evidence submission, supervisory monitoring, and regulatory reporting. All without Symphony ever holding funds or requiring payment licenses."

### Scene 5.2: Key Differentiators

**[Optional: Show comparison slide or bullet points]**

**Key Points**:
1. **Non-custodial**: No funds held, no payment license required
2. **Evidence-first**: Proof before payment, tamper-evident audit trail
3. **GPS-verified**: Geolocation API, not EXIF metadata
4. **Conflict resolution**: Latest-wins by sequence number
5. **Decimal precision**: No floating-point errors in financial calculations
6. **Multi-tenant**: Secure isolation for multiple financial institutions
7. **Regulatory-ready**: Compliance by design, not by policy

### Scene 5.3: Production Readiness

**Narration**:
> "This pilot-demo uses in-memory storage and simplified authentication for demonstration purposes. Production deployments use PostgreSQL, OAuth2, hardware security modules, and enterprise-grade monitoring. The architecture scales from pilot programmes to national-level green finance initiatives."

### Scene 5.4: Call to Action

**Narration**:
> "Symphony is open for pilot partnerships with financial institutions, impact investors, and climate project developers. We're particularly interested in waste management, renewable energy, and circular economy use cases in emerging markets."

**Visual**: Contact information or next steps slide

---

## Technical Notes for Video Production

### Camera Angles

- **Wide shot**: Full dashboard view for context
- **Medium shot**: Focus on specific panels (timeline, evidence completeness)
- **Close-up**: Drill-down details, JSON report contents
- **Picture-in-picture**: Show worker landing page while narrating dashboard

### Transitions

- Smooth tab switching (avoid jarring cuts)
- Fade between major sections (Acts 1-5)
- Highlight cursor movements for clarity
- Use zoom for small text (JSON fields, table cells)

### Pacing

- **Slow down** for complex concepts (sequence numbers, decimal arithmetic)
- **Speed up** for repetitive actions (second worker submission)
- **Pause** on key visuals (monitoring report summary, success criteria)
- **Emphasize** critical points (non-custodial, evidence-first)

### Audio

- Clear narration with minimal background noise
- Emphasize key terms: "non-custodial", "evidence-backed", "tamper-evident"
- Pause for visual absorption (1-2 seconds after showing new screen)
- Use consistent tone (professional but accessible)

### Captions

- Add text overlays for key metrics (total weight, collection count)
- Highlight important fields in JSON (plastic_totals_kg, proof_completeness_rate)
- Label tabs and panels for viewer orientation
- Use arrows or circles to draw attention

---

## Alternative Demo Scenarios

### Scenario A: Exception Handling

**Setup**: Manually seed exception log entry

**Workflow**:
1. Show exception log with SIM_SWAP_FLAG entry
2. Navigate to SIM-Swap Risk Hold tab
3. Explain policy-triggered holds vs. evidence absence
4. Demonstrate operator review workflow

**Duration**: +3 minutes

### Scenario B: Export Reporting Pack

**Setup**: Complete evidence set (all four proof types)

**Workflow**:
1. Submit all proof types for one instruction
2. Show complete_collections = 1
3. Click "Export Pack" button
4. Download JSON and PDF reports
5. Show deterministic fingerprint for audit verification

**Duration**: +2 minutes

### Scenario C: Multi-Programme Comparison

**Setup**: Create second programme with different policy

**Workflow**:
1. Create Programme B with stricter SIM-swap threshold (14 days vs. 30 days)
2. Show same supplier allowlisted in Programme A, denied in Programme B
3. Demonstrate programme-scoped policy enforcement

**Duration**: +4 minutes

---

## Post-Demo Q&A Preparation

### Common Questions

**Q: Does Symphony hold funds?**  
A: No. Symphony is non-custodial. We provide evidence and control, but disbursements happen through licensed financial channels.

**Q: What happens if GPS is unavailable?**  
A: Submissions without GPS are rejected. GPS is captured via Geolocation API at submission time, not from photo EXIF data.

**Q: How do you prevent double-counting?**  
A: Latest-wins conflict resolution using monotonic sequence numbers. Multiple submissions for the same instruction ID are deduplicated.

**Q: Is this blockchain?**  
A: No. Symphony uses append-only logs with cryptographic signatures, but not distributed ledger technology. This keeps costs low and performance high.

**Q: What about data privacy?**  
A: PII is decoupled from the audit trail. Evidence survives data purge requests while maintaining GDPR/privacy compliance.

**Q: Can this work offline?**  
A: Partial offline support is possible (queue submissions, sync later), but GPS and token validation require connectivity.

**Q: What's the cost per transaction?**  
A: Pilot-demo is free. Production pricing depends on volume, SLA, and support requirements. Contact for details.

---

## Appendix: Demo Checklist

### Pre-Recording

- [ ] Backend service running (port 5000)
- [ ] Frontend service running (port 8080)
- [ ] Browser in incognito mode
- [ ] Dashboard loads without errors
- [ ] Worker landing page accessible
- [ ] Screen recording software configured
- [ ] Audio levels tested
- [ ] Script reviewed and rehearsed

### During Recording

- [ ] Smooth cursor movements
- [ ] Clear narration (no filler words)
- [ ] Pause for visual absorption
- [ ] Highlight key fields and metrics
- [ ] Demonstrate all core workflows
- [ ] Show evidence completeness
- [ ] Generate monitoring report
- [ ] Explain non-custodial posture

### Post-Recording

- [ ] Edit for pacing and clarity
- [ ] Add captions and overlays
- [ ] Verify audio quality
- [ ] Check for visual glitches
- [ ] Add intro/outro slides
- [ ] Export in multiple formats (1080p, 720p)
- [ ] Upload to hosting platform
- [ ] Share with stakeholders

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-03  
**Maintained By**: Symphony Platform Team  
**Demo Duration**: 15-20 minutes  
**Target Audience**: Stakeholders, investors, partners, regulators
