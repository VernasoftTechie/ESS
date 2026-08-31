# Master Data Load Template — Phase 1

**Package:** ZHR_ESS_V1  
**Status:** Ready to load after DDIC tables created  
**Date:** 2026-08-31

---

## Overview

After all 13 DDIC tables are created and activated, master data will be loaded via:
- **SE16** (Direct table maintenance) for small datasets
- **SE16N** (Enhanced table maintenance) for larger datasets
- **Report ZHR_ESS_MASTER_DATA_LOAD** (custom ABAP program) for bulk load

---

## Master Data Load Sequence

**Order (Dependency-based):**

1. **ZHR_ESS_CLIENT** ← Must exist first (all others FK to this)
2. **ZHR_ESS_SERVICE** ← Loan type catalog
3. **ZHR_ESS_INT_RATE** ← Interest rates
4. **ZHR_ESS_LOAN_PARAM** ← Eligibility rules
5. **ZHR_ESS_WF_CONFIG** ← Approval matrix
6. **ZHR_ESS_VALIDATION_MSG** ← Validation messages
7. **ZHR_ESS_CUST_FIELD** ← Custom fields config (optional for Phase 1)
8. **ZHR_ESS_REQ_HEAD** ← Request headers (will be populated via RAP UI)
9. Other transactional tables ← Auto-populated via RAP actions

---

## TABLE 1: ZHR_ESS_CLIENT

**Transaction:** SE16 → ZHR_ESS_CLIENT → Create Entry (or SE16N)

**Test Data (Phase 1):**

```
Row 1:
  client_id:      100
  client_name:    Test Corporation
  company_code:   1000
  hcm_system:     001
  active:         Y
  created_on:     2026-08-31 08:00:00
  created_by:     <YOUR_USER_ID>
```

**Additional Clients (Optional):**
```
Row 2 (for testing isolation):
  client_id:      200
  client_name:    Partner Organization
  company_code:   2000
  hcm_system:     002
  active:         Y
```

**Load Method:** SE16 Manual Entry (1-2 rows)

---

## TABLE 2: ZHR_ESS_SERVICE

**Transaction:** SE16 → ZHR_ESS_SERVICE → Create Entries

**Test Data (Phase 1):**

```
Row 1 (PERSLOAN — Personal Loan):
  client_id:          100
  service_code:       PERSLOAN
  description:        Personal Loan
  icon_name:          sap-icon://loan
  sequence:           100
  remarks_mandatory:  N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)

Row 2 (CONVLOAN — Conveyance Loan - Future):
  client_id:          100
  service_code:       CONVLOAN
  description:        Conveyance Loan
  icon_name:          sap-icon://vehicle-car
  sequence:           200
  remarks_mandatory:  N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)

Row 3 (HOUSLOAN — Housing Loan - Future):
  client_id:          100
  service_code:       HOUSLOAN
  description:        Housing Loan
  icon_name:          sap-icon://home
  sequence:           300
  remarks_mandatory:  N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)
```

**Load Method:** SE16 or SE16N (3 rows)

---

## TABLE 3: ZHR_ESS_INT_RATE

**Transaction:** SE16 → ZHR_ESS_INT_RATE → Create Entries

**Test Data (Phase 1):**

```
Row 1:
  client_id:      100
  loan_type:      PERSLOAN
  effective_date: 20260801
  rate_percent:   8.50
  active:         Y

Row 2 (Future rate, effective Sept 1):
  client_id:      100
  loan_type:      PERSLOAN
  effective_date: 20260901
  rate_percent:   8.75
  active:         Y

Row 3 (CONVLOAN rate - future):
  client_id:      100
  loan_type:      CONVLOAN
  effective_date: 20260801
  rate_percent:   6.50
  active:         Y
```

**Load Method:** SE16 or SE16N (3 rows)

---

## TABLE 4: ZHR_ESS_LOAN_PARAM

**Transaction:** SE16 → ZHR_ESS_LOAN_PARAM → Create Entries

**Test Data (Phase 1):**

```
Row 1 (PERSLOAN - Personal Loan):
  client_id:                  100
  loan_type:                  PERSLOAN
  min_amount:                 50000.00
  max_amount:                 2500000.00
  max_tenure_months:          60
  min_tenure_months:          12
  salary_multiple:            5.00
  min_service_days:           365
  allow_during_probation:     N
  allow_contract_employees:   Y
  active:                     Y
  effective_from:             20260801
  effective_to:               (NULL)

Row 2 (CONVLOAN - Future):
  client_id:                  100
  loan_type:                  CONVLOAN
  min_amount:                 500000.00
  max_amount:                 5000000.00
  max_tenure_months:          120
  min_tenure_months:          24
  salary_multiple:            8.00
  min_service_days:           730
  allow_during_probation:     N
  allow_contract_employees:   N
  active:                     Y
  effective_from:             20260801
  effective_to:               (NULL)
```

**Load Method:** SE16 or SE16N (2 rows)

