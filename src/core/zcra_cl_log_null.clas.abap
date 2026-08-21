class zcra_cl_log_null definition
  public
  final
  create public .

  public section.
    interfaces zcra_if_logger .
    "! Convenience singleton (the logger is stateless).
    class-methods get_instance
      returning value(ro_logger) type ref to zcra_if_logger .
  protected section.
  private section.
    class-data go_instance type ref to zcra_if_logger .
endclass.



class zcra_cl_log_null implementation.

  method get_instance.
    if go_instance is initial.
      go_instance = new zcra_cl_log_null( ).
    endif.
    ro_logger = go_instance.
  endmethod.

  method zcra_if_logger~start_run.
  endmethod.

  method zcra_if_logger~log_rule.
  endmethod.

  method zcra_if_logger~snapshot.
  endmethod.

  method zcra_if_logger~end_run.
  endmethod.

endclass.
