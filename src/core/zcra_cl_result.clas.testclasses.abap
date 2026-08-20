CLASS ltc_result DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcra_cl_result.
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
    mo_cut = NEW #( ).
  ENDMETHOD.

  METHOD get_messages_empty.
    cl_abap_unit_assert=>assert_initial( mo_cut->get_messages( ) ).
  ENDMETHOD.

  METHOD add_message_appends.
    mo_cut->add_message( iv_type = 'I' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    mo_cut->add_message( iv_type = 'S' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_cut->get_messages( ) )
      exp = 2 ).
  ENDMETHOD.

  METHOD add_bapiret_appends.
    DATA ls_msg TYPE bapiret2.
    ls_msg-type   = 'S'.
    ls_msg-id     = 'ZCRA_ENGINE'.
    ls_msg-number = '001'.
    mo_cut->add_bapiret( ls_msg ).

    DATA(lt_msg) = mo_cut->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_msg ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-type   exp = 'S' ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-number exp = '001' ).
  ENDMETHOD.

  METHOD stop_flag_default.
    cl_abap_unit_assert=>assert_false( mo_cut->is_stop_requested( ) ).
  ENDMETHOD.

  METHOD stop_flag_set.
    mo_cut->request_stop( ).
    cl_abap_unit_assert=>assert_true( mo_cut->is_stop_requested( ) ).
  ENDMETHOD.

  METHOD has_errors_false.
    mo_cut->add_message( iv_type = 'S' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    mo_cut->add_message( iv_type = 'W' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    mo_cut->add_message( iv_type = 'I' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
  ENDMETHOD.

  METHOD has_errors_on_e.
    mo_cut->add_message( iv_type = 'S' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    mo_cut->add_message( iv_type = 'E' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
  ENDMETHOD.

  METHOD has_errors_on_a.
    mo_cut->add_message( iv_type = 'A' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
  ENDMETHOD.

  METHOD node_addressing.
    mo_cut->add_message(
      iv_type    = 'E'
      iv_id      = 'ZCRA_ENGINE'
      iv_number  = '000'
      iv_node_id = 'CHILD_1'
      iv_row     = 2
      iv_field   = 'BIRTHDT' ).

    DATA(ls_msg) = mo_cut->get_messages( )[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = ls_msg-parameter exp = 'CHILD_1' ).
    cl_abap_unit_assert=>assert_equals( act = ls_msg-row       exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_msg-field     exp = 'BIRTHDT' ).
  ENDMETHOD.

ENDCLASS.