---

## TABLE 5: ZHR_ESS_WF_CONFIG

**Transaction:** SE16 → ZHR_ESS_WF_CONFIG → Create Entries

**Test Data (Phase 1 - 3-Level Approval Chain):**

```
Row 1 (Level 1 - Amount: 0 to 500K):
  client_id:          100
  loan_type:          PERSLOAN
  level:              1
  relationship_id:    A002            (Reports-to)
  fallback_pernr:     00000001        (default manager)
  amount_from:        0.00
  amount_to:          500000.00
  default_sla_days:   5
  parallel_level:     N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)
  created_on:         2026-08-31 08:00:00
  created_by:         <YOUR_USER_ID>

Row 2 (Level 2 - Amount: 500K to 2M):
  client_id:          100
  loan_type:          PERSLOAN
  level:              2
  relationship_id:    A006            (Cost Center Manager)
  fallback_pernr:     00000002        (cost center mgr fallback)
  amount_from:        500000.00
  amount_to:          2000000.00
  default_sla_days:   7
  parallel_level:     N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)
  created_on:         2026-08-31 08:00:00
  created_by:         <YOUR_USER_ID>

Row 3 (Level 3 - Amount: 2M to unlimited):
  client_id:          100
  loan_type:          PERSLOAN
  level:              3
  relationship_id:    HR              (HR Department)
  fallback_pernr:     00000003        (HR head/CFO)
  amount_from:        2000000.00
  amount_to:          99999999.99
  default_sla_days:   10
  parallel_level:     N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)
  created_on:         2026-08-31 08:00:00
  created_by:         <YOUR_USER_ID>

Row 4 (Level 1 - CONVLOAN - Future):
  client_id:          100
  loan_type:          CONVLOAN
  level:              1
  relationship_id:    A002
  fallback_pernr:     00000001
  amount_from:        0.00
  amount_to:          2000000.00
  default_sla_days:   5
  parallel_level:     N
  active:             Y
  effective_from:     20260801
  effective_to:       (NULL)
```

**Notes:**
- relationship_id is **flexible** — you can maintain custom values (A002, A006, HR, Finance, Custom_ID, etc.)
- fallback_pernr is **mandatory** — if relationship doesn't resolve, use this
- amount_from/amount_to define brackets (non-overlapping recommended)
- Phase 1: 3-level chain per loan type
- Future: Add parallel_level=Y for parallel approvals

**Load Method:** SE16 or SE16N (4 rows)

---

## TABLE 6: ZHR_ESS_VALIDATION_MSG

**Transaction:** SE16 → ZHR_ESS_VALIDATION_MSG → Create Entries

**Test Data (Phase 1 - Sample Validation Messages):**

```
Row 1 (Employee not active):
  client_id:      100
  msg_id:         ESS_EMP_INACTIVE
  msg_type:       E               (Error)
  msg_text:       Employee is not active
  msg_detail:     Your employee record is marked as inactive. Contact HR.
  msg_params:     (NULL)
  active:         Y

Row 2 (Tenure too short):
  client_id:      100
  msg_id:         ESS_TENURE_SHORT
  msg_type:       E
  msg_text:       Tenure too short
  msg_detail:     You have {TENURE_DAYS} days. Minimum required: {MIN_DAYS}. You will be eligible from {ELIGIBLE_DATE}.
  msg_params:     TENURE_DAYS,MIN_DAYS,ELIGIBLE_DATE
  active:         Y

Row 3 (Loan amount exceeds cap):
  client_id:      100
  msg_id:         ESS_AMT_EXCEEDS_CAP
  msg_type:       W               (Warning)
  msg_text:       Requested amount exceeds salary multiple
  msg_detail:     Requested {AMOUNT}. Your salary cap is {CAP_AMOUNT}. This may require additional approvals.
  msg_params:     AMOUNT,CAP_AMOUNT
  active:         Y

Row 4 (Existing loan of same type):
  client_id:      100
  msg_id:         ESS_EXISTING_LOAN
  msg_type:       E
  msg_text:       You already have an active personal loan
  msg_detail:     Request ID: {REQUEST_ID}. You can only have one personal loan at a time.
  msg_params:     REQUEST_ID
  active:         Y

Row 5 (Employee suspended):
  client_id:      100
  msg_id:         ESS_EMP_SUSPENDED
  msg_type:       E
  msg_text:       Employee is suspended from duty
  msg_detail:     Your access to loan services is suspended. Contact HR for details.
  msg_params:     (NULL)
  active:         Y

Row 6 (Info - loan approved):
  client_id:      100
  msg_id:         ESS_LOAN_APPROVED
  msg_type:       I               (Info)
  msg_text:       Your loan has been approved
  msg_detail:     Request ID: {REQUEST_ID}. Amount approved: {AMOUNT}. You will receive further instructions via email.
  msg_params:     REQUEST_ID,AMOUNT
  active:         Y

Row 7 (Warning - no remarks):
  client_id:      100
  msg_id:         ESS_NO_REMARKS
  msg_type:       W
  msg_text:       No remarks provided
  msg_detail:     You may want to provide remarks about your loan request purpose.
  msg_params:     (NULL)
  active:         Y
```

