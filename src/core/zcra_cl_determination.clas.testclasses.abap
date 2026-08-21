class ltc_determination definition final for testing
  duration short
  risk level harmless .

  private section.
    data mo_cut type ref to zcra_cl_determination.
    methods setup.
    methods unknown_process_empty  for testing.
    methods registered_has_rules   for testing.
    methods get_rules_ordered      for testing.
endclass.


class lcl_rule definition.
  public section.
    interfaces zcra_if_rule.
    methods constructor
      importing iv_id type zcra_d_rule_id.
  private section.
    data mv_id type zcra_d_rule_id.
endclass.

class lcl_rule implementation.
  method constructor.
    mv_id = iv_id.
  endmethod.
  method zcra_if_rule~get_meta.
    rs_meta-rule_id = mv_id.
  endmethod.
  method zcra_if_rule~exec_condition.
    rv_applicable = abap_true.
  endmethod.
  method zcra_if_rule~validate.
  endmethod.
  method zcra_if_rule~transform.
  endmethod.
endclass.


class lcl_det definition.
  public section.
    interfaces zcra_if_determination.
endclass.

class lcl_det implementation.
  method zcra_if_determination~has_rules.
    rv_has = xsdbool( iv_type = zcra_if_c_rule_type=>validation_pre ).
  endmethod.
  method zcra_if_determination~get_rules.
    if iv_type = zcra_if_c_rule_type=>validation_pre.
      append cast zcra_if_rule( new lcl_rule( 'R1' ) ) to rt_rules.
      append cast zcra_if_rule( new lcl_rule( 'R2' ) ) to rt_rules.
    endif.
  endmethod.
endclass.


class ltc_determination implementation.

  method setup.
    mo_cut = new #( ).
    mo_cut->register( iv_process = zcra_if_c_process=>anerkennung
                      io_det     = new lcl_det( ) ).
  endmethod.

  method unknown_process_empty.
    cl_abap_unit_assert=>assert_false(
      mo_cut->has_rules( iv_process = zcra_if_c_process=>wegzug
                         iv_type    = zcra_if_c_rule_type=>validation_pre ) ).
    cl_abap_unit_assert=>assert_initial(
      mo_cut->get_rules( iv_process = zcra_if_c_process=>wegzug
                         iv_type    = zcra_if_c_rule_type=>validation_pre ) ).
  endmethod.

  method registered_has_rules.
    cl_abap_unit_assert=>assert_true(
      mo_cut->has_rules( iv_process = zcra_if_c_process=>anerkennung
                         iv_type    = zcra_if_c_rule_type=>validation_pre ) ).
    cl_abap_unit_assert=>assert_false(
      mo_cut->has_rules( iv_process = zcra_if_c_process=>anerkennung
                         iv_type    = zcra_if_c_rule_type=>transformation ) ).
  endmethod.

  method get_rules_ordered.
    data(lt_rules) = mo_cut->get_rules( iv_process = zcra_if_c_process=>anerkennung
                                        iv_type    = zcra_if_c_rule_type=>validation_pre ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_rules ) exp = 2 ).

    data(lo_first)  = lt_rules[ 1 ].
    data(lo_second) = lt_rules[ 2 ].
    cl_abap_unit_assert=>assert_equals( act = lo_first->get_meta( )-rule_id  exp = 'R1' ).
    cl_abap_unit_assert=>assert_equals( act = lo_second->get_meta( )-rule_id exp = 'R2' ).
  endmethod.

endclass.
