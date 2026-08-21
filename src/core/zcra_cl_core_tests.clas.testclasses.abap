"! Konfigurierbare Stub-Regel. Zählt Konstruktoraufrufe (statisch) und je-Instanz-
"! Ausführungen, sodass die Factory-Wiederverwendung durchgängig beobachtbar ist.
"! Eine Transformationsregel kann optional den neuen Graphen ändern, damit die
"! Snapshot-Inhaltserfassung beobachtbar ist.
CLASS lcl_rule DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zcra_if_rule.
    CLASS-DATA created TYPE i.
    DATA runs TYPE i READ-ONLY.
    METHODS constructor
      IMPORTING
        !id         TYPE zcra_d_rule_id
        !kind       TYPE zcra_s_rule_meta-kind
        !applicable TYPE abap_bool DEFAULT abap_true
        !emit_msg   TYPE abap_bool DEFAULT abap_false
        !do_stop    TYPE abap_bool DEFAULT abap_false
        !mutate     TYPE abap_bool DEFAULT abap_false.
  PRIVATE SECTION.
    DATA meta       TYPE zcra_s_rule_meta.
    DATA applicable TYPE abap_bool.
    DATA emit_msg   TYPE abap_bool.
    DATA do_stop    TYPE abap_bool.
    DATA mutate     TYPE abap_bool.
    METHODS act IMPORTING result TYPE REF TO zcra_cl_result.
ENDCLASS.

