# ESS RAP Phase 1 — Implementation Plan

**Status:** Ready for confirmation before coding  
**Created:** 2026-08-31  
**Target:** Requestor application (Create → Submit → Track → Return/Rework)

---

## Phase 1 Overview

Building a complete ESS Loan Request application with:
- 13 DDIC tables (tenant-aware)
- 6 utility classes + 1 static helper
- 1 RAP Managed BO with child entities & actions
- Fiori List Report + Object Page UI
- Multi-client support built-in

**Expected Output:** Single repository with all ABAP objects & Fiori UI

---

## Stage 1: DDIC Foundation (Tables, Domains, Structures)

### Step 1.1: Create Domains
**Objective:** Define all domain types used across tables

**Deliverables:**
- Domain: ZESS_REQ_STATUS (values: D, S, A, R, P, J, W)
- Domain: ZESS_APPR_STATUS (values: P, A, J, R, S, E, D)
- Domain: ZESS_FIELD_TYPE (values: T, A, D, S, C)
- Domain: ZESS_MSG_TYPE (values: E, W, I)
- Domain: ZESS_LOAN_PURPOSE (values: S, B, E, O)
- Domain: ZESS_ITEM_TYPE (values: customizable per client)

**Checks:**
- [ ] All domains created in SE11
- [ ] Value texts match specification
- [ ] No circular dependencies

**Estimated Effort:** 30 mins

---

### Step 1.2: Create Data Types (Structures)
**Objective:** Define reusable structures used in multiple places

**Deliverables:**
- Structure: ZESS_EMPLOYEE_PERSONAL_INFO
- Structure: ZESS_VALIDATION_MESSAGE
- Structure: ZESS_APPROVAL_STEP_VIEW
- Structure: ZESS_LOAN_DETAIL_VIEW
- Any other supporting structures per spec

**Checks:**
- [ ] All structures match DDIC spec
- [ ] Field types correct (NUMC, DATS, DEC, STRING, etc.)
- [ ] Field lengths match spec
- [ ] Compilation successful

**Estimated Effort:** 45 mins

---

### Step 1.3: Create DDIC Tables (13 Tables)
**Objective:** Build all persistent entities

**Deliverables:**
```
Core Tables:
  1. ZESS_CLIENT (tenant master)
  2. ZESS_SERVICE (loan type catalog)
  3. ZESS_REQ_HEAD (request header)
  4. ZESS_REQ_ITEM (request items)
  5. ZESS_LOAN_PERSONAL (loan details)
  6. ZESS_APPR_STEP (approval timeline)

Configuration Tables:
  7. ZESS_WF_CONFIG (approval matrix)
  8. ZESS_LOAN_PARAM (eligibility config)
  9. ZESS_INT_RATE (interest rates)

Customization Tables:
 10. ZESS_CUST_FIELD (custom fields config)
 11. ZESS_LOAN_PERSONAL_CUSTOM (custom field values)
 12. ZESS_VALIDATION_MSG (validation messages)

Audit:
 13. ZESS_CHANGE_LOG (audit trail)
```

**Checks:**
- [ ] All 13 tables created
- [ ] Primary keys match spec
- [ ] Indexes created per spec
- [ ] Foreign keys defined (where needed)
- [ ] Field types & lengths verified
- [ ] Audit fields (created_on, created_by, changed_on, changed_by) present where spec'd
- [ ] All tables allow SE11 transport
- [ ] No compilation errors

**Estimated Effort:** 2 hours

---

### Step 1.4: Load Master Data
**Objective:** Populate reference tables with test data

**Deliverables:**
- ZESS_CLIENT: 1 test client (client_id='100')
- ZESS_SERVICE: 1 loan type (PERSLOAN)
- ZESS_LOAN_PARAM: Eligibility rules for PERSLOAN
- ZESS_INT_RATE: Sample rate (8.5%)
- ZESS_WF_CONFIG: 3-level approval chain
- ZESS_VALIDATION_MSG: All validation message IDs

**Checks:**
- [ ] Master data loaded (via SE16 or program)
- [ ] No constraint violations
- [ ] Data matches test scenarios

**Estimated Effort:** 45 mins

---

## Stage 2: Service Layer (Interfaces & Utility Classes)

### Step 2.1: Create Interfaces (6 Interfaces)
**Objective:** Define all service contracts

**Deliverables:**
1. ZIF_ESS_EMPLOYEE_PROVIDER
   - Methods: get_employee_data(), get_employee_contact_info()
   
2. ZIF_ESS_VALIDATION_ENGINE
   - Methods: validate_eligibility(), validate_request_integrity()
   
3. ZIF_ESS_LOAN_VALIDATOR
   - Methods: validate_personal_loan()
   
4. ZIF_ESS_METADATA_PROVIDER
   - Methods: get_validation_messages(), get_loan_params(), get_custom_fields()
   
5. ZIF_ESS_WORKFLOW_ENGINE
   - Methods: resolve_approval_chain(), get_approver_by_relationship()
   
6. ZIF_ESS_NOTIFICATION_HANDLER
   - Methods: send_request_confirmation(), send_approval_notification()

