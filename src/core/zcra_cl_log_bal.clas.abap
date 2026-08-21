CLASS zcra_cl_log_bal DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zcra_if_logger.

    CONSTANTS:
      gc_object     TYPE balobj_d   VALUE 'ZCRA',
      gc_subobj_run TYPE balsubobj  VALUE 'RUN',
      gc_msgid      TYPE arbgb      VALUE 'ZCRA_ENGINE',
      BEGIN OF gc_detlevel,
        run      TYPE ballevel VALUE '1',
        rule     TYPE ballevel VALUE '2',
        snapshot TYPE ballevel VALUE '3',
      END OF gc_detlevel.

    "! @parameter persist | wenn wahr (Standard), sichert end_run das BAL-Protokoll
    "!   in der Datenbank und committet. In Unit-Tests abap_false übergeben, um das
    "!   Protokoll nur im Speicher zu halten (kein COMMIT WORK).
    METHODS constructor
      IMPORTING
        !persist TYPE abap_bool DEFAULT abap_true.
    "! Das von start_run erzeugte BAL-Protokoll-Handle (vorher leer). Zur Prüfung.
    METHODS get_handle
      RETURNING VALUE(result) TYPE balloghndl.
    "! Anzahl der zum aktuellen Protokoll hinzugefügten Meldungen. Zur Prüfung.
    METHODS get_msg_count
      RETURNING VALUE(result) TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA persist   TYPE abap_bool.
    DATA handle    TYPE balloghndl.
    DATA msg_count TYPE i.

    METHODS add_msg
      IMPORTING
        !msgno    TYPE msgnr
        !msgty    TYPE symsgty
        !detlevel TYPE ballevel
        !v1       TYPE string OPTIONAL.
    METHODS add_bapiret
      IMPORTING
        !ret TYPE bapiret2.
    METHODS add_free_text
      IMPORTING
        !text     TYPE string
        !detlevel TYPE ballevel.
ENDCLASS.



CLASS zcra_cl_log_bal IMPLEMENTATION.

  METHOD constructor.
    me->persist = persist.
  ENDMETHOD.

  METHOD get_handle.
    result = me->handle.
  ENDMETHOD.

  METHOD get_msg_count.
    result = me->msg_count.
  ENDMETHOD.

  METHOD zcra_if_logger~start_run.
    DATA log TYPE bal_s_log.
    log-object    = gc_object.
    log-subobject = gc_subobj_run.
    log-extnumber = process.
    log-aluser    = sy-uname.
    log-alprog    = sy-repid.
    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log                 = log
      IMPORTING
        e_log_handle            = me->handle
      EXCEPTIONS
        log_header_inconsistent = 1
        OTHERS                  = 2.
    IF sy-subrc = 0.
      add_msg( msgno = '001' msgty = 'I'
               detlevel = gc_detlevel-run v1 = |{ process }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zcra_if_logger~log_rule.
    IF me->handle IS INITIAL.
      RETURN.
    ENDIF.
    IF applicable = abap_false.
      add_msg( msgno = '003' msgty = 'I'
               detlevel = gc_detlevel-rule v1 = |{ meta-rule_id }| ).
      RETURN.
    ENDIF.
    " Regelkopf zur besseren Lesbarkeit, danach die gesammelten Meldungen.
    add_free_text(
      text     = |Regel { meta-rule_id } ({ meta-kind }): { meta-purpose }|
      detlevel = gc_detlevel-rule ).
    LOOP AT result->get_messages( ) INTO DATA(ret).
      add_bapiret( ret ).
    ENDLOOP.
    IF result->is_stop_requested( ) = abap_true.
      add_msg( msgno = '004' msgty = 'W'
               detlevel = gc_detlevel-rule v1 = |{ meta-rule_id }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zcra_if_logger~snapshot.
    IF me->handle IS INITIAL.
      RETURN.
    ENDIF.
    DATA: BEGIN OF snap,
            old TYPE zcra_s_graph,
            new TYPE zcra_s_graph,
          END OF snap.
    snap-old = context->get_old_graph( ).
    snap-new = context->get_new_graph( ).
    DATA(json) = /ui2/cl_json=>serialize( data = snap ).
    add_free_text(
      text     = |{ label }: { json }|
      detlevel = gc_detlevel-snapshot ).
  ENDMETHOD.

  METHOD zcra_if_logger~end_run.
    IF me->handle IS INITIAL.
      RETURN.
    ENDIF.
    add_msg( msgno = '002' msgty = 'I'
             detlevel = gc_detlevel-run v1 = |{ process }| ).
    IF me->persist = abap_true.
      DATA handles TYPE bal_t_logh.
      APPEND me->handle TO handles.
      CALL FUNCTION 'BAL_DB_SAVE'
        EXPORTING
          i_t_log_handle = handles
        EXCEPTIONS
          OTHERS         = 0.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.

  METHOD add_msg.
    IF me->handle IS INITIAL.
      RETURN.
    ENDIF.
    DATA msg TYPE bal_s_msg.
    msg-msgty     = msgty.
    msg-msgid     = gc_msgid.
    msg-msgno     = msgno.
    msg-msgv1     = v1.
    msg-probclass = '3'.
    msg-detlevel  = detlevel.
    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = me->handle
        i_s_msg      = msg
      EXCEPTIONS
        OTHERS       = 0.
    me->msg_count += 1.
  ENDMETHOD.

  METHOD add_bapiret.
    IF me->handle IS INITIAL.
      RETURN.
    ENDIF.
    DATA msg TYPE bal_s_msg.
    msg-msgty     = ret-type.
    msg-msgid     = ret-id.
    msg-msgno     = ret-number.
    msg-msgv1     = ret-message_v1.
    msg-msgv2     = ret-message_v2.
    msg-msgv3     = ret-message_v3.
    msg-msgv4     = ret-message_v4.
    msg-probclass = '2'.
    msg-detlevel  = gc_detlevel-rule.
    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = me->handle
        i_s_msg      = msg
      EXCEPTIONS
        OTHERS       = 0.
    me->msg_count += 1.
  ENDMETHOD.

  METHOD add_free_text.
    DATA chunk TYPE c LENGTH 200.
    DATA(rest) = text.
    WHILE strlen( rest ) > 0.
      DATA(len) = nmin( val1 = 200 val2 = strlen( rest ) ).
      chunk = substring( val = rest off = 0 len = len ).
      CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
        EXPORTING
          i_log_handle = me->handle
          i_msgty      = 'I'
          i_text       = chunk
          i_detlevel   = detlevel
        EXCEPTIONS
          OTHERS       = 0.
      me->msg_count += 1.
      IF strlen( rest ) > 200.
        rest = substring( val = rest off = 200 ).
      ELSE.
        CLEAR rest.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
