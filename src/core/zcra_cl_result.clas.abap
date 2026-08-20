class ZCRA_CL_RESULT definition
  public
  create public .

  public section.

    "! Add a message from individual fields. Node addressing follows D-45:
    "! NODE_ID -> PARAMETER, ROW -> row index, FIELD -> field, TYPE -> severity.
    methods add_message
      importing
        !iv_type       type bapiret2-type
        !iv_id         type bapiret2-id
        !iv_number     type bapiret2-number
        !iv_message_v1 type bapiret2-message_v1 optional
        !iv_message_v2 type bapiret2-message_v2 optional
        !iv_message_v3 type bapiret2-message_v3 optional
        !iv_message_v4 type bapiret2-message_v4 optional
        !iv_node_id    type bapiret2-parameter optional
        !iv_row        type bapiret2-row optional
        !iv_field      type bapiret2-field optional .
    "! Append a pre-built BAPIRET2 message.
    methods add_bapiret
      importing
        !is_message type bapiret2 .
    "! Request that the engine stop after the current rule.
    methods request_stop .
    "! Whether a stop has been requested.
    methods is_stop_requested
      returning value(rv_stop) type abap_bool .
    "! Whether any accumulated message is an error ('E') or abort ('A').
    methods has_errors
      returning value(rv_has_errors) type abap_bool .
    "! The accumulated messages.
    methods get_messages
      returning value(rt_messages) type bapiret2_tab .

  protected section.
  private section.

    data mt_messages type bapiret2_tab .
    data mv_stop type abap_bool .

endclass.



class ZCRA_CL_RESULT implementation.

  method add_message.
    data ls_msg type bapiret2.
    ls_msg-type       = iv_type.
    ls_msg-id         = iv_id.
    ls_msg-number     = iv_number.
    ls_msg-message_v1 = iv_message_v1.
    ls_msg-message_v2 = iv_message_v2.
    ls_msg-message_v3 = iv_message_v3.
    ls_msg-message_v4 = iv_message_v4.
    ls_msg-parameter  = iv_node_id.
    ls_msg-row        = iv_row.
    ls_msg-field      = iv_field.
    add_bapiret( ls_msg ).
  endmethod.

  method add_bapiret.
    append is_message to mt_messages.
  endmethod.

  method request_stop.
    mv_stop = abap_true.
  endmethod.

  method is_stop_requested.
    rv_stop = mv_stop.
  endmethod.

  method has_errors.
    loop at mt_messages transporting no fields
      where type = 'E' or type = 'A'.
      rv_has_errors = abap_true.
      exit.
    endloop.
  endmethod.

  method get_messages.
    rt_messages = mt_messages.
  endmethod.

endclass.
