CLASS zcra_cl_context DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zcra_if_context_mut.

    "! @parameter old_graph | Graph im Zustand VOR dem Lauf (optional).
    "! @parameter new_graph | Graph im Zustand NACH dem Lauf (optional).
    METHODS constructor
      IMPORTING
        !old_graph TYPE zcra_s_graph OPTIONAL
        !new_graph TYPE zcra_s_graph OPTIONAL.

    "! Liefert eine unabhängige tiefe Kopie dieses Kontexts.
    METHODS snapshot
      RETURNING VALUE(result) TYPE REF TO zcra_cl_context.

  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA old_graph TYPE zcra_s_graph.
    DATA new_graph TYPE zcra_s_graph.

ENDCLASS.



CLASS zcra_cl_context IMPLEMENTATION.

  METHOD constructor.
    me->old_graph = old_graph.
    me->new_graph = new_graph.
  ENDMETHOD.

  METHOD zcra_if_context~get_old_graph.
    result = me->old_graph.
  ENDMETHOD.

  METHOD zcra_if_context~get_new_graph.
    result = me->new_graph.
  ENDMETHOD.

  METHOD zcra_if_context_mut~get_new_graph_ref.
    result = REF #( me->new_graph ).
  ENDMETHOD.

  METHOD snapshot.
    result = NEW zcra_cl_context( old_graph = me->old_graph
                                  new_graph = me->new_graph ).
  ENDMETHOD.

ENDCLASS.
