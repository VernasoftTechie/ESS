# SE11 Creation Guide — Step-by-Step

**Package:** ZHR_ESS_V1  
**Transaction:** SE11 (ABAP Dictionary)  
**Process:** Create all DDIC objects in sequence

---

## STEP-BY-STEP: DOMAIN CREATION

### Domain 1: ZHR_ESS_REQ_STATUS

**Path:** SE11 → New → Domain

| Field | Value |
|---|---|
| Domain Name | ZHR_ESS_REQ_STATUS |
| Short Description | Request Status Domain |
| Data Type | CHAR |
| Number of Characters | 1 |
| Output Length | 10 |
| Lowercase | Unchecked |

**Value Range Tab:**

| Pos | Low Value | High Value | Meaning | Shorttext |
|---|---|---|---|---|
| 1 | D | | Draft | Draft Request |
| 2 | S | | Submitted | Submitted for Approval |
| 3 | A | | In Approval | In Approval Process |
| 4 | R | | Returned | Returned by Approver |
| 5 | P | | Approved | Approved |
| 6 | J | | Rejected | Rejected |
| 7 | W | | Withdrawn | Withdrawn by Requestor |

**Save & Activate** ✓

---

### Domain 2: ZHR_ESS_APPR_STATUS

**Path:** SE11 → New → Domain

| Field | Value |
|---|---|
| Domain Name | ZHR_ESS_APPR_STATUS |
| Short Description | Approval Step Status Domain |
| Data Type | CHAR |
| Number of Characters | 1 |
| Output Length | 10 |

**Value Range Tab:**

| Pos | Low Value | Meaning | Shorttext |
|---|---|---|---|
| 1 | P | Pending | Pending Approval |
| 2 | A | Approved | Approved |
| 3 | J | Rejected | Rejected |
| 4 | R | Returned | Returned for Rework |
| 5 | S | Skipped | Skipped |
| 6 | E | Escalated | Escalated |
| 7 | D | Delegated | Delegated |

**Save & Activate** ✓

---

### Domain 3: ZHR_ESS_FIELD_TYPE

**Path:** SE11 → New → Domain

| Field | Value |
|---|---|
| Domain Name | ZHR_ESS_FIELD_TYPE |
| Short Description | Custom Field Type Domain |
| Data Type | CHAR |
| Number of Characters | 1 |
| Output Length | 10 |

**Value Range Tab:**

| Pos | Low Value | Meaning | Shorttext |
|---|---|---|---|
| 1 | T | Text | Text Field |
| 2 | A | Amount | Amount Field |
| 3 | D | Date | Date Field |
| 4 | S | Dropdown | Dropdown/Select |
| 5 | C | Checkbox | Checkbox |

**Save & Activate** ✓

---

### Domain 4: ZHR_ESS_MSG_TYPE

**Path:** SE11 → New → Domain

| Field | Value |
|---|---|
| Domain Name | ZHR_ESS_MSG_TYPE |
| Short Description | Validation Message Type Domain |
| Data Type | CHAR |
| Number of Characters | 1 |
| Output Length | 5 |

**Value Range Tab:**

| Pos | Low Value | Meaning | Shorttext |
|---|---|---|---|
| 1 | E | Error | Error Message |
| 2 | W | Warning | Warning Message |
| 3 | I | Info | Info Message |

**Save & Activate** ✓

---

### Domain 5: ZHR_ESS_LOAN_PURPOSE

**Path:** SE11 → New → Domain

| Field | Value |
|---|---|
| Domain Name | ZHR_ESS_LOAN_PURPOSE |
| Short Description | Loan Purpose Domain |
| Data Type | CHAR |
| Number of Characters | 1 |
| Output Length | 15 |

**Value Range Tab:**

| Pos | Low Value | Meaning | Shorttext |
|---|---|---|---|
| 1 | S | Self | Self/Personal Use |
| 2 | B | Business | Business Purpose |
| 3 | E | Education | Education |
| 4 | O | Other | Other Purpose |

**Save & Activate** ✓

---

## STEP-BY-STEP: TABLE CREATION

