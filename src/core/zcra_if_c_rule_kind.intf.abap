INTERFACE zcra_if_c_rule_kind
  PUBLIC.

  "! Regelart: Validierung
  CONSTANTS validation     TYPE zcra_s_rule_meta-kind VALUE 'V'.
  "! Regelart: Transformation
  CONSTANTS transformation TYPE zcra_s_rule_meta-kind VALUE 'T'.

ENDINTERFACE.
