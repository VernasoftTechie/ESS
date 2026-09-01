@AccessControl.authorizationCheck: #CHECK
@UI.headerInfo: {
  typeName: 'Approval Step',
  typeNamePlural: 'Approval Steps'
}
define view entity ZC_ESS_APPRSTEP
  as projection on ZI_ESS_APPRSTEP
{
  key ClientId,
  key RequestId,
  key ApprLevel,
  key Attempt,

  @UI.lineItem: [ { position: 10 } ]
  ApproverName,

  @UI.lineItem: [ { position: 20 } ]
  Status,

  @UI.lineItem: [ { position: 30 } ]
  DecidedOn,

  DecidedTime,

  @UI.lineItem: [ { position: 40 } ]
  ApprComment,

  ApproverPernr,
  RelationshipIdUsed,
  DecidedByPernr,
  SlaDueDate,
  SlaBreached,

  _Header : redirected to parent ZC_ESS_REQ_HEAD
}
