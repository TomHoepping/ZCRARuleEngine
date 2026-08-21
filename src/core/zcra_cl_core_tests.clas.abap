"! Consolidated CORE acceptance suite (Phase 3).
"! Wires the real engine + determination registry + rule factory + memory
"! logger + stub rules to prove the framework end-to-end: snapshot content
"! capture, factory instance reuse across runs, STOP-in-transform short-circuit,
"! the default no-op logger path and cross-phase message accumulation.
"! Complements the per-object unit tests on ZCRA_CL_ENGINE / _DETERMINATION /
"! _RULE_FACTORY. Refs: D-16, D-19, D-21, D-30, D-33, D-39, spec 6.8.
class zcra_cl_core_tests definition
  public
  final
  create public .

  public section.

    "! Marker method so the class carries production content and its unit-test
    "! include is discovered by the ABAP Unit runner on this system.
    class-methods suite_id
      returning value(rv_id) type string.

  protected section.
  private section.
endclass.



class zcra_cl_core_tests implementation.

  method suite_id.
    rv_id = 'ZCRA_CORE_ACCEPTANCE'.
  endmethod.

endclass.
