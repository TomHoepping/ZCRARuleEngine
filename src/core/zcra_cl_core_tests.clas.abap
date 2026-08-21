"! Konsolidierte CORE-Akzeptanz-Suite (Phase 3).
"! Verdrahtet die echte Engine + Determination-Registry + Regel-Factory +
"! Memory-Logger + Stub-Regeln, um das Framework durchgängig zu beweisen:
"! Snapshot-Inhaltserfassung, Factory-Instanzwiederverwendung über Läufe hinweg,
"! STOP-in-Transformation-Kurzschluss, der Standard-No-op-Logger-Pfad und
"! phasenübergreifende Meldungssammlung. Ergänzt die objektweisen Unit-Tests auf
"! ZCRA_CL_ENGINE / _DETERMINATION / _RULE_FACTORY. Refs: D-16, D-19, D-21, D-30,
"! D-33, D-39, Spezifikation 6.8.
CLASS zcra_cl_core_tests DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Marker-Methode, damit die Klasse Produktivinhalt trägt und ihr Unit-Test-
    "! Include vom ABAP-Unit-Runner auf diesem System gefunden wird.
    CLASS-METHODS suite_id
      RETURNING VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcra_cl_core_tests IMPLEMENTATION.

  METHOD suite_id.
    result = 'ZCRA_CORE_ACCEPTANCE'.
  ENDMETHOD.

ENDCLASS.
