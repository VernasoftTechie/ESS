INTERFACE zif_ess_loan_validator
  PUBLIC .

************************************************************************
* ZIF_ESS_LOAN_VALIDATOR
* Loan-type-specific business rule checks (amount vs. cap, tenure vs.
* limits, concurrent-loan check, employee status). One implementation
* per loan type; Phase 1 ships ZCL_ESS_PERSLOAN_VALIDATOR for PERSLOAN.
* Reuses the message types from ZIF_ESS_VALIDATION_ENGINE rather than
* redeclaring them.
************************************************************************

  METHODS validate_personal_loan
    IMPORTING
      !iv_client_id      TYPE zhr_ess_req_head-client_id
      !iv_pernr          TYPE pernr_d
      !iv_amount         TYPE zhr_ess_req_head-amount
      !iv_tenure_months  TYPE zhr_ess_req_head-tenure_months
      !iv_basic_salary   TYPE zhr_ess_req_head-basic_salary
      !iv_service_days   TYPE i
      !iv_is_probation   TYPE abap_bool
      !iv_is_contract    TYPE abap_bool
    RETURNING
      VALUE(rt_messages) TYPE zif_ess_validation_engine=>ty_message_tab .

  METHODS check_existing_loan
    IMPORTING
      !iv_client_id       TYPE zhr_ess_req_head-client_id
      !iv_pernr           TYPE pernr_d
      !iv_loan_type       TYPE zhr_ess_req_head-loan_type
      !iv_exclude_request TYPE zhr_ess_req_head-request_id OPTIONAL
    RETURNING
      VALUE(rt_messages)  TYPE zif_ess_validation_engine=>ty_message_tab .

ENDINTERFACE.
