interface zcra_if_rule
  public .

  "! Rule metadata (id, purpose, kind).
  methods get_meta
    returning value(rs_meta) type zcra_s_rule_meta .

  "! Whether this rule applies to the given context. Default true.
  methods exec_condition
    importing
      !io_context          type ref to zcra_if_context
    returning value(rv_applicable) type abap_bool .

  "! Validation logic (read-only context). Appends messages to the result.
  methods validate
    importing
      !io_context type ref to zcra_if_context
      !io_result  type ref to zcra_cl_result .

  "! Transformation logic (mutable context). Appends messages to the result.
  methods transform
    importing
      !io_context type ref to zcra_if_context_mut
      !io_result  type ref to zcra_cl_result .

endinterface.
