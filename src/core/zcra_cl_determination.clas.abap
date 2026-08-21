CLASS zcra_cl_determination DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Registriert eine prozessspezifische Determination. Die Instanz wird vom
    "! Aufrufer per direktem NEW erzeugt (kein dynamisches CREATE OBJECT). Eine
    "! erneute Registrierung überschreibt die bisherige Zuordnung.
    "! @parameter process       | Prozesskennung.
    "! @parameter determination | Determination-Instanz für den Prozess.
    METHODS register
      IMPORTING
        !process       TYPE zcra_d_process_id
        !determination TYPE REF TO zcra_if_determination.

    "! Gibt an, ob der Prozess Regeln für den angegebenen TYPE-Bucket liefert.
    "! @parameter process   | Prozesskennung.
    "! @parameter rule_type | Determination-Bucket.
    "! @parameter result    | Wahr, wenn Regeln vorhanden sind.
    METHODS has_rules
      IMPORTING
        !process      TYPE zcra_d_process_id
        !rule_type    TYPE zcra_if_c_rule_type=>ty_type
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! Geordnete Regelinstanzen für Prozess + TYPE-Bucket. Leer, wenn der
    "! Prozess nicht registriert ist.
    "! @parameter process   | Prozesskennung.
    "! @parameter rule_type | Determination-Bucket.
    "! @parameter result    | Geordnete Regelinstanzen.
    METHODS get_rules
      IMPORTING
        !process      TYPE zcra_d_process_id
        !rule_type    TYPE zcra_if_c_rule_type=>ty_type
      RETURNING
        VALUE(result) TYPE zcra_if_determination=>tt_rules.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_registration,
        process TYPE zcra_d_process_id,
        det     TYPE REF TO zcra_if_determination,
      END OF ty_registration.

    DATA registry TYPE HASHED TABLE OF ty_registration WITH UNIQUE KEY process.

    METHODS find
      IMPORTING
        !process      TYPE zcra_d_process_id
      RETURNING
        VALUE(result) TYPE REF TO zcra_if_determination.

ENDCLASS.



CLASS zcra_cl_determination IMPLEMENTATION.

  METHOD register.
    DATA registration TYPE ty_registration.
    registration-process = process.
    registration-det     = determination.
    DELETE registry WHERE process = registration-process.
    INSERT registration INTO TABLE registry.
  ENDMETHOD.

  METHOD find.
    result = VALUE #( registry[ process = process ]-det OPTIONAL ).
  ENDMETHOD.

  METHOD has_rules.
    DATA(determination) = find( process ).
    IF determination IS BOUND.
      result = determination->has_rules( rule_type ).
    ENDIF.
  ENDMETHOD.

  METHOD get_rules.
    DATA(determination) = find( process ).
    IF determination IS BOUND.
      result = determination->get_rules( rule_type ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
