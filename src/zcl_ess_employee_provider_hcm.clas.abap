CLASS zcl_ess_employee_provider_hcm DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_ess_employee_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      gc_subty_basic_salary TYPE subty VALUE '1000',
      gc_subty_email        TYPE subty VALUE '0010',
      gc_subty_phone        TYPE subty VALUE '0020',
      gc_it0101_tabname     TYPE tabname VALUE 'PA0101'.

    METHODS read_pa0000
      IMPORTING
        !iv_pernr     TYPE pernr_d
        !iv_key_date  TYPE dats
      EXPORTING
        !ev_hire_date TYPE dats
        !ev_is_active TYPE abap_bool
        !ev_found     TYPE abap_bool .

    METHODS read_pa0001
      IMPORTING
        !iv_pernr             TYPE pernr_d
        !iv_key_date          TYPE dats
      EXPORTING
        !ev_company_code      TYPE bukrs
        !ev_cost_center       TYPE kostl
        !ev_employee_group    TYPE persg
        !ev_employee_subgroup TYPE persk
        !ev_found             TYPE abap_bool .

    METHODS read_pa0008
      IMPORTING
        !iv_pernr        TYPE pernr_d
        !iv_key_date     TYPE dats
      RETURNING
        VALUE(rv_salary) TYPE p LENGTH 8 DECIMALS 2 .

    METHODS read_employee_name
      IMPORTING
        !iv_pernr      TYPE pernr_d
        !iv_key_date   TYPE dats
      RETURNING
        VALUE(rv_name) TYPE string .

    METHODS is_on_probation
      IMPORTING
        !iv_pernr     TYPE pernr_d
        !iv_key_date  TYPE dats
      RETURNING
        VALUE(rv_yes) TYPE abap_bool .

    METHODS is_suspended
      IMPORTING
        !iv_pernr     TYPE pernr_d
        !iv_key_date  TYPE dats
      RETURNING
        VALUE(rv_yes) TYPE abap_bool .

    METHODS calculate_service_days
      IMPORTING
        !iv_hire_date  TYPE dats
        !iv_key_date   TYPE dats
      RETURNING
        VALUE(rv_days) TYPE i .

ENDCLASS.


CLASS zcl_ess_employee_provider_hcm IMPLEMENTATION.

  METHOD zif_ess_employee_provider~get_employee_data.

    DATA: lv_hire_date TYPE dats,
          lv_active    TYPE abap_bool,
          lv_found_00  TYPE abap_bool,
          lv_cc        TYPE bukrs,
          lv_kostl     TYPE kostl,
          lv_persg     TYPE persg,
          lv_persk     TYPE persk,
          lv_found_01  TYPE abap_bool.

    CLEAR rs_data.
    rs_data-pernr = iv_pernr.

    read_pa0000(
      EXPORTING
        iv_pernr     = iv_pernr
        iv_key_date  = iv_key_date
      IMPORTING
        ev_hire_date = lv_hire_date
        ev_is_active = lv_active
        ev_found     = lv_found_00 ).

    IF lv_found_00 = abap_false.
      rs_data-is_found = abap_false.
      RETURN.
    ENDIF.

    read_pa0001(
      EXPORTING
        iv_pernr             = iv_pernr
        iv_key_date          = iv_key_date
      IMPORTING
        ev_company_code      = lv_cc
        ev_cost_center       = lv_kostl
        ev_employee_group    = lv_persg
        ev_employee_subgroup = lv_persk
        ev_found             = lv_found_01 ).

    rs_data-employee_name     = read_employee_name( iv_pernr = iv_pernr iv_key_date = iv_key_date ).
    rs_data-hire_date         = lv_hire_date.
    rs_data-is_active         = lv_active.
    rs_data-company_code      = lv_cc.
    rs_data-cost_center       = lv_kostl.
    rs_data-employee_group    = lv_persg.
    rs_data-employee_subgroup = lv_persk.
    rs_data-basic_salary      = read_pa0008( iv_pernr = iv_pernr iv_key_date = iv_key_date ).
    rs_data-is_probation      = is_on_probation( iv_pernr = iv_pernr iv_key_date = iv_key_date ).
    rs_data-is_suspended      = is_suspended( iv_pernr = iv_pernr iv_key_date = iv_key_date ).
    rs_data-service_days      = calculate_service_days( iv_hire_date = lv_hire_date iv_key_date = iv_key_date ).

    DATA(ls_contact) = zif_ess_employee_provider~get_employee_contact_info(
                          iv_pernr    = iv_pernr
                          iv_key_date = iv_key_date ).
    rs_data-email = ls_contact-email.
    rs_data-phone = ls_contact-phone.

    rs_data-is_found = abap_true.

  ENDMETHOD.


  METHOD zif_ess_employee_provider~get_employee_contact_info.

