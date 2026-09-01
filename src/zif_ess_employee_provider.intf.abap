INTERFACE zif_ess_employee_provider
  PUBLIC .

************************************************************************
* ZIF_ESS_EMPLOYEE_PROVIDER
* Abstraction over the HR data source used to resolve an employee's
* master data and contact details. Implemented by
* ZCL_ESS_EMPLOYEE_PROVIDER_HCM (on-prem/embedded HCM via infotype
* SELECTs). A future BTP/API-based implementation can satisfy the same
* interface without changing any caller.
************************************************************************

  TYPES:
    BEGIN OF ty_employee_data,
      pernr              TYPE pernr_d,
      employee_name      TYPE string,
      email              TYPE string,
      phone              TYPE string,
      hire_date          TYPE dats,
      basic_salary       TYPE zhr_ess_req_head-basic_salary,
      company_code       TYPE bukrs,
      cost_center        TYPE kostl,
      employee_group     TYPE persg,
      employee_subgroup  TYPE persk,
      is_active          TYPE abap_bool,
      is_suspended       TYPE abap_bool,
      is_probation       TYPE abap_bool,
      service_days       TYPE i,
      is_found           TYPE abap_bool,
    END OF ty_employee_data .

  TYPES:
    BEGIN OF ty_contact_info,
      email       TYPE string,
      phone       TYPE string,
      source_used TYPE string,  " 'IT0006' or 'PA0006' or 'NONE'
    END OF ty_contact_info .

  METHODS get_employee_data
    IMPORTING
      !iv_pernr      TYPE pernr_d
      !iv_key_date   TYPE dats DEFAULT sy-datum
    RETURNING
      VALUE(rs_data) TYPE ty_employee_data .

  METHODS get_employee_contact_info
    IMPORTING
      !iv_pernr         TYPE pernr_d
      !iv_key_date      TYPE dats DEFAULT sy-datum
    RETURNING
      VALUE(rs_contact) TYPE ty_contact_info .

  METHODS get_pernr_for_user
    IMPORTING
      !iv_uname      TYPE syuname DEFAULT sy-uname
    RETURNING
      VALUE(rv_pernr) TYPE pernr_d .

ENDINTERFACE.
