"! Configurable stub rule. Counts constructor calls (static) and per-instance
"! executions so factory reuse can be observed end-to-end. A transform rule can
"! optionally mutate the new graph so snapshot content capture is observable.
class lcl_rule definition final.
  public section.
    interfaces zcra_if_rule.
    class-data gv_created type i.
    data mv_runs type i read-only.
    methods constructor
      importing
        !iv_id         type zcra_d_rule_id
        !iv_kind       type zcra_s_rule_meta-kind
        !iv_applicable type abap_bool default abap_true
        !iv_add_msg    type abap_bool default abap_false
        !iv_stop       type abap_bool default abap_false
        !iv_mutate     type abap_bool default abap_false.
  private section.
    data ms_meta       type zcra_s_rule_meta.
    data mv_applicable type abap_bool.
    data mv_add_msg    type abap_bool.
    data mv_stop       type abap_bool.
    data mv_mutate     type abap_bool.
    methods act importing io_result type ref to zcra_cl_result.
endclass.

class lcl_rule implementation.
  method constructor.
    gv_created      = gv_created + 1.
    ms_meta-rule_id = iv_id.
    ms_meta-kind    = iv_kind.
    mv_applicable   = iv_applicable.
    mv_add_msg      = iv_add_msg.
    mv_stop         = iv_stop.
    mv_mutate       = iv_mutate.
  endmethod.
  method zcra_if_rule~get_meta.
    rs_meta = ms_meta.
  endmethod.
  method zcra_if_rule~exec_condition.
    rv_applicable = mv_applicable.
  endmethod.
  method zcra_if_rule~validate.
    mv_runs = mv_runs + 1.
    act( io_result ).
  endmethod.
  method zcra_if_rule~transform.
    mv_runs = mv_runs + 1.
    if mv_mutate = abap_true.
      data(lr_new) = io_context->get_new_graph_ref( ).
      lr_new->shell_placeholder = 'X'.
    endif.
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


"! Determination backed by the real ZCRA_CL_RULE_FACTORY. On every get_rules
"! it builds a fresh rule instance and passes it through the factory; a repeat
"! run therefore hits the cache and reuses the first instance (D-21/D-39).
class lcl_det_factory definition final.
  public section.
    interfaces zcra_if_determination.
    methods constructor
      importing !io_factory type ref to zcra_cl_rule_factory.
    methods add
      importing
        !iv_type       type zcra_if_c_rule_type=>ty_type
        !iv_name       type string
        !iv_kind       type zcra_s_rule_meta-kind
        !iv_applicable type abap_bool default abap_true
        !iv_add_msg    type abap_bool default abap_false
        !iv_stop       type abap_bool default abap_false
        !iv_mutate     type abap_bool default abap_false.
  private section.
    types: begin of ty_cfg,
             type       type zcra_if_c_rule_type=>ty_type,
             name       type string,
             id         type zcra_d_rule_id,
             kind       type zcra_s_rule_meta-kind,
             applicable type abap_bool,
             add_msg    type abap_bool,
             stop       type abap_bool,
             mutate     type abap_bool,
           end of ty_cfg.
    data mo_factory type ref to zcra_cl_rule_factory.
    data mt_cfg     type standard table of ty_cfg.
endclass.

class lcl_det_factory implementation.
  method constructor.
    mo_factory = io_factory.
  endmethod.
  method add.
    append value #( type = iv_type name = iv_name id = conv #( iv_name )
                    kind = iv_kind applicable = iv_applicable
                    add_msg = iv_add_msg stop = iv_stop mutate = iv_mutate ) to mt_cfg.
  endmethod.
  method zcra_if_determination~has_rules.
    rv_has = xsdbool( line_exists( mt_cfg[ type = iv_type ] ) ).
  endmethod.
  method zcra_if_determination~get_rules.
    loop at mt_cfg into data(ls_cfg) where type = iv_type.
      data(lo_fresh) = cast zcra_if_rule( new lcl_rule(
        iv_id = ls_cfg-id iv_kind = ls_cfg-kind iv_applicable = ls_cfg-applicable
        iv_add_msg = ls_cfg-add_msg iv_stop = ls_cfg-stop iv_mutate = ls_cfg-mutate ) ).
      append mo_factory->get_or_put( iv_name = ls_cfg-name io_rule = lo_fresh ) to rt_rules.
    endloop.
  endmethod.
endclass.


class ltc_core definition final
  for testing duration short risk level harmless.

  private section.
    data mo_factory type ref to zcra_cl_rule_factory.
    data mo_det     type ref to zcra_cl_determination.
    data mo_log     type ref to zcra_cl_log_memory.

    methods setup.
    methods build importing io_det type ref to zcra_if_determination.

    methods snapshot_captures_mutation for testing raising cx_static_check.
    methods factory_reuses_instances   for testing raising cx_static_check.
    methods stop_in_transform_skips_post for testing raising cx_static_check.
    methods null_logger_default_runs   for testing raising cx_static_check.
    methods accumulates_across_phases  for testing raising cx_static_check.
endclass.

