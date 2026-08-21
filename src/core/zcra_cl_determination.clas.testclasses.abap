CLASS ltc_determination DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcra_cl_determination.
    METHODS setup.
    METHODS unknown_process_empty  FOR TESTING.
    METHODS registered_has_rules   FOR TESTING.
    METHODS get_rules_ordered      FOR TESTING.
ENDCLASS.


CLASS lcl_rule DEFINITION.
  PUBLIC SECTION.
    INTERFACES zcra_if_rule.
    METHODS constructor
      IMPORTING id TYPE zcra_d_rule_id.
  PRIVATE SECTION.
    DATA id TYPE zcra_d_rule_id.
ENDCLASS.

CLASS lcl_rule IMPLEMENTATION.
  METHOD constructor.
    me->id = id.
  ENDMETHOD.
  METHOD zcra_if_rule~get_meta.
    result-rule_id = me->id.
  ENDMETHOD.
  METHOD zcra_if_rule~exec_condition.
    result = abap_true.
  ENDMETHOD.
  METHOD zcra_if_rule~validate.
  ENDMETHOD.
  METHOD zcra_if_rule~transform.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_det DEFINITION.
  PUBLIC SECTION.
    INTERFACES zcra_if_determination.
ENDCLASS.

CLASS lcl_det IMPLEMENTATION.
  METHOD zcra_if_determination~has_rules.
    result = xsdbool( rule_type = zcra_if_c_rule_type=>validation_pre ).
  ENDMETHOD.
  METHOD zcra_if_determination~get_rules.
    IF rule_type = zcra_if_c_rule_type=>validation_pre.
      APPEND CAST zcra_if_rule( NEW lcl_rule( 'R1' ) ) TO result.
      APPEND CAST zcra_if_rule( NEW lcl_rule( 'R2' ) ) TO result.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_determination IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
    cut->register( process       = zcra_if_c_process=>anerkennung
                   determination = NEW lcl_det( ) ).
  ENDMETHOD.

  METHOD unknown_process_empty.
    cl_abap_unit_assert=>assert_false(
      cut->has_rules( process   = zcra_if_c_process=>wegzug
                      rule_type = zcra_if_c_rule_type=>validation_pre ) ).
    cl_abap_unit_assert=>assert_initial(
      cut->get_rules( process   = zcra_if_c_process=>wegzug
                      rule_type = zcra_if_c_rule_type=>validation_pre ) ).
  ENDMETHOD.

  METHOD registered_has_rules.
    cl_abap_unit_assert=>assert_true(
      cut->has_rules( process   = zcra_if_c_process=>anerkennung
                      rule_type = zcra_if_c_rule_type=>validation_pre ) ).
    cl_abap_unit_assert=>assert_false(
      cut->has_rules( process   = zcra_if_c_process=>anerkennung
                      rule_type = zcra_if_c_rule_type=>transformation ) ).
  ENDMETHOD.

  METHOD get_rules_ordered.
    DATA(rules) = cut->get_rules( process   = zcra_if_c_process=>anerkennung
                                  rule_type = zcra_if_c_rule_type=>validation_pre ).
    cl_abap_unit_assert=>assert_equals( act = lines( rules ) exp = 2 ).

    DATA(first)  = rules[ 1 ].
    DATA(second) = rules[ 2 ].
    cl_abap_unit_assert=>assert_equals( act = first->get_meta( )-rule_id  exp = 'R1' ).
    cl_abap_unit_assert=>assert_equals( act = second->get_meta( )-rule_id exp = 'R2' ).
  ENDMETHOD.

ENDCLASS.
