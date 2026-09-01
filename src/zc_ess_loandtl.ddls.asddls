@AccessControl.authorizationCheck: #CHECK
@UI.headerInfo: {
  typeName: 'Loan Detail',
  typeNamePlural: 'Loan Details'
}
define view entity ZC_ESS_LOANDTL
  as projection on ZI_ESS_LOANDTL
{
  key ClientId,
  key RequestId,

  @UI.identification: [ { position: 10 } ]
  Purpose,

  @UI.identification: [ { position: 20 } ]
  Amount,

  @UI.identification: [ { position: 30 } ]
  TenureMonths,

  @UI.identification: [ { position: 40 } ]
  EmiAmount,

  @UI.identification: [ { position: 50 } ]
  RateOfInterest,

  @UI.identification: [ { position: 60 } ]
  RepaymentStart,

  @UI.identification: [ { position: 70 } ]
  Remarks,

  CreatedOn,

  _Header : redirected to parent ZC_ESS_REQ_HEAD
}
