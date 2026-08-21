"! Unit tests for ZCRA_CL_ENGINE: phase order, empty-phase skip, STOP
"! short-circuit, snapshot capture, message accumulation, kind-vs-bucket.
class ltc_engine definition final
  for testing duration short risk level harmless.

  private section.
    data mo_det    type ref to zcra_cl_determination.
    data mo_log    type ref to zcra_cl_log_memory.
    data mo_engine type ref to zcra_cl_engine.

    methods setup.
    methods build importing io_det type ref to zcra_if_determination.

    methods runs_phases_in_order   for testing.
    methods skips_empty_transform  for testing.
    methods stop_short_circuits    for testing.
    methods accumulates_messages   for testing.
    methods inapplicable_skipped   for testing.
    methods kind_bucket_mismatch   for testing raising cx_static_check.
endclass.


"! Configurable stub rule.
class lcl_rule definition final.
  public section.
    interfaces zcra_if_rule.
    methods constructor
      importing
        !iv_id         type zcra_d_rule_id
        !iv_kind       type zcra_s_rule_meta-kind
        !iv_applicable type abap_bool default abap_true
        !iv_add_msg    type abap_bool default abap_false
        !iv_stop       type abap_bool default abap_false.
  private section.
    data ms_meta       type zcra_s_rule_meta.
    data mv_applicable type abap_bool.
    data mv_add_msg    type abap_bool.
    data mv_stop       type abap_bool.
    methods act importing io_result type ref to zcra_cl_result.
endclass.

class lcl_rule implementation.
  method constructor.
    ms_meta-rule_id = iv_id.
    ms_meta-kind    = iv_kind.
    mv_applicable   = iv_applicable.
    mv_add_msg      = iv_add_msg.
    mv_stop         = iv_stop.
  endmethod.
  method zcra_if_rule~get_meta.
    rs_meta = ms_meta.
  endmethod.
  method zcra_if_rule~exec_condition.
    rv_applicable = mv_applicable.
  endmethod.
  method zcra_if_rule~validate.
    act( io_result ).
  endmethod.
  method zcra_if_rule~transform.
    act( io_result ).
  endmethod.
  method act.
    if mv_add_msg = abap_true.
      io_result->add_message( iv_type = 'I' iv_id = 'ZCRA_ENGINE' iv_number = '000' ).
    endif.
    if mv_stop = abap_true.
      io_result->request_stop( ).
    endif.
  endmethod.
endclass.


"! Determination stub with per-bucket rule lists.
class lcl_det definition final.
  public section.
    interfaces zcra_if_determination.
    methods set
      importing
        !iv_type  type zcra_if_c_rule_type=>ty_type
        !it_rules type zcra_if_determination=>tt_rules.
  private section.
    data mt_pre  type zcra_if_determination=>tt_rules.
    data mt_trn  type zcra_if_determination=>tt_rules.
    data mt_post type zcra_if_determination=>tt_rules.
    methods pick
      importing !iv_type type zcra_if_c_rule_type=>ty_type
      returning value(rt_rules) type zcra_if_determination=>tt_rules.
endclass.

class lcl_det implementation.
  method set.
    case iv_type.
      when zcra_if_c_rule_type=>validation_pre.  mt_pre  = it_rules.
      when zcra_if_c_rule_type=>transformation.  mt_trn  = it_rules.
      when zcra_if_c_rule_type=>validation_post. mt_post = it_rules.
    endcase.
  endmethod.
  method pick.
    case iv_type.
      when zcra_if_c_rule_type=>validation_pre.  rt_rules = mt_pre.
      when zcra_if_c_rule_type=>transformation.  rt_rules = mt_trn.
      when zcra_if_c_rule_type=>validation_post. rt_rules = mt_post.
    endcase.
  endmethod.
  method zcra_if_determination~has_rules.
    rv_has = xsdbool( lines( pick( iv_type ) ) > 0 ).
  endmethod.
  method zcra_if_determination~get_rules.
    rt_rules = pick( iv_type ).
  endmethod.
endclass.