* NOTE ON SOURCE CORRECTION (see BUGS_AND_ISSUES.md Issue #005):
* The original architecture notes named infotype 0006 ("Addresses") as
* the primary email/phone source with PA0006 as fallback. Standard SAP
* HR has no email field on 0006 - communication data (email, mobile,
* etc.) lives in infotype 0105 "Communication". Implemented against
* the factually correct standard infotype (0105) as primary, keeping
* PA0006 as a genuine fallback for phone only (PA0006-TELNR is a real
* standard field). Adjust gc_subty_email / gc_subty_phone to match
* your system's T591A subtype configuration for infotype 0105.

    DATA: lv_email  TYPE string,
          lv_phone  TYPE string,
          lv_source TYPE string VALUE 'NONE'.

    SELECT SINGLE usrid_long FROM pa0105
      INTO @lv_email
      WHERE pernr = @iv_pernr
        AND subty = @gc_subty_email
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

    IF sy-subrc = 0 AND lv_email IS NOT INITIAL.
      lv_source = 'IT0105'.
    ELSE.
      CLEAR lv_email.
    ENDIF.

    SELECT SINGLE usrid_long FROM pa0105
      INTO @lv_phone
      WHERE pernr = @iv_pernr
        AND subty = @gc_subty_phone
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

    IF sy-subrc <> 0 OR lv_phone IS INITIAL.
      SELECT SINGLE telnr FROM pa0006
        INTO @lv_phone
        WHERE pernr = @iv_pernr
          AND begda <= @iv_key_date
          AND endda >= @iv_key_date.
      IF sy-subrc = 0 AND lv_phone IS NOT INITIAL AND lv_source = 'NONE'.
        lv_source = 'PA0006'.
      ENDIF.
    ELSE.
      IF lv_source = 'NONE'.
        lv_source = 'IT0105'.
      ENDIF.
    ENDIF.

    rs_contact-email       = lv_email.
    rs_contact-phone       = lv_phone.
    rs_contact-source_used = lv_source.

  ENDMETHOD.


  METHOD zif_ess_employee_provider~get_pernr_for_user.

* Standard system-user -> personnel number mapping via infotype 0105
* subtype '0001' (System User Name / SY-UNAME).
    SELECT SINGLE pernr FROM pa0105
      INTO @rv_pernr
      WHERE subty = '0001'
        AND usrid = @iv_uname
        AND begda <= @sy-datum
        AND endda >= @sy-datum.

  ENDMETHOD.


  METHOD read_pa0000.

    CLEAR: ev_hire_date, ev_is_active, ev_found.

    DATA lv_stat2 TYPE stat2.

    SELECT SINGLE stat2 FROM pa0000
      INTO @lv_stat2
      WHERE pernr = @iv_pernr
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

    IF sy-subrc = 0.
      ev_found     = abap_true.
      ev_is_active = COND #( WHEN lv_stat2 = '3' THEN abap_true ELSE abap_false ).
    ELSE.
      ev_found = abap_false.
      RETURN.
    ENDIF.

    " True hire date = earliest infotype 0000 record for this pernr,
    " independent of iv_key_date (which only selects the status period).
    SELECT SINGLE MIN( begda ) FROM pa0000
      INTO @ev_hire_date
      WHERE pernr = @iv_pernr.

  ENDMETHOD.


  METHOD read_pa0001.

    CLEAR: ev_company_code, ev_cost_center, ev_employee_group,
           ev_employee_subgroup, ev_found.

    SELECT SINGLE bukrs, kostl, persg, persk
      FROM pa0001
      INTO (@ev_company_code, @ev_cost_center, @ev_employee_group, @ev_employee_subgroup)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

    ev_found = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

  ENDMETHOD.


  METHOD read_pa0008.

    SELECT SINGLE bet01 FROM pa0008
      INTO @rv_salary
      WHERE pernr = @iv_pernr
        AND subty = @gc_subty_basic_salary
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

  ENDMETHOD.


  METHOD read_employee_name.

    DATA: lv_vorna TYPE pad_vorna,
          lv_nachn TYPE pad_nachn.

    SELECT SINGLE vorna, nachn FROM pa0002
      INTO (@lv_vorna, @lv_nachn)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

    IF sy-subrc = 0.
      rv_name = |{ lv_vorna } { lv_nachn }|.
    ENDIF.

  ENDMETHOD.


  METHOD is_on_probation.

* Infotype 0041 "Date Specifications" holds the probation end date
* under a customer-configured date-type slot (T548Y). DAT01 is used
* here as the default slot - adjust to the slot your system actually
* uses for "Probation End" if different.
    DATA lv_probation_end TYPE dats.

    SELECT SINGLE dat01 FROM pa0041
      INTO @lv_probation_end
      WHERE pernr = @iv_pernr
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date.

    rv_yes = COND #( WHEN lv_probation_end IS NOT INITIAL
                       AND lv_probation_end > iv_key_date
                      THEN abap_true
                      ELSE abap_false ).

  ENDMETHOD.


  METHOD is_suspended.

* Infotype 0101 ("Disciplinary") is referenced in the original
* architecture notes as this system's suspension source, but it is not
* a universal standard SAP infotype - its presence/structure is
* system-specific. Read via dynamic FROM so a system where PA0101
* doesn't exist fails safe (not suspended) at runtime instead of
* blocking activation of this entire class at compile time. If your
* system has PA0101, this returns TRUE when an active record exists
* at the key date - narrow the WHERE clause with a SUBTY filter if
* suspension needs to be distinguished from other record types there.
    DATA lv_dummy TYPE pernr_d.

    rv_yes = abap_false.

    TRY.
        SELECT SINGLE pernr FROM (gc_it0101_tabname)
          INTO @lv_dummy
          WHERE pernr = @iv_pernr
            AND begda <= @iv_key_date
            AND endda >= @iv_key_date.
        IF sy-subrc = 0.
          rv_yes = abap_true.
        ENDIF.
      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax.
        rv_yes = abap_false.
    ENDTRY.

  ENDMETHOD.


  METHOD calculate_service_days.

    IF iv_hire_date IS INITIAL.
      rv_days = 0.
      RETURN.
    ENDIF.

    rv_days = iv_key_date - iv_hire_date.

  ENDMETHOD.

ENDCLASS.
