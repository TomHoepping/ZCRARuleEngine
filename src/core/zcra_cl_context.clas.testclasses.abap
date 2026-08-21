CLASS ltc_context DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS old_new_accessors  FOR TESTING.
    METHODS mut_ref_is_new     FOR TESTING.
    METHODS snapshot_is_copy   FOR TESTING.
ENDCLASS.


CLASS ltc_context IMPLEMENTATION.

  METHOD old_new_accessors.
    DATA old_graph TYPE zcra_s_graph.
    DATA new_graph TYPE zcra_s_graph.
    old_graph-shell_placeholder = 'O'.
    new_graph-shell_placeholder = 'N'.

    DATA(context) = NEW zcra_cl_context( old_graph = old_graph new_graph = new_graph ).

    cl_abap_unit_assert=>assert_equals(
      act = context->zcra_if_context~get_old_graph( )-shell_placeholder
      exp = 'O' ).
    cl_abap_unit_assert=>assert_equals(
      act = context->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'N' ).
  ENDMETHOD.

  METHOD mut_ref_is_new.
    DATA new_graph TYPE zcra_s_graph.
    new_graph-shell_placeholder = 'N'.

    DATA(context) = NEW zcra_cl_context( new_graph = new_graph ).
    DATA(new_ref) = context->zcra_if_context_mut~get_new_graph_ref( ).

    " Änderung über die Referenz muss den neuen Graphen des Kontexts ändern.
    new_ref->shell_placeholder = 'X'.
    cl_abap_unit_assert=>assert_equals(
      act = context->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'X' ).
  ENDMETHOD.

  METHOD snapshot_is_copy.
    DATA new_graph TYPE zcra_s_graph.
    new_graph-shell_placeholder = 'A'.

    DATA(context) = NEW zcra_cl_context( new_graph = new_graph ).
    DATA(copy)    = context->snapshot( ).

    " Die Kopie muss dieselben Werte enthalten...
    cl_abap_unit_assert=>assert_equals(
      act = copy->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'A' ).

    " ...aber unabhängig sein: Änderung am Original darf die Kopie nicht beeinflussen.
    DATA(new_ref) = context->zcra_if_context_mut~get_new_graph_ref( ).
    new_ref->shell_placeholder = 'B'.
    cl_abap_unit_assert=>assert_equals(
      act = copy->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'A' ).
    cl_abap_unit_assert=>assert_false(
      xsdbool( context = copy ) ).
  ENDMETHOD.

ENDCLASS.
