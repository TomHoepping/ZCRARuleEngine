CLASS zcra_cl_rule_base DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zcra_if_rule.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcra_cl_rule_base IMPLEMENTATION.

  METHOD zcra_if_rule~get_meta.
    " Basis liefert leere Metadaten; konkrete Regeln redefinieren dies.
    RETURN.
  ENDMETHOD.

  METHOD zcra_if_rule~exec_condition.
    " Standard: Regel ist immer anwendbar.
    result = abap_true.
  ENDMETHOD.

  METHOD zcra_if_rule~validate.
    " Standard: keine Aktion. Validierungsregeln redefinieren dies.
    RETURN.
  ENDMETHOD.

  METHOD zcra_if_rule~transform.
    " Standard: keine Aktion. Transformationsregeln redefinieren dies.
    RETURN.
  ENDMETHOD.

ENDCLASS.
