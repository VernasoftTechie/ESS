# ZHR_ESS_V1 — Complete DDIC Specification

**Package:** ZHR_ESS_V1  
**Application:** Employee Self-Service Loan Request (RAP)  
**Date:** 2026-08-31  
**Status:** Ready for SE11 Creation

---

## Table of Contents

1. Domains (5 total)
2. Data Elements (supporting)
3. Structures (supporting)
4. Tables (13 total)
5. Indexes & Keys
6. SE11 Creation Checklist
7. Master Data Load Instructions

---

# SECTION 1: DOMAINS

## Domain 1: ZHR_ESS_REQ_STATUS
**Description:** Request Status Domain

| Value | Text |
|---|---|
| D | Draft |
| S | Submitted |
| A | In Approval |
| R | Returned |
| P | Approved |
| J | Rejected |
| W | Withdrawn |

**Field Type:** CHAR  
**Field Length:** 1  
**Output Length:** 10

---

## Domain 2: ZHR_ESS_APPR_STATUS
**Description:** Approval Step Status Domain

| Value | Text |
|---|---|
| P | Pending |
| A | Approved |
| J | Rejected |
| R | Returned |
| S | Skipped |
| E | Escalated |
| D | Delegated |

**Field Type:** CHAR  
**Field Length:** 1  
**Output Length:** 10

---

## Domain 3: ZHR_ESS_FIELD_TYPE
**Description:** Custom Field Type Domain

| Value | Text |
|---|---|
| T | Text |
| A | Amount |
| D | Date |
| S | Dropdown |
| C | Checkbox |

**Field Type:** CHAR  
**Field Length:** 1  
**Output Length:** 10

---

## Domain 4: ZHR_ESS_MSG_TYPE
**Description:** Validation Message Type Domain

| Value | Text |
|---|---|
| E | Error |
| W | Warning |
| I | Info |

**Field Type:** CHAR  
**Field Length:** 1  
**Output Length:** 5

---

## Domain 5: ZHR_ESS_LOAN_PURPOSE
**Description:** Loan Purpose Domain

| Value | Text |
|---|---|
| S | Self/Personal |
| B | Business |
| E | Education |
| O | Other |

**Field Type:** CHAR  
**Field Length:** 1  
**Output Length:** 15

---

# SECTION 2: DATA ELEMENTS (Supporting)

These are created to standardize field definitions across tables:

| Data Element | Domain/Type | Length | Description |
|---|---|---|---|
| ZHR_ESS_CLIENT_ID | CHAR | 3 | Tenant/Client ID |
| ZHR_ESS_REQUEST_ID | CHAR | 20 | Request unique ID |
| ZHR_ESS_LOAN_TYPE | CHAR | 10 | Loan type code |
| ZHR_ESS_REQ_STATUS | Domain | 1 | Request status |
| ZHR_ESS_APPR_STATUS | Domain | 1 | Approval status |
| ZHR_ESS_RELATIONSHIP_ID | CHAR | 10 | Org relationship (A002, A006, etc.) |
| ZHR_ESS_PERNR | NUMC | 8 | Personnel number |
| ZHR_ESS_AMOUNT | DEC | (15,2) | Amount |
| ZHR_ESS_RATE | DEC | (5,2) | Rate (interest %) |
| ZHR_ESS_TENURE_MONTHS | INT4 | — | Duration in months |
| ZHR_ESS_SLA_DAYS | INT4 | — | SLA days |
| ZHR_ESS_COMMENT | STRING | 500 | Comment/remark |
| ZHR_ESS_MESSAGE_ID | CHAR | 30 | Message ID |
| ZHR_ESS_MESSAGE_TEXT | STRING | 255 | Message text |
| ZHR_ESS_FIELD_KEY | CHAR | 30 | Custom field key |

---

# SECTION 3: STRUCTURES (Supporting)

## Structure 1: zhr_ess_employee_info
**Used for:** Employee data retrieval & display

```
Field Name              Type        Length   Description
─────────────────────────────────────────────────────
pernr                   NUMC        8        Personnel number
employee_name           STRING      100      Full name (PA0000)
email                   STRING      100      Email (PA0006/IT0006)
phone                   STRING      20       Phone
hire_date               DATS        —        Hire date (PA0000)
salary                  DEC         (15,2)   Basic salary (PA0008)
company_code            BUKRS       4        Company code (PA0001)
cost_center             CHAR        10       Cost center (PA0001)
employment_group       STRING      3        EE group (IT0001)
employment_subgroup    STRING      3        EE subgroup (IT0001)
```

