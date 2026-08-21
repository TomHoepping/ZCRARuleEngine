interface zcra_if_determination
  public .

  "! Ordered list of rule instances.
  types tt_rules type standard table of ref to zcra_if_rule with empty key .

  "! Whether this process provides rules for the given TYPE bucket
  "! (VALIDATION_PRE / TRANSFORMATION / VALIDATION_POST).
  methods has_rules
    importing
      !iv_type      type zcra_if_c_rule_type=>ty_type
    returning
      value(rv_has) type abap_bool .

  "! Ordered rule instances for the given TYPE bucket (in SEQNO order).
  methods get_rules
    importing
      !iv_type        type zcra_if_c_rule_type=>ty_type
    returning
      value(rt_rules) type tt_rules .

endinterface.
