interface zcra_if_c_rule_kind
  public .

  "! Rule kind: Validation
  constants validation     type zcra_s_rule_meta-kind value 'V'.
  "! Rule kind: Transformation
  constants transformation type zcra_s_rule_meta-kind value 'T'.

endinterface.