---

## Structure 2: zhr_ess_validation_message_type
**Used for:** Validation message handling

```
Field Name              Type        Length   Description
─────────────────────────────────────────────────────
msg_id                  CHAR        30       Message ID
msg_type                CHAR        1        Domain: ZHR_ESS_MSG_TYPE
msg_text                STRING      255      Message text
msg_detail              STRING      500      Detailed message
msg_params              STRING      100      Parameter names (comma-separated)
```

---

## Structure 3: zhr_ess_approval_step_type
**Used for:** Approval step display

```
Field Name              Type        Length   Description
─────────────────────────────────────────────────────
appr_level                   INT4        —        Approval level (1, 2, 3, ...)
attempt                 INT4        —        Attempt number
approver_pernr          NUMC        8        Approver personnel number
approver_name           STRING      100      Approver name
status                  CHAR        1        Domain: ZHR_ESS_APPR_STATUS
decided_on              DATS        —        Decision date
appr_comment                 STRING      500      Approver comment
```

---

# SECTION 4: TABLES (13 Total)

## TABLE 1: ZHR_ESS_CLIENT
**Description:** Tenant/Client Master  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | Tenant ID (e.g., 100, 200) |
| client_name | STRING | 100 | | Display name (e.g., "ACME Corp") |
| company_code | BUKRS | 4 | | Primary company code |
| hcm_system | CHAR | 3 | | HCM system ID (multi-system support) |
| active | CHAR | 1 | | Y/N flag |
| created_on | TIMESTAMP | | | Creation timestamp |
| created_by | SYUNAME | 12 | | Creator user ID |
| changed_on | TIMESTAMP | | | Last change timestamp |
| changed_by | SYUNAME | 12 | | Last modifier user ID |

**Indexes:**
- PK: client_id
- Idx_01: active, created_on

**Notes:** 
- Multi-client sharding root table
- Supports future multi-system replication via hcm_system

---

## TABLE 2: ZHR_ESS_SERVICE
**Description:** Loan Type Catalog  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **service_code** | CHAR | 10 | ✓ PK | Loan type (PERSLOAN, CONVLOAN, etc.) |
| description | STRING | 100 | | User-friendly description |
| icon_name | CHAR | 30 | | Fiori icon name (e.g., "sap-icon://loan") |
| sequence | INT4 | | | Display order (100, 200, 300, ...) |
| remarks_mandatory | CHAR | 1 | | Y/N — future: remarks config per type |
| active | CHAR | 1 | | Y/N flag |
| effective_from | DATS | | | Config effective from date |
| effective_to | DATS | | | Config effective to date (NULL = no end) |

**Indexes:**
- PK: (client_id, service_code)
- Idx_01: (client_id, active, effective_from, effective_to)
- Idx_02: (client_id, sequence)

**Notes:**
- Temporal versioning via effective_from/effective_to
- Supports future: remarks_mandatory config per loan type

---

## TABLE 3: ZHR_ESS_REQ_HEAD
**Description:** Loan Request Header (Root Entity)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 3  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **request_id** | CHAR | 20 | ✓ PK | Unique request ID (PERSLOAN-001, ...) |
| employee_pernr | NUMC | 8 | | FK to HR (PA0000) |
| employee_name | STRING | 100 | | Denormalized (PA0000) for audit/display |
| employee_email | STRING | 100 | | Denormalized (PA0006/IT0006) for notifications |
| loan_type | CHAR | 10 | | FK to ZHR_ESS_SERVICE.service_code |
| status | CHAR | 1 | | Domain: ZHR_ESS_REQ_STATUS |
| current_level | INT4 | | | Current approval level (NULL if terminal) |
| current_approver_pernr | NUMC | 8 | | Next approver (NULL if terminal) |
| current_approver_name | STRING | 100 | | Denormalized approver name |
| request_date | DATS | | | Request creation date |
| request_time | TIMS | | | Request creation time |
| submit_date | DATS | | | First submission date (NULL if Draft) |
| submit_time | TIMS | | | First submission time |
| amount | DEC | (15,2) | | Requested amount |
| currency | WAERS | 5 | | Currency code (auto from company_code) |
| tenure_months | INT4 | | | Loan duration in months |
| basic_salary | DEC | (15,2) | | Denormalized (PA0008) for audit |
| company_code | BUKRS | 4 | | Locked at submission time |
| created_on | TIMESTAMP | | | Technical creation |
| created_by | SYUNAME | 12 | | Creator |
| changed_on | TIMESTAMP | | | Last technical change |
| changed_by | SYUNAME | 12 | | Last modifier |

