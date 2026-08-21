"! Ausführbare Beispiel-/Debug-Schablone für die ZCRA Rule Engine.
"! In ADT ausführen: Rechtsklick -> Run As -> ABAP Application (Console) (F9).
"! Verdrahtet das gesamte Framework Ende-zu-Ende und gibt Ergebnis + Engine-Trace
"! aus, sodass Entwickler an beliebiger Stelle einen Breakpoint setzen und einen
"! echten Lauf durchsteppen können:
"!   Determination-Registry -> In-Memory-Logger -> Kontext -> engine->run( ).
"! Zum Integrieren der Engine diese Vorlage in die eigene Session/Klasse kopieren.
CLASS zcra_cl_demo_run DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    "! Demo-Prozesskennung (beliebiger Wert; die Registry schlüsselt darauf).
    CONSTANTS demo_process TYPE zcra_d_process_id VALUE 'EXAMPLE'.
ENDCLASS.



CLASS zcra_cl_demo_run IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    " 1) Zentrale Determination-Registry + die Demo-Prozess-Determination.
    DATA(registry) = NEW zcra_cl_determination( ).
    registry->register( process       = demo_process
                        determination = NEW zcra_cl_det_example( ) ).

    " 2) In-Memory-Logger, um den Engine-Trace danach ausgeben zu können.
    "    Für Ausgabe in SLG1 stattdessen NEW zcra_cl_log_bal( ) verwenden.
    DATA(logger) = NEW zcra_cl_log_memory( ).

    " 3) Kontext — leerer Graph; das Beispiel-Flag startet ungesetzt.
    DATA(context) = NEW zcra_cl_context( ).

    " 4) Engine (Logger ist optional; Standard ist der No-op-Logger).
    DATA(engine) = NEW zcra_cl_engine( determination = registry
                                       logger        = logger ).

    " 5) Pipeline ausführen: VALIDATION_PRE -> TRANSFORMATION -> VALIDATION_POST.
    out->write( |=== ZCRA Rule Engine Demo: Prozess { demo_process } ===| ).
    DATA result TYPE REF TO zcra_cl_result.
    TRY.
        result = engine->run( process = demo_process
                              context = context ).
      CATCH zcra_cx_rule_kind INTO DATA(kind_error).
        out->write( |FEHLER - KIND/Bucket-Konflikt: { kind_error->get_text( ) }| ).
        RETURN.
    ENDTRY.

    " 6) Ergebnis-Meldungen.
    out->write( |--- Ergebnis-Meldungen ({ lines( result->get_messages( ) ) }) ---| ).
    LOOP AT result->get_messages( ) INTO DATA(message).
      out->write( |{ message-type }  { message-id }/{ message-number }  { message-message_v1 }| ).
    ENDLOOP.
    out->write( |STOP angefordert: { result->is_stop_requested( ) }   Fehler: { result->has_errors( ) }| ).

    " 7) Vom In-Memory-Logger erfasster Engine-Trace.
    out->write( `--- Engine-Trace ---` ).
    LOOP AT logger->get_entries( ) INTO DATA(entry).
      CASE entry-event.
        WHEN zcra_cl_log_memory=>gc_event-rule.
          out->write( |RULE      { entry-rule_id } (KIND { entry-kind }) applicable={ entry-applicable } msgs={ entry-msg_count }| ).
        WHEN zcra_cl_log_memory=>gc_event-snapshot.
          out->write( |SNAPSHOT  { entry-label }| ).
        WHEN OTHERS.
          out->write( |{ entry-event }| ).
      ENDCASE.
    ENDLOOP.

    " 8) Endzustand des Kontexts — die Transformation hat das Beispiel-Flag gekippt.
    out->write( `--- Endzustand Kontext ---` ).
    out->write( |Beispiel-Flag = '{ context->zcra_if_context~get_new_graph( )-shell_placeholder }'| ).

  ENDMETHOD.

ENDCLASS.
