"! Beispiel-TRANSFORMATIONSREGEL (Payload-Schablone für Entwickler).
"! Verändert den Kontext: setzt das Beispiel-Flag (ZCRA_S_GRAPH-SHELL_PLACEHOLDER)
"! auf 'X' und schreibt eine Info-Meldung. Dies ist das minimale "verändere die
"! Daten"-Beispiel, bis der echte Datencontainer umgesetzt ist. KIND =
"! Transformation (D-33); die Engine umschließt diese Phase mit einem
"! Vorher/Nachher-Snapshot.
CLASS zcra_cl_trn_example DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM zcra_cl_rule_base.

  PUBLIC SECTION.
    METHODS zcra_if_rule~get_meta  REDEFINITION.
    METHODS zcra_if_rule~transform REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcra_cl_trn_example IMPLEMENTATION.

  METHOD zcra_if_rule~get_meta.
    result-rule_id = 'TRN_EXAMPLE'.
    result-purpose = 'Beispieltransformation: setzt das Beispiel-Flag im neuen Graphen'.
    result-kind    = zcra_if_c_rule_kind=>transformation.
  ENDMETHOD.

  METHOD zcra_if_rule~transform.
    DATA(new_ref) = context->get_new_graph_ref( ).
    new_ref->shell_placeholder = 'X'.
    result->add_message(
      severity   = 'I'
      id         = 'ZCRA_ENGINE'
      number     = '011'
      message_v1 = |{ new_ref->shell_placeholder }| ).
  ENDMETHOD.

ENDCLASS.
