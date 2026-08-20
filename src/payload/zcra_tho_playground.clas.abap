CLASS zcra_tho_playground DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCRA_THO_PLAYGROUND IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    out->write( '--- Sandbox Playground --- ' ).
    out->write( '--- Simple Wrapper Class to test Framework from Console without ATC --- ' ).


  ENDMETHOD.
ENDCLASS.
