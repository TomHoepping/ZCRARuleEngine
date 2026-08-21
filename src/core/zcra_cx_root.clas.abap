CLASS zcra_cx_root DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Optionaler technischer Freitext zur Fehlermeldung.
    DATA text TYPE string READ-ONLY.

    "! @parameter textid   | Nachrichtentextkennung der Ausnahme.
    "! @parameter previous | Vorausgehende (verkettete) Ausnahme.
    "! @parameter text     | Optionaler technischer Freitext.
    METHODS constructor
      IMPORTING
        !textid   LIKE textid OPTIONAL
        !previous LIKE previous OPTIONAL
        !text     TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcra_cx_root IMPLEMENTATION.

  METHOD constructor.
    super->constructor( textid = textid previous = previous ).
    me->text = text.
  ENDMETHOD.

  METHOD get_text.
    IF me->text IS NOT INITIAL.
      result = me->text.
    ELSE.
      result = super->get_text( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
