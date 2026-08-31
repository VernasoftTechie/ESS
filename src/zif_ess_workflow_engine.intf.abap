INTERFACE zif_ess_workflow_engine
  PUBLIC .

************************************************************************
* ZIF_ESS_WORKFLOW_ENGINE
* Resolves the approval chain for a request from ZHR_ESS_WFCONFIG
* (amount-bracket matched, level-ordered), and resolves each level's
* actual approver via org relationship (HRP1001), falling back to the
* level's mandatory fallback_pernr when the relationship doesn't
* resolve. Snapshot rows are written to ZHR_ESS_APPRSTEP by the RAP
* determination that calls resolve_approval_chain() at submit time.
************************************************************************

  TYPES:
    BEGIN OF ty_appr_step,
      appr_level           TYPE zhr_ess_apprstep-appr_level,
      relationship_id_used TYPE zhr_ess_apprstep-relationship_id_used,
      approver_pernr       TYPE zhr_ess_apprstep-approver_pernr,
      approver_name        TYPE string,
      sla_due_date         TYPE zhr_ess_apprstep-sla_due_date,
    END OF ty_appr_step .
  TYPES:
    ty_appr_step_tab TYPE STANDARD TABLE OF ty_appr_step WITH EMPTY KEY .

  METHODS resolve_approval_chain
    IMPORTING
      !iv_client_id   TYPE zhr_ess_wfconfig-client_id
      !iv_loan_type   TYPE zhr_ess_wfconfig-loan_type
      !iv_pernr       TYPE pernr_d
      !iv_amount      TYPE zhr_ess_req_head-amount
      !iv_key_date    TYPE dats DEFAULT sy-datum
    RETURNING
      VALUE(rt_chain) TYPE ty_appr_step_tab .

  METHODS get_approver_by_relationship
    IMPORTING
      !iv_pernr               TYPE pernr_d
      !iv_relationship_id     TYPE zhr_ess_wfconfig-relationship_id
      !iv_key_date            TYPE dats DEFAULT sy-datum
    RETURNING
      VALUE(rv_approver_pernr) TYPE pernr_d .

ENDINTERFACE.
