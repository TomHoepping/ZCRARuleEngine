CLASS ltc_factory DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcra_cl_rule_factory.
    METHODS setup.
    METHODS put_then_get      FOR TESTING.
    METHODS has_reflects_state FOR TESTING.
    METHODS get_or_put_caches FOR TESTING.
ENDCLASS.


CLASS lcl_rule DEFINITION.
  PUBLIC SECTION.
    INTERFACES zcra_if_rule.
ENDCLASS.

CLASS lcl_rule IMPLEMENTATION.
  METHOD zcra_if_rule~get_meta.
  ENDMETHOD.
  METHOD zcra_if_rule~exec_condition.
    result = abap_true.
  ENDMETHOD.
  METHOD zcra_if_rule~validate.
  ENDMETHOD.
  METHOD zcra_if_rule~transform.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_factory IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD put_then_get.
    DATA(rule) = CAST zcra_if_rule( NEW lcl_rule( ) ).
    cut->put( name = 'R1' rule = rule ).
    cl_abap_unit_assert=>assert_equals( act = cut->get( 'R1' ) exp = rule ).
  ENDMETHOD.

  METHOD has_reflects_state.
    cl_abap_unit_assert=>assert_false( cut->has( 'R1' ) ).
    cut->put( name = 'R1' rule = CAST zcra_if_rule( NEW lcl_rule( ) ) ).
    cl_abap_unit_assert=>assert_true( cut->has( 'R1' ) ).
  ENDMETHOD.

  METHOD get_or_put_caches.
    DATA(first)  = CAST zcra_if_rule( NEW lcl_rule( ) ).
    DATA(second) = CAST zcra_if_rule( NEW lcl_rule( ) ).

    DATA(a) = cut->get_or_put( name = 'R1' rule = first ).
    DATA(b) = cut->get_or_put( name = 'R1' rule = second ).

    " Erster Aufruf speichert und liefert die übergebene Instanz.
    cl_abap_unit_assert=>assert_equals( act = a exp = first ).
    " Wiederholungsaufruf ist ein Cache-Treffer: liefert die erste Instanz, nicht second.
    cl_abap_unit_assert=>assert_equals( act = b exp = first ).
  ENDMETHOD.

ENDCLASS.
