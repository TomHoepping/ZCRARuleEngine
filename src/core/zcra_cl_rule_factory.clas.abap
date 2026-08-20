class zcra_cl_rule_factory definition
  public
  create public .

  public section.

    "! Whether an instance is cached under the name.
    methods has
      importing
        !iv_name      type string
      returning
        value(rv_has) type abap_bool .

    "! Cached instance for the name (initial reference if none).
    methods get
      importing
        !iv_name       type string
      returning
        value(ro_rule) type ref to zcra_if_rule .

    "! Store an instance under the name (overwrites any existing).
    methods put
      importing
        !iv_name type string
        !io_rule type ref to zcra_if_rule .

    "! Return the cached instance, or store and return the supplied one.
    "! On a repeat call the cached instance is returned (cache hit) and the
    "! supplied io_rule is ignored. Callers pass a directly NEW'd instance so
    "! stateless rules are created once and reused.
    methods get_or_put
      importing
        !iv_name       type string
        !io_rule       type ref to zcra_if_rule
      returning
        value(ro_rule) type ref to zcra_if_rule .

  protected section.
  private section.

    types:
      begin of ty_cache,
        name type string,
        rule type ref to zcra_if_rule,
      end of ty_cache .

    data mt_cache type hashed table of ty_cache with unique key name .

endclass.



class zcra_cl_rule_factory implementation.

  method has.
    rv_has = xsdbool( line_exists( mt_cache[ name = iv_name ] ) ).
  endmethod.

  method get.
    read table mt_cache with key name = iv_name into data(ls_cache).
    if sy-subrc = 0.
      ro_rule = ls_cache-rule.
    endif.
  endmethod.

  method put.
    data ls_cache type ty_cache.
    ls_cache-name = iv_name.
    ls_cache-rule = io_rule.
    delete mt_cache where name = iv_name.
    insert ls_cache into table mt_cache.
  endmethod.

  method get_or_put.
    read table mt_cache with key name = iv_name into data(ls_cache).
    if sy-subrc = 0.
      ro_rule = ls_cache-rule.
      return.
    endif.
    ls_cache-name = iv_name.
    ls_cache-rule = io_rule.
    insert ls_cache into table mt_cache.
    ro_rule = io_rule.
  endmethod.

endclass.
