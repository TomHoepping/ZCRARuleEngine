"! In-memory BAL wiring tests (no COMMIT / no DB persistence).
class ltc_bal definition final
  for testing duration short risk level harmless.

  private section.
    data mo_cut type ref to zcra_cl_log_bal.
    data mo_log type ref to zcra_if_logger.

    methods setup.
    methods creates_handle_on_start  for testing.
    methods counts_messages          for testing.
    methods skipped_rule_logs_one    for testing.
endclass.

class lcl_ctx_stub definition final.
  public section.
    interfaces zcra_if_context.
endclass.

class lcl_ctx_stub implementation.
  method zcra_if_context~get_old_graph.
  endmethod.
  method zcra_if_context~get_new_graph.
  endmethod.
endclass.

class ltc_bal implementation.

  method setup.
    " iv_persist = abap_false: keep the log in BAL memory, never COMMIT.
    mo_cut = new zcra_cl_log_bal( iv_persist = abap_false ).
    mo_log = mo_cut.
  endmethod.

  method creates_handle_on_start.
    cl_abap_unit_assert=>assert_initial(
      act = mo_cut->get_handle( ) msg = 'handle must be empty before start' ).
    mo_log->start_run( iv_process = 'PROC01' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = mo_cut->get_handle( ) msg = 'start_run must create a BAL handle' ).
  endmethod.

  method counts_messages.
    mo_log->start_run( iv_process = 'PROC01' ).          " +1 (msg 001)

    data(lo_result) = new zcra_cl_result( ).
    lo_result->add_message( iv_type = 'E' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    lo_result->request_stop( ).
    mo_log->log_rule(                                    " +1 header +1 msg +1 stop
      is_meta       = value #( rule_id = 'R001' kind = 'T' purpose = 'x' )
      iv_applicable = abap_true
      io_result     = lo_result ).

    mo_log->snapshot( iv_label = 'BEFORE'                 " +>=1 free text
                      io_context = new lcl_ctx_stub( ) ).
    mo_log->end_run( iv_process = 'PROC01' ).             " +1 (msg 002)

    " start(1) + rule header(1) + rule msg(1) + stop(1) + snapshot(>=1) + end(1)
    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->get_msg_count( ) exp = 6
      msg = 'unexpected number of BAL messages' ).
  endmethod.

  method skipped_rule_logs_one.
    mo_log->start_run( iv_process = 'PROC01' ).
    data(lv_before) = mo_cut->get_msg_count( ).
    mo_log->log_rule(
      is_meta       = value #( rule_id = 'R002' kind = 'V' )
      iv_applicable = abap_false
      io_result     = new zcra_cl_result( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->get_msg_count( ) - lv_before exp = 1
      msg = 'a skipped rule must log exactly one message' ).
  endmethod.

endclass.
