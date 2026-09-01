@AccessControl.authorizationCheck: #CHECK
@UI.headerInfo: {
  typeName: 'Request Item',
  typeNamePlural: 'Request Items'
}
define view entity ZC_ESS_REQ_ITEM
  as projection on ZI_ESS_REQ_ITEM
{
  key ClientId,
  key RequestId,
  key ItemSequence,

  @UI.lineItem: [ { position: 10 } ]
  ItemType,

  @UI.lineItem: [ { position: 20 } ]
  ItemDescription,

  @UI.lineItem: [ { position: 30 } ]
  ItemValue,

  @UI.lineItem: [ { position: 40 } ]
  ItemStatus,

  CreatedOn,

  _Header : redirected to parent ZC_ESS_REQ_HEAD
}
