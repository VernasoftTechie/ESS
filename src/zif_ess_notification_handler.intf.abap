INTERFACE zif_ess_notification_handler
  PUBLIC .

************************************************************************
* ZIF_ESS_NOTIFICATION_HANDLER
* Sends requestor/approver notifications on request lifecycle events.
* Phase 1 implementation (ZCL_ESS_NOTIF_HANDLER_SMTP) sends plain-text
* email via SO_NEW_DOCUMENT_ATT_SEND_API1; kept behind this interface
* so a different channel (Business Workflow, Teams, etc.) can replace
* it later without touching callers.
************************************************************************

  METHODS send_request_confirmation
    IMPORTING
      !iv_client_id       TYPE zhr_ess_req_head-client_id
      !iv_request_id      TYPE zhr_ess_req_head-request_id
      !iv_recipient_email TYPE string
    RETURNING
      VALUE(rv_sent)      TYPE abap_bool .

  METHODS send_approval_notification
    IMPORTING
      !iv_client_id       TYPE zhr_ess_req_head-client_id
      !iv_request_id      TYPE zhr_ess_req_head-request_id
      !iv_recipient_email TYPE string
      !iv_action          TYPE string  " APPROVED / REJECTED / RETURNED / PENDING
    RETURNING
      VALUE(rv_sent)      TYPE abap_bool .

ENDINTERFACE.
