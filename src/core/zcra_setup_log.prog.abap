REPORT zcra_setup_log.

* One-time provisioning for the CRA Rule Engine logging infrastructure.
* Creates (idempotently):
*   - Message class ZCRA_ENGINE (via RPY_MESSAGE_ID_INSERT: TADIR + transport).
*   - BAL log object ZCRA with subobjects RUN and RULE (SLG0 tables).
* BAL objects are not abapGit-serializable, so this report is the git-tracked,
* reproducible source of truth for their creation. Re-runnable safely.

CONSTANTS: gc_msgid   TYPE arbgb    VALUE 'ZCRA_ENGINE',
           gc_balobj  TYPE balobj-object VALUE 'ZCRA',
           gc_transp  TYPE trkorr   VALUE 'S01K901334',
           gc_devclas TYPE devclass VALUE 'ZCRA_RULE_ENGINE_CORE'.

START-OF-SELECTION.

* ---------------------------------------------------------------------
* Message class ZCRA_ENGINE
* ---------------------------------------------------------------------
  SELECT SINGLE arbgb FROM t100a INTO @DATA(lv_arbgb) WHERE arbgb = @gc_msgid.
  IF sy-subrc <> 0.
    DATA lt_source TYPE STANDARD TABLE OF t100.
    lt_source = VALUE #(
      sprsl = sy-langu arbgb = gc_msgid
      ( msgnr = '000' text = '&1&2&3&4' )
      ( msgnr = '001' text = 'Engine run started: process &1' )
      ( msgnr = '002' text = 'Engine run finished: process &1' )
      ( msgnr = '003' text = 'Rule &1 skipped by condition' )
      ( msgnr = '004' text = 'Rule &1 requested stop' )
      ( msgnr = '005' text = 'No rules for process &1 / kind &2' ) ).

    CALL FUNCTION 'RPY_MESSAGE_ID_INSERT'
      EXPORTING
        development_class = gc_devclas
        language          = sy-langu
        message_id        = gc_msgid
        r2_flag           = space
        temporary         = space
        title_string      = 'CRA Rule Engine: messages'
        transport_number  = gc_transp
      TABLES
        source            = lt_source
      EXCEPTIONS
        already_exists    = 1
        cancelled         = 2
        name_not_allowed  = 3
        permission_error  = 4
        already_exist     = 5
        OTHERS            = 6.
    WRITE: / 'MSAG', gc_msgid, 'insert rc =', sy-subrc.
  ELSE.
    WRITE: / 'MSAG', gc_msgid, 'already exists'.
  ENDIF.

* ---------------------------------------------------------------------
* BAL log object ZCRA + subobjects RUN, RULE
* ---------------------------------------------------------------------
  DATA ls_obj  TYPE balobj.
  DATA ls_objt TYPE balobjt.
  ls_obj-object = gc_balobj.
  MODIFY balobj FROM ls_obj.
  ls_objt-spras  = sy-langu.
  ls_objt-object = gc_balobj.
  ls_objt-objtxt = 'CRA Rule Engine'.
  MODIFY balobjt FROM ls_objt.

  DATA ls_sub  TYPE balsub.
  DATA ls_subt TYPE balsubt.

  ls_sub-object = gc_balobj.
  ls_sub-subobject = 'RUN'.
  INSERT balsub FROM ls_sub. "#EC dup key ok
  ls_subt-spras = sy-langu.
  ls_subt-object = gc_balobj.
  ls_subt-subobject = 'RUN'.
  ls_subt-subobjtxt = 'Engine run'.
  MODIFY balsubt FROM ls_subt.

  CLEAR ls_sub.
  CLEAR ls_subt.
  ls_sub-object = gc_balobj.
  ls_sub-subobject = 'RULE'.
  INSERT balsub FROM ls_sub. "#EC dup key ok
  ls_subt-spras = sy-langu.
  ls_subt-object = gc_balobj.
  ls_subt-subobject = 'RULE'.
  ls_subt-subobjtxt = 'Rule execution'.
  MODIFY balsubt FROM ls_subt.

  COMMIT WORK AND WAIT.
  WRITE: / 'BAL object', gc_balobj, '+ subobjects RUN, RULE provisioned'.
