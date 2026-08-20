class ltc_factory definition final for testing
  duration short
  risk level harmless .

  private section.
    data mo_cut type ref to zcra_cl_rule_factory.
    methods setup.
    methods put_then_get      for testing.
    methods has_reflects_state for testing.
    methods get_or_put_caches for testing.
endclass.


class lcl_rule definition.
  public section.
    interfaces zcra_if_rule.
endclass.

class lcl_rule implementation.
  method zcra_if_rule~get_meta.
  endmethod.
  method zcra_if_rule~exec_condition.
    rv_applicable = abap_true.
  endmethod.
  method zcra_if_rule~validate.
  endmethod.
  method zcra_if_rule~transform.
  endmethod.
endclass.


class ltc_factory implementation.

  method setup.
    mo_cut = new #( ).
  endmethod.

  method put_then_get.
    data(lo_rule) = cast zcra_if_rule( new lcl_rule( ) ).
    mo_cut->put( iv_name = 'R1' io_rule = lo_rule ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get( 'R1' ) exp = lo_rule ).
  endmethod.

  method has_reflects_state.
    cl_abap_unit_assert=>assert_false( mo_cut->has( 'R1' ) ).
    mo_cut->put( iv_name = 'R1' io_rule = cast zcra_if_rule( new lcl_rule( ) ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->has( 'R1' ) ).
  endmethod.

  method get_or_put_caches.
    data(lo_first)  = cast zcra_if_rule( new lcl_rule( ) ).
    data(lo_second) = cast zcra_if_rule( new lcl_rule( ) ).

    data(lo_a) = mo_cut->get_or_put( iv_name = 'R1' io_rule = lo_first ).
    data(lo_b) = mo_cut->get_or_put( iv_name = 'R1' io_rule = lo_second ).

    " First call stores and returns the supplied instance.
    cl_abap_unit_assert=>assert_equals( act = lo_a exp = lo_first ).
    " Repeat call is a cache hit: returns the first instance, not lo_second.
    cl_abap_unit_assert=>assert_equals( act = lo_b exp = lo_first ).
  endmethod.

endclass.
