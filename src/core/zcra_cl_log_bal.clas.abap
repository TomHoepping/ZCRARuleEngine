class zcra_cl_log_bal definition
  public
  final
  create public .

  public section.
    interfaces zcra_if_logger .

    constants:
      gc_object     type balobj_d   value 'ZCRA',
      gc_subobj_run type balsubobj  value 'RUN',
      gc_msgid      type arbgb      value 'ZCRA_ENGINE',
      begin of gc_detlevel,
        run      type ballevel value '1',
        rule     type ballevel value '2',
        snapshot type ballevel value '3',
      end of gc_detlevel .

    "! @parameter iv_persist | when true (default) end_run saves the BAL log to
    "!   the database and commits. Pass abap_false in unit tests to keep the log
    "!   in memory only (no COMMIT WORK).
    methods constructor
      importing
        !iv_persist type abap_bool default abap_true .
    "! The BAL log handle created by start_run (empty before). For verification.
    methods get_handle
      returning value(rv_handle) type balloghndl .
    "! Number of messages added to the current log. For verification.
    methods get_msg_count
      returning value(rv_count) type i .

  protected section.
  private section.
    data mv_persist   type abap_bool .
    data mv_handle    type balloghndl .
    data mv_msg_count type i .

    methods add_msg
      importing
        !iv_msgno    type msgnr
        !iv_msgty    type symsgty
        !iv_detlevel type ballevel
        !iv_v1       type string optional .
    methods add_bapiret
      importing
        !is_ret type bapiret2 .
    methods add_free_text
      importing
        !iv_text     type string
        !iv_detlevel type ballevel .
endclass.



class zcra_cl_log_bal implementation.

  method constructor.
    mv_persist = iv_persist.
  endmethod.

  method get_handle.
    rv_handle = mv_handle.
  endmethod.

  method get_msg_count.
    rv_count = mv_msg_count.
  endmethod.

  method zcra_if_logger~start_run.
    data ls_log type bal_s_log.
    ls_log-object    = gc_object.
    ls_log-subobject = gc_subobj_run.
    ls_log-extnumber = iv_process.
    ls_log-aluser    = sy-uname.
    ls_log-alprog    = sy-repid.
    call function 'BAL_LOG_CREATE'
      exporting
        i_s_log                 = ls_log
      importing
        e_log_handle            = mv_handle
      exceptions
        log_header_inconsistent = 1
        others                  = 2.
    if sy-subrc = 0.
      add_msg( iv_msgno = '001' iv_msgty = 'I'
               iv_detlevel = gc_detlevel-run iv_v1 = |{ iv_process }| ).
    endif.
  endmethod.

  method zcra_if_logger~log_rule.
    if mv_handle is initial.
      return.
    endif.
    if iv_applicable = abap_false.
      add_msg( iv_msgno = '003' iv_msgty = 'I'
               iv_detlevel = gc_detlevel-rule iv_v1 = |{ is_meta-rule_id }| ).
      return.
    endif.
    " Rule header for readability, then its accumulated messages.
    add_free_text(
      iv_text     = |Rule { is_meta-rule_id } ({ is_meta-kind }): { is_meta-purpose }|
      iv_detlevel = gc_detlevel-rule ).
    loop at io_result->get_messages( ) into data(ls_ret).
      add_bapiret( ls_ret ).
    endloop.
    if io_result->is_stop_requested( ) = abap_true.
      add_msg( iv_msgno = '004' iv_msgty = 'W'
               iv_detlevel = gc_detlevel-rule iv_v1 = |{ is_meta-rule_id }| ).
    endif.
  endmethod.

  method zcra_if_logger~snapshot.
    if mv_handle is initial.
      return.
    endif.
    data: begin of ls_snap,
            old type zcra_s_graph,
            new type zcra_s_graph,
          end of ls_snap.
    ls_snap-old = io_context->get_old_graph( ).
    ls_snap-new = io_context->get_new_graph( ).
    data(lv_json) = /ui2/cl_json=>serialize( data = ls_snap ).
    add_free_text(
      iv_text     = |{ iv_label }: { lv_json }|
      iv_detlevel = gc_detlevel-snapshot ).
  endmethod.

  method zcra_if_logger~end_run.
    if mv_handle is initial.
      return.
    endif.
    add_msg( iv_msgno = '002' iv_msgty = 'I'
             iv_detlevel = gc_detlevel-run iv_v1 = |{ iv_process }| ).
    if mv_persist = abap_true.
      data lt_handle type bal_t_logh.
      append mv_handle to lt_handle.
      call function 'BAL_DB_SAVE'
        exporting
          i_t_log_handle = lt_handle
        exceptions
          others         = 0.
      commit work.
    endif.
  endmethod.

  method add_msg.
    if mv_handle is initial.
      return.
    endif.
    data ls_msg type bal_s_msg.
    ls_msg-msgty     = iv_msgty.
    ls_msg-msgid     = gc_msgid.
    ls_msg-msgno     = iv_msgno.
    ls_msg-msgv1     = iv_v1.
    ls_msg-probclass = '3'.
    ls_msg-detlevel  = iv_detlevel.
    call function 'BAL_LOG_MSG_ADD'
      exporting
        i_log_handle = mv_handle
        i_s_msg      = ls_msg
      exceptions
        others       = 0.
    add 1 to mv_msg_count.
  endmethod.

  method add_bapiret.
    if mv_handle is initial.
      return.
    endif.
    data ls_msg type bal_s_msg.
    ls_msg-msgty     = is_ret-type.
    ls_msg-msgid     = is_ret-id.
    ls_msg-msgno     = is_ret-number.
    ls_msg-msgv1     = is_ret-message_v1.
    ls_msg-msgv2     = is_ret-message_v2.
    ls_msg-msgv3     = is_ret-message_v3.
    ls_msg-msgv4     = is_ret-message_v4.
    ls_msg-probclass = '2'.
    ls_msg-detlevel  = gc_detlevel-rule.
    call function 'BAL_LOG_MSG_ADD'
      exporting
        i_log_handle = mv_handle
        i_s_msg      = ls_msg
      exceptions
        others       = 0.
    add 1 to mv_msg_count.
  endmethod.

  method add_free_text.
    data lv_chunk type c length 200.
    data(lv_rest) = iv_text.
    while strlen( lv_rest ) > 0.
      data(lv_len) = nmin( val1 = 200 val2 = strlen( lv_rest ) ).
      lv_chunk = substring( val = lv_rest off = 0 len = lv_len ).
      call function 'BAL_LOG_MSG_ADD_FREE_TEXT'
        exporting
          i_log_handle = mv_handle
          i_msgty      = 'I'
          i_text       = lv_chunk
          i_detlevel   = iv_detlevel
        exceptions
          others       = 0.
      add 1 to mv_msg_count.
      if strlen( lv_rest ) > 200.
        lv_rest = substring( val = lv_rest off = 200 ).
      else.
        clear lv_rest.
      endif.
    endwhile.
  endmethod.

endclass.
