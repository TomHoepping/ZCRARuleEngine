"! Example DETERMINATION (payload shell / template for developers).
"! Maps the demo process to its ordered rule buckets and creates the rule
"! instances via direct NEW (D-39, no dynamic CREATE OBJECT). Register it in the
"! central ZCRA_CL_DETERMINATION under a process id, then run the engine.
"!   PRE  : VAL_EXAMPLE  (flag not yet set -> info message)
"!   TRN  : TRN_EXAMPLE  (sets the sample flag)
"!   POST : VAL_EXAMPLE  (flag now set -> silent) — shows the before/after effect
class zcra_cl_det_example definition
  public
  final
  create public .

  public section.
    interfaces zcra_if_determination .
    methods constructor .
  private section.
    data mo_val type ref to zcra_if_rule .
    data mo_trn type ref to zcra_if_rule .
endclass.



class zcra_cl_det_example implementation.

  method constructor.
    mo_val = new zcra_cl_val_example( ).
    mo_trn = new zcra_cl_trn_example( ).
  endmethod.

  method zcra_if_determination~get_rules.
    case iv_type.
      when zcra_if_c_rule_type=>validation_pre.
        rt_rules = value #( ( mo_val ) ).
      when zcra_if_c_rule_type=>transformation.
        rt_rules = value #( ( mo_trn ) ).
      when zcra_if_c_rule_type=>validation_post.
        rt_rules = value #( ( mo_val ) ).
    endcase.
  endmethod.

  method zcra_if_determination~has_rules.
    rv_has = xsdbool( lines( zcra_if_determination~get_rules( iv_type ) ) > 0 ).
  endmethod.

endclass.
