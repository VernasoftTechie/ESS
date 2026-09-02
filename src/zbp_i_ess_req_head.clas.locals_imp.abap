CLASS lhc_LoanRequest DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR LoanRequest RESULT result.

    METHODS submit FOR MODIFY
      IMPORTING keys FOR ACTION LoanRequest~submit RESULT result.

    METHODS withdraw FOR MODIFY
      IMPORTING keys FOR ACTION LoanRequest~withdraw RESULT result.

    METHODS calcEmiSchedule FOR DETERMINE ON MODIFY
      IMPORTING keys FOR LoanRequest~calcEmiSchedule.

    METHODS resolveEmployeeData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR LoanRequest~resolveEmployeeData.

    METHODS validateEligibility FOR VALIDATE ON SAVE
      IMPORTING keys FOR LoanRequest~validateEligibility.

ENDCLASS.

CLASS lhc_LoanRequest IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD submit.
  ENDMETHOD.

  METHOD withdraw.
  ENDMETHOD.

  METHOD calcEmiSchedule.
  ENDMETHOD.

  METHOD resolveEmployeeData.
  ENDMETHOD.

  METHOD validateEligibility.
  ENDMETHOD.

ENDCLASS.
