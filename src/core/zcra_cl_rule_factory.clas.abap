CLASS zcra_cl_rule_factory DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Gibt an, ob unter dem Namen eine Instanz zwischengespeichert ist.
    METHODS has
      IMPORTING
        !name         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! Zwischengespeicherte Instanz zum Namen (initiale Referenz, wenn keine).
    METHODS get
      IMPORTING
        !name         TYPE string
      RETURNING
        VALUE(result) TYPE REF TO zcra_if_rule.

    "! Speichert eine Instanz unter dem Namen (überschreibt eine vorhandene).
    METHODS put
      IMPORTING
        !name TYPE string
        !rule TYPE REF TO zcra_if_rule.

    "! Liefert die zwischengespeicherte Instanz, oder speichert die übergebene
    "! und liefert sie. Bei einem Wiederholungsaufruf wird die gecachte Instanz
    "! geliefert (Cache-Treffer) und die übergebene Regel ignoriert. Aufrufer
    "! übergeben eine direkt per NEW erzeugte Instanz, sodass zustandslose Regeln
    "! einmal erzeugt und wiederverwendet werden.
    METHODS get_or_put
      IMPORTING
        !name         TYPE string
        !rule         TYPE REF TO zcra_if_rule
      RETURNING
        VALUE(result) TYPE REF TO zcra_if_rule.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_cache,
        name TYPE string,
        rule TYPE REF TO zcra_if_rule,
      END OF ty_cache.

    DATA cache TYPE HASHED TABLE OF ty_cache WITH UNIQUE KEY name.

ENDCLASS.



CLASS zcra_cl_rule_factory IMPLEMENTATION.

  METHOD has.
    result = xsdbool( line_exists( cache[ name = name ] ) ).
  ENDMETHOD.

  METHOD get.
    result = VALUE #( cache[ name = name ]-rule OPTIONAL ).
  ENDMETHOD.

  METHOD put.
    DATA entry TYPE ty_cache.
    entry-name = name.
    entry-rule = rule.
    DELETE cache WHERE name = entry-name.
    INSERT entry INTO TABLE cache.
  ENDMETHOD.

  METHOD get_or_put.
    DATA(existing) = VALUE #( cache[ name = name ]-rule OPTIONAL ).
    IF existing IS BOUND.
      result = existing.
      RETURN.
    ENDIF.
    DATA entry TYPE ty_cache.
    entry-name = name.
    entry-rule = rule.
    INSERT entry INTO TABLE cache.
    result = rule.
  ENDMETHOD.

ENDCLASS.
