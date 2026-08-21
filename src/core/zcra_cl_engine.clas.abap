CLASS zcra_cl_engine DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! @parameter determination | Zentraler Prozess->Determination-Dispatcher.
    "! @parameter logger         | Technischer Logger; Standard ist der No-op-Logger.
    METHODS constructor
      IMPORTING
        !determination TYPE REF TO zcra_cl_determination
        !logger        TYPE REF TO zcra_if_logger OPTIONAL.

    "! Reiner Lauf der Regel-Engine für einen Prozess über einen Kontext.
    "! Ablauf (D-02, D-19, D-30): VALIDATION_PRE -> TRANSFORMATION -> VALIDATION_POST.
    "! Jede Phase wird übersprungen, wenn ihr Bucket leer ist; die Transformationsphase
    "! wird in einen Vorher/Nachher-Kontext-Snapshot eingefasst (D-16). Eine STOP-
    "! Anforderung hält die restlichen Regeln der aktuellen Phase an und überspringt
    "! alle späteren Phasen; alle bis dahin gesammelten Meldungen werden dennoch
    "! zurückgegeben.
    "! @parameter process | Prozesskennung.
    "! @parameter context | Veränderbarer Kontext (alter/neuer Graph).
    "! @parameter result  | Gesammelte Meldungen und STOP-Status.
    "! @raising zcra_cx_rule_kind | die KIND einer Regel passt nicht zum Bucket (D-33).
    METHODS run
      IMPORTING
        !process      TYPE zcra_d_process_id
        !context      TYPE REF TO zcra_if_context_mut
      RETURNING
        VALUE(result) TYPE REF TO zcra_cl_result
      RAISING
        zcra_cx_rule_kind.

  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA determination TYPE REF TO zcra_cl_determination.
    DATA logger        TYPE REF TO zcra_if_logger.
    DATA context       TYPE REF TO zcra_if_context_mut.
    DATA result        TYPE REF TO zcra_cl_result.
    DATA process       TYPE zcra_d_process_id.

    METHODS run_phase
      IMPORTING
        !rule_type TYPE zcra_if_c_rule_type=>ty_type
      RAISING
        zcra_cx_rule_kind.

    "! Prüft, ob die KIND der Regel zur erwarteten KIND des TYPE-Buckets passt (D-33).
    METHODS assert_kind_vs_bucket
      IMPORTING
        !rule_type TYPE zcra_if_c_rule_type=>ty_type
        !meta      TYPE zcra_s_rule_meta
      RAISING
        zcra_cx_rule_kind.

ENDCLASS.



CLASS zcra_cl_engine IMPLEMENTATION.

  METHOD constructor.
    me->determination = determination.
    IF logger IS BOUND.
      me->logger = logger.
    ELSE.
      me->logger = zcra_cl_log_null=>get_instance( ).
    ENDIF.
  ENDMETHOD.

  METHOD run.
    me->context = context.
    me->process = process.
    me->result  = NEW zcra_cl_result( ).
    result      = me->result.

    me->logger->start_run( me->process ).

    run_phase( zcra_if_c_rule_type=>validation_pre ).

    IF me->result->is_stop_requested( ) = abap_false
       AND me->determination->has_rules( process   = me->process
                                         rule_type = zcra_if_c_rule_type=>transformation ) = abap_true.
      me->logger->snapshot( label = 'BEFORE' context = me->context ).
      run_phase( zcra_if_c_rule_type=>transformation ).
      me->logger->snapshot( label = 'AFTER' context = me->context ).
    ENDIF.

    IF me->result->is_stop_requested( ) = abap_false.
      run_phase( zcra_if_c_rule_type=>validation_post ).
    ENDIF.

    me->logger->end_run( me->process ).
  ENDMETHOD.

  METHOD run_phase.
    LOOP AT me->determination->get_rules( process   = me->process
                                          rule_type = rule_type ) INTO DATA(rule).
      DATA(meta) = rule->get_meta( ).
      assert_kind_vs_bucket( rule_type = rule_type meta = meta ).

      IF rule->exec_condition( me->context ) = abap_false.
        me->logger->log_rule( meta = meta applicable = abap_false result = me->result ).
        CONTINUE.
      ENDIF.

      CASE rule_type.
        WHEN zcra_if_c_rule_type=>transformation.
          rule->transform( context = me->context result = me->result ).
        WHEN OTHERS.
          rule->validate( context = me->context result = me->result ).
      ENDCASE.

      me->logger->log_rule( meta = meta applicable = abap_true result = me->result ).

      " Bei STOP-Anforderung die restlichen Regeln dieser Phase abbrechen.
      IF me->result->is_stop_requested( ) = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD assert_kind_vs_bucket.
    DATA expected_kind TYPE zcra_s_rule_meta-kind.
    CASE rule_type.
      WHEN zcra_if_c_rule_type=>transformation.
        expected_kind = zcra_if_c_rule_kind=>transformation.
      WHEN OTHERS.
        expected_kind = zcra_if_c_rule_kind=>validation.
    ENDCASE.
    IF meta-kind <> expected_kind.
      RAISE EXCEPTION TYPE zcra_cx_rule_kind.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
