INTERFACE zcra_if_context_mut
  PUBLIC.

  INTERFACES zcra_if_context.

  "! Referenz auf den NEUEN Graphen, damit eine Transformation ihn direkt ändern kann.
  METHODS get_new_graph_ref
    RETURNING VALUE(result) TYPE REF TO zcra_s_graph.

ENDINTERFACE.
