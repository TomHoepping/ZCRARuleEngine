INTERFACE zcra_if_c_log_mode
  PUBLIC.

  "! Protokollierungsmodus für die Engine-Fassade (ZCRA_CL_ENGINE_RUNNER).
  TYPES ty_mode TYPE c LENGTH 1.

  "! Keine Protokollierung (No-op-Logger).
  CONSTANTS none    TYPE ty_mode VALUE '0'.
  "! Nur Ausgabe: In-Memory-Logger; der Trace kann per GET_TRACE_LINES( ) abgerufen werden.
  CONSTANTS console TYPE ty_mode VALUE '1'.
  "! Persistente Protokollierung nach SLG1 (BAL-Objekt ZCRA/RUN).
  CONSTANTS slg1    TYPE ty_mode VALUE '2'.

ENDINTERFACE.
