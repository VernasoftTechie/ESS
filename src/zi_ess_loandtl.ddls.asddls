@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'ESS Personal Loan Details'
define view entity ZI_ESS_LOANDTL
  as select from zhr_ess_loandtl

  association to parent ZI_ESS_REQ_HEAD as _Header
    on  $projection.ClientId  = _Header.ClientId
    and $projection.RequestId = _Header.RequestId
{
  key client_id       as ClientId,
  key request_id       as RequestId,
      purpose           as Purpose,
      amount            as Amount,
      tenure_months     as TenureMonths,
      emi_amount        as EmiAmount,
      rate_of_interest  as RateOfInterest,
      repayment_start   as RepaymentStart,
      remarks           as Remarks,
      created_on        as CreatedOn,

      _Header
}
