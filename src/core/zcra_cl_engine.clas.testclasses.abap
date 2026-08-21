"! Unit-Tests für ZCRA_CL_ENGINE: Phasenreihenfolge, Überspringen leerer Phasen,
"! STOP-Kurzschluss, Snapshot-Erfassung, Meldungssammlung, Kind-vs-Bucket.
CLASS ltc_engine DEFINITION FINAL
  FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA det    TYPE REF TO zcra_cl_determination.
    DATA log    TYPE REF TO zcra_cl_log_memory.
    DATA engine TYPE REF TO zcra_cl_engine.

    METHODS setup.
    METHODS build IMPORTING determination TYPE REF TO zcra_if_determination.

    METHODS runs_phases_in_order   FOR TESTING RAISING cx_static_check.
    METHODS skips_empty_transform  FOR TESTING RAISING cx_static_check.
    METHODS stop_short_circuits    FOR TESTING RAISING cx_static_check.
    METHODS accumulates_messages   FOR TESTING RAISING cx_static_check.
    METHODS inapplicable_skipped   FOR TESTING RAISING cx_static_check.
    METHODS kind_bucket_mismatch   FOR TESTING RAISING cx_static_check.
ENDCLASS.


"! Konfigurierbare Stub-Regel.
CLASS lcl_rule DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zcra_if_rule.
    METHODS constructor
      IMPORTING
        !id         TYPE zcra_d_rule_id
        !kind       TYPE zcra_s_rule_meta-kind
        !applicable TYPE abap_bool DEFAULT abap_true
        !emit_msg   TYPE abap_bool DEFAULT abap_false
        !do_stop    TYPE abap_bool DEFAULT abap_false.
  PRIVATE SECTION.
    DATA meta       TYPE zcra_s_rule_meta.
    DATA applicable TYPE abap_bool.
    DATA emit_msg   TYPE abap_bool.
    DATA do_stop    TYPE abap_bool.
    METHODS act IMPORTING result TYPE REF TO zcra_cl_result.
ENDCLASS.