class ltc_core implementation.

  method setup.
    lcl_rule=>gv_created = 0.
    mo_factory = new #( ).
    mo_log     = new #( ).
  endmethod.

  method build.
    mo_det = new zcra_cl_determination( ).
    mo_det->register( iv_process = zcra_if_c_process=>anerkennung io_det = io_det ).
  endmethod.

  method snapshot_captures_mutation.
    data(lo_det) = new lcl_det_factory( mo_factory ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_pre
                 iv_name = 'VP' iv_kind = zcra_if_c_rule_kind=>validation ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>transformation
                 iv_name = 'TR' iv_kind = zcra_if_c_rule_kind=>transformation
                 iv_mutate = abap_true ).
    build( lo_det ).

    data(lo_engine) = new zcra_cl_engine(
      io_determination = mo_det io_logger = mo_log ).
    lo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                    io_context = new zcra_cl_context( ) ).

    data(lt) = mo_log->get_entries( ).
    data(lv_before) = lt[ event = zcra_cl_log_memory=>gc_event-snapshot label = 'BEFORE' ]-json.
    data(lv_after)  = lt[ event = zcra_cl_log_memory=>gc_event-snapshot label = 'AFTER' ]-json.

    " BEFORE snapshot is frozen prior to the transform => no mutation marker.
    cl_abap_unit_assert=>assert_false(
      act = xsdbool( lv_before cs 'X' ) msg = 'BEFORE snapshot must not contain the mutation' ).
    " AFTER snapshot reflects the mutated new graph.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_after cs 'X' ) msg = 'AFTER snapshot must capture the mutation' ).
  endmethod.

  method factory_reuses_instances.
    data(lo_det) = new lcl_det_factory( mo_factory ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_pre
                 iv_name = 'R' iv_kind = zcra_if_c_rule_kind=>validation ).
    build( lo_det ).

    data(lo_engine) = new zcra_cl_engine( io_determination = mo_det io_logger = mo_log ).
    lo_engine->run( iv_process = zcra_if_c_process=>anerkennung io_context = new zcra_cl_context( ) ).
    lo_engine->run( iv_process = zcra_if_c_process=>anerkennung io_context = new zcra_cl_context( ) ).

    " Determination built a fresh instance for each of the two runs...
    cl_abap_unit_assert=>assert_equals(
      act = lcl_rule=>gv_created exp = 2 msg = 'determination should create per run' ).
    " ...but the engine executed the ONE cached instance both times (D-21/D-39).
    cl_abap_unit_assert=>assert_true( mo_factory->has( 'R' ) ).
    data(lo_cached) = cast lcl_rule( mo_factory->get( 'R' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_cached->mv_runs exp = 2 msg = 'cached instance must be reused across runs' ).
  endmethod.

  method stop_in_transform_skips_post.
    data(lo_det) = new lcl_det_factory( mo_factory ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_pre
                 iv_name = 'VP' iv_kind = zcra_if_c_rule_kind=>validation ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>transformation
                 iv_name = 'TR1' iv_kind = zcra_if_c_rule_kind=>transformation iv_stop = abap_true ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>transformation
                 iv_name = 'TR2' iv_kind = zcra_if_c_rule_kind=>transformation ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_post
                 iv_name = 'VO' iv_kind = zcra_if_c_rule_kind=>validation ).
    build( lo_det ).

    data(lo_engine) = new zcra_cl_engine( io_determination = mo_det io_logger = mo_log ).
    data(lo_result) = lo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                                      io_context = new zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_true( lo_result->is_stop_requested( ) ).
    data(lt) = mo_log->get_entries( ).
    " TR2 (rest of transform phase) and VO (POST phase) must not run.
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( lt[ rule_id = 'TR2' ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( lt[ rule_id = 'VO' ] ) ) ).
    " Both transform snapshots are still recorded around the (halted) phase.
    cl_abap_unit_assert=>assert_equals(
      act = mo_log->count( zcra_cl_log_memory=>gc_event-snapshot ) exp = 2 ).
  endmethod.

  method null_logger_default_runs.
    data(lo_det) = new lcl_det_factory( mo_factory ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_pre
                 iv_name = 'VP' iv_kind = zcra_if_c_rule_kind=>validation iv_add_msg = abap_true ).
    build( lo_det ).

    " No logger supplied => engine must default to the no-op logger and still run.
    data(lo_engine) = new zcra_cl_engine( io_determination = mo_det ).
    data(lo_result) = lo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                                      io_context = new zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_bound( lo_result ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_result->get_messages( ) ) exp = 1 ).
    cl_abap_unit_assert=>assert_false( lo_result->is_stop_requested( ) ).
  endmethod.

  method accumulates_across_phases.
    data(lo_det) = new lcl_det_factory( mo_factory ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_pre
                 iv_name = 'VP' iv_kind = zcra_if_c_rule_kind=>validation iv_add_msg = abap_true ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>transformation
                 iv_name = 'TR' iv_kind = zcra_if_c_rule_kind=>transformation iv_add_msg = abap_true ).
    lo_det->add( iv_type = zcra_if_c_rule_type=>validation_post
                 iv_name = 'VO' iv_kind = zcra_if_c_rule_kind=>validation iv_add_msg = abap_true ).
    build( lo_det ).

    data(lo_engine) = new zcra_cl_engine( io_determination = mo_det io_logger = mo_log ).
    data(lo_result) = lo_engine->run( iv_process = zcra_if_c_process=>anerkennung
                                      io_context = new zcra_cl_context( ) ).

    " One message from each of the three phases.
    cl_abap_unit_assert=>assert_equals( act = lines( lo_result->get_messages( ) ) exp = 3 ).
    " Full event envelope present: START ... END.
    data(lt) = mo_log->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = lt[ 1 ]-event exp = zcra_cl_log_memory=>gc_event-start ).
    cl_abap_unit_assert=>assert_equals(
      act = lt[ lines( lt ) ]-event exp = zcra_cl_log_memory=>gc_event-end ).
  endmethod.

endclass.
