"! Beispiel-DETERMINATION (Payload-Schablone für Entwickler).
"! Ordnet dem Demo-Prozess seine geordneten Regel-Buckets zu und erzeugt die
"! Regelinstanzen per direktem NEW (D-39, kein dynamisches CREATE OBJECT).
"! In der zentralen ZCRA_CL_DETERMINATION unter einer Prozesskennung registrieren
"! und anschließend die Engine ausführen.
"!   PRE  : VAL_EXAMPLE  (Flag noch nicht gesetzt -> Info-Meldung)
"!   TRN  : TRN_EXAMPLE  (setzt das Beispiel-Flag)
"!   POST : VAL_EXAMPLE  (Flag jetzt gesetzt -> still) — zeigt den Vorher/Nachher-Effekt
CLASS zcra_cl_det_example DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zcra_if_determination.
    METHODS constructor.
  PRIVATE SECTION.
    "! Zwischengespeicherte Validierungsregel-Instanz (zustandslos).
    DATA validation_rule     TYPE REF TO zcra_if_rule.
    "! Zwischengespeicherte Transformationsregel-Instanz (zustandslos).
    DATA transformation_rule TYPE REF TO zcra_if_rule.
ENDCLASS.



CLASS zcra_cl_det_example IMPLEMENTATION.

  METHOD constructor.
    me->validation_rule     = NEW zcra_cl_val_example( ).
    me->transformation_rule = NEW zcra_cl_trn_example( ).
  ENDMETHOD.

  METHOD zcra_if_determination~get_rules.
    CASE rule_type.
      WHEN zcra_if_c_rule_type=>validation_pre.
        result = VALUE #( ( me->validation_rule ) ).
      WHEN zcra_if_c_rule_type=>transformation.
        result = VALUE #( ( me->transformation_rule ) ).
      WHEN zcra_if_c_rule_type=>validation_post.
        result = VALUE #( ( me->validation_rule ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zcra_if_determination~has_rules.
    result = xsdbool( lines( zcra_if_determination~get_rules( rule_type ) ) > 0 ).
  ENDMETHOD.

ENDCLASS.
