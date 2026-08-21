INTERFACE zcra_if_context
  PUBLIC.

  "! Liefert den Graphen im Zustand VOR dem Engine-Lauf (schreibgeschützte Basis).
  METHODS get_old_graph
    RETURNING VALUE(result) TYPE zcra_s_graph.
  "! Liefert den aktuellen NEUEN Graphen (schreibgeschützte Sicht).
  METHODS get_new_graph
    RETURNING VALUE(result) TYPE zcra_s_graph.

ENDINTERFACE.