**Checks:**
- [ ] All 6 interfaces created
- [ ] Method signatures match design
- [ ] No compilation errors
- [ ] Interfaces are draft/ready to implement

**Estimated Effort:** 1 hour

---

### Step 2.2: Create Utility Classes (7 Classes)
**Objective:** Implement service layer with business logic

**Deliverables:**
1. ZCL_ESS_EMPLOYEE_PROVIDER_HCM
   - Read PA0000, PA0001, PA0008, PA0006, IT0006, HRP1001
   - Dual-source email logic (IT0006 → PA0006)
   
2. ZCL_ESS_VALIDATION_ENGINE
   - Retrieve messages from ZESS_VALIDATION_MSG
   - Format with parameters
   - Classify as ERROR/WARNING/INFO
   
3. ZCL_ESS_LOAN_VALIDATOR_PERSONAL
   - Amount checks (min/max, salary cap)
   - Tenure checks
   - Concurrent loan checks
   
4. ZCL_ESS_METADATA_PROVIDER
   - Read ZESS_LOAN_PARAM, ZESS_INT_RATE, ZESS_CUST_FIELD, ZESS_VALIDATION_MSG
   - Cache where appropriate
   
5. ZCL_ESS_WORKFLOW_ENGINE
   - Read ZESS_WF_CONFIG
   - Resolve approval chain per amount bracket
   - Get approver by relationship (A002, A006, etc.)
   - Fallback to hardcoded pernr
   
6. ZCL_ESS_NOTIFICATION_HANDLER_SMTP
   - Send emails to requestor & approvers
   - Use simple SMTP
   
7. ZCL_ESS_UTILITY (static methods)
   - get_pernr_for_user()
   - calculate_emi()
   - get_next_request_id()
   - get_currency_for_cc()
   - Others per design

**Checks:**
- [ ] All 7 classes created & tested
- [ ] All interfaces implemented
- [ ] Unit tests for critical logic (validation, approval chain, EMI calculation)
- [ ] No runtime errors
- [ ] Methods follow naming conventions

**Estimated Effort:** 4 hours (with unit testing)

---

## Stage 3: RAP Business Object

### Step 3.1: Create CDS Views & Annotations
**Objective:** Define RAP BO structure with all entities

**Deliverables:**
1. **Root Entity:** Z_ESS_LOAN_REQUEST
   - Base on ZESS_REQ_HEAD
   - CUD enabled (Create, Update, Delete)
   - Fiori object page annotations
   
2. **Child Entities:**
   - Z_ESS_LOAN_REQUEST_ITEM (ZESS_REQ_ITEM, CUD)
   - Z_ESS_LOAN_REQUEST_DETAILS (ZESS_LOAN_PERSONAL, CUD)
   - Z_ESS_LOAN_APPROVAL_STEPS (ZESS_APPR_STEP, Read-only)

3. **Projections:**
   - ZP_ESS_LOAN_REQUEST (with navigation links)
   - UI annotations (list, object page, field controls)

**Checks:**
- [ ] All CDS views created
- [ ] Annotations complete & correct
- [ ] Field controls set per status (editable in Draft/Returned, read-only after Submit)
- [ ] No compilation errors

**Estimated Effort:** 2 hours

---

### Step 3.2: Create Determinations & Validations
**Objective:** Implement business logic in RAP actions & events

**Deliverables:**
1. **Determinations:**
   - resolveEmployeeData() — on Create, fetch HR data
   - calcEMISchedule() — on amount/tenure change, calculate EMI
   - resolveApprovalChain() — on Submit, resolve chain & create APPR_STEP rows
   
2. **Validations:**
   - validateEmployeeEligibility() — active, not suspended, tenure, etc.
   - validateRequestIntegrity() — mandatory fields, amounts, etc.
   - validateNoExistingLoan() — same type doesn't exist
   
3. **Actions:**
   - submit() — change status to Submitted, lock request
   - withdraw() — set status to Withdrawn (draft only)
   - delete() — delete draft (on delete interaction)

**Checks:**
- [ ] All determinations implemented
- [ ] All validations implemented
- [ ] All actions callable
- [ ] No runtime errors when triggered

**Estimated Effort:** 3 hours

---

### Step 3.3: Create Behaviors (BDEF)
**Objective:** Wire all determinations, validations, actions

**Deliverables:**
- z_ess_loan_request_bdef.xml (or .bdef file)
- All child entities linked
- All actions, determinations, validations wired
- Instance authorization (requestor only sees own)

**Checks:**
- [ ] BDEF syntax correct
- [ ] All determinations/validations registered
- [ ] All actions callable
- [ ] Behavior compilation successful

**Estimated Effort:** 1 hour

---

## Stage 4: Fiori UI

### Step 4.1: Create List Report
**Objective:** Dashboard showing all user's loan requests

**Deliverables:**
- Fiori List Report app
- Columns: Request ID, Amount, Status, Submit Date, Current Approver
- Filters: Status, Date Range, Amount Range
- "Create New" action (custom action)
- Quick links to Object Page

**Checks:**
- [ ] App loads without errors
- [ ] List displays sample data
- [ ] Filters work
- [ ] Create action launches Object Page
- [ ] Click to row opens Object Page

