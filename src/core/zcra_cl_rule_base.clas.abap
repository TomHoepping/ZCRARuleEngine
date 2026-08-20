class ZCRA_CL_RULE_BASE definition
  public
  abstract
  create public .

  public section.
    interfaces zcra_if_rule .
  protected section.
  private section.
endclass.



class ZCRA_CL_RULE_BASE implementation.

  method zcra_if_rule~get_meta.
    " Base returns empty meta; concrete rules redefine.
    return.
  endmethod.

  method zcra_if_rule~exec_condition.
    " Default: rule always applies.
    rv_applicable = abap_true.
  endmethod.

  method zcra_if_rule~validate.
    " No-op default. Validation rules redefine.
    return.
  endmethod.

  method zcra_if_rule~transform.
    " No-op default. Transformation rules redefine.
    return.
  endmethod.

endclass.
