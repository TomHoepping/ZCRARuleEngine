CLASS ltc_result DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcra_cl_result.
    METHODS setup.

    METHODS add_message_appends   FOR TESTING.
    METHODS add_bapiret_appends   FOR TESTING.
    METHODS get_messages_empty    FOR TESTING.
    METHODS stop_flag_default     FOR TESTING.
    METHODS stop_flag_set         FOR TESTING.
    METHODS has_errors_false      FOR TESTING.
    METHODS has_errors_on_e       FOR TESTING.
    METHODS has_errors_on_a       FOR TESTING.
    METHODS node_addressing       FOR TESTING.
ENDCLASS.


CLASS ltc_result IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD get_messages_empty.
    cl_abap_unit_assert=>assert_initial( cut->get_messages( ) ).
  ENDMETHOD.

  METHOD add_message_appends.
    cut->add_message( severity = 'I' id = 'ZCRA_ENGINE' number = '000' ).
    cut->add_message( severity = 'S' id = 'ZCRA_ENGINE' number = '000' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( cut->get_messages( ) )
      exp = 2 ).
  ENDMETHOD.

  METHOD add_bapiret_appends.
    DATA msg TYPE bapiret2.
    msg-type   = 'S'.
    msg-id     = 'ZCRA_ENGINE'.
    msg-number = '001'.
    cut->add_bapiret( msg ).

    DATA(messages) = cut->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type   exp = 'S' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-number exp = '001' ).
  ENDMETHOD.

  METHOD stop_flag_default.
    cl_abap_unit_assert=>assert_false( cut->is_stop_requested( ) ).
  ENDMETHOD.

  METHOD stop_flag_set.
    cut->request_stop( ).
    cl_abap_unit_assert=>assert_true( cut->is_stop_requested( ) ).
  ENDMETHOD.

  METHOD has_errors_false.
    cut->add_message( severity = 'S' id = 'ZCRA_ENGINE' number = '000' ).
    cut->add_message( severity = 'W' id = 'ZCRA_ENGINE' number = '000' ).
    cut->add_message( severity = 'I' id = 'ZCRA_ENGINE' number = '000' ).
    cl_abap_unit_assert=>assert_false( cut->has_errors( ) ).
  ENDMETHOD.

  METHOD has_errors_on_e.
    cut->add_message( severity = 'S' id = 'ZCRA_ENGINE' number = '000' ).
    cut->add_message( severity = 'E' id = 'ZCRA_ENGINE' number = '000' ).
    cl_abap_unit_assert=>assert_true( cut->has_errors( ) ).
  ENDMETHOD.

  METHOD has_errors_on_a.
    cut->add_message( severity = 'A' id = 'ZCRA_ENGINE' number = '000' ).
    cl_abap_unit_assert=>assert_true( cut->has_errors( ) ).
  ENDMETHOD.

  METHOD node_addressing.
    cut->add_message(
      severity = 'E'
      id       = 'ZCRA_ENGINE'
      number   = '000'
      node_id  = 'CHILD_1'
      row      = 2
      field    = 'BIRTHDT' ).

    DATA(messages) = cut->get_messages( ).
    DATA(msg) = messages[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = msg-parameter exp = 'CHILD_1' ).
    cl_abap_unit_assert=>assert_equals( act = msg-row       exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = msg-field     exp = 'BIRTHDT' ).
  ENDMETHOD.

ENDCLASS.
