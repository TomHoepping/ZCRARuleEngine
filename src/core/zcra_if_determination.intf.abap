INTERFACE zcra_if_determination
  PUBLIC.

  "! Geordnete Liste von Regelinstanzen.
  TYPES tt_rules TYPE STANDARD TABLE OF REF TO zcra_if_rule WITH EMPTY KEY.

  "! Gibt an, ob dieser Prozess Regeln für den angegebenen TYPE-Bucket liefert
  "! (VALIDATION_PRE / TRANSFORMATION / VALIDATION_POST).
  METHODS has_rules
    IMPORTING
      !rule_type    TYPE zcra_if_c_rule_type=>ty_type
    RETURNING
      VALUE(result) TYPE abap_bool.

  "! Geordnete Regelinstanzen für den angegebenen TYPE-Bucket (in SEQNO-Reihenfolge).
  METHODS get_rules
    IMPORTING
      !rule_type    TYPE zcra_if_c_rule_type=>ty_type
    RETURNING
      VALUE(result) TYPE tt_rules.

ENDINTERFACE.
