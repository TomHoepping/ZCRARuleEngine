interface zcra_if_context_mut
  public .

  interfaces zcra_if_context .

  "! Reference to the NEW graph so a transformation can mutate it in place.
  methods get_new_graph_ref
    returning value(rr_graph) type ref to zcra_s_graph .

endinterface.
