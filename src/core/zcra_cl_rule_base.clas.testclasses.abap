"! Wegwerf-Regel, die NUR validate redefiniert und damit beweist, dass die Basis
"! funktionierende Standardwerte für get_meta / exec_condition / transform liefert.
CLASS ltc_rule DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS default_condition_true FOR TESTING.
    METHODS validate_redefined     FOR TESTING.
    METHODS transform_is_noop      FOR TESTING.
ENDCLASS.


CLASS lcl_validation_rule DEFINITION
  INHERITING FROM zcra_cl_rule_base.
  PUBLIC SECTION.
    METHODS zcra_if_rule~validate REDEFINITION.
ENDCLASS.

CLASS lcl_validation_rule IMPLEMENTATION.
  METHOD zcra_if_rule~validate.
    result->add_message(
      severity = 'E'
      id       = 'ZCRA_ENGINE'
      number   = '000' ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_rule IMPLEMENTATION.

  METHOD default_condition_true.
    DATA(rule)    = NEW lcl_validation_rule( ).
    DATA(context) = NEW zcra_cl_context( ).
    cl_abap_unit_assert=>assert_true(
      rule->zcra_if_rule~exec_condition( context ) ).
  ENDMETHOD.

  METHOD validate_redefined.
    DATA(rule)    = NEW lcl_validation_rule( ).
    DATA(context) = NEW zcra_cl_context( ).
    DATA(result)  = NEW zcra_cl_result( ).

    rule->zcra_if_rule~validate( context = context
                                 result  = result ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( result->get_messages( ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_true( result->has_errors( ) ).
  ENDMETHOD.

  METHOD transform_is_noop.
    DATA(rule)    = NEW lcl_validation_rule( ).
    DATA(context) = NEW zcra_cl_context( ).
    DATA(result)  = NEW zcra_cl_result( ).

    rule->zcra_if_rule~transform( context = context
                                  result  = result ).

    cl_abap_unit_assert=>assert_initial( result->get_messages( ) ).
  ENDMETHOD.

ENDCLASS.