### TABLE 1: ZHR_ESS_CLIENT (Tenant Master)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_CLIENT |
| | Short Description | Tenant/Client Master |
| | Delivery Class | A (Application Table) |
| | Data Class | APPL0 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name          Type    Length  Key  Domain/Data Type
───────────────────────────────────────────────────────────────
1    client_id           CHAR    3       ✓    —
2    client_name         STRING  100         —
3    company_code        BUKRS   4           —
4    hcm_system          CHAR    3           —
5    active              CHAR    1           —
6    created_on          TIMESTAMP           —
7    created_by          SYUNAME 12          —
8    changed_on          TIMESTAMP           —
9    changed_by          SYUNAME 12          —
```

**Indexes Tab:**
- Primary Key: client_id
- Secondary Index 1:
  - Unique: N
  - Name: Idx_01
  - Fields: active, created_on

**Technical Settings:**
- Buffering: Allowed
- Table Maintenance Generator: Not checked (managed by RAP)
- Log Changes: Checked

**Save & Activate** ✓

---

### TABLE 2: ZHR_ESS_SERVICE (Loan Type Catalog)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_SERVICE |
| | Short Description | Loan Type Catalog |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name            Type    Length  Key  Domain
───────────────────────────────────────────────────────
1    client_id             CHAR    3       ✓    —
2    service_code          CHAR    10      ✓    —
3    description           STRING  100         —
4    icon_name             CHAR    30          —
5    sequence              INT4                —
6    remarks_mandatory     CHAR    1           —
7    active                CHAR    1           —
8    effective_from        DATS                —
9    effective_to          DATS                —
```

**Indexes Tab:**
- Primary Key: (client_id, service_code)
- Secondary Index 1:
  - Name: Idx_01
  - Fields: client_id, active, effective_from, effective_to
- Secondary Index 2:
  - Name: Idx_02
  - Fields: client_id, sequence

**Technical Settings:**
- Buffering: Allowed
- Log Changes: Checked

**Save & Activate** ✓

---

### TABLE 3: ZHR_ESS_REQ_HEAD (Request Header — Root Entity)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_REQ_HEAD |
| | Short Description | Loan Request Header |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 3 |

**Fields Tab:**

```
Pos  Field Name                Type       Length   Key  Domain/Data Type
────────────────────────────────────────────────────────────────────────
1    client_id                 CHAR       3        ✓    —
2    request_id                CHAR       20       ✓    —
3    employee_pernr            NUMC       8            —
4    employee_name             STRING     100         —
5    employee_email            STRING     100         —
6    loan_type                 CHAR       10          —
7    status                    CHAR       1           ZHR_ESS_REQ_STATUS
8    current_level             INT4                   —
9    current_approver_pernr    NUMC       8           —
10   current_approver_name     STRING     100         —
11   request_date              DATS                   —
12   request_time              TIMS                   —
13   submit_date               DATS                   —
14   submit_time               TIMS                   —
15   amount                    DEC        (15,2)      —
16   currency                  WAERS      5           —
17   tenure_months             INT4                   —
18   basic_salary              DEC        (15,2)      —
19   company_code              BUKRS      4           —
20   created_on                TIMESTAMP              —
21   created_by                SYUNAME    12          —
22   changed_on                TIMESTAMP              —
23   changed_by                SYUNAME    12          —
```

**Indexes Tab:**
- Primary Key: (client_id, request_id)
- Secondary Indexes:
  - Idx_01: (client_id, employee_pernr, status)
  - Idx_02: (client_id, current_approver_pernr, status)
  - Idx_03: (client_id, loan_type, employee_pernr) — Unique
  - Idx_04: (client_id, status, submit_date)
  - Idx_05: (client_id, created_on DESC)

**Technical Settings:**
- Buffering: Allowed
- Log Changes: Checked

**Save & Activate** ✓

---

### TABLE 4: ZHR_ESS_REQ_ITEM (Request Items)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_REQ_ITEM |
| | Short Description | Loan Request Items |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name            Type       Length   Key  
────────────────────────────────────────────────────
1    client_id             CHAR       3        ✓    
2    request_id            CHAR       20       ✓    
3    item_sequence         CHAR       2        ✓    
4    item_type             CHAR       20           
5    item_description      STRING     255         
6    item_value            DEC        (15,2)     
7    item_status           CHAR       1           
8    created_on            TIMESTAMP             
```

**Indexes Tab:**
- Primary Key: (client_id, request_id, item_sequence)

**Save & Activate** ✓

---

### TABLE 5: ZHR_ESS_LOAN_PERSONAL (Personal Loan Details)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_LOAN_PERSONAL |
| | Short Description | Personal Loan Details |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name          Type       Length   Key  Domain
────────────────────────────────────────────────────────
1    client_id           CHAR       3        ✓    
2    request_id          CHAR       20       ✓    
3    purpose             CHAR       1            ZHR_ESS_LOAN_PURPOSE
4    amount              DEC        (15,2)       
5    tenure_months       INT4                    
6    emi_amount          DEC        (15,2)       
7    rate_of_interest    DEC        (5,2)        
8    repayment_start     DATS                    
9    remarks             STRING     1000         
10   created_on          TIMESTAMP              
```

