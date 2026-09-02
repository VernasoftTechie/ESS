CLASS lhc_zess_v1_loanreq IMPLEMENTATION.

  METHOD resolveEmployeeData.

* Fills employee_name/email/basic_salary/company_code once, right
* after create, from the Service Layer (ZCL_ESS_EMPLOYEE_PROVIDER_HCM,
* activated in Stage 2). Skips rows where EmployeePernr hasn't been
* set yet, or where the provider can't find that pernr.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        FIELDS ( ClientId RequestId EmployeePernr )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_update TYPE TABLE FOR UPDATE zi_ess_req_head\\LoanRequest.

    DATA(lo_provider) = NEW zcl_ess_employee_provider_hcm( ).

    LOOP AT lt_requests INTO DATA(ls_request).

      IF ls_request-EmployeePernr IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(ls_emp) = lo_provider->zif_ess_employee_provider~get_employee_data(
                        iv_pernr = ls_request-EmployeePernr ).

      IF ls_emp-is_found = abap_false.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( ClientId      = ls_request-ClientId
                       RequestId     = ls_request-RequestId
                       EmployeeName  = ls_emp-employee_name
                       EmployeeEmail = ls_emp-email
                       BasicSalary   = ls_emp-basic_salary
                       CompanyCode   = ls_emp-company_code
                       %control-EmployeeName  = if_abap_behv=>mk-on
                       %control-EmployeeEmail = if_abap_behv=>mk-on
                       %control-BasicSalary   = if_abap_behv=>mk-on
                       %control-CompanyCode   = if_abap_behv=>mk-on )
        TO lt_update.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ess_req_head IN LOCAL MODE
        ENTITY LoanRequest
          UPDATE FIELDS ( EmployeeName EmployeeEmail BasicSalary CompanyCode )
          WITH lt_update.
    ENDIF.

  ENDMETHOD.


  METHOD calcEmiSchedule.

* Recalculates EMI/interest rate on the associated LoanDetail child
* whenever Amount or TenureMonths change, via ZCL_ESS_METADATA_PROVIDER
* (interest rate lookup) and ZCL_ESS_UTILITY=>calculate_emi. Assumes
* LoanDetail already exists for this request (created together with
* the header via deep create) - if it doesn't yet, the UPDATE below
* simply has no matching row and is a no-op for that request.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        FIELDS ( ClientId RequestId LoanType Amount TenureMonths )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_update TYPE TABLE FOR UPDATE zi_ess_req_head\\LoanDetail.

    DATA(lo_metadata) = NEW zcl_ess_metadata_provider( ).

    LOOP AT lt_requests INTO DATA(ls_request).

      IF ls_request-Amount IS INITIAL OR ls_request-TenureMonths IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_rate) = lo_metadata->zif_ess_metadata_provider~get_interest_rate(
                         iv_client_id = ls_request-ClientId
                         iv_loan_type = ls_request-LoanType ).

      DATA(lv_emi) = zcl_ess_utility=>calculate_emi(
                        iv_amount   = ls_request-Amount
                        iv_rate_pct = lv_rate
                        iv_tenure   = ls_request-TenureMonths ).

      APPEND VALUE #( ClientId       = ls_request-ClientId
                       RequestId      = ls_request-RequestId
                       EmiAmount      = lv_emi
                       RateOfInterest = lv_rate
                       %control-EmiAmount      = if_abap_behv=>mk-on
                       %control-RateOfInterest = if_abap_behv=>mk-on )
        TO lt_update.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ess_req_head IN LOCAL MODE
        ENTITY LoanDetail
          UPDATE FIELDS ( EmiAmount RateOfInterest )
          WITH lt_update.
    ENDIF.

  ENDMETHOD.


  METHOD validateEligibility.

* Delegates to ZCL_ESS_VALIDATION_ENGINE (Stage 2), which itself calls
* the employee provider and loan validator. Any ERROR-severity message
* blocks save via FAILED; kept deliberately minimal (no populated %msg
* text yet) for this first activation pass - see BUGS_AND_ISSUES.md
* Issue #011.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        FIELDS ( ClientId RequestId EmployeePernr LoanType Amount TenureMonths )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA(lo_engine) = NEW zcl_ess_validation_engine( ).

    LOOP AT lt_requests INTO DATA(ls_request).

      DATA(lt_messages) = lo_engine->zif_ess_validation_engine~validate_eligibility(
                             iv_client_id     = ls_request-ClientId
                             iv_pernr         = ls_request-EmployeePernr
                             iv_loan_type     = ls_request-LoanType
                             iv_amount        = ls_request-Amount
                             iv_tenure_months = ls_request-TenureMonths ).

      IF lo_engine->zif_ess_validation_engine~has_errors( lt_messages ) = abap_true.
        APPEND VALUE #( %tky = ls_request-%tky ) TO failed-loanrequest.
        APPEND VALUE #( %tky = ls_request-%tky ) TO reported-loanrequest.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD submit.

