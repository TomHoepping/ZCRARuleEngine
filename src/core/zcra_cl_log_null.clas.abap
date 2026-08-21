CLASS zcra_cl_log_null DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zcra_if_logger.
    "! Komfort-Singleton (der Logger ist zustandslos).
    CLASS-METHODS get_instance
      RETURNING VALUE(result) TYPE REF TO zcra_if_logger.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA instance TYPE REF TO zcra_if_logger.
ENDCLASS.



CLASS zcra_cl_log_null IMPLEMENTATION.

  METHOD get_instance.
    IF instance IS INITIAL.
      instance = NEW zcra_cl_log_null( ).
    ENDIF.
    result = instance.
  ENDMETHOD.

  METHOD zcra_if_logger~start_run.
  ENDMETHOD.

  METHOD zcra_if_logger~log_rule.
  ENDMETHOD.

  METHOD zcra_if_logger~snapshot.
  ENDMETHOD.

  METHOD zcra_if_logger~end_run.
  ENDMETHOD.

ENDCLASS.
