INTERFACE zif_ess_metadata_provider
  PUBLIC .

************************************************************************
* ZIF_ESS_METADATA_PROVIDER
* Read-only access to configuration/customizing tables: eligibility
* parameters (ZHR_ESS_LOANPRM), custom field metadata (ZHR_ESS_CUSTFLD),
* and interest rates (ZHR_ESS_INT_RATE). Callers should go through this
* interface rather than SELECTing these tables directly, so caching can
* be added later without touching call sites.
************************************************************************

  TYPES:
    BEGIN OF ty_loan_param,
      min_amount               TYPE zhr_ess_loanprm-min_amount,
      max_amount                TYPE zhr_ess_loanprm-max_amount,
      max_tenure_months         TYPE zhr_ess_loanprm-max_tenure_months,
      min_tenure_months         TYPE zhr_ess_loanprm-min_tenure_months,
      salary_multiple           TYPE zhr_ess_loanprm-salary_multiple,
      min_service_days          TYPE zhr_ess_loanprm-min_service_days,
      allow_during_probation    TYPE zhr_ess_loanprm-allow_during_probation,
      allow_contract_employees  TYPE zhr_ess_loanprm-allow_contract_employees,
      is_found                  TYPE abap_bool,
    END OF ty_loan_param .

  TYPES:
    BEGIN OF ty_custom_field,
      field_key        TYPE zhr_ess_custfld-field_key,
      field_label      TYPE string,
      field_type       TYPE zhr_ess_custfld-field_type,   " T/A/D/S/C
      mandatory        TYPE zhr_ess_custfld-mandatory,
      field_order      TYPE zhr_ess_custfld-field_order,
      field_length     TYPE zhr_ess_custfld-field_length,
      dropdown_domain  TYPE zhr_ess_custfld-dropdown_domain,
      help_text        TYPE string,
      validation_regex TYPE string,
    END OF ty_custom_field .
  TYPES:
    ty_custom_field_tab TYPE STANDARD TABLE OF ty_custom_field WITH EMPTY KEY .

  METHODS get_loan_params
    IMPORTING
      !iv_client_id  TYPE zhr_ess_loanprm-client_id
      !iv_loan_type  TYPE zhr_ess_loanprm-loan_type
      !iv_key_date   TYPE dats DEFAULT sy-datum
    RETURNING
      VALUE(rs_param) TYPE ty_loan_param .

  METHODS get_custom_fields
    IMPORTING
      !iv_client_id  TYPE zhr_ess_custfld-client_id
      !iv_loan_type  TYPE zhr_ess_custfld-loan_type
    RETURNING
      VALUE(rt_fields) TYPE ty_custom_field_tab .

  METHODS get_interest_rate
    IMPORTING
      !iv_client_id  TYPE zhr_ess_int_rate-client_id
      !iv_loan_type  TYPE zhr_ess_int_rate-loan_type
      !iv_key_date   TYPE dats DEFAULT sy-datum
    RETURNING
      VALUE(rv_rate) TYPE zhr_ess_int_rate-rate_percent .

ENDINTERFACE.
