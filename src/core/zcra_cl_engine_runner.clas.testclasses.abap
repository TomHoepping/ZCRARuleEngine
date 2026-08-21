" Unit-Tests für ZCRA_CL_ENGINE_RUNNER: Fassade verdrahtet Logger, Kontext und
" Engine korrekt; CONSOLE liefert Trace, SLG1/NONE nicht; Ergebnisgraph enthält
" die Transformationsergebnisse. Lokale Doubles halten den Test CORE-eigenständig.

"! Transformationsregel-Double: setzt das Beispiel-Flag im neuen Graphen.
CLASS lcl_trn DEFINITION FINAL INHERITING FROM zcra_cl_rule_base.
  PUBLIC SECTION.
    METHODS zcra_if_rule~get_meta  REDEFINITION.
    METHODS zcra_if_rule~transform REDEFINITION.
ENDCLASS.

CLASS lcl_trn IMPLEMENTATION.
  METHOD zcra_if_rule~get_meta.
    result-rule_id = 'T_TRN'.
    result-kind    = zcra_if_c_rule_kind=>transformation.
  ENDMETHOD.
  METHOD zcra_if_rule~transform.
    DATA(new_graph) = context->get_new_graph_ref( ).
    new_graph->shell_placeholder = 'X'.
  ENDMETHOD.
ENDCLASS.

"! Validierungsregel-Double: meldet, wenn das Flag noch nicht gesetzt ist.
CLASS lcl_val DEFINITION FINAL INHERITING FROM zcra_cl_rule_base.
  PUBLIC SECTION.
    METHODS zcra_if_rule~get_meta REDEFINITION.
    METHODS zcra_if_rule~validate REDEFINITION.
ENDCLASS.

CLASS lcl_val IMPLEMENTATION.
  METHOD zcra_if_rule~get_meta.
    result-rule_id = 'T_VAL'.
    result-kind    = zcra_if_c_rule_kind=>validation.
  ENDMETHOD.
  METHOD zcra_if_rule~validate.
    IF context->get_new_graph( )-shell_placeholder IS INITIAL.
      result->add_message( severity = 'I' id = 'ZCRA_ENGINE' number = '000' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

"! Determination-Double: VAL in PRE/POST, TRN in TRANSFORMATION.
CLASS lcl_det DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zcra_if_determination.
    METHODS constructor.
  PRIVATE SECTION.
    DATA val TYPE REF TO zcra_if_rule.
    DATA trn TYPE REF TO zcra_if_rule.
ENDCLASS.

CLASS lcl_det IMPLEMENTATION.
  METHOD constructor.
    me->val = NEW lcl_val( ).
    me->trn = NEW lcl_trn( ).
  ENDMETHOD.
  METHOD zcra_if_determination~get_rules.
    CASE rule_type.
      WHEN zcra_if_c_rule_type=>validation_pre.  result = VALUE #( ( me->val ) ).
      WHEN zcra_if_c_rule_type=>transformation.  result = VALUE #( ( me->trn ) ).
      WHEN zcra_if_c_rule_type=>validation_post. result = VALUE #( ( me->val ) ).
    ENDCASE.
  ENDMETHOD.
  METHOD zcra_if_determination~has_rules.
    result = xsdbool( lines( zcra_if_determination~get_rules( rule_type ) ) > 0 ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_runner DEFINITION FINAL
  FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_process TYPE zcra_d_process_id VALUE 'TEST'.

    METHODS build_registry
      RETURNING VALUE(result) TYPE REF TO zcra_cl_determination.

    METHODS console_returns_trace   FOR TESTING RAISING cx_static_check.
    METHODS transform_reaches_graph FOR TESTING RAISING cx_static_check.
    METHODS slg1_has_no_trace       FOR TESTING RAISING cx_static_check.
    METHODS none_has_no_trace       FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_runner IMPLEMENTATION.

  METHOD build_registry.
    result = NEW zcra_cl_determination( ).
    result->register( process = c_process determination = NEW lcl_det( ) ).
  ENDMETHOD.

  METHOD console_returns_trace.
    DATA(runner) = NEW zcra_cl_engine_runner( determination = build_registry( )
                                              log_mode      = zcra_if_c_log_mode=>console ).
    DATA(result) = runner->run( input_graph = VALUE #( ) process = c_process ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( result->get_messages( ) ) exp = 1
      msg = 'PRE meldet, POST bleibt still -> genau eine Meldung' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = lines( runner->get_trace_lines( ) )
      msg = 'CONSOLE-Modus muss einen Trace liefern' ).
  ENDMETHOD.

  METHOD transform_reaches_graph.
    DATA(runner) = NEW zcra_cl_engine_runner( determination = build_registry( )
                                              log_mode      = zcra_if_c_log_mode=>none ).
    runner->run( input_graph = VALUE #( ) process = c_process ).
    cl_abap_unit_assert=>assert_equals(
      act = runner->get_result_graph( )-shell_placeholder exp = 'X'
      msg = 'Transformation muss den Ergebnisgraphen erreichen' ).
  ENDMETHOD.

  METHOD slg1_has_no_trace.
    DATA(runner) = NEW zcra_cl_engine_runner( determination = build_registry( )
                                              log_mode      = zcra_if_c_log_mode=>slg1 ).
    runner->run( input_graph = VALUE #( ) process = c_process ).
    cl_abap_unit_assert=>assert_initial(
      act = lines( runner->get_trace_lines( ) )
      msg = 'SLG1-Modus stellt keinen In-Memory-Trace bereit' ).
  ENDMETHOD.

  METHOD none_has_no_trace.
    DATA(runner) = NEW zcra_cl_engine_runner( determination = build_registry( )
                                              log_mode      = zcra_if_c_log_mode=>none ).
    runner->run( input_graph = VALUE #( ) process = c_process ).
    cl_abap_unit_assert=>assert_initial(
      act = lines( runner->get_trace_lines( ) )
      msg = 'NONE-Modus stellt keinen Trace bereit' ).
  ENDMETHOD.

ENDCLASS.
