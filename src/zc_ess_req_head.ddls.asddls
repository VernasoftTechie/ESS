@AccessControl.authorizationCheck: #CHECK
@UI.headerInfo: {
  typeName: 'Loan Request',
  typeNamePlural: 'Loan Requests',
  title: { type: #STANDARD, value: 'RequestId' },
  description: { type: #STANDARD, value: 'LoanType' }
}
define root view entity ZC_ESS_REQ_HEAD
  provider contract transactional_query
  as projection on ZI_ESS_REQ_HEAD
{
  @UI.facet: [
    { id: 'Overview', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Request Overview', position: 10 },
    { id: 'LoanDetail', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, targetElement: '_LoanDetail', label: 'Loan Details', position: 20 },
    { id: 'Items', purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Items', label: 'Request Items', position: 30 },
    { id: 'ApprovalTimeline', purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_ApprovalSteps', label: 'Approval Timeline', position: 40 },
    { id: 'CustomFields', purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_CustomValues', label: 'Additional Details', position: 50 }
  ]
  key ClientId,
  key RequestId,

  @UI.lineItem: [ { position: 10, importance: #HIGH } ]
  @UI.identification: [ { position: 10 } ]
  EmployeePernr,

  @UI.identification: [ { position: 20 } ]
  EmployeeName,

  @UI.identification: [ { position: 30 } ]
  EmployeeEmail,

  @UI.lineItem: [ { position: 20 } ]
  @UI.identification: [ { position: 40 } ]
  LoanType,

  @UI.lineItem: [ { position: 30 } ]
  @UI.identification: [ { position: 50 } ]
  Status,

  @UI.identification: [ { position: 60 } ]
  CurrentLevel,

  @UI.identification: [ { position: 70 } ]
  CurrentApproverPernr,

  @UI.identification: [ { position: 80 } ]
  CurrentApproverName,

  @UI.identification: [ { position: 90 } ]
  RequestDate,

  RequestTime,

  @UI.identification: [ { position: 100 } ]
  SubmitDate,

  SubmitTime,

  @Semantics.amount.currencyCode: 'Currency'
  @UI.lineItem: [ { position: 40 } ]
  @UI.identification: [ { position: 110 } ]
  Amount,

  @Semantics.currencyCode: true
  Currency,

  @UI.identification: [ { position: 120 } ]
  TenureMonths,

  @Semantics.amount.currencyCode: 'Currency'
  @UI.identification: [ { position: 130 } ]
  BasicSalary,

  @UI.identification: [ { position: 140 } ]
  CompanyCode,

  CreatedOn,
  CreatedBy,
  ChangedOn,
  ChangedBy,

  _LoanDetail    : redirected to composition child ZC_ESS_LOANDTL,
  _Items         : redirected to composition child ZC_ESS_REQ_ITEM,
  _ApprovalSteps : redirected to composition child ZC_ESS_APPRSTEP,
  _CustomValues  : redirected to composition child ZC_ESS_CUSTVAL
}
