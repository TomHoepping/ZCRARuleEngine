"! Ausführbare Beispiel-/Debug-Schablone für die ZCRA Rule Engine.
"! In ADT ausführen: Rechtsklick -> Run As -> ABAP Application (Console) (F9).
"! Delegiert die gesamte Verdrahtung an die Fassade ZCRA_CL_ENGINE_RUNNER und
"! gibt Ergebnis + Engine-Trace aus, sodass Entwickler an beliebiger Stelle einen
"! Breakpoint setzen und einen echten Lauf durchsteppen können:
"!   Registry -> ZCRA_CL_ENGINE_RUNNER->run( ) -> Meldungen/Trace/Endzustand.
"! Zum Integrieren der Engine diese Vorlage in die eigene Session/Klasse kopieren.
CLASS zcra_cl_demo_run DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    "! Demo-Prozesskennung (die Registry schlüsselt darauf).
    CONSTANTS demo_process TYPE zcra_d_process_id VALUE 'EXAMPLE'.
ENDCLASS.



CLASS zcra_cl_demo_run IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    " 1) Fassade mit zentraler Registrierung und Konsolen-Trace (In-Memory).
    "    Für persistente Protokollierung in SLG1 (Objekt ZCRA, Unterobjekt RUN)
    "    stattdessen ZCRA_IF_C_LOG_MODE=>SLG1 übergeben; der Konsolen-Trace
    "    entfällt dann (GET_TRACE_LINES liefert leer).
    DATA(runner) = NEW zcra_cl_engine_runner(
                         determination = zcra_cl_det_registry=>build( )
                         log_mode      = zcra_if_c_log_mode=>console ).

    " 2) Eingabegraph — leer; das Beispiel-Flag startet ungesetzt.
    DATA(input_graph) = VALUE zcra_s_graph( ).

    " 3) Pipeline ausführen: VALIDATION_PRE -> TRANSFORMATION -> VALIDATION_POST.
    out->write( |=== ZCRA Rule Engine Demo: Prozess { demo_process } ===| ).
    DATA result TYPE REF TO zcra_cl_result.
    TRY.
        result = runner->run( input_graph = input_graph
                              process      = demo_process ).
      CATCH zcra_cx_rule_kind INTO DATA(kind_error).
        out->write( |FEHLER - KIND/Bucket-Konflikt: { kind_error->get_text( ) }| ).
        RETURN.
    ENDTRY.

    " 4) Ergebnis-Meldungen.
    out->write( |--- Ergebnis-Meldungen ({ lines( result->get_messages( ) ) }) ---| ).
    LOOP AT result->get_messages( ) INTO DATA(message).
      out->write( |{ message-type }  { message-id }/{ message-number }  { message-message_v1 }| ).
    ENDLOOP.
    out->write( |STOP angefordert: { result->is_stop_requested( ) }   Fehler: { result->has_errors( ) }| ).

    " 5) Engine-Trace — nur im Modus CONSOLE gefüllt. Der Modus SLG1 schreibt
    "    stattdessen nach SLG1 (Transaktion SLG1, Objekt ZCRA/RUN).
    DATA(trace_lines) = runner->get_trace_lines( ).
    IF trace_lines IS INITIAL.
      out->write( `--- Engine-Trace: nur im Modus CONSOLE verfügbar (SLG1 -> Objekt ZCRA/RUN) ---` ).
    ELSE.
      out->write( `--- Engine-Trace ---` ).
      LOOP AT trace_lines INTO DATA(trace_line).
        out->write( trace_line ).
      ENDLOOP.
    ENDIF.

    " 6) Endzustand des Graphen — die Transformation hat das Beispiel-Flag gekippt.
    out->write( `--- Endzustand Graph ---` ).
    out->write( |Beispiel-Flag = '{ runner->get_result_graph( )-shell_placeholder }'| ).

  ENDMETHOD.

ENDCLASS.