**Indexes:**
- PK: (client_id, request_id)
- Idx_01: (client_id, employee_pernr, status) — requestor view
- Idx_02: (client_id, current_approver_pernr, status) — approver worklist (future)
- Idx_03: (client_id, loan_type, employee_pernr) — duplicate prevention
- Idx_04: (client_id, status, submit_date) — dashboard filters
- Idx_05: (client_id, created_on DESC) — recent requests

**Notes:**
- Root entity for RAP BO
- Denormalized fields enable offline display & audit trail
- current_level/current_approver updated as chain progresses

---

## TABLE 4: ZHR_ESS_REQ_ITEM
**Description:** Loan Request Items (Supporting Details)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **request_id** | CHAR | 20 | ✓ PK | FK to ZHR_ESS_REQ_HEAD |
| **item_sequence** | CHAR | 2 | ✓ PK | Item sequence (01, 02, ..., 99) |
| item_type | CHAR | 20 | | GUARANTOR, CO_APPLICANT, COLLATERAL, ... |
| item_description | STRING | 255 | | Free text description |
| item_value | DEC | (15,2) | | Amount (if applicable) |
| item_status | CHAR | 1 | | A=Active, I=Inactive, V=Verified |
| created_on | TIMESTAMP | | | When added |

**Indexes:**
- PK: (client_id, request_id, item_sequence)

**Notes:**
- Child entity of ZHR_ESS_REQ_HEAD
- item_type extensible via configuration (future)

---

## TABLE 5: ZHR_ESS_LOANDTL
**Description:** Personal Loan Details (1:1 Child)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **request_id** | CHAR | 20 | ✓ PK | FK to ZHR_ESS_REQ_HEAD |
| purpose | CHAR | 1 | | Domain: ZHR_ESS_LOAN_PURPOSE |
| amount | DEC | (15,2) | | Requested amount (copy from header) |
| tenure_months | INT4 | | | Loan duration (copy from header) |
| emi_amount | DEC | (15,2) | | Calculated EMI (monthly payment) |
| rate_of_interest | DEC | (5,2) | | Annual interest rate % |
| repayment_start | DATS | | | Calculated start date (next month end) |
| remarks | STRING | 1000 | | Requestor comments (optional, v1: optional) |
| created_on | TIMESTAMP | | | Creation timestamp |

**Indexes:**
- PK: (client_id, request_id)

**Notes:**
- 1:1 relationship with ZHR_ESS_REQ_HEAD
- remarks future: configurable mandatory per loan type
- Denormalized amount/tenure for quick access

---

## TABLE 6: ZHR_ESS_APPRSTEP
**Description:** Approval Timeline (Read-Only Child)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **request_id** | CHAR | 20 | ✓ PK | FK to ZHR_ESS_REQ_HEAD |
| **appr_level** | INT4 | | ✓ PK | Approval level (1, 2, 3, ...) |
| **attempt** | INT4 | | ✓ PK | Attempt number (1, 2, ... increments on Return→Resubmit) |
| approver_pernr | NUMC | 8 | | Approver personnel number |
| approver_name | STRING | 100 | | Denormalized approver name |
| relationship_id_used | CHAR | 10 | | Org relationship used (A002, A006, HR, Finance, ...) |
| status | CHAR | 1 | | Domain: ZHR_ESS_APPR_STATUS |
| decided_by_pernr | NUMC | 8 | | Person who took action (NULL if Pending) |
| decided_on | DATS | | | Decision date |
| decided_time | TIMS | | | Decision time |
| appr_comment | STRING | 500 | | Approver remark (reason for rejection, etc.) |
| sla_due_date | DATS | | | Expected completion (submission + SLA days) |
| sla_breached | CHAR | 1 | | Y/N flag (set by job if SLA exceeded) |

