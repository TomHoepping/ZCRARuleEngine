class ZCRA_CL_CONTEXT definition
  public
  create public .

  public section.

    interfaces zcra_if_context_mut .

    methods constructor
      importing
        !is_old type zcra_s_graph optional
        !is_new type zcra_s_graph optional .

    "! Return an independent deep copy of this context.
    methods snapshot
      returning value(ro_copy) type ref to zcra_cl_context .

  protected section.
  private section.

    data ms_old type zcra_s_graph .
    data ms_new type zcra_s_graph .

endclass.



class ZCRA_CL_CONTEXT implementation.

  method constructor.
    ms_old = is_old.
    ms_new = is_new.
  endmethod.

  method zcra_if_context~get_old_graph.
    rs_graph = ms_old.
  endmethod.

  method zcra_if_context~get_new_graph.
    rs_graph = ms_new.
  endmethod.

  method zcra_if_context_mut~get_new_graph_ref.
    rr_graph = ref #( ms_new ).
  endmethod.

  method snapshot.
    ro_copy = new zcra_cl_context( is_old = ms_old
                                   is_new = ms_new ).
  endmethod.

endclass.
