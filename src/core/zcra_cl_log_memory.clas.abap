class zcra_cl_log_memory definition
  public
  final
  create public .

  public section.
    interfaces zcra_if_logger .

    types:
      "! A single recorded logger event.
      begin of ty_entry,
        event      type string,   " START | RULE | SNAPSHOT | END
        process    type zcra_d_process_id,
        rule_id    type zcra_d_rule_id,
        kind       type zcra_s_rule_meta-kind,
        applicable type abap_bool,
        stop       type abap_bool,
        has_errors type abap_bool,
        msg_count  type i,
        label      type string,
        json       type string,
      end of ty_entry,
      tt_entry type standard table of ty_entry with default key .

    constants:
      begin of gc_event,
        start    type string value 'START',
        rule     type string value 'RULE',
        snapshot type string value 'SNAPSHOT',
        end      type string value 'END',
      end of gc_event .

    "! All recorded events, in insertion order.
    methods get_entries
      returning value(rt_entries) type tt_entry .
    "! Number of recorded events (optionally filtered by event type).
    methods count
      importing
        !iv_event      type string optional
      returning value(rv_count) type i .

  protected section.
  private section.
    data mt_entries type tt_entry .
endclass.



class zcra_cl_log_memory implementation.

  method zcra_if_logger~start_run.
    append value #( event = gc_event-start process = iv_process ) to mt_entries.
  endmethod.

  method zcra_if_logger~log_rule.
    append value #(
      event      = gc_event-rule
      rule_id    = is_meta-rule_id
      kind       = is_meta-kind
      applicable = iv_applicable
      stop       = io_result->is_stop_requested( )
      has_errors = io_result->has_errors( )
      msg_count  = lines( io_result->get_messages( ) )
    ) to mt_entries.
  endmethod.

  method zcra_if_logger~snapshot.
    data: begin of ls_snap,
            old type zcra_s_graph,
            new type zcra_s_graph,
          end of ls_snap.
    ls_snap-old = io_context->get_old_graph( ).
    ls_snap-new = io_context->get_new_graph( ).
    append value #(
      event = gc_event-snapshot
      label = iv_label
      json  = /ui2/cl_json=>serialize( data = ls_snap )
    ) to mt_entries.
  endmethod.

  method zcra_if_logger~end_run.
    append value #( event = gc_event-end process = iv_process ) to mt_entries.
  endmethod.

  method get_entries.
    rt_entries = mt_entries.
  endmethod.

  method count.
    if iv_event is initial.
      rv_count = lines( mt_entries ).
    else.
      rv_count = reduce i( init n = 0 for ls in mt_entries
                           next n = cond #( when ls-event = iv_event then n + 1 else n ) ).
    endif.
  endmethod.

endclass.