CLASS lcl_rule IMPLEMENTATION.
  METHOD constructor.
    meta-rule_id    = id.
    meta-kind       = kind.
    me->applicable  = applicable.
    me->emit_msg    = emit_msg.
    me->do_stop     = do_stop.
  ENDMETHOD.
  METHOD zcra_if_rule~get_meta.
    result = meta.
  ENDMETHOD.
  METHOD zcra_if_rule~exec_condition.
    result = me->applicable.
  ENDMETHOD.
  METHOD zcra_if_rule~validate.
    act( result ).
  ENDMETHOD.
  METHOD zcra_if_rule~transform.
    act( result ).
  ENDMETHOD.
  METHOD act.
    IF me->emit_msg = abap_true.
      result->add_message( severity = 'I' id = 'ZCRA_ENGINE' number = '000' ).
    ENDIF.
    IF me->do_stop = abap_true.
      result->request_stop( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


"! Determination-Stub mit bucketweisen Regellisten.
CLASS lcl_det DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zcra_if_determination.
    METHODS set
      IMPORTING
        !rule_type TYPE zcra_if_c_rule_type=>ty_type
        !rules     TYPE zcra_if_determination=>tt_rules.
  PRIVATE SECTION.
    DATA rules_pre  TYPE zcra_if_determination=>tt_rules.
    DATA rules_trn  TYPE zcra_if_determination=>tt_rules.
    DATA rules_post TYPE zcra_if_determination=>tt_rules.
    METHODS pick
      IMPORTING !rule_type TYPE zcra_if_c_rule_type=>ty_type
      RETURNING VALUE(result) TYPE zcra_if_determination=>tt_rules.
ENDCLASS.

CLASS lcl_det IMPLEMENTATION.
  METHOD set.
    CASE rule_type.
      WHEN zcra_if_c_rule_type=>validation_pre.  rules_pre  = rules.
      WHEN zcra_if_c_rule_type=>transformation.  rules_trn  = rules.
      WHEN zcra_if_c_rule_type=>validation_post. rules_post = rules.
    ENDCASE.
  ENDMETHOD.
  METHOD pick.
    CASE rule_type.
      WHEN zcra_if_c_rule_type=>validation_pre.  result = rules_pre.
      WHEN zcra_if_c_rule_type=>transformation.  result = rules_trn.
      WHEN zcra_if_c_rule_type=>validation_post. result = rules_post.
    ENDCASE.
  ENDMETHOD.
  METHOD zcra_if_determination~has_rules.
    result = xsdbool( lines( pick( rule_type ) ) > 0 ).
  ENDMETHOD.
  METHOD zcra_if_determination~get_rules.
    result = pick( rule_type ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_engine IMPLEMENTATION.

  METHOD setup.
    log = NEW zcra_cl_log_memory( ).
  ENDMETHOD.

  METHOD build.
    det = NEW zcra_cl_determination( ).
    det->register( process = zcra_if_c_process=>anerkennung determination = determination ).
    engine = NEW zcra_cl_engine( determination = det logger = log ).
  ENDMETHOD.

  METHOD runs_phases_in_order.
    DATA(det_stub) = NEW lcl_det( ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_pre
                   rules = VALUE #( ( NEW lcl_rule( id = 'VP' kind = 'V' ) ) ) ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>transformation
                   rules = VALUE #( ( NEW lcl_rule( id = 'TR' kind = 'T' ) ) ) ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_post
                   rules = VALUE #( ( NEW lcl_rule( id = 'VO' kind = 'V' ) ) ) ).
    build( det_stub ).

    engine->run( process = zcra_if_c_process=>anerkennung
                 context = NEW zcra_cl_context( ) ).

    DATA(entries) = log->get_entries( ).
    " START, RULE(VP), SNAPSHOT(BEFORE), RULE(TR), SNAPSHOT(AFTER), RULE(VO), END
    cl_abap_unit_assert=>assert_equals( act = lines( entries ) exp = 7 ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 1 ]-event exp = 'START' ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 2 ]-rule_id exp = 'VP' ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 3 ]-label exp = 'BEFORE' ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 4 ]-rule_id exp = 'TR' ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 5 ]-label exp = 'AFTER' ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 6 ]-rule_id exp = 'VO' ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 7 ]-event exp = 'END' ).
  ENDMETHOD.

  METHOD skips_empty_transform.
    DATA(det_stub) = NEW lcl_det( ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_pre
                   rules = VALUE #( ( NEW lcl_rule( id = 'VP' kind = 'V' ) ) ) ).
    build( det_stub ).

    engine->run( process = zcra_if_c_process=>anerkennung
                 context = NEW zcra_cl_context( ) ).

    " Kein Transformations-Bucket => keine BEFORE/AFTER-Snapshot-Ereignisse.
    cl_abap_unit_assert=>assert_equals(
      act = log->count( zcra_cl_log_memory=>gc_event-snapshot ) exp = 0 ).
  ENDMETHOD.

  METHOD stop_short_circuits.
    DATA(det_stub) = NEW lcl_det( ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_pre
                   rules = VALUE #(
                     ( NEW lcl_rule( id = 'VP1' kind = 'V' do_stop = abap_true ) )
                     ( NEW lcl_rule( id = 'VP2' kind = 'V' ) ) ) ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>transformation
                   rules = VALUE #( ( NEW lcl_rule( id = 'TR' kind = 'T' ) ) ) ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_post
                   rules = VALUE #( ( NEW lcl_rule( id = 'VO' kind = 'V' ) ) ) ).
    build( det_stub ).

    DATA(result) = engine->run( process = zcra_if_c_process=>anerkennung
                                context = NEW zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_true( result->is_stop_requested( ) ).
    " Nur VP1 lief (als anwendbar); VP2, TR, VO werden übersprungen.
    cl_abap_unit_assert=>assert_equals(
      act = log->count( zcra_cl_log_memory=>gc_event-rule ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = log->count( zcra_cl_log_memory=>gc_event-snapshot ) exp = 0 ).
  ENDMETHOD.

  METHOD accumulates_messages.
    DATA(det_stub) = NEW lcl_det( ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_pre
                   rules = VALUE #(
                     ( NEW lcl_rule( id = 'VP1' kind = 'V' emit_msg = abap_true ) )
                     ( NEW lcl_rule( id = 'VP2' kind = 'V' emit_msg = abap_true ) ) ) ).
    build( det_stub ).

    DATA(result) = engine->run( process = zcra_if_c_process=>anerkennung
                                context = NEW zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( result->get_messages( ) ) exp = 2 ).
  ENDMETHOD.

  METHOD inapplicable_skipped.
    DATA(det_stub) = NEW lcl_det( ).
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_pre
                   rules = VALUE #(
                     ( NEW lcl_rule( id = 'VP1' kind = 'V'
                                     applicable = abap_false emit_msg = abap_true ) ) ) ).
    build( det_stub ).

    DATA(result) = engine->run( process = zcra_if_c_process=>anerkennung
                                context = NEW zcra_cl_context( ) ).

    " Regel nicht anwendbar => validate nicht aufgerufen => keine Meldung, aber protokolliert.
    cl_abap_unit_assert=>assert_initial( result->get_messages( ) ).
    DATA(entries) = log->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 2 ]-applicable exp = abap_false ).
  ENDMETHOD.

  METHOD kind_bucket_mismatch.
    DATA(det_stub) = NEW lcl_det( ).
    " Eine Transformationsregel fälschlich im PRE-(Validierungs-)Bucket.
    det_stub->set( rule_type = zcra_if_c_rule_type=>validation_pre
                   rules = VALUE #( ( NEW lcl_rule( id = 'BAD' kind = 'T' ) ) ) ).
    build( det_stub ).

    TRY.
        engine->run( process = zcra_if_c_process=>anerkennung
                     context = NEW zcra_cl_context( ) ).
        cl_abap_unit_assert=>fail( 'ZCRA_CX_RULE_KIND erwartet' ).
      CATCH zcra_cx_rule_kind.
        " erwartet
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
