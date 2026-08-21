"! In-Memory-BAL-Verdrahtungstests (kein COMMIT / keine DB-Persistenz).
CLASS ltc_bal DEFINITION FINAL
  FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcra_cl_log_bal.
    DATA log TYPE REF TO zcra_if_logger.

    METHODS setup.
    METHODS creates_handle_on_start  FOR TESTING.
    METHODS counts_messages          FOR TESTING.
    METHODS skipped_rule_logs_one    FOR TESTING.
ENDCLASS.

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

CLASS ltc_bal IMPLEMENTATION.

  METHOD setup.
    " persist = abap_false: Protokoll nur im BAL-Speicher halten, nie COMMIT.
    cut = NEW zcra_cl_log_bal( persist = abap_false ).
    log = cut.
  ENDMETHOD.

  METHOD creates_handle_on_start.
    cl_abap_unit_assert=>assert_initial(
      act = cut->get_handle( ) msg = 'Handle muss vor start leer sein' ).
    log->start_run( 'PROC01' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = cut->get_handle( ) msg = 'start_run muss ein BAL-Handle erzeugen' ).
  ENDMETHOD.

  METHOD counts_messages.
    log->start_run( 'PROC01' ).                          " +1 (Meldung 001)

    DATA(result) = NEW zcra_cl_result( ).
    result->add_message( severity = 'E' id = 'ZCRA_ENGINE' number = '000' ).
    result->request_stop( ).
    log->log_rule(                                       " +1 Kopf +1 Meldung +1 Stop
      meta       = VALUE #( rule_id = 'R001' kind = 'T' purpose = 'x' )
      applicable = abap_true
      result     = result ).

    log->snapshot( label   = 'BEFORE'                    " +>=1 Freitext
                   context = NEW lcl_ctx_stub( ) ).
    log->end_run( 'PROC01' ).                            " +1 (Meldung 002)

    " start(1) + Regelkopf(1) + Regelmeldung(1) + Stop(1) + Snapshot(>=1) + Ende(1)
    cl_abap_unit_assert=>assert_equals(
      act = cut->get_msg_count( ) exp = 6
      msg = 'unerwartete Anzahl BAL-Meldungen' ).
  ENDMETHOD.

  METHOD skipped_rule_logs_one.
    log->start_run( 'PROC01' ).
    DATA(before) = cut->get_msg_count( ).
    log->log_rule(
      meta       = VALUE #( rule_id = 'R002' kind = 'V' )
      applicable = abap_false
      result     = NEW zcra_cl_result( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->get_msg_count( ) - before exp = 1
      msg = 'eine übersprungene Regel muss genau eine Meldung protokollieren' ).
  ENDMETHOD.

ENDCLASS.
