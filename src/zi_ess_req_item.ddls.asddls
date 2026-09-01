@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'ESS Loan Request Item'
define view entity ZI_ESS_REQ_ITEM
  as select from zhr_ess_req_item

  association to parent ZI_ESS_REQ_HEAD as _Header
    on  $projection.ClientId  = _Header.ClientId
    and $projection.RequestId = _Header.RequestId
{
  key client_id         as ClientId,
  key request_id         as RequestId,
  key item_sequence      as ItemSequence,
      item_type           as ItemType,
      item_description    as ItemDescription,
      item_value          as ItemValue,
      item_status         as ItemStatus,
      created_on          as CreatedOn,

      _Header
}
