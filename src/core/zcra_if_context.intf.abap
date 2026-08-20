interface zcra_if_context
  public .

  "! The graph as it was BEFORE the engine run (read-only baseline).
  methods get_old_graph
    returning value(rs_graph) type zcra_s_graph .
  "! The current NEW graph (read-only view).
  methods get_new_graph
    returning value(rs_graph) type zcra_s_graph .

endinterface.
