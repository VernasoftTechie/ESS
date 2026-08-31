CLASS zcl_ess_workflow_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_ess_workflow_engine .

  PRIVATE SECTION.

    METHODS get_approver_name
      IMPORTING
        !iv_pernr      TYPE pernr_d
      RETURNING
        VALUE(rv_name) TYPE string .

ENDCLASS.


CLASS zcl_ess_workflow_engine IMPLEMENTATION.

  METHOD zif_ess_workflow_engine~resolve_approval_chain.

    DATA(lv_no_end) = VALUE dats( ).  " '00000000' - "no end date" sentinel

    " Step 1: find the highest level whose amount bracket contains
    " iv_amount. Brackets are configured non-overlapping and ascending
    " (e.g. L1: 0-500K, L2: 500K-2M, L3: 2M-unlimited) so the matched
    " level is the TOP of the chain - all levels 1..matched participate.
    SELECT SINGLE appr_level FROM zhr_ess_wfconfig
      INTO @DATA(lv_top_level)
      WHERE client_id      = @iv_client_id
        AND loan_type      = @iv_loan_type
        AND active         = @abap_true
        AND effective_from <= @iv_key_date
        AND ( effective_to = @lv_no_end OR effective_to >= @iv_key_date )
        AND amount_from    <= @iv_amount
        AND amount_to      >  @iv_amount.

    IF sy-subrc <> 0.
      " No bracket matched (e.g. amount at/above the highest configured
      " amount_to) - fall back to the single highest level configured.
      SELECT SINGLE MAX( appr_level ) FROM zhr_ess_wfconfig
        INTO @lv_top_level
        WHERE client_id      = @iv_client_id
          AND loan_type      = @iv_loan_type
          AND active         = @abap_true
          AND effective_from <= @iv_key_date
          AND ( effective_to = @lv_no_end OR effective_to >= @iv_key_date ).
    ENDIF.

    IF lv_top_level IS INITIAL.
      RETURN.  " No approval chain configured for this loan type/client
    ENDIF.

    " Step 2: build the chain from level 1 through lv_top_level
    SELECT appr_level, relationship_id, fallback_pernr, default_sla_days
      FROM zhr_ess_wfconfig
      INTO TABLE @DATA(lt_levels)
      WHERE client_id      = @iv_client_id
        AND loan_type      = @iv_loan_type
        AND active         = @abap_true
        AND effective_from <= @iv_key_date
        AND ( effective_to = @lv_no_end OR effective_to >= @iv_key_date )
        AND appr_level     <= @lv_top_level
      ORDER BY appr_level ASCENDING.

    LOOP AT lt_levels INTO DATA(ls_level).

      DATA(lv_approver) = zif_ess_workflow_engine~get_approver_by_relationship(
                             iv_pernr           = iv_pernr
                             iv_relationship_id = ls_level-relationship_id
                             iv_key_date        = iv_key_date ).

      DATA(lv_rel_used) = ls_level-relationship_id.
      IF lv_approver IS INITIAL.
        lv_approver = ls_level-fallback_pernr.
        lv_rel_used = 'FALLBACK'.
      ENDIF.

      APPEND VALUE #( appr_level           = ls_level-appr_level
                       relationship_id_used = lv_rel_used
                       approver_pernr       = lv_approver
                       approver_name        = get_approver_name( lv_approver )
                       sla_due_date         = iv_key_date + ls_level-default_sla_days )
        TO rt_chain.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_ess_workflow_engine~get_approver_by_relationship.

* Resolves the approver via HR org-relationship (HRP1001). This is a
* simplified, single-hop Person->Person lookup for relationship A002
* ("reports to") - real org models more commonly route this through
* Position objects (Person -holds-> Position -reports_to-> Position
* -held_by-> Person), which varies by how each system's org structure
* is built. Treat this as a working starting point for the common case,
* not a universal resolver; extend per-relationship as needed. Any
* relationship_id this method can't resolve returns an initial value,
* and the caller (resolve_approval_chain) falls back to the level's
* mandatory fallback_pernr - by design, this can never leave a chain
* step without an approver.
    IF iv_relationship_id = 'A002'.

      SELECT SINGLE sobid FROM hrp1001
        INTO @DATA(lv_sobid)
        WHERE otype = 'P'
          AND objid = @iv_pernr
          AND plvar = '01'
          AND rsign = 'A'
          AND relat = '002'
          AND sclas = 'P'
          AND begda <= @iv_key_date
          AND endda >= @iv_key_date.

      IF sy-subrc = 0.
        rv_approver_pernr = lv_sobid.
      ENDIF.

    ELSE.
* Other relationship IDs (A006, HR, Finance, or client-specific codes)
* are not yet resolved automatically here - left initial so the caller
* falls back to fallback_pernr. Extend this ELSE branch as more
* relationship types are implemented.
      CLEAR rv_approver_pernr.
    ENDIF.

  ENDMETHOD.


  METHOD get_approver_name.

    DATA: lv_vorna TYPE pad_vorna,
          lv_nachn TYPE pad_nachn.

    SELECT SINGLE vorna, nachn FROM pa0002
      INTO (@lv_vorna, @lv_nachn)
      WHERE pernr = @iv_pernr
        AND begda <= @sy-datum
        AND endda >= @sy-datum.

    IF sy-subrc = 0.
      rv_name = |{ lv_vorna } { lv_nachn }|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
