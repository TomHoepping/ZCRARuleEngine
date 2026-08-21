"! Unit tests for ZCRA_CL_LOG_MEMORY and ZCRA_CL_LOG_NULL.
class ltc_memory definition final
  for testing duration short risk level harmless.

  private section.
    data mo_cut type ref to zcra_cl_log_memory.
    data mo_log type ref to zcra_if_logger.

    methods setup.
    methods records_run_lifecycle for testing.
    methods records_rule_outcome  for testing.
    methods records_snapshot_json for testing.
    methods null_logger_is_inert  for testing.
endclass.

"! Minimal read-only context stub for snapshot tests.
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

class ltc_memory implementation.

  method setup.
    mo_cut = new zcra_cl_log_memory( ).
    mo_log = mo_cut.
  endmethod.

  method records_run_lifecycle.
    mo_log->start_run( iv_process = 'PROC01' ).
    mo_log->end_run( iv_process = 'PROC01' ).

    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->count( ) exp = 2 msg = 'expected two lifecycle entries' ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->count( zcra_cl_log_memory=>gc_event-start ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_cut->count( zcra_cl_log_memory=>gc_event-end ) exp = 1 ).
  endmethod.

  method records_rule_outcome.
    data(lo_result) = new zcra_cl_result( ).
    lo_result->add_message(
      iv_type = 'E' iv_id = 'ZCRA_ENGINE' iv_number = '003' ).
    lo_result->request_stop( ).

    mo_log->log_rule(
      is_meta       = value #( rule_id = 'R001' kind = 'T' )
      iv_applicable = abap_true
      io_result     = lo_result ).

    data(lt) = mo_cut->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt ) exp = 1 ).
    data(ls) = lt[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = ls-event exp = 'RULE' ).
    cl_abap_unit_assert=>assert_equals( act = ls-rule_id exp = 'R001' ).
    cl_abap_unit_assert=>assert_equals( act = ls-applicable exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = ls-stop exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = ls-has_errors exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = ls-msg_count exp = 1 ).
  endmethod.

  method records_snapshot_json.
    data(lo_ctx) = new lcl_ctx_stub( ).
    mo_log->snapshot( iv_label = 'BEFORE' io_context = lo_ctx ).

    data(lt) = mo_cut->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 1 ]-label exp = 'BEFORE' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = lt[ 1 ]-json msg = 'snapshot JSON must be populated' ).
  endmethod.

  method null_logger_is_inert.
    data(lo_null) = zcra_cl_log_null=>get_instance( ).
    lo_null->start_run( iv_process = 'PROC01' ).
    lo_null->snapshot( iv_label = 'X' io_context = new lcl_ctx_stub( ) ).
    lo_null->end_run( iv_process = 'PROC01' ).
    " Singleton returns the same instance and never dumps.
    cl_abap_unit_assert=>assert_equals(
      act = lo_null exp = zcra_cl_log_null=>get_instance( ) ).
  endmethod.

endclass.