**Indexes:**
- PK: (client_id, request_id, appr_level, attempt)
- Idx_01: (client_id, approver_pernr, status) — approver worklist (future)
- Idx_02: (client_id, request_id, status) — timeline view
- Idx_03: (client_id, sla_due_date, sla_breached) — SLA tracking (future)

**Notes:**
- Read-only in RAP BO (created at submit, updated only on action)
- Immutable once created (only status changes)
- On Return: old rows kept, new rows on Resubmit (attempt++)
- SLA fields for future SLA monitoring

---

## TABLE 7: ZHR_ESS_WFCONFIG
**Description:** Approval Matrix (Customizing)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL2  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **loan_type** | CHAR | 10 | ✓ PK | FK to ZHR_ESS_SERVICE.service_code |
| **appr_level** | INT4 | | ✓ PK | Approval level (1, 2, 3, ...) |
| relationship_id | CHAR | 10 | | Org relationship (A002, A006, HR, Finance, etc.) |
| fallback_pernr | NUMC | 8 | | Mandatory: if relationship_id fails, use this |
| amount_from | DEC | (15,2) | | Amount bracket from (0 for minimum) |
| amount_to | DEC | (15,2) | | Amount bracket to (99999999.99 for unlimited) |
| default_sla_days | INT4 | | | Days allowed for approval at this level |
| parallel_level | CHAR | 1 | | Y/N — future: parallel approval support |
| active | CHAR | 1 | | Y/N flag |
| effective_from | DATS | | | Config effective from date |
| effective_to | DATS | | | Config effective to date (NULL = no end) |
| created_on | TIMESTAMP | | | Audit: creation timestamp |
| created_by | SYUNAME | 12 | | Audit: creator |

**Indexes:**
- PK: (client_id, loan_type, appr_level)
- Idx_01: (client_id, loan_type, amount_from, amount_to, active, effective_from, effective_to) — chain resolution
- Idx_02: (client_id, active, effective_from, effective_to)

**Chain Resolution Logic:**
1. Read rows for (loan_type, active=Y, effective_from ≤ today ≤ effective_to)
2. For requested amount, find matching bracket
3. For each level, resolve relationship_id; if fails → use fallback_pernr

**Notes:**
- Temporal versioning for config changes
- relationship_id flexible for custom org structures
- parallel_level reserved for Phase 2

---

## TABLE 8: ZHR_ESS_LOANPRM
**Description:** Loan Eligibility Parameters (Customizing)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL2  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **loan_type** | CHAR | 10 | ✓ PK | FK to ZHR_ESS_SERVICE.service_code |
| min_amount | DEC | (15,2) | | Minimum loan amount |
| max_amount | DEC | (15,2) | | Maximum loan amount |
| max_tenure_months | INT4 | | | Maximum tenure in months |
| min_tenure_months | INT4 | | | Minimum tenure in months |
| salary_multiple | DEC | (5,2) | | Loan cap as multiple of basic salary (e.g., 5.00) |
| min_service_days | INT4 | | | Minimum employment tenure in days |
| allow_during_probation | CHAR | 1 | | Y/N — allow loan during probation? |
| allow_contract_employees | CHAR | 1 | | Y/N — allow contract employees? |
| active | CHAR | 1 | | Y/N flag |
| effective_from | DATS | | | Config effective from date |
| effective_to | DATS | | | Config effective to date |

**Indexes:**
- PK: (client_id, loan_type)
- Idx_01: (client_id, active, effective_from, effective_to)

**Notes:**
- Temporal versioning for rule changes
- Used by validation engine for eligibility checks

---

## TABLE 9: ZHR_ESS_INT_RATE
**Description:** Interest Rate Master (Effective-Dated)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL2  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **loan_type** | CHAR | 10 | ✓ PK | FK to ZHR_ESS_SERVICE.service_code |
| **effective_date** | DATS | | ✓ PK | Effective from this date |
| rate_percent | DEC | (5,2) | | Annual interest rate % |
| active | CHAR | 1 | | Y/N flag |

