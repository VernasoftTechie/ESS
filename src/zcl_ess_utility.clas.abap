CLASS zcl_ess_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS get_pernr_for_user
      IMPORTING
        !iv_uname       TYPE syuname DEFAULT sy-uname
      RETURNING
        VALUE(rv_pernr) TYPE pernr_d .

    CLASS-METHODS calculate_emi
      IMPORTING
        !iv_amount    TYPE zhr_ess_req_head-amount
        !iv_rate_pct  TYPE zhr_ess_int_rate-rate_percent
        !iv_tenure    TYPE zhr_ess_req_head-tenure_months
      RETURNING
        VALUE(rv_emi) TYPE zhr_ess_loandtl-emi_amount .

    CLASS-METHODS get_next_request_id
      IMPORTING
        !iv_client_id        TYPE zhr_ess_req_head-client_id
        !iv_loan_type         TYPE zhr_ess_req_head-loan_type
      RETURNING
        VALUE(rv_request_id) TYPE zhr_ess_req_head-request_id .

    CLASS-METHODS get_currency_for_cc
      IMPORTING
        !iv_company_code   TYPE bukrs
      RETURNING
        VALUE(rv_currency) TYPE waers .

ENDCLASS.


CLASS zcl_ess_utility IMPLEMENTATION.

  METHOD get_pernr_for_user.

    SELECT SINGLE pernr FROM pa0105
      INTO @rv_pernr
      WHERE subty = '0001'
        AND usrid = @iv_uname
        AND begda <= @sy-datum
        AND endda >= @sy-datum.

  ENDMETHOD.


  METHOD calculate_emi.

* Standard reducing-balance EMI formula:
*   EMI = P * r * (1+r)^n / ( (1+r)^n - 1 )
* where P = principal, r = monthly interest rate (decimal), n = tenure
* in months. Falls back to a straight-line (no-interest) EMI when the
* rate is zero, to avoid a divide-by-zero.
    IF iv_tenure <= 0 OR iv_amount <= 0.
      rv_emi = 0.
      RETURN.
    ENDIF.

    IF iv_rate_pct = 0.
      rv_emi = iv_amount / iv_tenure.
      RETURN.
    ENDIF.

    DATA(lv_r)      = iv_rate_pct / 12 / 100.
    DATA(lv_factor) = ( 1 + lv_r ) ** iv_tenure.

    rv_emi = iv_amount * lv_r * lv_factor / ( lv_factor - 1 ).

  ENDMETHOD.


  METHOD get_next_request_id.

* Portable fallback (no SNRO number range object required): finds the
* highest existing numeric suffix for this client + loan type and
* increments it. A proper SNRO number range per client/loan_type is a
* natural future upgrade - like the reference project's own number-
* range note, it is not abapGit-serializable, so it's left as a manual
* customizing step rather than attempted here. This method's fixed-
* width zero-padded suffix (WIDTH=6) makes lexicographic MAX() on the
* CHAR field equal to numeric MAX, which is what the MAX() below
* depends on - do not generate request IDs any other way.
    DATA: lv_prefix   TYPE string,
          lv_max_id   TYPE zhr_ess_req_head-request_id,
          lv_max_num  TYPE i,
          lv_next_num TYPE i.

    lv_prefix = |{ iv_loan_type }-|.

    SELECT SINGLE MAX( request_id ) FROM zhr_ess_req_head
      INTO @lv_max_id
      WHERE client_id = @iv_client_id
        AND loan_type = @iv_loan_type.

    IF lv_max_id IS NOT INITIAL.
      DATA(lv_suffix) = substring_after( val = lv_max_id sub = '-' ).
      lv_max_num = lv_suffix.
    ENDIF.

    lv_next_num = lv_max_num + 1.

    rv_request_id = |{ lv_prefix }{ lv_next_num WIDTH = 6 PAD = '0' ALIGN = RIGHT }|.

  ENDMETHOD.


  METHOD get_currency_for_cc.

    SELECT SINGLE waers FROM t001
      INTO @rv_currency
      WHERE bukrs = @iv_company_code.

  ENDMETHOD.

ENDCLASS.
