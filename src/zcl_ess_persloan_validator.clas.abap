CLASS zcl_ess_persloan_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_ess_loan_validator .

  PRIVATE SECTION.

    METHODS get_message
      IMPORTING
        !iv_client_id      TYPE zhr_ess_valmsg-client_id
        !iv_msg_id         TYPE zhr_ess_valmsg-msg_id
        !it_params         TYPE string_table OPTIONAL
      RETURNING
        VALUE(rs_message)  TYPE zif_ess_validation_engine=>ty_message .

    METHODS get_loan_params
      IMPORTING
        !iv_client_id    TYPE zhr_ess_loanprm-client_id
        !iv_loan_type    TYPE zhr_ess_loanprm-loan_type
      RETURNING
        VALUE(rs_param)  TYPE zif_ess_metadata_provider=>ty_loan_param .

ENDCLASS.


CLASS zcl_ess_persloan_validator IMPLEMENTATION.

  METHOD zif_ess_loan_validator~validate_personal_loan.

    DATA(ls_param) = get_loan_params( iv_client_id = iv_client_id iv_loan_type = 'PERSLOAN' ).

    IF ls_param-is_found = abap_false.
      APPEND get_message( iv_client_id = iv_client_id iv_msg_id = 'ESS_CONFIG_MISSING' ) TO rt_messages.
      RETURN.
    ENDIF.

    IF iv_amount < ls_param-min_amount.
      APPEND get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_AMT_BELOW_MIN'
               it_params    = VALUE #( ( |{ iv_amount }| ) ( |{ ls_param-min_amount }| ) ) )
        TO rt_messages.
    ENDIF.

    IF iv_amount > ls_param-max_amount.
      APPEND get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_AMT_ABOVE_MAX'
               it_params    = VALUE #( ( |{ iv_amount }| ) ( |{ ls_param-max_amount }| ) ) )
        TO rt_messages.
    ENDIF.

    IF iv_tenure_months < ls_param-min_tenure_months.
      APPEND get_message( iv_client_id = iv_client_id iv_msg_id = 'ESS_TENURE_BELOW_MIN' ) TO rt_messages.
    ENDIF.

    IF iv_tenure_months > ls_param-max_tenure_months.
      APPEND get_message( iv_client_id = iv_client_id iv_msg_id = 'ESS_TENURE_ABOVE_MAX' ) TO rt_messages.
    ENDIF.

    IF ls_param-salary_multiple > 0 AND iv_basic_salary > 0.
      DATA(lv_cap) = iv_basic_salary * ls_param-salary_multiple.
      IF iv_amount > lv_cap.
        APPEND get_message(
                 iv_client_id = iv_client_id
                 iv_msg_id    = 'ESS_AMT_EXCEEDS_CAP'
                 it_params    = VALUE #( ( |{ iv_amount }| ) ( |{ lv_cap }| ) ) )
          TO rt_messages.
      ENDIF.
    ENDIF.

    IF iv_service_days < ls_param-min_service_days.
      APPEND get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_TENURE_SHORT'
               it_params    = VALUE #( ( |{ iv_service_days }| )
                                        ( |{ ls_param-min_service_days }| )
                                        ( |{ sy-datum + ( ls_param-min_service_days - iv_service_days ) }| ) ) )
        TO rt_messages.
    ENDIF.

    IF iv_is_probation = abap_true AND ls_param-allow_during_probation = abap_false.
      APPEND get_message( iv_client_id = iv_client_id iv_msg_id = 'ESS_PROBATION_BLOCKED' ) TO rt_messages.
    ENDIF.

    IF iv_is_contract = abap_true AND ls_param-allow_contract_employees = abap_false.
      APPEND get_message( iv_client_id = iv_client_id iv_msg_id = 'ESS_CONTRACT_BLOCKED' ) TO rt_messages.
    ENDIF.

  ENDMETHOD.


  METHOD zif_ess_loan_validator~check_existing_loan.

    SELECT client_id, request_id, status FROM zhr_ess_req_head
      INTO TABLE @DATA(lt_existing)
      WHERE client_id      = @iv_client_id
        AND employee_pernr = @iv_pernr
        AND loan_type      = @iv_loan_type
        AND status         IN ( 'D', 'S', 'A', 'R' )   " active / non-terminal statuses only
        AND request_id     <> @iv_exclude_request.

    IF lines( lt_existing ) > 0.
      APPEND get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_EXISTING_LOAN'
               it_params    = VALUE #( ( lt_existing[ 1 ]-request_id ) ) )
        TO rt_messages.
    ENDIF.

  ENDMETHOD.


  METHOD get_message.

    DATA ls_msg TYPE zhr_ess_valmsg.

    SELECT SINGLE * FROM zhr_ess_valmsg
      INTO @ls_msg
      WHERE client_id = @iv_client_id
        AND msg_id    = @iv_msg_id
        AND active    = @abap_true.

    IF sy-subrc <> 0.
      rs_message-msg_id     = iv_msg_id.
      rs_message-msg_type   = 'E'.
      rs_message-msg_text   = |Message { iv_msg_id } not configured|.
      rs_message-msg_detail = rs_message-msg_text.
      RETURN.
    ENDIF.

    rs_message-msg_id     = ls_msg-msg_id.
    rs_message-msg_type   = ls_msg-msg_type.
    rs_message-msg_text   = ls_msg-msg_text.
    rs_message-msg_detail = ls_msg-msg_detail.

    IF ls_msg-msg_params IS NOT INITIAL AND it_params IS NOT INITIAL.
      DATA(lt_param_names) = VALUE string_table( ).
      SPLIT ls_msg-msg_params AT ',' INTO TABLE lt_param_names.

      DATA(lv_count) = nmin( val1 = lines( it_params ) val2 = lines( lt_param_names ) ).
      DO lv_count TIMES.
        DATA(lv_idx)   = sy-index.
        DATA(lv_name)  = lt_param_names[ lv_idx ].
        CONDENSE lv_name.
        DATA(lv_token) = |\{{ lv_name }\}|.
        REPLACE ALL OCCURRENCES OF lv_token IN rs_message-msg_detail WITH it_params[ lv_idx ].
      ENDDO.
    ENDIF.

  ENDMETHOD.


  METHOD get_loan_params.

    DATA ls_param TYPE zhr_ess_loanprm.

    SELECT SINGLE * FROM zhr_ess_loanprm
      INTO @ls_param
      WHERE client_id = @iv_client_id
        AND loan_type = @iv_loan_type
        AND active    = @abap_true.

    IF sy-subrc <> 0.
      rs_param-is_found = abap_false.
      RETURN.
    ENDIF.

    rs_param-min_amount               = ls_param-min_amount.
    rs_param-max_amount               = ls_param-max_amount.
    rs_param-max_tenure_months        = ls_param-max_tenure_months.
    rs_param-min_tenure_months        = ls_param-min_tenure_months.
    rs_param-salary_multiple          = ls_param-salary_multiple.
    rs_param-min_service_days         = ls_param-min_service_days.
    rs_param-allow_during_probation   = ls_param-allow_during_probation.
    rs_param-allow_contract_employees = ls_param-allow_contract_employees.
    rs_param-is_found                 = abap_true.

  ENDMETHOD.

ENDCLASS.
