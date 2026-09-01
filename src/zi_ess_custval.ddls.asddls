@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'ESS Custom Field Value'
define view entity ZI_ESS_CUSTVAL
  as select from zhr_ess_custval

  association to parent ZI_ESS_REQ_HEAD as _Header
    on  $projection.ClientId  = _Header.ClientId
    and $projection.RequestId = _Header.RequestId
{
  key client_id     as ClientId,
  key request_id     as RequestId,
  key field_key       as FieldKey,
      field_value      as FieldValue,

      _Header
}
