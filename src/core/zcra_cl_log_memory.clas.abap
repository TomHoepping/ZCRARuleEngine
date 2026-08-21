CLASS zcra_cl_log_memory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zcra_if_logger.

    TYPES:
      "! Ein einzelnes aufgezeichnetes Logger-Ereignis.
      BEGIN OF ty_entry,
        event      TYPE string,   " START | RULE | SNAPSHOT | END
        process    TYPE zcra_d_process_id,
        rule_id    TYPE zcra_d_rule_id,
        kind       TYPE zcra_s_rule_meta-kind,
        applicable TYPE abap_bool,
        stop       TYPE abap_bool,
        has_errors TYPE abap_bool,
        msg_count  TYPE i,
        label      TYPE string,
        json       TYPE string,
      END OF ty_entry,
      tt_entry TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    CONSTANTS:
      BEGIN OF gc_event,
        start    TYPE string VALUE 'START',
        rule     TYPE string VALUE 'RULE',
        snapshot TYPE string VALUE 'SNAPSHOT',
        end      TYPE string VALUE 'END',
      END OF gc_event.

    "! Alle aufgezeichneten Ereignisse in Einfügereihenfolge.
    METHODS get_entries
      RETURNING VALUE(result) TYPE tt_entry.
    "! Anzahl der aufgezeichneten Ereignisse (optional nach Ereignistyp gefiltert).
    METHODS count
      IMPORTING
        !event        TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA entries TYPE tt_entry.
ENDCLASS.



CLASS zcra_cl_log_memory IMPLEMENTATION.

  METHOD zcra_if_logger~start_run.
    APPEND VALUE #( event = gc_event-start process = process ) TO entries.
  ENDMETHOD.

  METHOD zcra_if_logger~log_rule.
    APPEND VALUE #(
      event      = gc_event-rule
      rule_id    = meta-rule_id
      kind       = meta-kind
      applicable = applicable
      stop       = result->is_stop_requested( )
      has_errors = result->has_errors( )
      msg_count  = lines( result->get_messages( ) )
    ) TO entries.
  ENDMETHOD.

  METHOD zcra_if_logger~snapshot.
    DATA: BEGIN OF snap,
            old TYPE zcra_s_graph,
            new TYPE zcra_s_graph,
          END OF snap.
    snap-old = context->get_old_graph( ).
    snap-new = context->get_new_graph( ).
    APPEND VALUE #(
      event = gc_event-snapshot
      label = label
      json  = /ui2/cl_json=>serialize( data = snap )
    ) TO entries.
  ENDMETHOD.

  METHOD zcra_if_logger~end_run.
    APPEND VALUE #( event = gc_event-end process = process ) TO entries.
  ENDMETHOD.

  METHOD get_entries.
    result = entries.
  ENDMETHOD.

  METHOD count.
    IF event IS INITIAL.
      result = lines( entries ).
    ELSE.
      result = REDUCE i( INIT n = 0 FOR entry IN entries
                         NEXT n = COND #( WHEN entry-event = event THEN n + 1 ELSE n ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