CLASS lcl_rule IMPLEMENTATION.
  METHOD constructor.
    created         = created + 1.
    meta-rule_id    = id.
    meta-kind       = kind.
    me->applicable  = applicable.
    me->emit_msg    = emit_msg.
    me->do_stop     = do_stop.
    me->mutate      = mutate.
  ENDMETHOD.
  METHOD zcra_if_rule~get_meta.
    result = meta.
  ENDMETHOD.
  METHOD zcra_if_rule~exec_condition.
    result = me->applicable.
  ENDMETHOD.
  METHOD zcra_if_rule~validate.
    me->runs = me->runs + 1.
    act( result ).
  ENDMETHOD.
  METHOD zcra_if_rule~transform.
    me->runs = me->runs + 1.
    IF me->mutate = abap_true.
      DATA(new_ref) = context->get_new_graph_ref( ).
      new_ref->shell_placeholder = 'X'.
    ENDIF.
    act( result ).
  ENDMETHOD.
  METHOD act.
    IF me->emit_msg = abap_true.
      result->add_message( severity = 'I' id = 'ZCRA_ENGINE' number = '000' ).
    ENDIF.
    IF me->do_stop = abap_true.
      result->request_stop( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


"! Determination auf Basis der echten ZCRA_CL_RULE_FACTORY. Bei jedem get_rules
"! wird eine frische Regelinstanz erzeugt und durch die Factory geleitet; ein
"! Wiederholungslauf trifft daher den Cache und verwendet die erste Instanz
"! wieder (D-21/D-39).
CLASS lcl_det_factory DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zcra_if_determination.
    METHODS constructor
      IMPORTING !factory TYPE REF TO zcra_cl_rule_factory.
    METHODS add
      IMPORTING
        !rule_type  TYPE zcra_if_c_rule_type=>ty_type
        !name       TYPE string
        !kind       TYPE zcra_s_rule_meta-kind
        !applicable TYPE abap_bool DEFAULT abap_true
        !emit_msg   TYPE abap_bool DEFAULT abap_false
        !do_stop    TYPE abap_bool DEFAULT abap_false
        !mutate     TYPE abap_bool DEFAULT abap_false.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_cfg,
             bucket     TYPE zcra_if_c_rule_type=>ty_type,
             name       TYPE string,
             id         TYPE zcra_d_rule_id,
             kind       TYPE zcra_s_rule_meta-kind,
             applicable TYPE abap_bool,
             emit_msg   TYPE abap_bool,
             do_stop    TYPE abap_bool,
             mutate     TYPE abap_bool,
           END OF ty_cfg.
    DATA factory TYPE REF TO zcra_cl_rule_factory.
    DATA configs TYPE STANDARD TABLE OF ty_cfg.
ENDCLASS.

CLASS lcl_det_factory IMPLEMENTATION.
  METHOD constructor.
    me->factory = factory.
  ENDMETHOD.
  METHOD add.
    APPEND VALUE #( bucket = rule_type name = name id = CONV #( name )
                    kind = kind applicable = applicable
                    emit_msg = emit_msg do_stop = do_stop mutate = mutate ) TO configs.
  ENDMETHOD.
  METHOD zcra_if_determination~has_rules.
    result = xsdbool( line_exists( configs[ bucket = rule_type ] ) ).
  ENDMETHOD.
  METHOD zcra_if_determination~get_rules.
    LOOP AT configs INTO DATA(cfg) WHERE bucket = rule_type.
      DATA(fresh) = CAST zcra_if_rule( NEW lcl_rule(
        id = cfg-id kind = cfg-kind applicable = cfg-applicable
        emit_msg = cfg-emit_msg do_stop = cfg-do_stop mutate = cfg-mutate ) ).
      APPEND me->factory->get_or_put( name = cfg-name rule = fresh ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_core DEFINITION FINAL
  FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA factory TYPE REF TO zcra_cl_rule_factory.
    DATA det     TYPE REF TO zcra_cl_determination.
    DATA log     TYPE REF TO zcra_cl_log_memory.

    METHODS setup.
    METHODS build IMPORTING determination TYPE REF TO zcra_if_determination.

    METHODS snapshot_captures_mutation FOR TESTING RAISING cx_static_check.
    METHODS factory_reuses_instances   FOR TESTING RAISING cx_static_check.
    METHODS stop_in_transform_skips_post FOR TESTING RAISING cx_static_check.
    METHODS null_logger_default_runs   FOR TESTING RAISING cx_static_check.
    METHODS accumulates_across_phases  FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_core IMPLEMENTATION.

  METHOD setup.
    lcl_rule=>created = 0.
    factory = NEW #( ).
    log     = NEW #( ).
  ENDMETHOD.

  METHOD build.
    det = NEW zcra_cl_determination( ).
    det->register( process = zcra_if_c_process=>anerkennung determination = determination ).
  ENDMETHOD.

  METHOD snapshot_captures_mutation.
    DATA(det_cfg) = NEW lcl_det_factory( factory ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_pre
                  name = 'VP' kind = zcra_if_c_rule_kind=>validation ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>transformation
                  name = 'TR' kind = zcra_if_c_rule_kind=>transformation
                  mutate = abap_true ).
    build( det_cfg ).

    DATA(engine) = NEW zcra_cl_engine(
      determination = det logger = log ).
    engine->run( process = zcra_if_c_process=>anerkennung
                 context = NEW zcra_cl_context( ) ).

    DATA(entries) = log->get_entries( ).
    DATA(before_json) = entries[ event = zcra_cl_log_memory=>gc_event-snapshot label = 'BEFORE' ]-json.
    DATA(after_json)  = entries[ event = zcra_cl_log_memory=>gc_event-snapshot label = 'AFTER' ]-json.

    " Der BEFORE-Snapshot wird vor der Transformation eingefroren => keine Änderungsmarke.
    cl_abap_unit_assert=>assert_false(
      act = xsdbool( before_json CS 'X' ) msg = 'BEFORE-Snapshot darf die Änderung nicht enthalten' ).
    " Der AFTER-Snapshot spiegelt den geänderten neuen Graphen wider.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( after_json CS 'X' ) msg = 'AFTER-Snapshot muss die Änderung erfassen' ).
  ENDMETHOD.

  METHOD factory_reuses_instances.
    DATA(det_cfg) = NEW lcl_det_factory( factory ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_pre
                  name = 'R' kind = zcra_if_c_rule_kind=>validation ).
    build( det_cfg ).

    DATA(engine) = NEW zcra_cl_engine( determination = det logger = log ).
    engine->run( process = zcra_if_c_process=>anerkennung context = NEW zcra_cl_context( ) ).
    engine->run( process = zcra_if_c_process=>anerkennung context = NEW zcra_cl_context( ) ).

    " Die Determination erzeugte für jeden der beiden Läufe eine frische Instanz...
    cl_abap_unit_assert=>assert_equals(
      act = lcl_rule=>created exp = 2 msg = 'Determination sollte je Lauf erzeugen' ).
    " ...aber die Engine führte beide Male die EINE gecachte Instanz aus (D-21/D-39).
    cl_abap_unit_assert=>assert_true( factory->has( 'R' ) ).
    DATA(cached) = CAST lcl_rule( factory->get( 'R' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = cached->runs exp = 2 msg = 'gecachte Instanz muss über Läufe wiederverwendet werden' ).
  ENDMETHOD.

  METHOD stop_in_transform_skips_post.
    DATA(det_cfg) = NEW lcl_det_factory( factory ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_pre
                  name = 'VP' kind = zcra_if_c_rule_kind=>validation ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>transformation
                  name = 'TR1' kind = zcra_if_c_rule_kind=>transformation do_stop = abap_true ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>transformation
                  name = 'TR2' kind = zcra_if_c_rule_kind=>transformation ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_post
                  name = 'VO' kind = zcra_if_c_rule_kind=>validation ).
    build( det_cfg ).

    DATA(engine) = NEW zcra_cl_engine( determination = det logger = log ).
    DATA(result) = engine->run( process = zcra_if_c_process=>anerkennung
                                context = NEW zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_true( result->is_stop_requested( ) ).
    DATA(entries) = log->get_entries( ).
    " TR2 (Rest der Transformationsphase) und VO (POST-Phase) dürfen nicht laufen.
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( entries[ rule_id = 'TR2' ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( entries[ rule_id = 'VO' ] ) ) ).
    " Beide Transformations-Snapshots werden dennoch um die (angehaltene) Phase aufgezeichnet.
    cl_abap_unit_assert=>assert_equals(
      act = log->count( zcra_cl_log_memory=>gc_event-snapshot ) exp = 2 ).
  ENDMETHOD.

  METHOD null_logger_default_runs.
    DATA(det_cfg) = NEW lcl_det_factory( factory ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_pre
                  name = 'VP' kind = zcra_if_c_rule_kind=>validation emit_msg = abap_true ).
    build( det_cfg ).

    " Kein Logger übergeben => Engine muss auf den No-op-Logger zurückfallen und laufen.
    DATA(engine) = NEW zcra_cl_engine( determination = det ).
    DATA(result) = engine->run( process = zcra_if_c_process=>anerkennung
                                context = NEW zcra_cl_context( ) ).

    cl_abap_unit_assert=>assert_bound( result ).
    cl_abap_unit_assert=>assert_equals( act = lines( result->get_messages( ) ) exp = 1 ).
    cl_abap_unit_assert=>assert_false( result->is_stop_requested( ) ).
  ENDMETHOD.

  METHOD accumulates_across_phases.
    DATA(det_cfg) = NEW lcl_det_factory( factory ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_pre
                  name = 'VP' kind = zcra_if_c_rule_kind=>validation emit_msg = abap_true ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>transformation
                  name = 'TR' kind = zcra_if_c_rule_kind=>transformation emit_msg = abap_true ).
    det_cfg->add( rule_type = zcra_if_c_rule_type=>validation_post
                  name = 'VO' kind = zcra_if_c_rule_kind=>validation emit_msg = abap_true ).
    build( det_cfg ).

    DATA(engine) = NEW zcra_cl_engine( determination = det logger = log ).
    DATA(result) = engine->run( process = zcra_if_c_process=>anerkennung
                                context = NEW zcra_cl_context( ) ).

    " Je eine Meldung aus jeder der drei Phasen.
    cl_abap_unit_assert=>assert_equals( act = lines( result->get_messages( ) ) exp = 3 ).
    " Vollständige Ereignishülle vorhanden: START ... END.
    DATA(entries) = log->get_entries( ).
    cl_abap_unit_assert=>assert_equals( act = entries[ 1 ]-event exp = zcra_cl_log_memory=>gc_event-start ).
    cl_abap_unit_assert=>assert_equals(
      act = entries[ lines( entries ) ]-event exp = zcra_cl_log_memory=>gc_event-end ).
  ENDMETHOD.

ENDCLASS.
