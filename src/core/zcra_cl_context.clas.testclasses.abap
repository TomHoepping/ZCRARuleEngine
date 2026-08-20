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
    DATA ls_old TYPE zcra_s_graph.
    DATA ls_new TYPE zcra_s_graph.
    ls_old-shell_placeholder = 'O'.
    ls_new-shell_placeholder = 'N'.

    DATA(lo_ctx) = NEW zcra_cl_context( is_old = ls_old is_new = ls_new ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_ctx->zcra_if_context~get_old_graph( )-shell_placeholder
      exp = 'O' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_ctx->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'N' ).
  ENDMETHOD.

  METHOD mut_ref_is_new.
    DATA ls_new TYPE zcra_s_graph.
    ls_new-shell_placeholder = 'N'.

    DATA(lo_ctx) = NEW zcra_cl_context( is_new = ls_new ).
    DATA(lr_new) = lo_ctx->zcra_if_context_mut~get_new_graph_ref( ).

    " Mutating through the reference must change the context's new graph.
    lr_new->shell_placeholder = 'X'.
    cl_abap_unit_assert=>assert_equals(
      act = lo_ctx->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'X' ).
  ENDMETHOD.

  METHOD snapshot_is_copy.
    DATA ls_new TYPE zcra_s_graph.
    ls_new-shell_placeholder = 'A'.

    DATA(lo_ctx)  = NEW zcra_cl_context( is_new = ls_new ).
    DATA(lo_copy) = lo_ctx->snapshot( ).

    " Copy must hold the same values...
    cl_abap_unit_assert=>assert_equals(
      act = lo_copy->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'A' ).

    " ...but be independent: mutating the original must not affect the copy.
    DATA(lr_new) = lo_ctx->zcra_if_context_mut~get_new_graph_ref( ).
    lr_new->shell_placeholder = 'B'.
    cl_abap_unit_assert=>assert_equals(
      act = lo_copy->zcra_if_context~get_new_graph( )-shell_placeholder
      exp = 'A' ).
    cl_abap_unit_assert=>assert_false(
      xsdbool( lo_ctx = lo_copy ) ).
  ENDMETHOD.

ENDCLASS.