class ltc_engine implementation.

  method setup.
    mo_log = new zcra_cl_log_memory( ).
  endmethod.

  method build.
    mo_det = new zcra_cl_determination( ).
    mo_det->register( iv_process = zcra_if_c_process=>anerkennung io_det = io_det ).
    mo_engine = new zcra_cl_engine( io_determination = mo_det io_logger = mo_log ).
  endmethod.

  method runs_phases_in_order.
    data(lo_det) = new lcl_det( ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_pre
                 it_rules = value #( ( new lcl_rule( iv_id = 'VP' iv_kind = 'V' ) ) ) ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>transformation
                 it_rules = value #( ( new lcl_rule( iv_id = 'TR' iv_kind = 'T' ) ) ) ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_post
                 it_rules = value #( ( new lcl_rule( iv_id = 'VO' iv_kind = 'V' ) ) ) ).
    build( lo_det ).

    mo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                    io_context = new zcra_cl_context( ) ).

    data(lt) = mo_log->get_entries( ).
    " START, RULE(VP), SNAPSHOT(BEFORE), RULE(TR), SNAPSHOT(AFTER), RULE(VO), END
    cl_abap_unit_assert=>assert_equals( act = lines( lt ) exp = 7 ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 1 ]-event exp = 'START' ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 2 ]-rule_id exp = 'VP' ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 3 ]-label exp = 'BEFORE' ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 4 ]-rule_id exp = 'TR' ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 5 ]-label exp = 'AFTER' ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 6 ]-rule_id exp = 'VO' ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 7 ]-event exp = 'END' ).
  endmethod.

  method skips_empty_transform.
    data(lo_det) = new lcl_det( ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_pre
                 it_rules = value #( ( new lcl_rule( iv_id = 'VP' iv_kind = 'V' ) ) ) ).
    build( lo_det ).

    mo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                    io_context = new zcra_cl_context( ) ).

    " No transform bucket => no BEFORE/AFTER snapshot events.
    cl_abap_unit_assert=>assert_equals(
      act = mo_log->count( zcra_cl_log_memory=>gc_event-snapshot ) exp = 0 ).
  endmethod.

  method stop_short_circuits.
    data(lo_det) = new lcl_det( ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_pre
                 it_rules = value #(
                   ( new lcl_rule( iv_id = 'VP1' iv_kind = 'V' iv_stop = abap_true ) )
                   ( new lcl_rule( iv_id = 'VP2' iv_kind = 'V' ) ) ) ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>transformation
                 it_rules = value #( ( new lcl_rule( iv_id = 'TR' iv_kind = 'T' ) ) ) ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_post
                 it_rules = value #( ( new lcl_rule( iv_id = 'VO' iv_kind = 'V' ) ) ) ).
    build( lo_det ).

    data(lo_result) = mo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                                      io_context = new zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_true( lo_result->is_stop_requested( ) ).
    " Only VP1 ran (as applicable); VP2, TR, VO all skipped.
    cl_abap_unit_assert=>assert_equals(
      act = mo_log->count( zcra_cl_log_memory=>gc_event-rule ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_log->count( zcra_cl_log_memory=>gc_event-snapshot ) exp = 0 ).
  endmethod.

  method accumulates_messages.
    data(lo_det) = new lcl_det( ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_pre
                 it_rules = value #(
                   ( new lcl_rule( iv_id = 'VP1' iv_kind = 'V' iv_add_msg = abap_true ) )
                   ( new lcl_rule( iv_id = 'VP2' iv_kind = 'V' iv_add_msg = abap_true ) ) ) ).
    build( lo_det ).

    data(lo_result) = mo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                                      io_context = new zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lo_result->get_messages( ) ) exp = 2 ).
  endmethod.

  method inapplicable_skipped.
    data(lo_det) = new lcl_det( ).
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_pre
                 it_rules = value #(
                   ( new lcl_rule( iv_id = 'VP1' iv_kind = 'V'
                                   iv_applicable = abap_false iv_add_msg = abap_true ) ) ) ).
    build( lo_det ).

    data(lo_result) = mo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                                      io_context = new zcra_cl_context( ) ).

    " Rule not applicable => validate not called => no message, but it is logged.
    cl_abap_unit_assert=>assert_initial( lo_result->get_messages( ) ).
    data(lt) = mo_log->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 2 ]-applicable exp = abap_false ).
  endmethod.

  method kind_bucket_mismatch.
    data(lo_det) = new lcl_det( ).
    " A transformation-kind rule wrongly placed in the PRE (validation) bucket.
    lo_det->set( iv_type = zcra_if_c_rule_type=>validation_pre
                 it_rules = value #( ( new lcl_rule( iv_id = 'BAD' iv_kind = 'T' ) ) ) ).
    build( lo_det ).

    try.
        mo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                        io_context = new zcra_cl_context( ) ).
        cl_abap_unit_assert=>fail( 'expected ZCRA_CX_RULE_KIND' ).
      catch zcra_cx_rule_kind.
        " expected
    endtry.
  endmethod.

endclass.
