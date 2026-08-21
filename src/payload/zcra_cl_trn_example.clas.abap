"! Example TRANSFORMATION rule (payload shell / template for developers).
"! Mutates the context: sets the sample flag (ZCRA_S_GRAPH-SHELL_PLACEHOLDER)
"! to 'X' and records an info message. This is the minimal "do something to the
"! data" example until the real data container is implemented. Kind =
"! Transformation (D-33); the engine wraps this phase in a before/after snapshot.
class zcra_cl_trn_example definition
  public
  final
  create public
  inheriting from zcra_cl_rule_base .

  public section.
    methods zcra_if_rule~get_meta   redefinition .
    methods zcra_if_rule~transform  redefinition .
  protected section.
  private section.
endclass.



class zcra_cl_trn_example implementation.

  method zcra_if_rule~get_meta.
    rs_meta-rule_id = 'TRN_EXAMPLE'.
    rs_meta-purpose = 'Example transformation: set the sample flag on the new graph'.
    rs_meta-kind    = zcra_if_c_rule_kind=>transformation.
  endmethod.

  method zcra_if_rule~transform.
    data(lr_new) = io_context->get_new_graph_ref( ).
    lr_new->shell_placeholder = 'X'.
    io_result->add_message(
      iv_type       = 'I'
      iv_id         = 'ZCRA_ENGINE'
      iv_number     = '000'
      iv_message_v1 = 'sample flag set to X' ).
  endmethod.

endclass.
