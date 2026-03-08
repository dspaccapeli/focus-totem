# TODO

## Pre-Launch UX Review

### How To Read This Plan

- **Gate** = a required checkpoint that must be true before dependent work starts.
- **Workstream** = a parallelizable track of implementation tasks.
- Each item includes `depends_on` for sequencing clarity.

---

### Plan Table

| ID | Type | Task | depends_on | Status |
|---|---|---|---|---|
| G1 | Gate | Lock readiness model + onboarding completion rules | - | pending |
| W1 | Workstream | Home prerequisite recovery CTAs | G1 | pending |
| W2 | Workstream | Totem capture/verification UX feedback | G1 | pending |
| W3 | Workstream | Home primary action hierarchy | G1, W1 | pending |
| G2 | Gate | Lock blocking-state contract + unblock rules | G1 | pending |
| W4 | Workstream | In-session emergency unblock shortcut | G2 | pending |
| W5 | Workstream | Copy/naming consistency pass | W1, W2, W3, W4 | pending |
| W6 | Workstream | Final onboarding recap screen | G1, W5 | pending |

---

### Detailed Tasks

#### G1 - Lock Readiness Model + Onboarding Completion Rules
- [ ] Define canonical `readyToFocus` state (single source of truth)
- [ ] Require Screen Time permission approved before onboarding completion
- [ ] Require at least one app/category selected before onboarding completion
- [ ] Disable final completion CTA until required conditions are met
- [ ] Replace dots with `Step X of Y` + named milestones tied to real requirements
- [ ] Add inline "what is missing" guidance

**Exit criteria**
- [ ] User cannot finish onboarding unless fully ready to start focus
- [ ] Progress UI reflects required outcomes, not just screen count

---

#### W1 - Home Prerequisite Recovery CTAs (`depends_on: G1`)
- [ ] In "No Active Totem" state, add `Register Totem` CTA
- [ ] In missing Screen Time state, add `Allow Screen Time` CTA
- [ ] In no-app-selection state, add `Select Apps` CTA
- [ ] Ensure each CTA routes directly to completion path (no dead ends)

**Exit criteria**
- [ ] Every prerequisite failure state has a direct, one-tap recovery action

---

#### W2 - Totem Capture/Verification UX Feedback (`depends_on: G1`)
- [ ] Show persistent failure text when verification does not pass
- [ ] Add actionable guidance (distance, angle changes, lighting, glare)
- [ ] Keep help visible until user corrects the issue
- [ ] Confirm guidance does not conflict with capture flow

**Exit criteria**
- [ ] Failure states are actionable without guessing

---

#### W3 - Home Primary Action Hierarchy (`depends_on: G1, W1`)
- [ ] Set one dominant idle-state CTA: `Scan to Start Focus`
- [ ] Keep long-press as secondary/manual fallback
- [ ] Align visual hierarchy and copy with primary vs secondary intent

**Exit criteria**
- [ ] New users can identify the primary action in <3 seconds

---

#### G2 - Lock Blocking-State Contract + Unblock Rules (`depends_on: G1`)
- [ ] Validate `isBlocking` transition rules (start/stop + confirmation points)
- [ ] Validate emergency unblock quota behavior + messaging contract
- [ ] Confirm blocking state availability for UI shortcut logic

**Exit criteria**
- [ ] Blocking/unblocking behavior is stable and predictable for dependent UI

---

#### W4 - In-Session Emergency Unblock Shortcut (`depends_on: G2`)
- [ ] Show shortcut only while blocking is active
- [ ] Keep confirmation dialog before unblock action
- [ ] Preserve remaining-unblocks count and feedback
- [ ] Ensure shortcut does not bypass safety constraints

**Exit criteria**
- [ ] Emergency unblock is fast to access during blocking, with safeguards intact

---

#### W5 - Copy/Naming Consistency Pass (`depends_on: W1, W2, W3, W4`)
- [ ] Standardize product name to `Focus Totem`
- [ ] Standardize key terms: `totem`, `focus session`, `block/unblock`
- [ ] Remove legacy/inconsistent wording across onboarding/home/settings/alerts

**Exit criteria**
- [ ] Terminology is consistent and trust-building across all touchpoints

---

#### W6 - Final Onboarding Recap Screen (`depends_on: G1, W5`)
- [ ] Add readiness checklist summary (totem saved, permission granted, apps selected)
- [ ] Keep reminders optional
- [ ] Add final CTA: `Start Focusing`

**Exit criteria**
- [ ] User exits onboarding with clear confidence that setup is complete

---

### Parallel Execution Guidance

After **G1** is complete:
- Run **W1** and **W2** in parallel.
- Start **W3** once W1 is far enough to confirm final CTA destinations.
- Run **G2** once blocking-state behavior is stable.
- Start **W4** immediately after G2 (does not need W2/W3 to finish).
- Finish with **W5**, then **W6**.

---

### Definition of Done (Global)

- [ ] First-time user can complete setup and start focus without going into Settings
- [ ] Onboarding completion is impossible unless core setup is truly complete
- [ ] Every failure state has a direct recovery path
- [ ] Emergency unblock is accessible during blocking with guardrails
- [ ] Language is consistent across the full journey
