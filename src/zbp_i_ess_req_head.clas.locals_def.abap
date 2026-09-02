CLASS lhc_zess_v1_loanreq DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS resolveEmployeeData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR LoanRequest~resolveEmployeeData .

    METHODS calcEmiSchedule FOR DETERMINE ON MODIFY
      IMPORTING keys FOR LoanRequest~calcEmiSchedule .

    METHODS validateEligibility FOR VALIDATE ON SAVE
      IMPORTING keys FOR LoanRequest~validateEligibility .

    METHODS submit FOR MODIFY
      IMPORTING keys FOR ACTION LoanRequest~submit RESULT result .

    METHODS withdraw FOR MODIFY
      IMPORTING keys FOR ACTION LoanRequest~withdraw RESULT result .

ENDCLASS.
