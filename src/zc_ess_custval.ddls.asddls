@AccessControl.authorizationCheck: #CHECK
@UI.headerInfo: {
  typeName: 'Custom Field Value',
  typeNamePlural: 'Custom Field Values'
}
define view entity ZC_ESS_CUSTVAL
  as projection on ZI_ESS_CUSTVAL
{
  key ClientId,
  key RequestId,
  key FieldKey,

  @UI.lineItem: [ { position: 10 } ]
  FieldValue,

  _Header : redirected to parent ZC_ESS_REQ_HEAD
}
