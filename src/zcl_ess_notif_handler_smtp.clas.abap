CLASS zcl_ess_notif_handler_smtp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_ess_notification_handler .

  PRIVATE SECTION.

    METHODS send_email
      IMPORTING
        !iv_recipient  TYPE string
        !iv_subject    TYPE string
        !iv_body       TYPE string
      RETURNING
        VALUE(rv_sent) TYPE abap_bool .

ENDCLASS.


CLASS zcl_ess_notif_handler_smtp IMPLEMENTATION.

  METHOD zif_ess_notification_handler~send_request_confirmation.

    DATA ls_head TYPE zhr_ess_req_head.

    SELECT SINGLE * FROM zhr_ess_req_head
      INTO @ls_head
      WHERE client_id  = @iv_client_id
        AND request_id = @iv_request_id.

    IF sy-subrc <> 0.
      rv_sent = abap_false.
      RETURN.
    ENDIF.

    DATA(lv_subject) = |Loan Request { ls_head-request_id } Submitted|.
    DATA(lv_body)    = |Your loan request { ls_head-request_id } for { ls_head-amount } | &&
                       |{ ls_head-currency } has been submitted and is now in approval.|.

    rv_sent = send_email( iv_recipient = iv_recipient_email
                           iv_subject   = lv_subject
                           iv_body      = lv_body ).

  ENDMETHOD.


  METHOD zif_ess_notification_handler~send_approval_notification.

    DATA ls_head TYPE zhr_ess_req_head.

    SELECT SINGLE * FROM zhr_ess_req_head
      INTO @ls_head
      WHERE client_id  = @iv_client_id
        AND request_id = @iv_request_id.

    IF sy-subrc <> 0.
      rv_sent = abap_false.
      RETURN.
    ENDIF.

    DATA(lv_subject) = |Loan Request { ls_head-request_id } - { iv_action }|.
    DATA(lv_body)    = |Your loan request { ls_head-request_id } status has been updated to: { iv_action }.|.

    rv_sent = send_email( iv_recipient = iv_recipient_email
                           iv_subject   = lv_subject
                           iv_body      = lv_body ).

  ENDMETHOD.


  METHOD send_email.

* Plain-text email via SAPconnect (SO_NEW_DOCUMENT_ATT_SEND_API1).
* commit_work = abap_true triggers immediate send; for high-volume use,
* switch to abap_false and let a background job COMMIT + trigger
* RSCONN01 instead.
    DATA: lt_packing_list TYPE STANDARD TABLE OF sopcklsti1,
          lt_receivers    TYPE STANDARD TABLE OF somlreci1,
          lt_body         TYPE STANDARD TABLE OF solisti1,
          ls_document     TYPE sodocchgi1.

    IF iv_recipient IS INITIAL.
      rv_sent = abap_false.
      RETURN.
    ENDIF.

    APPEND VALUE #( line = iv_body ) TO lt_body.

    ls_document-obj_name  = 'ESS_NOTIF'.
    ls_document-obj_descr = iv_subject.
    ls_document-obj_langu = sy-langu.

    APPEND VALUE #( transf_bin = space
                     head_start = 1
                     head_num   = 0
                     body_start = 1
                     body_num   = lines( lt_body )
                     doc_type   = 'RAW' )
      TO lt_packing_list.

    APPEND VALUE #( receiver   = iv_recipient
                     rec_type  = 'U'          " Internet address
                     com_type  = 'INT'
                     notif_del = abap_true
                     notif_ndel = abap_true )
      TO lt_receivers.

    CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
      EXPORTING
        document_data              = ls_document
        commit_work                 = abap_true
      TABLES
        packing_list                = lt_packing_list
        contents_txt                 = lt_body
        receivers                    = lt_receivers
      EXCEPTIONS
        too_many_receivers           = 1
        document_not_sent            = 2
        document_type_not_exist      = 3
        operation_no_authorization   = 4
        parameter_error              = 5
        x_error                      = 6
        enqueue_error                = 7
        OTHERS                       = 8.

    rv_sent = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

  ENDMETHOD.

ENDCLASS.
