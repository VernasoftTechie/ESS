INTERFACE zif_ess_validation_engine
  PUBLIC .

************************************************************************
* ZIF_ESS_VALIDATION_ENGINE
* Retrieves and formats validation messages from ZHR_ESS_VALMSG, and
* orchestrates eligibility / integrity checks by calling
* ZIF_ESS_LOAN_VALIDATOR and ZIF_ESS_EMPLOYEE_PROVIDER. The message
* types ty_message / ty_message_tab declared here are reused by other
* interfaces (ZIF_ESS_LOAN_VALIDATOR) via ZIF_ESS_VALIDATION_ENGINE=>.
************************************************************************

  TYPES:
    BEGIN OF ty_message,
      msg_id     TYPE zhr_ess_valmsg-msg_id,
      msg_type   TYPE zhr_ess_valmsg-msg_type,   " E / W / I
      msg_text   TYPE string,
      msg_detail TYPE string,
    END OF ty_message .
  TYPES:
    ty_message_tab TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY .

  METHODS get_message
    IMPORTING
      !iv_client_id      TYPE zhr_ess_valmsg-client_id
      !iv_msg_id         TYPE zhr_ess_valmsg-msg_id
      !it_params         TYPE string_table OPTIONAL
    RETURNING
      VALUE(rs_message)  TYPE ty_message .

  METHODS validate_eligibility
    IMPORTING
      !iv_client_id      TYPE zhr_ess_req_head-client_id
      !iv_pernr          TYPE pernr_d
      !iv_loan_type      TYPE zhr_ess_req_head-loan_type
      !iv_amount         TYPE zhr_ess_req_head-amount
      !iv_tenure_months  TYPE zhr_ess_req_head-tenure_months
    RETURNING
      VALUE(rt_messages) TYPE ty_message_tab .

  METHODS validate_request_integrity
    IMPORTING
      !iv_client_id      TYPE zhr_ess_req_head-client_id
      !iv_request_id     TYPE zhr_ess_req_head-request_id
    RETURNING
      VALUE(rt_messages) TYPE ty_message_tab .

  METHODS has_errors
    IMPORTING
      !it_messages   TYPE ty_message_tab
    RETURNING
      VALUE(rv_yes)  TYPE abap_bool .

ENDINTERFACE.
