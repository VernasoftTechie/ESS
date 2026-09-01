@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'ESS Approval Timeline Step'
define view entity ZI_ESS_APPRSTEP
  as select from zhr_ess_apprstep

  association to parent ZI_ESS_REQ_HEAD as _Header
    on  $projection.ClientId  = _Header.ClientId
    and $projection.RequestId = _Header.RequestId
{
  key client_id           as ClientId,
  key request_id           as RequestId,
  key appr_level           as ApprLevel,
  key attempt              as Attempt,
      approver_pernr        as ApproverPernr,
      approver_name         as ApproverName,
      relationship_id_used  as RelationshipIdUsed,
      status                as Status,
      decided_by_pernr      as DecidedByPernr,
      decided_on            as DecidedOn,
      decided_time          as DecidedTime,
      appr_comment          as ApprComment,
      sla_due_date          as SlaDueDate,
      sla_breached          as SlaBreached,

      _Header
}