**Indexes:**
- PK: (client_id, loan_type, effective_date)
- Idx_01: (client_id, loan_type, effective_date DESC) — lookup latest rate

**Notes:**
- Effective-dated master for rate history
- UI uses latest active rate for EMI calculation

---

## TABLE 10: ZHR_ESS_CUSTFLD
**Description:** Custom Fields Configuration  
**Application Component:** ZHR_ESS  
**Data Class:** APPL2  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **loan_type** | CHAR | 10 | ✓ PK | FK to ZHR_ESS_SERVICE.service_code |
| **field_key** | CHAR | 30 | ✓ PK | Custom field key (VEHICLE_REG, CO_APPLICANT_NAME, ...) |
| field_label | STRING | 100 | | Display label |
| field_type | CHAR | 1 | | Domain: ZHR_ESS_FIELD_TYPE |
| mandatory | CHAR | 1 | | Y/N |
| field_order | INT4 | | | Display sequence (100, 200, 300, ...) |
| field_length | INT4 | | | Max length for TEXT (0 = unlimited) |
| dropdown_domain | CHAR | 30 | | If field_type=S, domain reference |
| help_text | STRING | 200 | | Tooltip/help text |
| validation_regex | STRING | 500 | | Optional regex for validation |
| active | CHAR | 1 | | Y/N flag |

**Indexes:**
- PK: (client_id, loan_type, field_key)
- Idx_01: (client_id, loan_type, active, field_order)

**Notes:**
- Zero-code field additions for new clients
- validation_regex for future custom validation rules

---

## TABLE 11: ZHR_ESS_CUSTVAL
**Description:** Custom Field Values  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **request_id** | CHAR | 20 | ✓ PK | FK to ZHR_ESS_REQ_HEAD |
| **field_key** | CHAR | 30 | ✓ PK | FK to ZHR_ESS_CUSTFLD.field_key |
| field_value | STRING | 1000 | | Polymorphic value (TEXT, AMOUNT, DATE, DROPDOWN) |

**Indexes:**
- PK: (client_id, request_id, field_key)

**Notes:**
- One row per custom field per request
- field_value polymorphic (dates as YYYYMMDD, amounts as numbers, etc.)
- All changes logged in ZHR_ESS_CHGLOG

---

## TABLE 12: ZHR_ESS_VALMSG
**Description:** Validation Messages (i18n)  
**Application Component:** ZHR_ESS  
**Data Class:** APPL2  
**Size Category:** 2  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **msg_id** | CHAR | 30 | ✓ PK | Message ID (ESS_EMP_INACTIVE, ESS_TENURE_SHORT, ...) |
| msg_type | CHAR | 1 | | Domain: ZHR_ESS_MSG_TYPE |
| msg_text | STRING | 255 | | User-friendly message |
| msg_detail | STRING | 500 | | Detailed message with placeholders |
| msg_params | STRING | 100 | | Parameter names (comma-separated) |
| active | CHAR | 1 | | Y/N flag |

**Indexes:**
- PK: (client_id, msg_id)
- Idx_01: (client_id, active)

**Example:**
```
(100, ESS_TENURE_SHORT, E, "Tenure too short", 
 "You have {TENURE_DAYS} days. Required: {MIN_DAYS}. Eligible from {DATE}.",
 "TENURE_DAYS,MIN_DAYS,DATE")
```

**Notes:**
- Client-specific messages (i18n ready)
- msg_params enable dynamic formatting in UI/validation engine

---

## TABLE 13: ZHR_ESS_CHGLOG
**Description:** Audit Trail  
**Application Component:** ZHR_ESS  
**Data Class:** APPL0  
**Size Category:** 3  

| Field Name | Type | Length | Key | Description |
|---|---|---|---|---|
| **client_id** | CHAR | 3 | ✓ PK | FK to ZHR_ESS_CLIENT |
| **request_id** | CHAR | 20 | ✓ PK | FK to ZHR_ESS_REQ_HEAD |
| **sequence** | INT4 | | ✓ PK | Sequential number (1, 2, 3, ...) per request |
| changed_on | TIMESTAMP | | | When change occurred |
| changed_by | SYUNAME | 12 | | User who made change |
| change_reason | CHAR | 20 | | CREATED, EDITED, SUBMITTED, APPROVED, REJECTED, RETURNED, WITHDRAWN |
| object_type | CHAR | 20 | | REQ_HEAD, LOAN_PERSONAL, APPR_STEP, CUSTOM_FIELD |
| field_name | STRING | 30 | | Which field changed (NULL for status transitions) |
| old_value | STRING | 1000 | | Previous value (NULL if N/A) |
| new_value | STRING | 1000 | | New value (NULL if N/A) |
| notes | STRING | 500 | | Additional context |