**Load Method:** SE16 or SE16N (7 rows)

**Note:** Add more messages as validations are discovered during testing.

---

## TABLE 7: ZHR_ESS_CUST_FIELD (Optional for Phase 1)

**Transaction:** SE16 → ZHR_ESS_CUST_FIELD → Create Entries

**Test Data (Phase 1 - Optional, skip if not needed yet):**

```
Row 1 (Custom field for PERSLOAN):
  client_id:          100
  loan_type:          PERSLOAN
  field_key:          PURPOSE_DETAIL
  field_label:        Detailed Purpose
  field_type:         T               (Text)
  mandatory:          N
  field_order:        100
  field_length:       500
  dropdown_domain:    (NULL)
  help_text:          Provide detailed reason for loan request
  validation_regex:   (NULL)
  active:             Y

Row 2 (Custom field - Dropdown):
  client_id:          100
  loan_type:          PERSLOAN
  field_key:          COLLATERAL_TYPE
  field_label:        Collateral Type
  field_type:         S               (Dropdown)
  mandatory:          N
  field_order:        200
  field_length:       0
  dropdown_domain:    ZHR_ESS_COLLATERAL_TYPE
  help_text:          Select collateral type if applicable
  validation_regex:   (NULL)
  active:             Y
```

**Load Method:** SE16 (optional, can be loaded during Phase 2)

---

## Transactional Tables (Auto-Populated)

**These tables are populated via RAP actions, NOT manually:**

- ZHR_ESS_REQ_HEAD — Created when user submits request
- ZHR_ESS_REQ_ITEM — Created for request items
- ZHR_ESS_LOAN_PERSONAL — Created with request details
- ZHR_ESS_APPR_STEP — Created at submission (approval chain snapshot)
- ZHR_ESS_LOAN_PERSONAL_CUSTOM — Created for custom field values
- ZHR_ESS_CHANGE_LOG — Created for audit trail

**Do NOT manually load these. They are managed by RAP logic.**

---

## Data Validation Checklist

After loading all master data:

### ZHR_ESS_CLIENT
- [ ] At least 1 client created (client_id=100)
- [ ] active=Y
- [ ] company_code populated

### ZHR_ESS_SERVICE
- [ ] At least 1 loan type (PERSLOAN)
- [ ] active=Y
- [ ] sequence defined for UI ordering

### ZHR_ESS_INT_RATE
- [ ] At least 1 rate for PERSLOAN
- [ ] rate_percent between 0 and 100
- [ ] active=Y
- [ ] effective_date ≤ today

### ZHR_ESS_LOAN_PARAM
- [ ] At least 1 eligibility rule for PERSLOAN
- [ ] min_amount ≤ max_amount
- [ ] min_tenure_months ≤ max_tenure_months
- [ ] salary_multiple > 0
- [ ] active=Y

### ZHR_ESS_WF_CONFIG
- [ ] At least 3 levels for PERSLOAN (bracket-based)
- [ ] amount_from/amount_to don't overlap
- [ ] fallback_pernr filled (mandatory)
- [ ] default_sla_days > 0
- [ ] active=Y
- [ ] effective_from ≤ today

### ZHR_ESS_VALIDATION_MSG
- [ ] At least 5-7 validation messages loaded
- [ ] msg_type values are E, W, or I
- [ ] msg_params comma-separated (if applicable)
- [ ] active=Y

---

## Verification Queries

Run these checks in SE16/SE16N to verify data:

```sql
-- Check client data
SELECT * FROM ZHR_ESS_CLIENT WHERE active = 'Y'

-- Check loan types
SELECT * FROM ZHR_ESS_SERVICE WHERE client_id = '100' AND active = 'Y'

-- Check approval chain
SELECT * FROM ZHR_ESS_WF_CONFIG 
  WHERE client_id = '100' AND loan_type = 'PERSLOAN' 
  ORDER BY level, amount_from

-- Check interest rates
SELECT * FROM ZHR_ESS_INT_RATE 
  WHERE client_id = '100' AND loan_type = 'PERSLOAN' 
  ORDER BY effective_date DESC

-- Check eligibility rules
SELECT * FROM ZHR_ESS_LOAN_PARAM 
  WHERE client_id = '100' AND loan_type = 'PERSLOAN'

-- Check validation messages
SELECT * FROM ZHR_ESS_VALIDATION_MSG 
  WHERE client_id = '100' AND active = 'Y'
```

---

## Next Steps

Once master data is loaded:

1. ✓ DDIC tables created
2. ✓ Master data loaded
3. → Start **Stage 2: Service Layer** (Utility Classes)

---

**Status:** Ready for manual data entry via SE16 after DDIC activation