**Indexes Tab:**
- Primary Key: (client_id, request_id)

**Save & Activate** ✓

---

### TABLE 6: ZHR_ESS_APPR_STEP (Approval Timeline)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_APPR_STEP |
| | Short Description | Approval Timeline |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name              Type       Length   Key  Domain
───────────────────────────────────────────────────────────
1    client_id               CHAR       3        ✓    
2    request_id              CHAR       20       ✓    
3    level                   INT4                 ✓    
4    attempt                 INT4                 ✓    
5    approver_pernr          NUMC       8            
6    approver_name           STRING     100         
7    relationship_id_used    CHAR       10          
8    status                  CHAR       1            ZHR_ESS_APPR_STATUS
9    decided_by_pernr        NUMC       8           
10   decided_on              DATS                   
11   decided_time            TIMS                   
12   comment                 STRING     500         
13   sla_due_date            DATS                   
14   sla_breached            CHAR       1           
```

**Indexes Tab:**
- Primary Key: (client_id, request_id, level, attempt)
- Secondary Indexes:
  - Idx_01: (client_id, approver_pernr, status)
  - Idx_02: (client_id, request_id, status)
  - Idx_03: (client_id, sla_due_date, sla_breached)

**Save & Activate** ✓

---

### TABLE 7: ZHR_ESS_WF_CONFIG (Approval Matrix)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_WF_CONFIG |
| | Short Description | Approval Matrix Configuration |
| | Delivery Class | A |
| | Data Class | APPL2 (Customizing) |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name          Type       Length   Key  
────────────────────────────────────────────────
1    client_id           CHAR       3        ✓    
2    loan_type           CHAR       10       ✓    
3    level               INT4                 ✓    
4    relationship_id     CHAR       10          
5    fallback_pernr      NUMC       8           
6    amount_from         DEC        (15,2)      
7    amount_to           DEC        (15,2)      
8    default_sla_days    INT4                   
9    parallel_level      CHAR       1           
10   active              CHAR       1           
11   effective_from      DATS                   
12   effective_to        DATS                   
13   created_on          TIMESTAMP             
14   created_by          SYUNAME    12          
```

**Indexes Tab:**
- Primary Key: (client_id, loan_type, level)
- Secondary Indexes:
  - Idx_01: (client_id, loan_type, amount_from, amount_to, active, effective_from, effective_to)
  - Idx_02: (client_id, active, effective_from, effective_to)

**Save & Activate** ✓

---

### TABLE 8: ZHR_ESS_LOAN_PARAM (Eligibility Parameters)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_LOAN_PARAM |
| | Short Description | Loan Eligibility Parameters |
| | Delivery Class | A |
| | Data Class | APPL2 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name                Type    Length   Key  
──────────────────────────────────────────────────
1    client_id                 CHAR    3        ✓    
2    loan_type                 CHAR    10       ✓    
3    min_amount                DEC     (15,2)       
4    max_amount                DEC     (15,2)       
5    max_tenure_months         INT4                
6    min_tenure_months         INT4                
7    salary_multiple           DEC     (5,2)        
8    min_service_days          INT4                
9    allow_during_probation    CHAR    1           
10   allow_contract_employees  CHAR    1           
11   active                    CHAR    1           
12   effective_from            DATS                
13   effective_to              DATS                
```

**Indexes Tab:**
- Primary Key: (client_id, loan_type)
- Secondary Index:
  - Idx_01: (client_id, active, effective_from, effective_to)

**Save & Activate** ✓

---

### TABLE 9: ZHR_ESS_INT_RATE (Interest Rates)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_INT_RATE |
| | Short Description | Interest Rate Master |
| | Delivery Class | A |
| | Data Class | APPL2 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name       Type       Length   Key  
───────────────────────────────────────────────
1    client_id        CHAR       3        ✓    
2    loan_type        CHAR       10       ✓    
3    effective_date   DATS                ✓    
4    rate_percent     DEC        (5,2)        
5    active           CHAR       1           
```

