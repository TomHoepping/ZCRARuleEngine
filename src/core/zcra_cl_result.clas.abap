CLASS zcra_cl_result DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Fügt eine Meldung aus Einzelfeldern hinzu. Die Knotenadressierung folgt D-45:
    "! NODE_ID -> PARAMETER, ROW -> Zeilenindex, FIELD -> Feld, SEVERITY -> Meldungstyp.
    "! @parameter severity   | Meldungstyp (E/W/I/A/S).
    "! @parameter id         | Nachrichtenklasse.
    "! @parameter number     | Nachrichtennummer.
    "! @parameter node_id    | Knotenadresse (BAPIRET2-PARAMETER).
    "! @parameter row        | Zeilenindex innerhalb des Knotens.
    "! @parameter field      | Betroffenes Feld.
    METHODS add_message
      IMPORTING
        !severity   TYPE bapiret2-type
        !id         TYPE bapiret2-id
        !number     TYPE bapiret2-number
        !message_v1 TYPE bapiret2-message_v1 OPTIONAL
        !message_v2 TYPE bapiret2-message_v2 OPTIONAL
        !message_v3 TYPE bapiret2-message_v3 OPTIONAL
        !message_v4 TYPE bapiret2-message_v4 OPTIONAL
        !node_id    TYPE bapiret2-parameter OPTIONAL
        !row        TYPE bapiret2-row OPTIONAL
        !field      TYPE bapiret2-field OPTIONAL.
    "! Hängt eine bereits aufgebaute BAPIRET2-Meldung an.
    METHODS add_bapiret
      IMPORTING
        !bapiret TYPE bapiret2.
    "! Fordert an, dass die Engine nach der aktuellen Regel anhält.
    METHODS request_stop.
    "! Gibt an, ob ein Abbruch angefordert wurde.
    METHODS is_stop_requested
      RETURNING VALUE(result) TYPE abap_bool.
    "! Gibt an, ob eine gesammelte Meldung ein Fehler ('E') oder Abbruch ('A') ist.
    METHODS has_errors
      RETURNING VALUE(result) TYPE abap_bool.
    "! Die gesammelten Meldungen.
    METHODS get_messages
      RETURNING VALUE(result) TYPE bapiret2_tab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA messages TYPE bapiret2_tab.
    DATA stop_requested TYPE abap_bool.

ENDCLASS.



CLASS zcra_cl_result IMPLEMENTATION.

  METHOD add_message.
    DATA msg TYPE bapiret2.
    msg-type       = severity.
    msg-id         = id.
    msg-number     = number.
    msg-message_v1 = message_v1.
    msg-message_v2 = message_v2.
    msg-message_v3 = message_v3.
    msg-message_v4 = message_v4.
    msg-parameter  = node_id.
    msg-row        = row.
    msg-field      = field.
    add_bapiret( msg ).
  ENDMETHOD.

  METHOD add_bapiret.
    APPEND bapiret TO me->messages.
  ENDMETHOD.

  METHOD request_stop.
    me->stop_requested = abap_true.
  ENDMETHOD.

  METHOD is_stop_requested.
    result = me->stop_requested.
  ENDMETHOD.

  METHOD has_errors.
    result = xsdbool( line_exists( me->messages[ type = 'E' ] )
                   OR line_exists( me->messages[ type = 'A' ] ) ).
  ENDMETHOD.

  METHOD get_messages.
    result = me->messages.
  ENDMETHOD.

ENDCLASS.
