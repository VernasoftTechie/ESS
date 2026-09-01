@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'ESS Loan Request Header'
define root view entity ZI_ESS_REQ_HEAD
  as select from zhr_ess_req_head

  composition [0..1] of ZI_ESS_LOANDTL  as _LoanDetail
  composition [0..*] of ZI_ESS_REQ_ITEM as _Items
  composition [0..*] of ZI_ESS_APPRSTEP as _ApprovalSteps
  composition [0..*] of ZI_ESS_CUSTVAL  as _CustomValues
{
  key client_id             as ClientId,
  key request_id             as RequestId,
      employee_pernr          as EmployeePernr,
      employee_name           as EmployeeName,
      employee_email          as EmployeeEmail,
      loan_type               as LoanType,
      status                  as Status,
      current_level           as CurrentLevel,
      current_approver_pernr  as CurrentApproverPernr,
      current_approver_name   as CurrentApproverName,
      request_date            as RequestDate,
      request_time            as RequestTime,
      submit_date             as SubmitDate,
      submit_time             as SubmitTime,
      amount                  as Amount,
      currency                as Currency,
      tenure_months           as TenureMonths,
      basic_salary            as BasicSalary,
      company_code            as CompanyCode,
      created_on              as CreatedOn,
      created_by              as CreatedBy,
      changed_on              as ChangedOn,
      changed_by              as ChangedBy,

      _LoanDetail,
      _Items,
      _ApprovalSteps,
      _CustomValues
}
