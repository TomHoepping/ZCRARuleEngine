"! Example VALIDATION rule (payload shell / template for developers).
"! Reads the context (read-only) and raises an info message when the sample
"! flag (ZCRA_S_GRAPH-SHELL_PLACEHOLDER) is not set. Used PRE (flag missing ->
"! message) and POST (flag set by the transform -> silent) to demonstrate the
"! before/after effect of a transformation. Kind = Validation (D-33).
class zcra_cl_val_example definition
  public
  final
  create public
  inheriting from zcra_cl_rule_base .

  public section.
    methods zcra_if_rule~get_meta redefinition .
    methods zcra_if_rule~validate redefinition .
  protected section.
  private section.
endclass.



class zcra_cl_val_example implementation.

  method zcra_if_rule~get_meta.
    rs_meta-rule_id = 'VAL_EXAMPLE'.
    rs_meta-purpose = 'Example validation: report when the sample flag is not set'.
    rs_meta-kind    = zcra_if_c_rule_kind=>validation.
  endmethod.

  method zcra_if_rule~validate.
    data(ls_new) = io_context->get_new_graph( ).
    if ls_new-shell_placeholder is initial.
      io_result->add_message(
        iv_type   = 'I'
        iv_id     = 'ZCRA_ENGINE'
        iv_number = '010' ).
    endif.
  endmethod.

endclass.
