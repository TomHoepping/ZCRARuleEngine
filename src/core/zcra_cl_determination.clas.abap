class zcra_cl_determination definition
  public
  create public .

  public section.

    "! Register a per-process determination. The instance is created by the
    "! caller via direct NEW (no dynamic CREATE OBJECT). Re-registering a
    "! process overwrites the previous mapping.
    methods register
      importing
        !iv_process type zcra_d_process_id
        !io_det     type ref to zcra_if_determination .

    "! Whether the process provides rules for the given kind.
    methods has_rules
      importing
        !iv_process   type zcra_d_process_id
        !iv_kind      type zcra_s_rule_meta-kind
      returning
        value(rv_has) type abap_bool .

    "! Ordered rule instances for the process + kind. Empty if the process is
    "! not registered.
    methods get_rules
      importing
        !iv_process     type zcra_d_process_id
        !iv_kind        type zcra_s_rule_meta-kind
      returning
        value(rt_rules) type zcra_if_determination=>tt_rules .

  protected section.
  private section.

    types:
      begin of ty_registration,
        process type zcra_d_process_id,
        det     type ref to zcra_if_determination,
      end of ty_registration .

    data mt_registry type hashed table of ty_registration with unique key process .

    methods find
      importing
        !iv_process   type zcra_d_process_id
      returning
        value(ro_det) type ref to zcra_if_determination .

endclass.



class zcra_cl_determination implementation.

  method register.
    data ls_reg type ty_registration.
    ls_reg-process = iv_process.
    ls_reg-det     = io_det.
    delete mt_registry where process = iv_process.
    insert ls_reg into table mt_registry.
  endmethod.

  method find.
    read table mt_registry with key process = iv_process into data(ls_reg).
    if sy-subrc = 0.
      ro_det = ls_reg-det.
    endif.
  endmethod.

  method has_rules.
    data(lo_det) = find( iv_process ).
    if lo_det is bound.
      rv_has = lo_det->has_rules( iv_kind ).
    endif.
  endmethod.

  method get_rules.
    data(lo_det) = find( iv_process ).
    if lo_det is bound.
      rt_rules = lo_det->get_rules( iv_kind ).
    endif.
  endmethod.

endclass.
