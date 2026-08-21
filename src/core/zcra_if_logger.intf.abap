interface zcra_if_logger
  public .

  "! Log the start of an engine run for the given process.
  methods start_run
    importing
      !iv_process type zcra_d_process_id .
  "! Log the outcome of a single rule: its metadata, whether it applied,
  "! any accumulated result messages, and whether it requested a stop.
  methods log_rule
    importing
      !is_meta       type zcra_s_rule_meta
      !iv_applicable type abap_bool
      !io_result     type ref to zcra_cl_result .
  "! Attach a JSON snapshot of the context graphs under a label
  "! (e.g. BEFORE / AFTER a transformation phase).
  methods snapshot
    importing
      !iv_label   type string
      !io_context type ref to zcra_if_context .
  "! Log the end of an engine run and persist the log (BAL impl).
  methods end_run
    importing
      !iv_process type zcra_d_process_id .

endinterface.