**Estimated Effort:** 2 hours

---

### Step 4.2: Create Object Page
**Objective:** Full request form for requestor

**Deliverables:**
- Fiori Object Page app
- Sections:
  - Request Info (ID, Status, Submit Date)
  - Employee Info (Name, Email, Salary, Tenure)
  - Loan Details (Amount, Tenure, EMI, Purpose, Remarks)
  - Dynamic Custom Fields (rendered per ZESS_CUST_FIELD)
  - Request Items (read-only list)
  - Approval Timeline (read-only, tabular, showing all levels & comments)
  
- Actions:
  - Save (draft only)
  - Submit (with confirmation dialog showing validations)
  - Withdraw (with confirmation)
  - Edit (draft/returned only)

**Checks:**
- [ ] Page loads
- [ ] All sections render
- [ ] Dynamic fields load from metadata
- [ ] Approval timeline shows correctly
- [ ] Actions callable & confirmations appear
- [ ] Validations trigger on Submit
- [ ] Error/Warning messages display

**Estimated Effort:** 4 hours

---

### Step 4.3: Confirmation Dialogs & Validation Display
**Objective:** UX for validation feedback

**Deliverables:**
- Confirmation dialog on Create (early validation)
- Confirmation dialog on Submit (pre-submit validation)
  - Structure: [Validation Section] + [Action Details] + [Proceed/Cancel]
  - Messages from ZESS_VALIDATION_MSG
  - Errors block proceed, warnings allow
- Real-time validation as user types
- Inline error messages on fields

**Checks:**
- [ ] Early validation triggers on Create
- [ ] Submit confirmation shows all validations
- [ ] Messages format correctly with params
- [ ] Dialog logic (block on error, allow on warning) works
- [ ] Real-time validation responsive

**Estimated Effort:** 2 hours

---

## Stage 5: Testing & Documentation

### Step 5.1: Unit Tests
**Objective:** Verify all utility classes work

**Deliverables:**
- Unit tests for:
  - ZCL_ESS_VALIDATION_ENGINE (message formatting, classification)
  - ZCL_ESS_WORKFLOW_ENGINE (approval chain resolution, bracket matching)
  - ZCL_ESS_LOAN_VALIDATOR_PERSONAL (amount/tenure checks, concurrency)
  - ZCL_ESS_UTILITY (EMI calculation, request ID generation)

**Checks:**
- [ ] All tests pass
- [ ] Coverage >80% on critical paths
- [ ] Edge cases tested (empty config, no approver, multiple brackets)

**Estimated Effort:** 2 hours

---

### Step 5.2: Integration Tests
**Objective:** Test end-to-end flows

**Scenarios:**
1. Create request → validate → save as draft
2. Draft → submit → approval chain created
3. Approval chain returned → edit & resubmit → attempt++ (new rows)
4. Submit with validations (warnings only) → proceed
5. Concurrent loan prevention

**Checks:**
- [ ] All scenarios pass
- [ ] No data corruption
- [ ] Audit trail complete
- [ ] Dynamic fields working

**Estimated Effort:** 2 hours

---

### Step 5.3: Documentation
**Objective:** Record decisions & known issues

**Deliverables:**
- Repository README (setup, deployment, testing)
- Architecture overview (ER diagram, data flows)
- Bug/Issue log (any issues found & resolutions)
- Continuation notes for Phase 2

**Checks:**
- [ ] README complete
- [ ] Bug log documented
- [ ] All decisions recorded

**Estimated Effort:** 1 hour

---

## Bug & Issue Log Template

A **BUGS_AND_ISSUES.md** file will be created in the repository to track:

```markdown
# Phase 1 — Bugs & Issues Log

## Issue Template

### Issue #001: [Title]
- **Date Found:** YYYY-MM-DD
- **Component:** (DDIC/Utility/RAP/UI)
- **Severity:** (Critical/High/Medium/Low)
- **Description:** What went wrong
- **Root Cause:** Why it happened
- **Resolution:** How it was fixed
- **Test Case:** How to reproduce & verify fix
- **Related Code:** File/line references
- **Lesson Learned:** What to avoid next time

---
```

---

## Summary: Total Effort & Dependencies

| Stage | Steps | Duration | Dependencies |
|---|---|---|---|
| 1: DDIC | 4 steps | ~4 hrs | None |
| 2: Service | 2 steps | ~5 hrs | Stage 1 complete |
| 3: RAP BO | 3 steps | ~6 hrs | Stages 1 & 2 complete |
| 4: Fiori UI | 3 steps | ~8 hrs | Stages 1, 2, 3 complete |
| 5: Testing & Docs | 3 steps | ~5 hrs | Stages 1-4 complete |
| **TOTAL** | **15 steps** | **~28 hrs** | Sequential |

---

## Next Actions

1. **Confirm this plan:** Do you agree with the steps & effort?
2. **Confirm repository structure:** Where should the project live? (GitHub, ADO, local SAP package?)
3. **Confirm test data:** Which HR scenarios should we test with?
4. **Start Stage 1.1:** Create domains in SE11 once you confirm

**Ready to proceed?**
