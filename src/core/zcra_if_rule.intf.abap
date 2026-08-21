INTERFACE zcra_if_rule
  PUBLIC.

  "! Regel-Metadaten (Id, Zweck, Art).
  METHODS get_meta
    RETURNING VALUE(result) TYPE zcra_s_rule_meta.

  "! Gibt an, ob diese Regel auf den gegebenen Kontext anwendbar ist. Standard: true.
  METHODS exec_condition
    IMPORTING
      !context      TYPE REF TO zcra_if_context
    RETURNING VALUE(result) TYPE abap_bool.

  "! Validierungslogik (schreibgeschützter Kontext). Hängt Meldungen an das Ergebnis an.
  METHODS validate
    IMPORTING
      !context TYPE REF TO zcra_if_context
      !result  TYPE REF TO zcra_cl_result.

  "! Transformationslogik (veränderbarer Kontext). Hängt Meldungen an das Ergebnis an.
  METHODS transform
    IMPORTING
      !context TYPE REF TO zcra_if_context_mut
      !result  TYPE REF TO zcra_cl_result.

ENDINTERFACE.
