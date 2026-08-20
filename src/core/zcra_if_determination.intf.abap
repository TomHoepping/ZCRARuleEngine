interface zcra_if_determination
  public .

  "! Ordered list of rule instances.
  types tt_rules type standard table of ref to zcra_if_rule with empty key .

  "! Whether this process provides rules for the given kind.
  methods has_rules
    importing
      !iv_kind      type zcra_s_rule_meta-kind
    returning
      value(rv_has) type abap_bool .

  "! Ordered rule instances for the given kind.
  methods get_rules
    importing
      !iv_kind        type zcra_s_rule_meta-kind
    returning
      value(rt_rules) type tt_rules .

endinterface.