**Indexes Tab:**
- Primary Key: (client_id, loan_type, effective_date)
- Secondary Index:
  - Idx_01: (client_id, loan_type, effective_date DESC)

**Save & Activate** ✓

---

### TABLE 10: ZHR_ESS_CUST_FIELD (Custom Fields Config)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_CUST_FIELD |
| | Short Description | Custom Fields Configuration |
| | Delivery Class | A |
| | Data Class | APPL2 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name          Type       Length   Key  Domain
────────────────────────────────────────────────────────
1    client_id           CHAR       3        ✓    
2    loan_type           CHAR       10       ✓    
3    field_key           CHAR       30       ✓    
4    field_label         STRING     100         
5    field_type          CHAR       1            ZHR_ESS_FIELD_TYPE
6    mandatory           CHAR       1           
7    field_order         INT4                   
8    field_length        INT4                   
9    dropdown_domain     CHAR       30          
10   help_text           STRING     200         
11   validation_regex    STRING     500         
12   active              CHAR       1           
```

**Indexes Tab:**
- Primary Key: (client_id, loan_type, field_key)
- Secondary Index:
  - Idx_01: (client_id, loan_type, active, field_order)

**Save & Activate** ✓

---

### TABLE 11: ZHR_ESS_LOAN_PERSONAL_CUSTOM (Custom Field Values)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_LOAN_PERSONAL_CUSTOM |
| | Short Description | Custom Field Values |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name       Type       Length   Key  
────────────────────────────────────────────
1    client_id        CHAR       3        ✓    
2    request_id       CHAR       20       ✓    
3    field_key        CHAR       30       ✓    
4    field_value      STRING     1000         
```

**Indexes Tab:**
- Primary Key: (client_id, request_id, field_key)

**Save & Activate** ✓

---

### TABLE 12: ZHR_ESS_VALIDATION_MSG (Validation Messages)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_VALIDATION_MSG |
| | Short Description | Validation Messages |
| | Delivery Class | A |
| | Data Class | APPL2 |
| | Size Category | 2 |

**Fields Tab:**

```
Pos  Field Name       Type       Length   Key  Domain
──────────────────────────────────────────────────────
1    client_id        CHAR       3        ✓    
2    msg_id           CHAR       30       ✓    
3    msg_type         CHAR       1            ZHR_ESS_MSG_TYPE
4    msg_text         STRING     255         
5    msg_detail       STRING     500         
6    msg_params       STRING     100         
7    active           CHAR       1           
```

**Indexes Tab:**
- Primary Key: (client_id, msg_id)
- Secondary Index:
  - Idx_01: (client_id, active)

**Save & Activate** ✓

---

### TABLE 13: ZHR_ESS_CHANGE_LOG (Audit Trail)

**Path:** SE11 → New → Table

| Tab | Field | Value |
|---|---|---|
| **Basic** | Table Name | ZHR_ESS_CHANGE_LOG |
| | Short Description | Audit Trail / Change Log |
| | Delivery Class | A |
| | Data Class | APPL0 |
| | Size Category | 3 |

**Fields Tab:**

```
Pos  Field Name         Type       Length   Key  
─────────────────────────────────────────────────
1    client_id          CHAR       3        ✓    
2    request_id         CHAR       20       ✓    
3    sequence           INT4                 ✓    
4    changed_on         TIMESTAMP              
5    changed_by         SYUNAME    12          
6    change_reason      CHAR       20          
7    object_type        CHAR       20          
8    field_name         STRING     30          
9    old_value          STRING     1000        
10   new_value          STRING     1000        
11   notes              STRING     500         
```

**Indexes Tab:**
- Primary Key: (client_id, request_id, sequence)
- Secondary Indexes:
  - Idx_01: (client_id, request_id, changed_on DESC)
  - Idx_02: (client_id, changed_on DESC)

**Save & Activate** ✓

---

## POST-CREATION VERIFICATION

After all 13 tables are created:

- [ ] Check SE11 → Display Table → All 13 tables listed
- [ ] Run SE11 → Utilities → Table contents check (no errors)
- [ ] Verify all indexes created (SE14 → Table indexes)
- [ ] Check activation status (all green ✓)
- [ ] Test INSERT access via SE16 (if available) on test data
- [ ] Verify no foreign key conflicts
- [ ] Confirm all tables in package ZHR_ESS_V1

---

**Ready to Create DDIC Objects? Confirm and we'll begin SE11 creation step-by-step!**
