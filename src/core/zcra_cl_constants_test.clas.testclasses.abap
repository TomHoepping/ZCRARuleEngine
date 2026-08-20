CLASS ltc_constants DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS process_constants   FOR TESTING.
    METHODS rule_kind_constants FOR TESTING.
ENDCLASS.


CLASS ltc_constants IMPLEMENTATION.

  METHOD process_constants.
    cl_abap_unit_assert=>assert_equals(
      act = zcra_if_c_process=>wegzug
      exp = 'WEGZUG' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcra_if_c_process=>anerkennung
      exp = 'ANERKENNUNG' ).

    " constants must be usable as ZCRA_D_PROCESS_ID
    DATA lv_process TYPE zcra_d_process_id.
    lv_process = zcra_if_c_process=>wegzug.
    cl_abap_unit_assert=>assert_not_initial( lv_process ).
  ENDMETHOD.

  METHOD rule_kind_constants.
    cl_abap_unit_assert=>assert_equals(
      act = zcra_if_c_rule_kind=>validation
      exp = 'V' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcra_if_c_rule_kind=>transformation
      exp = 'T' ).

    " constants must fit ZCRA_S_RULE_META-KIND
    DATA ls_meta TYPE zcra_s_rule_meta.
    ls_meta-kind = zcra_if_c_rule_kind=>validation.
    cl_abap_unit_assert=>assert_equals(
      act = ls_meta-kind
      exp = 'V' ).
  ENDMETHOD.

ENDCLASS.