**Indexes:**
- PK: (client_id, request_id, sequence)
- Idx_01: (client_id, request_id, changed_on DESC) — timeline view
- Idx_02: (client_id, changed_on DESC) — global audit

**Notes:**
- Complementary to RAP change documents
- Manual entries for approval decisions & status transitions
- Comprehensive audit trail for compliance

---

# SECTION 5: SUMMARY & FIELD STANDARDS

## Field Length & Type Standards Applied

| Field Type | Standard Length | SAP Type | Notes |
|---|---|---|---|
| Client ID | 3 | CHAR | Same logic as MANDT |
| Request ID | 20 | CHAR | Allows: TYPE-NNNN (e.g., PERSLOAN-0001) |
| Personnel Number | 8 | NUMC | Standard SAP HR format |
| Loan Type | 10 | CHAR | Extendable: PERSLOAN, CONVLOAN, HOUSLOAN |
| Relationship ID | 10 | CHAR | A002, A006, HR, Finance, Custom (flexible) |
| Amount | (15,2) | DEC | Large enough for global amounts |
| Rate % | (5,2) | DEC | 0.00 to 100.00 format |
| Status | 1 | CHAR | Domain-based, single character |
| Comments | 500-1000 | STRING | Flexible for future content |
| Name/Description | 100 | STRING | Standard SAP size |
| Email | 100 | STRING | Standard email size |

## Naming Conventions Applied

✅ **Domain Names:** ZHR_ESS_[TYPE] (uppercase)  
✅ **Table Names:** ZHR_ESS_[PURPOSE] (uppercase, max 30 chars)  
✅ **Field Names:** lowercase_with_underscores (lowercase)  
✅ **Structure Names:** zhr_ess_[type] (lowercase, with _type suffix)  
✅ **Primary Keys:** Always first (with PK icon in SE11)  
✅ **Foreign Keys:** Noted where applicable  
✅ **Audit Fields:** created_on, created_by, changed_on, changed_by (consistent placement)

---

# SECTION 6: SE11 CREATION CHECKLIST

## Phase 1: Domains (5 total)
- [ ] Domain: ZHR_ESS_REQ_STATUS (values: D, S, A, R, P, J, W)
- [ ] Domain: ZHR_ESS_APPR_STATUS (values: P, A, J, R, S, E, D)
- [ ] Domain: ZHR_ESS_FIELD_TYPE (values: T, A, D, S, C)
- [ ] Domain: ZHR_ESS_MSG_TYPE (values: E, W, I)
- [ ] Domain: ZHR_ESS_LOAN_PURPOSE (values: S, B, E, O)

## Phase 2: Tables (13 total)
- [ ] ZHR_ESS_CLIENT
- [ ] ZHR_ESS_SERVICE
- [ ] ZHR_ESS_REQ_HEAD
- [ ] ZHR_ESS_REQ_ITEM
- [ ] ZHR_ESS_LOANDTL
- [ ] ZHR_ESS_APPRSTEP
- [ ] ZHR_ESS_WFCONFIG
- [ ] ZHR_ESS_LOANPRM
- [ ] ZHR_ESS_INT_RATE
- [ ] ZHR_ESS_CUSTFLD
- [ ] ZHR_ESS_CUSTVAL
- [ ] ZHR_ESS_VALMSG
- [ ] ZHR_ESS_CHGLOG

## Verification Checklist
- [ ] All tables created successfully in SE11
- [ ] All fields have correct types & lengths
- [ ] All primary keys defined
- [ ] All indexes created per spec
- [ ] No compilation errors
- [ ] All tables allow transport (Delivery class: A or L)
- [ ] Audit fields present where spec'd

---

# SECTION 7: MASTER DATA LOAD INSTRUCTIONS

Will be prepared once Phase 1 DDIC creation is complete.

---

**End of DDIC Specification**
