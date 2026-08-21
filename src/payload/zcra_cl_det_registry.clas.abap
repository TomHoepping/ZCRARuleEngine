"! Zentrale Determination-Registrierung (Payload-Bootstrap).
"! Baut die zentrale ZCRA_CL_DETERMINATION auf und trägt jede Prozess->Determination-
"! Zuordnung explizit zur Übersetzungszeit ein (D-38). CORE bleibt frei von
"! PAYLOAD-Abhängigkeiten: die Fassade ZCRA_CL_ENGINE_RUNNER erhält die fertige
"! Registrierung per Konstruktor injiziert.
"!
"! Beispiel:
"!   DATA(runner) = NEW zcra_cl_engine_runner(
"!                        determination = zcra_cl_det_registry=>build( )
"!                        log_mode      = zcra_if_c_log_mode=>console ).
"!   DATA(result) = runner->run( input_graph = graph process = 'EXAMPLE' ).
"!
"! Neue Prozesse werden hier durch eine weitere REGISTER-Zeile ergänzt.
CLASS zcra_cl_det_registry DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Prozesskennung der Beispiel-Determination.
    CONSTANTS example_process TYPE zcra_d_process_id VALUE 'EXAMPLE'.

    "! Erzeugt die vollständig befüllte zentrale Determination.
    "! @parameter result | Registrierung mit allen bekannten Prozessen.
    CLASS-METHODS build
      RETURNING VALUE(result) TYPE REF TO zcra_cl_determination.
ENDCLASS.



CLASS zcra_cl_det_registry IMPLEMENTATION.

  METHOD build.
    result = NEW zcra_cl_determination( ).
    result->register( process       = example_process
                      determination = NEW zcra_cl_det_example( ) ).
  ENDMETHOD.

ENDCLASS.
