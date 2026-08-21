"! Beispiel-VALIDIERUNGSREGEL (Payload-Schablone für Entwickler).
"! Liest den Kontext (schreibgeschützt) und meldet eine Info-Meldung, wenn das
"! Beispiel-Flag (ZCRA_S_GRAPH-SHELL_PLACEHOLDER) nicht gesetzt ist. Wird PRE
"! (Flag fehlt -> Meldung) und POST (Flag durch die Transformation gesetzt ->
"! still) verwendet, um den Vorher/Nachher-Effekt einer Transformation zu zeigen.
"! KIND = Validierung (D-33).
CLASS zcra_cl_val_example DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM zcra_cl_rule_base.

  PUBLIC SECTION.
    METHODS zcra_if_rule~get_meta REDEFINITION.
    METHODS zcra_if_rule~validate REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcra_cl_val_example IMPLEMENTATION.

  METHOD zcra_if_rule~get_meta.
    result-rule_id = 'VAL_EXAMPLE'.
    result-purpose = 'Beispielvalidierung: meldet, wenn das Beispiel-Flag nicht gesetzt ist'.
    result-kind    = zcra_if_c_rule_kind=>validation.
  ENDMETHOD.

  METHOD zcra_if_rule~validate.
    DATA(new_graph) = context->get_new_graph( ).
    IF new_graph-shell_placeholder IS INITIAL.
      result->add_message(
        severity = 'I'
        id       = 'ZCRA_ENGINE'
        number   = '010' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
