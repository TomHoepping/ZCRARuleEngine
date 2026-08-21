"! Unit-Tests für ZCRA_CL_LOG_MEMORY und ZCRA_CL_LOG_NULL.
CLASS ltc_memory DEFINITION FINAL
  FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcra_cl_log_memory.
    DATA log TYPE REF TO zcra_if_logger.

    METHODS setup.
    METHODS records_run_lifecycle FOR TESTING.
    METHODS records_rule_outcome  FOR TESTING.
    METHODS records_snapshot_json FOR TESTING.
    METHODS null_logger_is_inert  FOR TESTING.
ENDCLASS.

"! Minimaler schreibgeschützter Kontext-Stub für Snapshot-Tests.
CLASS lcl_ctx_stub DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zcra_if_context.
ENDCLASS.

CLASS lcl_ctx_stub IMPLEMENTATION.
  METHOD zcra_if_context~get_old_graph.
  ENDMETHOD.
  METHOD zcra_if_context~get_new_graph.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_memory IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcra_cl_log_memory( ).
    log = cut.
  ENDMETHOD.

  METHOD records_run_lifecycle.
    log->start_run( 'PROC01' ).
    log->end_run( 'PROC01' ).

    cl_abap_unit_assert=>assert_equals(
      act = cut->count( ) exp = 2 msg = 'zwei Lebenszyklus-Einträge erwartet' ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->count( zcra_cl_log_memory=>gc_event-start ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->count( zcra_cl_log_memory=>gc_event-end ) exp = 1 ).
  ENDMETHOD.

  METHOD records_rule_outcome.
    DATA(result) = NEW zcra_cl_result( ).
    result->add_message(
      severity = 'E' id = 'ZCRA_ENGINE' number = '003' ).
    result->request_stop( ).

    log->log_rule(
      meta       = VALUE #( rule_id = 'R001' kind = 'T' )
      applicable = abap_true
      result     = result ).

    DATA(entries) = cut->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = lines( entries ) exp = 1 ).
    DATA(entry) = entries[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = entry-event exp = 'RULE' ).
    cl_abap_unit_assert=>assert_equals( act = entry-rule_id exp = 'R001' ).
    cl_abap_unit_assert=>assert_equals( act = entry-applicable exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = entry-stop exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = entry-has_errors exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = entry-msg_count exp = 1 ).
  ENDMETHOD.

  METHOD records_snapshot_json.
    DATA(context) = NEW lcl_ctx_stub( ).
    log->snapshot( label = 'BEFORE' context = context ).

    DATA(entries) = cut->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = lines( entries ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 1 ]-label exp = 'BEFORE' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = entries[ 1 ]-json msg = 'Snapshot-JSON muss befüllt sein' ).
  ENDMETHOD.

  METHOD null_logger_is_inert.
    DATA(null_logger) = zcra_cl_log_null=>get_instance( ).
    null_logger->start_run( 'PROC01' ).
    null_logger->snapshot( label = 'X' context = NEW lcl_ctx_stub( ) ).
    null_logger->end_run( 'PROC01' ).
    " Singleton liefert dieselbe Instanz und dumpt niemals.
    cl_abap_unit_assert=>assert_equals(
      act = null_logger exp = zcra_cl_log_null=>get_instance( ) ).
  ENDMETHOD.

ENDCLASS.
