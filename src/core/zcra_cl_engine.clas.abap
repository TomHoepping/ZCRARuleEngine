class zcra_cl_engine definition
  public
  create public .

  public section.

    "! @parameter io_determination | central process->determination dispatcher.
    "! @parameter io_logger | technical logger; defaults to the no-op logger.
    methods constructor
      importing
        !io_determination type ref to zcra_cl_determination
        !io_logger        type ref to zcra_if_logger optional .

    "! Pure run of the rule engine for one process over one context.
    "! Flow (D-02, D-19, D-30): VALIDATION_PRE -> TRANSFORMATION -> VALIDATION_POST.
    "! Each phase is skipped when its bucket is empty; the transform phase is
    "! wrapped in a before/after context snapshot (D-16). A STOP request halts the
    "! remaining rules of the current phase and skips all later phases; every
    "! message collected so far is still returned.
    "! @raising zcra_cx_rule_kind | a rule's KIND does not match its bucket (D-33).
    methods run
      importing
        !iv_process       type zcra_d_process_id
        !io_context       type ref to zcra_if_context_mut
      returning
        value(ro_result)  type ref to zcra_cl_result
      raising
        zcra_cx_rule_kind .

  protected section.
  private section.

    data mo_det     type ref to zcra_cl_determination .
    data mo_logger  type ref to zcra_if_logger .
    data mo_context type ref to zcra_if_context_mut .
    data mo_result  type ref to zcra_cl_result .
    data mv_process type zcra_d_process_id .

    methods run_phase
      importing
        !iv_type type zcra_if_c_rule_type=>ty_type
      raising
        zcra_cx_rule_kind .

    "! Assert rule KIND matches the expected KIND of the TYPE bucket (D-33).
    methods assert_kind_vs_bucket
      importing
        !iv_type type zcra_if_c_rule_type=>ty_type
        !is_meta type zcra_s_rule_meta
      raising
        zcra_cx_rule_kind .

endclass.



class zcra_cl_engine implementation.

  method constructor.
    mo_det = io_determination.
    if io_logger is bound.
      mo_logger = io_logger.
    else.
      mo_logger = zcra_cl_log_null=>get_instance( ).
    endif.
  endmethod.

  method run.
    mo_context = io_context.
    mv_process = iv_process.
    mo_result  = new zcra_cl_result( ).
    ro_result  = mo_result.

    mo_logger->start_run( iv_process = mv_process ).

    run_phase( zcra_if_c_rule_type=>validation_pre ).

    if mo_result->is_stop_requested( ) = abap_false
       and mo_det->has_rules( iv_process = mv_process
                              iv_type    = zcra_if_c_rule_type=>transformation ) = abap_true.
      mo_logger->snapshot( iv_label = 'BEFORE' io_context = mo_context ).
      run_phase( zcra_if_c_rule_type=>transformation ).
      mo_logger->snapshot( iv_label = 'AFTER' io_context = mo_context ).
    endif.

    if mo_result->is_stop_requested( ) = abap_false.
      run_phase( zcra_if_c_rule_type=>validation_post ).
    endif.

    mo_logger->end_run( iv_process = mv_process ).
  endmethod.

  method run_phase.
    loop at mo_det->get_rules( iv_process = mv_process iv_type = iv_type ) into data(lo_rule).
      data(ls_meta) = lo_rule->get_meta( ).
      assert_kind_vs_bucket( iv_type = iv_type is_meta = ls_meta ).

      if lo_rule->exec_condition( io_context = mo_context ) = abap_false.
        mo_logger->log_rule( is_meta = ls_meta iv_applicable = abap_false io_result = mo_result ).
        continue.
      endif.

      case iv_type.
        when zcra_if_c_rule_type=>transformation.
          lo_rule->transform( io_context = mo_context io_result = mo_result ).
        when others.
          lo_rule->validate( io_context = mo_context io_result = mo_result ).
      endcase.

      mo_logger->log_rule( is_meta = ls_meta iv_applicable = abap_true io_result = mo_result ).

      if mo_result->is_stop_requested( ) = abap_true.
        exit.
      endif.
    endloop.
  endmethod.

  method assert_kind_vs_bucket.
    data lv_expected type zcra_s_rule_meta-kind.
    case iv_type.
      when zcra_if_c_rule_type=>transformation.
        lv_expected = zcra_if_c_rule_kind=>transformation.
      when others.
        lv_expected = zcra_if_c_rule_kind=>validation.
    endcase.
    if is_meta-kind <> lv_expected.
      raise exception type zcra_cx_rule_kind.
    endif.
  endmethod.

endclass.
