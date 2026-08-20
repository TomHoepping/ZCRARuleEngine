"! Throwaway concrete rule that redefines ONLY validate, proving the base
"! supplies working defaults for get_meta / exec_condition / transform.
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
    io_result->add_message(
      iv_type   = 'E'
      iv_id     = 'ZCRA_ENGINE'
      iv_number = '000' ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_rule IMPLEMENTATION.

  METHOD default_condition_true.
    DATA(lo_rule) = NEW lcl_validation_rule( ).
    DATA(lo_ctx)  = NEW zcra_cl_context( ).
    cl_abap_unit_assert=>assert_true(
      lo_rule->zcra_if_rule~exec_condition( lo_ctx ) ).
  ENDMETHOD.

  METHOD validate_redefined.
    DATA(lo_rule)   = NEW lcl_validation_rule( ).
    DATA(lo_ctx)    = NEW zcra_cl_context( ).
    DATA(lo_result) = NEW zcra_cl_result( ).

    lo_rule->zcra_if_rule~validate( io_context = lo_ctx
                                    io_result  = lo_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lo_result->get_messages( ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_true( lo_result->has_errors( ) ).
  ENDMETHOD.

  METHOD transform_is_noop.
    DATA(lo_rule)   = NEW lcl_validation_rule( ).
    DATA(lo_ctx)    = NEW zcra_cl_context( ).
    DATA(lo_result) = NEW zcra_cl_result( ).

    lo_rule->zcra_if_rule~transform( io_context = lo_ctx
                                     io_result  = lo_result ).

    cl_abap_unit_assert=>assert_initial( lo_result->get_messages( ) ).
  ENDMETHOD.

ENDCLASS.
