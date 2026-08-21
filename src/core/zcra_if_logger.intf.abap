INTERFACE zcra_if_logger
  PUBLIC.

  "! Protokolliert den Start eines Engine-Laufs für den angegebenen Prozess.
  METHODS start_run
    IMPORTING
      !process TYPE zcra_d_process_id.
  "! Protokolliert das Ergebnis einer einzelnen Regel: Metadaten, ob sie angewandt wurde,
  "! die bisher gesammelten Ergebnismeldungen und ob ein Abbruch angefordert wurde.
  METHODS log_rule
    IMPORTING
      !meta       TYPE zcra_s_rule_meta
      !applicable TYPE abap_bool
      !result     TYPE REF TO zcra_cl_result.
  "! Hängt einen JSON-Snapshot der Kontext-Graphen unter einem Label an
  "! (z. B. BEFORE / AFTER einer Transformationsphase).
  METHODS snapshot
    IMPORTING
      !label   TYPE string
      !context TYPE REF TO zcra_if_context.
  "! Protokolliert das Ende eines Engine-Laufs und sichert das Protokoll (BAL-Impl).
  METHODS end_run
    IMPORTING
      !process TYPE zcra_d_process_id.

ENDINTERFACE.