* Moves a Draft/Returned request to Submitted, resolving the approval
* chain via ZCL_ESS_WORKFLOW_ENGINE and snapshotting it into
* ZHR_ESS_APPRSTEP with a direct table INSERT (that entity exposes no
* RAP create - it's a system-managed, read-only-to-the-API child, see
* DDIC/01_DDIC_COMPLETE_SPECIFICATION.md). Attempt number increments
* on resubmit after a Return, per the documented Return/Resubmit
* behavior.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        FIELDS ( ClientId RequestId LoanType Amount EmployeePernr Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_update TYPE TABLE FOR UPDATE zi_ess_req_head\\LoanRequest.

    LOOP AT lt_requests INTO DATA(ls_request).

      IF ls_request-Status <> 'D' AND ls_request-Status <> 'R'.
        APPEND VALUE #( %tky = ls_request-%tky ) TO failed-loanrequest.
        CONTINUE.
      ENDIF.

      DATA(lo_workflow) = NEW zcl_ess_workflow_engine( ).
      DATA(lt_chain) = lo_workflow->zif_ess_workflow_engine~resolve_approval_chain(
                          iv_client_id = ls_request-ClientId
                          iv_loan_type = ls_request-LoanType
                          iv_pernr     = ls_request-EmployeePernr
                          iv_amount    = ls_request-Amount ).

      IF lt_chain IS INITIAL.
        APPEND VALUE #( %tky = ls_request-%tky ) TO failed-loanrequest.
        CONTINUE.
      ENDIF.

      SELECT SINGLE MAX( attempt ) FROM zhr_ess_apprstep
        INTO @DATA(lv_max_attempt)
        WHERE client_id  = @ls_request-ClientId
          AND request_id = @ls_request-RequestId.
      DATA(lv_attempt) = COND #( WHEN lv_max_attempt IS INITIAL THEN 1 ELSE lv_max_attempt + 1 ).

      LOOP AT lt_chain INTO DATA(ls_step).
        INSERT zhr_ess_apprstep FROM @( VALUE #(
          client_id             = ls_request-ClientId
          request_id            = ls_request-RequestId
          appr_level             = ls_step-appr_level
          attempt                 = lv_attempt
          approver_pernr           = ls_step-approver_pernr
          approver_name             = ls_step-approver_name
          relationship_id_used       = ls_step-relationship_id_used
          status                     = 'P'
          sla_due_date               = ls_step-sla_due_date ) ).
      ENDLOOP.

      DATA(ls_first_step) = lt_chain[ 1 ].

      APPEND VALUE #( ClientId             = ls_request-ClientId
                       RequestId            = ls_request-RequestId
                       Status               = 'S'
                       CurrentLevel         = 1
                       CurrentApproverPernr = ls_first_step-approver_pernr
                       CurrentApproverName  = ls_first_step-approver_name
                       SubmitDate           = sy-datum
                       SubmitTime           = sy-uzeit
                       %control-Status               = if_abap_behv=>mk-on
                       %control-CurrentLevel         = if_abap_behv=>mk-on
                       %control-CurrentApproverPernr = if_abap_behv=>mk-on
                       %control-CurrentApproverName  = if_abap_behv=>mk-on
                       %control-SubmitDate           = if_abap_behv=>mk-on
                       %control-SubmitTime           = if_abap_behv=>mk-on )
        TO lt_update.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ess_req_head IN LOCAL MODE
        ENTITY LoanRequest
          UPDATE FIELDS ( Status CurrentLevel CurrentApproverPernr CurrentApproverName SubmitDate SubmitTime )
          WITH lt_update.
    ENDIF.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).

  ENDMETHOD.


  METHOD withdraw.

* Sets status to Withdrawn from Draft, Submitted, or In Approval.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        FIELDS ( ClientId RequestId Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_update TYPE TABLE FOR UPDATE zi_ess_req_head\\LoanRequest.

    LOOP AT lt_requests INTO DATA(ls_request).

      IF ls_request-Status <> 'D' AND ls_request-Status <> 'S' AND ls_request-Status <> 'A'.
        APPEND VALUE #( %tky = ls_request-%tky ) TO failed-loanrequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( ClientId  = ls_request-ClientId
                       RequestId = ls_request-RequestId
                       Status    = 'W'
                       %control-Status = if_abap_behv=>mk-on )
        TO lt_update.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ess_req_head IN LOCAL MODE
        ENTITY LoanRequest
          UPDATE FIELDS ( Status )
          WITH lt_update.
    ENDIF.

    READ ENTITIES OF zi_ess_req_head IN LOCAL MODE
      ENTITY LoanRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).

  ENDMETHOD.

ENDCLASS.
