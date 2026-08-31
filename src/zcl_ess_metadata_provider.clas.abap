CLASS zcl_ess_metadata_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_ess_metadata_provider .

ENDCLASS.


CLASS zcl_ess_metadata_provider IMPLEMENTATION.

  METHOD zif_ess_metadata_provider~get_loan_params.

    DATA ls_param  TYPE zhr_ess_loanprm.
    DATA(lv_no_end) = VALUE dats( ).  " '00000000' - "no end date" sentinel

    SELECT SINGLE * FROM zhr_ess_loanprm
      INTO @ls_param
      WHERE client_id      = @iv_client_id
        AND loan_type      = @iv_loan_type
        AND active         = @abap_true
        AND effective_from <= @iv_key_date
        AND ( effective_to = @lv_no_end OR effective_to >= @iv_key_date ).

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


  METHOD zif_ess_metadata_provider~get_custom_fields.

    SELECT field_key, field_label, field_type, mandatory, field_order,
           field_length, dropdown_domain, help_text, validation_regex
      FROM zhr_ess_custfld
      INTO TABLE @DATA(lt_fields)
      WHERE client_id = @iv_client_id
        AND loan_type = @iv_loan_type
        AND active    = @abap_true
      ORDER BY field_order.

    rt_fields = CORRESPONDING #( lt_fields ).

  ENDMETHOD.


  METHOD zif_ess_metadata_provider~get_interest_rate.

    SELECT SINGLE rate_percent FROM zhr_ess_int_rate
      INTO @rv_rate
      WHERE client_id      = @iv_client_id
        AND loan_type      = @iv_loan_type
        AND effective_date <= @iv_key_date
        AND active         = @abap_true
      ORDER BY effective_date DESCENDING.

  ENDMETHOD.

ENDCLASS.
