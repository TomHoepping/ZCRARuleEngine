*&---------------------------------------------------------------------*
*& Report ZCRA_TEST_ENGINE
*&---------------------------------------------------------------------*
*& Klassisches Test-/Debug-Programm für die ZCRA Rule Engine (SE38/SA38).
*& Ergänzt die ADT-Konsolenklasse ZCRA_CL_DEMO_RUN für Entwickler, die mit
*& dem klassischen Debugger arbeiten. Baut die Determination-Registry auf,
*& füllt einen Demo-Eingabegraphen, ruft die Fassade ZCRA_CL_ENGINE_RUNNER
*& auf und gibt Meldungen, Engine-Trace und Endzustand als Liste aus.
*&---------------------------------------------------------------------*
REPORT zcra_test_engine.

SELECTION-SCREEN BEGIN OF BLOCK sel WITH FRAME TITLE TEXT-001.
  PARAMETERS p_proc TYPE zcra_d_process_id DEFAULT 'EXAMPLE' OBLIGATORY.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_cons RADIOBUTTON GROUP mode DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 3(20) TEXT-002 FOR FIELD p_cons.
    PARAMETERS p_slg1 RADIOBUTTON GROUP mode.
    SELECTION-SCREEN COMMENT 30(20) TEXT-003 FOR FIELD p_slg1.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK sel.

START-OF-SELECTION.

  DATA(log_mode) = COND zcra_if_c_log_mode=>ty_mode(
                     WHEN p_slg1 = abap_true THEN zcra_if_c_log_mode=>slg1
                     ELSE zcra_if_c_log_mode=>console ).

  " Fassade mit zentraler Registrierung und gewähltem Protokollierungsmodus.
  DATA(runner) = NEW zcra_cl_engine_runner(
                       determination = zcra_cl_det_registry=>build( )
                       log_mode      = log_mode ).

  " Demo-Eingabegraph — leer; das Beispiel-Flag startet ungesetzt und wird
  " von der Transformation gekippt.
  DATA(input_graph) = VALUE zcra_s_graph( ).

  WRITE: / |=== ZCRA Rule Engine Test: Prozess { p_proc } ===|.
  ULINE.

  DATA result TYPE REF TO zcra_cl_result.
  TRY.
      result = runner->run( input_graph = input_graph
                            process      = p_proc ).
    CATCH zcra_cx_rule_kind INTO DATA(kind_error).
      WRITE: / |FEHLER - KIND/Bucket-Konflikt: { kind_error->get_text( ) }|.
      RETURN.
  ENDTRY.

  " Ergebnis-Meldungen.
  WRITE: / |--- Ergebnis-Meldungen ({ lines( result->get_messages( ) ) }) ---|.
  LOOP AT result->get_messages( ) INTO DATA(message).
    WRITE: / |{ message-type }  { message-id }/{ message-number }  { message-message_v1 }|.
  ENDLOOP.
  WRITE: / |STOP angefordert: { result->is_stop_requested( ) }   Fehler: { result->has_errors( ) }|.

  " Engine-Trace — nur im Modus CONSOLE gefüllt. Im Modus SLG1 nach SLG1
  " (Transaktion SLG1, Objekt ZCRA, Unterobjekt RUN) prüfen.
  ULINE.
  DATA(trace_lines) = runner->get_trace_lines( ).
  IF trace_lines IS INITIAL.
    WRITE: / `--- Engine-Trace: nur im Modus CONSOLE verfügbar (SLG1 -> Transaktion SLG1, Objekt ZCRA/RUN) ---`.
  ELSE.
    WRITE: / |--- Engine-Trace ({ lines( trace_lines ) }) ---|.
    LOOP AT trace_lines INTO DATA(trace_line).
      WRITE: / trace_line.
    ENDLOOP.
  ENDIF.

  " Endzustand des Graphen — die Transformation hat das Beispiel-Flag gekippt.
  ULINE.
  WRITE: / |Beispiel-Flag = '{ runner->get_result_graph( )-shell_placeholder }'|.
