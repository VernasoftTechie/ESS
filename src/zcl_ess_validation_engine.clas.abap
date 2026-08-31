CLASS zcl_ess_validation_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_ess_validation_engine .

  PRIVATE SECTION.

    METHODS format_detail
      IMPORTING
        !iv_detail      TYPE string
        !it_params      TYPE string_table
        !it_param_names TYPE string_table
      RETURNING
        VALUE(rv_text)  TYPE string .

    METHODS get_employee_provider
      RETURNING
        VALUE(ro_provider) TYPE REF TO zif_ess_employee_provider .

    METHODS get_loan_validator
      IMPORTING
        !iv_loan_type      TYPE zhr_ess_req_head-loan_type
      RETURNING
        VALUE(ro_validator) TYPE REF TO zif_ess_loan_validator .

ENDCLASS.


CLASS zcl_ess_validation_engine IMPLEMENTATION.

  METHOD zif_ess_validation_engine~get_message.

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

    rs_message-msg_id   = ls_msg-msg_id.
    rs_message-msg_type = ls_msg-msg_type.
    rs_message-msg_text = ls_msg-msg_text.

    IF ls_msg-msg_params IS NOT INITIAL AND it_params IS NOT INITIAL.
      DATA(lt_param_names) = VALUE string_table( ).
      SPLIT ls_msg-msg_params AT ',' INTO TABLE lt_param_names.
      rs_message-msg_detail = format_detail(
                                 iv_detail      = ls_msg-msg_detail
                                 it_params      = it_params
                                 it_param_names = lt_param_names ).
    ELSE.
      rs_message-msg_detail = ls_msg-msg_detail.
    ENDIF.

  ENDMETHOD.


  METHOD format_detail.

    rv_text = iv_detail.

    DATA(lv_count) = nmin( val1 = lines( it_params ) val2 = lines( it_param_names ) ).

    DO lv_count TIMES.
      DATA(lv_idx)  = sy-index.
      DATA(lv_name) = it_param_names[ lv_idx ].
      CONDENSE lv_name.
      DATA(lv_token) = |\{{ lv_name }\}|.
      REPLACE ALL OCCURRENCES OF lv_token IN rv_text WITH it_params[ lv_idx ].
    ENDDO.

  ENDMETHOD.


  METHOD zif_ess_validation_engine~validate_eligibility.

    DATA(lo_emp) = get_employee_provider( ).
    DATA(ls_emp) = lo_emp->get_employee_data( iv_pernr = iv_pernr ).

    IF ls_emp-is_found = abap_false.
      APPEND zif_ess_validation_engine~get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_EMP_INACTIVE' ) TO rt_messages.
      RETURN.
    ENDIF.

    IF ls_emp-is_active = abap_false.
      APPEND zif_ess_validation_engine~get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_EMP_INACTIVE' ) TO rt_messages.
    ENDIF.

    IF ls_emp-is_suspended = abap_true.
      APPEND zif_ess_validation_engine~get_message(
               iv_client_id = iv_client_id
               iv_msg_id    = 'ESS_EMP_SUSPENDED' ) TO rt_messages.
    ENDIF.

    DATA(lo_validator) = get_loan_validator( iv_loan_type ).
    IF lo_validator IS BOUND.

      DATA(lt_loan_msgs) = lo_validator->validate_personal_loan(
                              iv_client_id     = iv_client_id
                              iv_pernr         = iv_pernr
                              iv_amount        = iv_amount
                              iv_tenure_months = iv_tenure_months
                              iv_basic_salary  = ls_emp-basic_salary
                              iv_service_days  = ls_emp-service_days
                              iv_is_probation  = ls_emp-is_probation
                              iv_is_contract   = abap_false ).
      APPEND LINES OF lt_loan_msgs TO rt_messages.

      DATA(lt_existing_msgs) = lo_validator->check_existing_loan(
                                  iv_client_id = iv_client_id
                                  iv_pernr     = iv_pernr
                                  iv_loan_type = iv_loan_type ).
      APPEND LINES OF lt_existing_msgs TO rt_messages.

    ENDIF.

  ENDMETHOD.


  METHOD zif_ess_validation_engine~validate_request_integrity.

    DATA ls_head TYPE zhr_ess_req_head.

    SELECT SINGLE * FROM zhr_ess_req_head
      INTO @ls_head
      WHERE client_id  = @iv_client_id
        AND request_id = @iv_request_id.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    IF ls_head-amount IS INITIAL OR ls_head-amount <= 0.
      APPEND VALUE #( msg_id   = 'ESS_AMOUNT_INVALID'
                       msg_type = 'E'
                       msg_text = 'Amount must be greater than zero' )
        TO rt_messages.
    ENDIF.

    IF ls_head-tenure_months IS INITIAL OR ls_head-tenure_months <= 0.
      APPEND VALUE #( msg_id   = 'ESS_TENURE_INVALID'
                       msg_type = 'E'
                       msg_text = 'Tenure must be greater than zero months' )
        TO rt_messages.
    ENDIF.

  ENDMETHOD.


  METHOD zif_ess_validation_engine~has_errors.

    rv_yes = line_exists( it_messages[ msg_type = 'E' ] ).

  ENDMETHOD.


  METHOD get_employee_provider.

    ro_provider = NEW zcl_ess_employee_provider_hcm( ).

  ENDMETHOD.


  METHOD get_loan_validator.

    CASE iv_loan_type.
      WHEN 'PERSLOAN'.
        ro_validator = NEW zcl_ess_persloan_validator( ).
      WHEN OTHERS.
        CLEAR ro_validator. " No validator implemented yet for this loan type (Phase 2+)
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
