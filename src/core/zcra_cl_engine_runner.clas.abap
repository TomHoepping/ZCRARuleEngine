"! Fassade / Aufruf-Schablone für die ZCRA Rule Engine.
"! Kapselt die vollständige Verdrahtung (Logger-Auswahl, Kontextaufbau,
"! Engine-Konstruktion, Trace-Extraktion), sodass Integratoren nur noch
"! Eingabegraph + Prozess übergeben. Die prozessspezifische Determination
"! (Prozess -> ZCRA_CL_DET_... je Prozess) wird per Konstruktor injiziert, damit
"! CORE frei von PAYLOAD-Abhängigkeiten bleibt (D-35, D-38).
"!
"! Beispiel:
"!   DATA(runner) = NEW zcra_cl_engine_runner(
"!                        determination = zcra_cl_det_registry=>build( )
"!                        log_mode      = zcra_if_c_log_mode=>console ).
"!   DATA(result) = runner->run( input_graph = graph process = 'WEGZUG' ).
"!   LOOP AT runner->get_trace_lines( ) INTO DATA(line). ... ENDLOOP.
CLASS zcra_cl_engine_runner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! @parameter determination | Zentraler Prozess->Determination-Dispatcher.
    "! @parameter log_mode       | Protokollierungsmodus (Standard: CONSOLE = In-Memory-Trace).
    METHODS constructor
      IMPORTING
        !determination TYPE REF TO zcra_cl_determination
        !log_mode      TYPE zcra_if_c_log_mode=>ty_mode DEFAULT zcra_if_c_log_mode=>console.

    "! Führt die Engine für einen Prozess über einen Eingabegraphen aus. Der
    "! Eingabegraph bildet sowohl den alten (Basis) als auch den neuen Graphen;
    "! Transformationsregeln verändern den neuen Graphen.
    "! @parameter input_graph | Eingabegraph (Ausgangszustand).
    "! @parameter process     | Prozesskennung.
    "! @parameter result      | Gesammelte Meldungen und STOP-Status.
    "! @raising zcra_cx_rule_kind | KIND einer Regel passt nicht zum Bucket (D-33).
    METHODS run
      IMPORTING
        !input_graph  TYPE zcra_s_graph
        !process      TYPE zcra_d_process_id
      RETURNING
        VALUE(result) TYPE REF TO zcra_cl_result
      RAISING
        zcra_cx_rule_kind.

    "! Aufbereiteter Engine-Trace. Nur im Modus CONSOLE gefüllt (In-Memory-Logger);
    "! im Modus SLG1/NONE leer, da der Trace dort nicht im Speicher vorliegt.
    METHODS get_trace_lines
      RETURNING VALUE(result) TYPE string_table.

    "! Neuer Graph nach dem Lauf (enthält die Transformationsergebnisse).
    METHODS get_result_graph
      RETURNING VALUE(result) TYPE zcra_s_graph.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA determination TYPE REF TO zcra_cl_determination.
    DATA logger        TYPE REF TO zcra_if_logger.
    DATA context       TYPE REF TO zcra_cl_context.

    "! Erzeugt den passenden Logger zum gewählten Modus.
    METHODS build_logger
      IMPORTING
        !log_mode     TYPE zcra_if_c_log_mode=>ty_mode
      RETURNING
        VALUE(result) TYPE REF TO zcra_if_logger.
ENDCLASS.



CLASS zcra_cl_engine_runner IMPLEMENTATION.

  METHOD constructor.
    me->determination = determination.
    me->logger        = build_logger( log_mode ).
  ENDMETHOD.

  METHOD build_logger.
    CASE log_mode.
      WHEN zcra_if_c_log_mode=>none.
        result = NEW zcra_cl_log_null( ).
      WHEN zcra_if_c_log_mode=>slg1.
        result = NEW zcra_cl_log_bal( ).
      WHEN OTHERS.
        result = NEW zcra_cl_log_memory( ).
    ENDCASE.
  ENDMETHOD.

  METHOD run.
    me->context = NEW zcra_cl_context( old_graph = input_graph
                                       new_graph = input_graph ).
    DATA(engine) = NEW zcra_cl_engine( determination = me->determination
                                       logger        = me->logger ).
    result = engine->run( process = process
                          context = me->context ).
  ENDMETHOD.

  METHOD get_trace_lines.
    IF me->logger IS INSTANCE OF zcra_cl_log_memory.
      DATA(memory_logger) = CAST zcra_cl_log_memory( me->logger ).
      LOOP AT memory_logger->get_entries( ) INTO DATA(entry).
        CASE entry-event.
          WHEN zcra_cl_log_memory=>gc_event-rule.
            APPEND |RULE      { entry-rule_id } (KIND { entry-kind }) applicable={ entry-applicable } msgs={ entry-msg_count }| TO result.
          WHEN zcra_cl_log_memory=>gc_event-snapshot.
            APPEND |SNAPSHOT  { entry-label }| TO result.
          WHEN OTHERS.
            APPEND |{ entry-event }| TO result.
        ENDCASE.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_result_graph.
    IF me->context IS BOUND.
      result = me->context->zcra_if_context~get_new_graph( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
